
# TODO dev and debugging, used by some of the DFG drivers
export _packSolverData

# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

## Version checking
#NOTE fixed really bad function but kept similar as fallback #TODO upgrade to use pkgversion(m::Module)
function _getDFGVersion()

    if VERSION >= v"1.9"
        return pkgversion(DistributedFactorGraphs)
    end
    #TODO when we drop jl<1.9 remove the rest here
    pkgorigin = get(Base.pkgorigins, Base.PkgId(DistributedFactorGraphs), nothing) 
    if !isnothing(pkgorigin) && !isnothing(pkgorigin.version) 
        return pkgorigin.version
    end
    dep = get(Pkg.dependencies(), Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04"), nothing)
    if !isnothing(dep)
        return dep.version
    else
        # This is arguably slower, but needed for Travis.
        return Pkg.TOML.parse(read(joinpath(dirname(pathof(@__MODULE__)), "..", "Project.toml"), String))["version"] |> VersionNumber
    end
end

function _versionCheck(node::Union{<:PackedVariable, <:PackedFactor})
    if VersionNumber(node._version) < _getDFGVersion()
        @warn "This data was serialized using DFG $(node._version) but you have $(_getDFGVersion()) installed, there may be deserialization issues." maxlog=10
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
  @debug "Dispatching conversion variable -> packed variable for type $(string(getVariableType(d)))"
  castval = if 0 < length(d.val)
    precast = getCoordinates.(T, d.val)
    @cast castval[i,j] := precast[j][i]
    castval
  else
    zeros(1,0)
  end
  _val = castval[:]

  length(d.covar) > 1 && @warn("Packing of more than one parametric covariance is NOT supported yet, only packing first.")
  
  return PackedVariableNodeData(d.id, _val, size(castval,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                typeModuleName(getVariableType(d)),
                                d.initialized,
                                d.infoPerCoord,
                                d.ismargin,
                                d.dontmargin,
                                d.solveInProgress,
                                d.solvedCount,
                                d.solveKey,
                                isempty(d.covar) ? Float64[] : vec(d.covar[1]),
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
    N = getDimension(T)
    return VariableNodeData{T, getPointType(T), N}(;
        id = d.id,
        val = vals, 
        bw = BW, 
        #TODO only one covar is currently supported in packed VND
        covar = isempty(d.covar) ? SMatrix{N, N, Float64}[] : [d.covar],
        BayesNetOutVertIDs = Symbol.(d.BayesNetOutVertIDs),
        dimIDs = d.dimIDs, 
        dims = d.dims, 
        eliminated = d.eliminated, 
        BayesNetVertID = Symbol(d.BayesNetVertID), 
        separator = Symbol.(d.separator),
        initialized = d.initialized, 
        infoPerCoord = d.infoPerCoord, 
        ismargin = d.ismargin, 
        dontmargin = d.dontmargin, 
        solveInProgress = d.solveInProgress, 
        solvedCount = d.solvedCount, 
        solveKey = Symbol(d.solveKey),
        events = Dict{Symbol,Threads.Condition}() )
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================

function packVariable(v::AbstractDFGVariable; includePPEs::Bool=true, includeSolveData::Bool=true, includeDataEntries::Bool=true)
    return PackedVariable(;
        id=v.id,
        label = v.label,
        timestamp = v.timestamp,
        nstime = string(v.nstime.value),
        tags = collect(v.tags), # Symbol.()
        ppes = collect(values(v.ppeDict)),
        solverData = packVariableNodeData.(collect(values(v.solverDataDict))),
        metadata = base64encode(JSON3.write(v.smallData)),
        solvable = v.solvable,
        variableType = DFG.typeModuleName(DFG.getVariableType(v)),
        blobEntries = collect(values(v.dataDict)),
        _version = string(DFG._getDFGVersion()))
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
    dataDict = Dict{Symbol, BlobEntry}(map(de -> de.label, variable.blobEntries) .=> variable.blobEntries)
    metadata = JSON3.read(base64decode(variable.metadata), Dict{Symbol, DFG.SmallDataTypes})

    return DFGVariable(
        variable.label, 
        variableType;
        id = variable.id,
        timestamp=variable.timestamp, 
        nstime=Nanosecond(variable.nstime), 
        tags=Set(variable.tags), 
        ppeDict=ppeDict, 
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

# returns PackedFactor
function packFactor(f::DFGFactor)
    fnctype = getSolverData(f).fnc.usrfnc!
    return PackedFactor(;    
        id = f.id,
        label = f.label,
        tags = collect(f.tags),
        _variableOrderSymbols = f._variableOrderSymbols,
        timestamp = f.timestamp,
        nstime = string(f.nstime.value),
        fnctype = String(_getname(fnctype)),
        solvable = getSolvable(f),
        metadata = base64encode(JSON3.write(f.smallData)),
        # Pack the node data
        data = JSON3.write(_packSolverData(f, fnctype)),
        _version = string(_getDFGVersion()))
    return props
end

function reconstFactorData end

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

function fncStringToData(packtype::Type{<:AbstractPackedFactor}, data::String)

    # Read string as JSON object to use as kwargs
    fncData = JSON3.read(data)
    packT = packtype(;fncData.fnc...)

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
fncStringToData(packtype::Type{<:AbstractPackedFactor}, data::NamedTuple) = error("Who is calling deserialize factor with NamedTuple, likely JSON3 somewhere")

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
    # FIXME, should rather just store the data as `PackedFactorX` rather than hard code the type change here???
    packtype = DFG.getTypeFromSerializationModule("Packed"*fncType)
    fncStringToData(packtype, data)
end


function unpackFactor(
    dfg::AbstractDFG, 
    factor::PackedFactor;
    skipVersionCheck::Bool=false
)
    #
    @debug "DECODING factor type = '$(factor.fnctype)' for factor '$(factor.label)'"
    !skipVersionCheck && _versionCheck(factor)
    
    fullFactorData = nothing
    try
        packedFnc = fncStringToData(factor.fnctype, factor.data)
        decodeType = getFactorOperationalMemoryType(dfg)
        fullFactorData = decodePackedType(dfg, factor._variableOrderSymbols, decodeType, packedFnc)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while unpacking '$(factor.label)' as '$(factor.fnctype)', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end  

    metadata = JSON3.read(base64decode(factor.metadata), Dict{Symbol, DFG.SmallDataTypes})

    return DFGFactor(
        factor.label,
        factor.timestamp,
        Nanosecond(factor.nstime),
        Set(factor.tags),
        fullFactorData,
        factor.solvable,
        Tuple(factor._variableOrderSymbols),
        id=factor.id,
        smallData = metadata
    )
end

#