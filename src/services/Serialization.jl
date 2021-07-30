
# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

## Custom serialization
using JSON
import JSON.show_json
import JSON.Writer: StructuralContext, JSONContext, show_json
import JSON.Serializations: CommonSerialization, StandardSerialization
JSON.show_json(io::JSONContext, serialization::CommonSerialization, uuid::UUID) = print(io.io, "\"$uuid\"")

## Version checking
function _getDFGVersion()
    if haskey(Pkg.dependencies(), Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04"))
        return string(Pkg.dependencies()[Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04")].version)
    else
        # This is arguably slower, but needed for Travis.
        return Pkg.TOML.parse(read(joinpath(dirname(pathof(@__MODULE__)), "..", "Project.toml"), String))["version"]
    end
end

function _versionCheck(props::Dict{String, Any})
    if haskey(props, "_version")
        if props["_version"] != _getDFGVersion()
            @warn "This data was serialized using DFG $(props["_version"]) but you have $(_getDFGVersion()) installed, there may be deserialization issues."
        end
    else
        @warn "There isn't a version tag in this data so it's older than v0.10, there may be deserialization issues."
    end
end

## Utility functions for ZonedDateTime

# Regex parser that converts clauses like ":59.82-" to well formatted ":59.820-"
function _fixSubseconds(a)
    length(a) == 4 && return a[1:3]*".000"*a[4]
    frac = a[5:length(a)-1]
    frac = length(frac) > 3 ? frac[1:3] : frac*'0'^(3-length(frac))
    return a[1:4]*frac*a[length(a)]
end

function getStandardZDTString(stringTimestamp::String)
    # Additional check+fix for the ultraweird "2020-08-12T12:00Z"
    ts = replace(stringTimestamp, r"T(\d\d):(\d\d)(Z|z|\+|-)" => s"T\1:\2:00.000\3")

    # This is finding :59Z or :59.82-05:00 and fixing it to always have 3 subsecond digits.
    # Temporary fix until TimeZones.jl gets an upstream fix.
    return replace(ts, r":\d\d(\.\d+)?(Z|z|\+|-)" => _fixSubseconds)
end

# Corrects any `::ZonedDateTime` fields of T in corresponding `interm::Dict` as `dateformat"yyyy-mm-ddTHH:MM:SS.ssszzz"`
function standardizeZDTStrings!(T, interm::Dict)
    for (name, typ) in zip(fieldnames(T), T.types)
        if typ <: ZonedDateTime
            namestr = string(name)
            interm[namestr] = getStandardZDTString(interm[namestr])
        end
    end
    nothing
end

function string2ZonedDateTime(stringTimestamp) 
    #   ss = split(stringTimestamp, r"(T[0-9.:]*?\K(?=[-+Zz]))|[\[\]]")
  ss = split(stringTimestamp, r"T[\d.:]{5,12}?\K(?=[-+Zz])")
  length(ss) != 2 && error("Misformed zoned timestamp string $stringTimestamp")
  ZonedDateTime(DateTime(ss[1]), TimeZone(ss[2]))
end

# variableType module.type string functions
function typeModuleName(variableType::InferenceVariable)
    io = IOBuffer()
    ioc = IOContext(io, :module=>DistributedFactorGraphs)
    show(ioc, typeof(variableType))
    return String(take!(io))
end

function getTypeFromSerializationModule(variableTypeString::String)
    try
        # split the type at last `.`
        split_st = split(variableTypeString, r"\.(?!.*\.)")
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
        @error "Unable to deserialize soft type $(variableTypeString)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    nothing
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================
function packVariable(dfg::AbstractDFG, v::DFGVariable) 
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = Dates.format(v.timestamp, "yyyy-mm-ddTHH:MM:SS.ssszzz")
    props["nstime"] = string(v.nstime.value)
    props["tags"] = JSON2.write(v.tags)
    props["ppeDict"] = JSON2.write(v.ppeDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["solvable"] = v.solvable
    props["variableType"] = typeModuleName(getVariableType(v))
    props["dataEntry"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> JSON.json(bde), values(v.dataDict))))
    props["dataEntryType"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> typeof(bde), values(v.dataDict))))
    props["_version"] = _getDFGVersion()
    return props::Dict{String, Any}
end

# returns a DFGVariable
function unpackVariable(dfg::G,
                        packedProps::Dict{String, Any};
                        unpackPPEs::Bool=true,
                        unpackSolverData::Bool=true,
                        unpackBigData::Bool=true) where G <: AbstractDFG
    @debug "Unpacking variable:\r\n$packedProps"
    # Version checking.
    _versionCheck(packedProps)
    label = Symbol(packedProps["label"])
    # Make sure that the timestamp is correctly formatted with subseconds
    packedProps["timestamp"] = getStandardZDTString(packedProps["timestamp"])
    # Parse it
    timestamp = ZonedDateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))
    # Supporting string serialization using packVariable and CGDFG serialization (Vector{String})
    if packedProps["tags"] isa String
        tags = JSON2.read(packedProps["tags"], Vector{Symbol})
    else
        tags = Symbol.(packedProps["tags"])
    end
    ppeDict = unpackPPEs ? JSON2.read(packedProps["ppeDict"], Dict{Symbol, MeanMaxPPE}) : Dict{Symbol, MeanMaxPPE}()
    smallData = JSON2.read(packedProps["smallData"], Dict{Symbol, SmallDataTypes})

    variableTypeString = if haskey(packedProps, "softtype")
        # TODO Deprecate, remove in v0.12
        @warn "Packed field `softtype` is deprecated and replaced with `variableType`"
        packedProps["softtype"]
    else
        packedProps["variableType"]
    end

    variableType = getTypeFromSerializationModule(variableTypeString)
    isnothing(variableType) && error("Cannot deserialize variableType '$variableTypeString' in variable '$label'")
    pointType = getPointType(variableType)

    if unpackSolverData
        packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
        solverData = Dict{Symbol, VariableNodeData{variableType, pointType}}(Symbol.(keys(packed)) .=> map(p -> unpackVariableNodeData(dfg, p), values(packed)))
    else
        solverData = Dict{Symbol, VariableNodeData{variableType, pointType}}()
    end
    # Rebuild DFGVariable using the first solver variableType in solverData
    # @info "dbg Serialization 171" variableType Symbol(packedProps["label"]) timestamp nstime ppeDict solverData smallData Dict{Symbol,AbstractDataEntry}() Ref(packedProps["solvable"])
    # variable = DFGVariable{variableType}(Symbol(packedProps["label"]), timestamp, nstime, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractDataEntry}(), Ref(packedProps["solvable"]))
    variable = DFGVariable( Symbol(packedProps["label"]), 
                            variableType, 
                            timestamp=timestamp, 
                            nstime=nstime, 
                            tags=Set{Symbol}(tags), 
                            estimateDict=ppeDict, 
                            solverDataDict=solverData,  
                            smallData=smallData, 
                            dataDict=Dict{Symbol,AbstractDataEntry}(), 
                            solvable=packedProps["solvable"] )
    #

    # Now rehydrate complete DataEntry type.
    if unpackBigData
        #TODO Deprecate - for backward compatibility between v0.8 and v0.9, remove in v0.10
        if haskey(packedProps, "bigDataElemType")
            @warn "`bigDataElemType` is deprecate, please save data again with new version that uses `dataEntryType`"
            dataElemTypes = JSON2.read(packedProps["bigDataElemType"], Dict{Symbol, Symbol})
        else
            dataElemTypes = JSON2.read(packedProps["dataEntryType"], Dict{Symbol, Symbol})
            for (k,name) in dataElemTypes 
                dataElemTypes[k] = Symbol(split(string(name), '.')[end])
            end
        end

        #TODO Deprecate - for backward compatibility between v0.8 and v0.9, remove in v0.10
        if haskey(packedProps, "bigData")
            @warn "`bigData` is deprecate, please save data again with new version"
            dataIntermed = JSON2.read(packedProps["bigData"], Dict{Symbol, String})
        else
            dataIntermed = JSON2.read(packedProps["dataEntry"], Dict{Symbol, String})
        end

        for (k,bdeInter) in dataIntermed
            interm = JSON.parse(bdeInter)
            objType = getfield(DistributedFactorGraphs, dataElemTypes[k])
            standardizeZDTStrings!(objType, interm)
            fullVal = Unmarshal.unmarshal(objType, interm)
            variable.dataDict[k] = fullVal
        end
    end

    return variable
end


# returns a PackedVariableNodeData
function packVariableNodeData(::G, d::VariableNodeData{T}) where {G <: AbstractDFG, T <: InferenceVariable}
  @debug "Dispatching conversion variable -> packed variable for type $(string(d.variableType))"
  # TODO change to Vector{Vector{Float64}} which can be directly packed by JSON
  castval = if 0 < length(d.val)
    precast = getCoordinates.(T, d.val)
    @cast castval[i,j] := precast[j][i]
    castval
  else
    zeros(1,0)
  end
  _val = castval[:]
#   castbw = if 0 < length(d.bw)
#     @cast castbw[i,j] := d.bw[j][i]
#     castbw
#   else
#     zeros(1,0)
#   end
#   _bw = castbw[:]
  return PackedVariableNodeData(_val, size(castval,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                typeModuleName(d.variableType),
                                d.initialized,
                                d.inferdim,
                                d.ismargin,
                                d.dontmargin,
                                d.solveInProgress,
                                d.solvedCount,
                                d.solveKey)
end

function unpackVariableNodeData(dfg::G, d::PackedVariableNodeData) where G <: AbstractDFG
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
    return VariableNodeData{T, getPointType(T)}(vals, BW, d.BayesNetOutVertIDs,
        d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
        T(), d.initialized, d.inferdim, d.ismargin, d.dontmargin, 
        d.solveInProgress, d.solvedCount, d.solveKey,
        Dict{Symbol,Threads.Condition}() )
end

##==============================================================================
## Factor Packing and unpacking
##==============================================================================


function packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["timestamp"] = Dates.format(f.timestamp, "yyyy-mm-ddTHH:MM:SS.ssszzz")
    props["nstime"] = string(f.nstime.value)
    props["tags"] = JSON2.write(f.tags)
    # Pack the node data
    fnctype = getSolverData(f).fnc.usrfnc!
    try
        packtype = convertPackedType(fnctype)
        packed = convert(PackedFunctionNodeData{packtype}, getSolverData(f))
        props["data"] = JSON2.write(packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end
    # Include the type
    props["fnctype"] = String(_getname(fnctype))
    props["_variableOrderSymbols"] = JSON2.write(f._variableOrderSymbols)
    props["solvable"] = getSolvable(f)
    props["_version"] = _getDFGVersion()
    return props
end

function decodePackedType(::Type{T}, packeddata::GenericFunctionNodeData{PT}) where {T<:FactorOperationalMemory, PT}
    # usrtyp = convert(FunctorInferenceType, packeddata.fnc)
    # Also look at parentmodule
    usrtyp = convertStructType(PT)
    fulltype = DFG.FunctionNodeData{T{usrtyp}}
    factordata = convert(fulltype, packeddata)
    return factordata
end


function unpackFactor(dfg::G, packedProps::Dict{String, Any})::DFGFactor where G <: AbstractDFG
    # Version checking.
    _versionCheck(packedProps)

    label = packedProps["label"]
    # Make sure that the timestamp is correctly formatted with subseconds
    packedProps["timestamp"] = getStandardZDTString(packedProps["timestamp"])
    # Parse it
    timestamp = ZonedDateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))
    if packedProps["tags"] isa String
        tags = JSON2.read(packedProps["tags"], Vector{Symbol})
    else
        tags = Symbol.(packedProps["tags"])
        # If tags is empty we need to make sure it's a Vector{Symbol}
        if length(tags) == 0
            tags = Vector{Symbol}()
        end
    end
    data = packedProps["data"]
    datatype = packedProps["fnctype"]
    @debug "DECODING factor type = '$(datatype)' for factor '$label'"
    packtype = getTypeFromSerializationModule(dfg, Symbol("Packed"*datatype))

    # FIXME type instability from nothing to T
    packed = nothing
    fullFactorData = nothing
    try
        packed = JSON2.read(data, GenericFunctionNodeData{packtype})
        decodeType = getFactorOperationalMemoryType(dfg)
        fullFactorData = decodePackedType(decodeType, packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while unpacking '$label' as '$datatype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end

    # Include the type
    if packedProps["_variableOrderSymbols"] isa String
        _variableOrderSymbols = JSON2.read(packedProps["_variableOrderSymbols"], Vector{Symbol})
    else
        _variableOrderSymbols = Symbol.(packedProps["_variableOrderSymbols"])
    end
    solvable = packedProps["solvable"]

    # Rebuild DFGFactor
    #TODO use constuctor to create factor
    factor = DFGFactor(Symbol(label),
                       timestamp,
                       nstime,
                       Set(tags),
                       fullFactorData,
                       solvable,
                       Tuple(_variableOrderSymbols))


    # Note, once inserted, you still need to call rebuildFactorMetadata!
    return factor
end


##==============================================================================
## Serialization
##==============================================================================

"""
  $(SIGNATURES)
Get a type from the serialization module inside DFG.
"""
function getTypeFromSerializationModule(dfg::G, moduleType::Symbol) where G <: AbstractDFG
    st = nothing
    try
        st = getfield(Main, Symbol(moduleType))
    catch ex
        @error "Unable to deserialize type $(moduleType)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    return st
end
