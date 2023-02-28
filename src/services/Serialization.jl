
# TODO dev and debugging, used by some of the DFG drivers
export _packSolverData

# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

## Version checking
# FIXME return VersionNumber
function _getDFGVersion()
    if haskey(Pkg.dependencies(), Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04"))
        return string(Pkg.dependencies()[Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04")].version) |> VersionNumber
    else
        # This is arguably slower, but needed for Travis.
        return Pkg.TOML.parse(read(joinpath(dirname(pathof(@__MODULE__)), "..", "Project.toml"), String))["version"] |> VersionNumber
    end
end

function _versionCheck(node::Union{<:PackedVariable, <:PackedFactor})
    if VersionNumber(node._version) < _getDFGVersion()
        @warn "This data was serialized using DFG $(props["_version"]) but you have $(_getDFGVersion()) installed, there may be deserialization issues." maxlog=10
    end
end

## Utility functions for ZonedDateTime

# variableType module.type string functions
function typeModuleName(variableType::InferenceVariable)
    io = IOBuffer()
    ioc = IOContext(io, :module=>DistributedFactorGraphs)
    show(ioc, typeof(variableType))
    return String(take!(io))
end

typeModuleName(varT::Type{<:InferenceVariable}) = typeModuleName(varT())

"""
  $(SIGNATURES)
Get a type from the serialization module.
"""
function getTypeFromSerializationModule(_typeString::AbstractString)
    @debug "DFG converting type string to Julia type" _typeString
    try
        # split the type at last `.`
        split_st = split(_typeString, r"\.(?!.*\.)")
        #if module is specified look for the module in main, otherwise use Main        
        if length(split_st) == 2
            m = getfield(Main, Symbol(split_st[1]))
        else
            m = Main
        end
        noparams = split(split_st[end], r"{") 
        ret = if 1 < length(noparams)
            # fix #671, but does not work with specific module yet
            bidx = findfirst(r"{", split_st[end])[1]
            Core.eval(m, Base.Meta.parse("$(noparams[1])$(split_st[end][bidx:end])"))
            # eval(Base.Meta.parse("Main.$(noparams[1])$(split_st[end][bidx:end])"))
        else
            getfield(m, Symbol(split_st[end]))
        end

        return ret 

    catch ex
        @error "Unable to deserialize type $(_typeString)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    nothing
end

# returns a PackedVariableNodeData
function packVariableNodeData(d::VariableNodeData{T}) where {T <: InferenceVariable}
  @debug "Dispatching conversion variable -> packed variable for type $(string(d.variableType))"
  castval = if 0 < length(d.val)
    precast = getCoordinates.(T, d.val)
    @cast castval[i,j] := precast[j][i]
    castval
  else
    zeros(1,0)
  end
  _val = castval[:]
  return PackedVariableNodeData(d.id, _val, size(castval,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                typeModuleName(d.variableType),
                                d.initialized,
                                d.infoPerCoord,
                                d.ismargin,
                                d.dontmargin,
                                d.solveInProgress,
                                d.solvedCount,
                                d.solveKey,
                                string(_getDFGVersion()))
end

function unpackVariableNodeData(d::PackedVariableNodeData)
    @debug "Dispatching conversion packed variable -> variable for type $(string(d.variableType))"
    # Figuring out the variableType
    # TODO deprecated remove in v0.11 - for backward compatibility for saved variableTypes. 
    ststring = string(split(d.variableType, "(")[1])
    T = getTypeFromSerializationModule(ststring)
    isnothing(T) && error("The variable doesn't seem to have a variableType. It needs to set up with an InferenceVariable from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().")
    
    r3 = d.dimval
    c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
    M3 = reshape(d.vecval,r3,c3)
    @cast val_[j][i] := M3[i,j]
    vals = Vector{getPointType(T)}(undef, length(val_))
    # vals = getPoint.(T, val_)
    for (i,v) in enumerate(val_)
      vals[i] = getPoint(T, v)
    end
    
    r4 = d.dimbw
    c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
    BW = reshape(d.vecbw,r4,c4)

    # 
    return VariableNodeData{T, getPointType(T)}(
        d.id,
        vals, 
        BW, 
        Symbol.(d.BayesNetOutVertIDs),
        d.dimIDs, 
        d.dims, 
        d.eliminated, 
        Symbol(d.BayesNetVertID), 
        Symbol.(d.separator),
        T(), 
        d.initialized, 
        d.infoPerCoord, 
        d.ismargin, 
        d.dontmargin, 
        d.solveInProgress, 
        d.solvedCount, 
        Symbol(d.solveKey),
        Dict{Symbol,Threads.Condition}() )
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================

function packVariable(v::AbstractDFGVariable; includePPEs::Bool=true, includeSolveData::Bool=true, includeDataEntries::Bool=true)
    return PackedVariable(;
        id=v.id,
        label = v.label,
        timestamp = v.timestamp,
        nstime = v.nstime.value,
        tags = collect(v.tags), # Symbol.()
        ppes = collect(values(v.ppeDict)),
        solverData = packVariableNodeData.(collect(values(v.solverDataDict))),
        metadata = base64encode(JSON3.write(v.smallData)),
        solvable = v.solvable,
        variableType = DFG.typeModuleName(DFG.getVariableType(v)),
        dataEntries = collect(values(v.dataDict)),
        _version = DFG._getDFGVersion())
end
  
function unpackVariable(variable::PackedVariable; skipVersionCheck::Bool=false)
    !skipVersionCheck && _versionCheck(variable)

    # Variable and point type
    variableType = DFG.getTypeFromSerializationModule(variable.variableType)
    isnothing(variableType) && error("Cannot deserialize variableType '$(variable.variableType)' in variable '$(variable.label)'")
    pointType = DFG.getPointType(variableType)

    ppeDict = Dict{Symbol, MeanMaxPPE}(map(p->p.solveKey, variable.ppes) .=> variable.ppes)
    solverDict = Dict{Symbol, VariableNodeData{variableType, pointType}}(
        map(sd -> sd.solveKey, variable.solverData) .=> 
        map(sd -> DFG.unpackVariableNodeData(sd), variable.solverData))
    dataDict = Dict{Symbol, BlobEntry}(map(de -> de.label, variable.dataEntries) .=> variable.dataEntries)
    metadata = JSON3.read(base64decode(variable.metadata), Dict{Symbol, DFG.SmallDataTypes})

    return DFGVariable(
        id = variable.id,
        variable.label, 
        variableType, 
        timestamp=variable.timestamp, 
        nstime=Nanosecond(variable.nstime), 
        tags=Set(variable.tags), 
        estimateDict=ppeDict, 
        solverDataDict=solverDict,  
        smallData=metadata, 
        dataDict=dataDict, 
        solvable=variable.solvable )
    end

##==============================================================================
## Factor Packing and unpacking
##==============================================================================


function _packSolverData(
        f::DFGFactor, 
        fnctype::AbstractFactor)
    #
    packtype = convertPackedType(fnctype)
    try
        packed = convert( PackedFunctionNodeData{packtype}, getSolverData(f) )
        packedJson = packed
        return packedJson
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end
end

# returns ::Dict{String, <:Any}
function packFactor(dfg::AbstractDFG, f::DFGFactor)
    fnctype = getSolverData(f).fnc.usrfnc!
    return PackedFactor(;    
        id = f.id !== nothing ? string(f.id) : nothing,
        label = f.label,
        tags = collect(f.tags),
        _variableOrderSymbols = f._variableOrderSymbols,
        timestamp = f.timestamp,
        nstime = f.nstime.value,
        fnctype = String(_getname(fnctype)),
        solvable = getSolvable(f),
        metadata = base64encode(JSON3.write(f.smallData)),
        # Pack the node data
        data = JSON3.write(_packSolverData(f, fnctype)),
        _version = string(_getDFGVersion()))
    return props
end

function reconstFactorData() end

function decodePackedType(dfg::AbstractDFG, varOrder::AbstractVector{Symbol}, ::Type{T}, packeddata::GenericFunctionNodeData{PT}) where {T<:FactorOperationalMemory, PT}
    #
    # TODO, to solve IIF 1424
    # variables = map(lb->getVariable(dfg, lb), varOrder)

    # Also look at parentmodule
    usrtyp = convertStructType(PT)
    fulltype = DFG.FunctionNodeData{T{usrtyp}}
    factordata = reconstFactorData(dfg, varOrder, fulltype, packeddata)
    return factordata
end

# TODO: REFACTOR THIS AS A JSON3 STRUCT DESERIALIZER.
function fncStringToData(packtype::Type{<:AbstractPackedFactor}, data::String)

    # Convert string to Named Tuples for kwargs
    # packed = JSON3.read(data, GenericFunctionNodeData{packtype})
    fncData = JSON3.read(data, Dict{String,Any})

    # data isa AbstractString ? JSON2.read(data) : data
    
    # TODO use kwdef constructors instead,
    @show fncData["fnc"]
    packT = JSON3.read(JSON3.write(fncData["fnc"]), packtype)
    # nt = NamedTuple{}
    # packtype(;fncData["fnc"]...)

    packed = GenericFunctionNodeData{packtype}(
        fncData["eliminated"],
        fncData["potentialused"],
        fncData["edgeIDs"],
        # NamedTuple args become kwargs with the splat
        packT,
        fncData["multihypo"],
        fncData["certainhypo"],
        fncData["nullhypo"],
        fncData["solveInProgress"],
        fncData["inflation"],
    )
    return packed
end
fncStringToData(packtype::Type{<:AbstractPackedFactor}, data::NamedTuple) = error("Who is calling deserialize factor with NamedTuple, likely JSON2 somewhere")

fncStringToData(::Type{T}, data::PackedFunctionNodeData{T}) where {T <: AbstractPackedFactor} = data
function fncStringToData(fncType::String, data::PackedFunctionNodeData{T}) where {T <: AbstractPackedFactor}
    packtype = DFG.getTypeFromSerializationModule("Packed"*fncType)
    if packtype == T
        data
    else
        error("Unknown type conversion\n$(fncType)\n$packtype\n$(PackedFunctionNodeData{T})")
    end
end

function fncStringToData(fncType::String, data::T) where {T <: AbstractPackedFactor}
    packtype = DFG.getTypeFromSerializationModule("Packed"*fncType)
    if packtype == T # || T <: packtype
        data
    else
        fncStringToData(packtype, data)
    end
end
function fncStringToData(fncType::String, data::Union{String, <:NamedTuple})
    packtype = DFG.getTypeFromSerializationModule("Packed"*fncType)
    fncStringToData(packtype, data)
end


# Returns `::DFGFactor`
function unpackFactor(
    dfg::G, 
    packedFactor::PackedFactor;
    skipVersionCheck::Bool=false
) where G <: AbstractDFG
    # Version checking.
    !skipVersionCheck && _versionCheck(packedFactor)

    # id = if haskey(packedProps, "id") && packedProps["id"] !== nothing 
    #     UUID(packedProps["id"]) else nothing end
    # label = packedProps["label"]

    # # various formats in which the timestamp might be stored
    # packedProps["timestamp"] = getStandardZDTString(packedProps["timestamp"])
    # timestamp = ZonedDateTime(packedProps["timestamp"])
    # nstime = Nanosecond(get(packedProps, "nstime", 0))

    # Get the stored tags and variable order
    # @assert !(packedProps["tags"] isa String) "unpackFactor expecting JSON only data, packed `tags` should be a vector of strings (not a single string of elements)."
    # @assert !(packedProps["_variableOrderSymbols"] isa String) "unpackFactor expecting JSON only data, packed `_variableOrderSymbols` should be a vector of strings (not a single string of elements)."
    # tags = Symbol.(packedProps["tags"])
    # _variableOrderSymbols = Symbol.(packedProps["_variableOrderSymbols"])

    data = packedFactor.data
    # if(data isa AbstractString)
    # data = JSON3.read(data, NamedTuple) # was a JSON2
    # end
    datatype = packedFactor.fnctype
    @debug "DECODING factor type = '$(datatype)' for factor '$label'"
    # packtype = getTypeFromSerializationModule("Packed"*datatype)

    # FIXME type instability from nothing to T
    packed = nothing
    fullFactorData = nothing
    
    try
        packed = fncStringToData(datatype, data) #convert(GenericFunctionNodeData{packtype}, data) 
        decodeType = getFactorOperationalMemoryType(dfg)
        fullFactorData = decodePackedType(dfg, packedFactor._variableOrderSymbols, decodeType, packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while unpacking '$(packedFactor.label)' as '$datatype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end

    # solvable = packedProps["solvable"]

    smallData = JSON3.read(base64decode(packedFactor.metadata), Dict{Symbol, DFG.SmallDataTypes})
    # Rebuild DFGFactor
    #TODO use constuctor to create factor
    factor = DFGFactor( packedFactor.label,
                        packedFactor.timestamp,
                        Nanosecond(packedFactor.nstime),
                        Set(packedFactor.tags),
                        fullFactorData,
                        packedFactor.solvable,
                        Tuple(packedFactor._variableOrderSymbols);
                        packedFactor.id,
                        smallData)
    #

    # Note, once inserted, you still need to call rebuildFactorMetadata!
    return factor
end


##==============================================================================
## Serialization
##==============================================================================


