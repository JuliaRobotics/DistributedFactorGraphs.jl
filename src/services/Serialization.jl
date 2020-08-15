
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
    # Looks like this is deprecated but there's no replacement function yet.
    return string(Pkg.dependencies()[Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04")].version)
end

function _versionCheck(props::Dict{String, Any})
    if haskey(props, "_version")
        if props["_version"] != _getDFGVersion()
            @warn "This data was serialized using DFG $(props["_version"]) but you have $(_getDFGVersion()) installed, there may be deserialization issues."
        end
    else
        @warn "There isn't a version tag in this data so it older than v0.10, there may be deserialization issues."
    end
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================
function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = Dates.format(v.timestamp, "yyyy-mm-ddTHH:MM:SS.ssszzz")#string(v.timestamp)
    props["nstime"] = string(v.nstime.value)
    props["tags"] = JSON2.write(v.tags)
    props["ppeDict"] = JSON2.write(v.ppeDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["solvable"] = v.solvable
    props["softtype"] = string(typeof(getSofttype(v)))
    # props["bigData"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> JSON2.write(bde), values(v.dataDict))))
    # props["bigDataElemType"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> typeof(bde), values(v.dataDict))))
    props["dataEntry"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> JSON.json(bde), values(v.dataDict))))
    
    props["dataEntryType"] = JSON2.write(Dict(keys(v.dataDict) .=> map(bde -> typeof(bde), values(v.dataDict))))
    props["_version"] = _getDFGVersion()
    return props
end

# Corrects any `::ZonedDateTime` fields of T in corresponding `interm::Dict` as `dateformat"yyyy-mm-ddTHH:MM:SS.ssszzz"`
function standardizeZDTString!(T, interm::Dict)
    @debug "About to look through types of" T
    for (name, typ) in zip(fieldnames(T), T.types)
        # @debug "name=$name" 
        # @debug "typ=$typ"
        if typ <: ZonedDateTime
            # Make sure that the timestamp is correctly formatted with subseconds
            namestr = string(name)
            @debug "must ensure SS.ssszzz on $name :: $typ -- $(interm[namestr])"
                # # FIXME copy #588, but doesnt work: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/582#issuecomment-671884668
                # #   E.g.: interm[namestr] = replace(interm[namestr], r":(\d)(\d)(Z|z|\+|-)" => s":\1\2.000\3") = "2020-08-11T04:05:59.82-04:00"
                # @show interm[namestr] = replace(interm[namestr], r":(\d)(\d)(Z|z|\+|-)" => s":\1\2.000\3")
                # @debug "after SS.ssszzz -- $(interm[namestr])"
            ## DROP piece below once this cleaner copy #588 is working
            supersec, subsec = split(interm[namestr], '.')
            sss, zzz = split(subsec, '-')
            # @debug "split time elements are $sss-$zzz"
            # make sure milliseconds portion is precisely 3 characters long
            if length(sss) < 3
                # pad with zeros at the end
                while length(sss) < 3
                    sss *= "0"
                end
                newtimessszzz = supersec*"."*sss*"-"*zzz
                @debug "new time string: $newtimessszzz"
                # reassembled ZonedDateTime is put back in the dict
                interm[namestr] = newtimessszzz
            end
        end
    end
    nothing
end

function unpackVariable(dfg::G,
        packedProps::Dict{String, Any};
        unpackPPEs::Bool=true,
        unpackSolverData::Bool=true,
        unpackBigData::Bool=true)::DFGVariable where G <: AbstractDFG
    @debug "Unpacking variable:\r\n$packedProps"
    # Version checking.
    _versionCheck(packedProps)
    label = Symbol(packedProps["label"])
    # Make sure that the timestamp is correctly formatted with subseconds
    packedProps["timestamp"] = replace(packedProps["timestamp"], r":(\d)(\d)(Z|z|\+|-)" => s":\1\2.000\3")
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

    softtypeString = packedProps["softtype"]
    softtype = getTypeFromSerializationModule(dfg, Symbol(softtypeString))
    softtype == nothing && error("Cannot deserialize softtype '$softtypeString' in variable '$label'")

    if unpackSolverData
        packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
        solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpackVariableNodeData(dfg, p), values(packed)))
    else
        solverData = Dict{Symbol, VariableNodeData}()
    end
    # Rebuild DFGVariable using the first solver softtype in solverData
    variable = DFGVariable{softtype}(Symbol(packedProps["label"]), timestamp, nstime, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractDataEntry}(), Ref(packedProps["solvable"]))

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
            # @debug "label=$label" 
            # @debug "bdeInter=$bdeInter"
            interm = JSON.parse(bdeInter)
            objType = getfield(DistributedFactorGraphs, dataElemTypes[k])
            standardizeZDTString!(objType, interm)
            fullVal = Unmarshal.unmarshal(objType, interm)
            variable.dataDict[k] = fullVal
        end
    end

    return variable
end

function packVariableNodeData(dfg::G, d::VariableNodeData)::PackedVariableNodeData where G <: AbstractDFG
  @debug "Dispatching conversion variable -> packed variable for type $(string(d.softtype))"
  return PackedVariableNodeData(d.val[:],size(d.val,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                d.softtype != nothing ? string(d.softtype) : nothing,
                                d.initialized,
                                d.inferdim,
                                d.ismargin,
                                d.dontmargin,
                                d.solveInProgress,
                                d.solvedCount,
                                d.solverKey)
end

function unpackVariableNodeData(dfg::G, d::PackedVariableNodeData)::VariableNodeData where G <: AbstractDFG
  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  @debug "Dispatching conversion packed variable -> variable for type $(string(d.softtype))"
  # Figuring out the softtype
  unpackedTypeName = split(d.softtype, "(")[1]
  unpackedTypeName = split(unpackedTypeName, '.')[end]
  @debug "DECODING Softtype = $unpackedTypeName"
  st = getTypeFromSerializationModule(dfg, Symbol(unpackedTypeName))
  st == nothing && error("The variable doesn't seem to have a softtype. It needs to set up with an InferenceVariable from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().")

  return VariableNodeData{st}(M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    st(), d.initialized, d.inferdim, d.ismargin, d.dontmargin, d.solveInProgress, d.solvedCount, d.solverKey)
end

##==============================================================================
## Factor Packing and unpacking
##==============================================================================

function packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["timestamp"] = Dates.format(f.timestamp, "yyyy-mm-ddTHH:MM:SS.ssszzz")#string(f.timestamp)
    props["nstime"] = string(f.nstime.value)
    props["tags"] = JSON2.write(f.tags)
    # Pack the node data
    fnctype = getSolverData(f).fnc.usrfnc!
    try
        packtype = getfield(_getmodule(fnctype), Symbol("Packed$(_getname(fnctype))"))
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
  usrtyp = getfield(PT.name.module, Symbol(string(PT.name.name)[7:end]))
  fulltype = DFG.FunctionNodeData{T{usrtyp}}
  factordata = convert(fulltype, packeddata)
  return factordata
end


function unpackFactor(dfg::G, packedProps::Dict{String, Any})::DFGFactor where G <: AbstractDFG
    # Version checking.
    _versionCheck(packedProps)

    label = packedProps["label"]
    # Make sure that the timestamp is correctly formatted with subseconds
    packedProps["timestamp"] = replace(packedProps["timestamp"], r":(\d)(\d)(Z|z|\+|-)" => s":\1\2.000\3")
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
    @debug "DECODING Softtype = '$(datatype)' for factor '$label'"
    packtype = getTypeFromSerializationModule(dfg, Symbol("Packed"*datatype))

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
    if packedProps["tags"] isa String
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
        @error "Unable to deserialize soft type $(moduleType)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    return st
end
