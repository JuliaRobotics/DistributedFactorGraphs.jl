
# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

##==============================================================================
## Variable Packing and unpacking
##==============================================================================
function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
    props["nstime"] = string(v.nstime.value)
    props["tags"] = JSON2.write(v.tags)
    props["ppeDict"] = JSON2.write(v.ppeDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["solvable"] = v.solvable
    props["softtype"] = string(typeof(getSofttype(v)))
    props["bigData"] = JSON2.write(Dict(keys(v.bigData) .=> map(bde -> JSON2.write(bde), values(v.bigData))))
    props["bigDataElemType"] = JSON2.write(Dict(keys(v.bigData) .=> map(bde -> typeof(bde), values(v.bigData))))
    return props
end

function unpackVariable(dfg::G,
        packedProps::Dict{String, Any};
        unpackPPEs::Bool=true,
        unpackSolverData::Bool=true,
        unpackBigData::Bool=true)::DFGVariable where G <: AbstractDFG
    @debug "Unpacking variable:\r\n$packedProps"
    label = Symbol(packedProps["label"])
    timestamp = ZonedDateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))
    # Supporting string serialization using packVariable and CGDFG serialization (Vector{String})
    if packedProps["tags"] isa String
        tags = JSON2.read(packedProps["tags"], Vector{Symbol})
    else
        tags = Symbol.(packedProps["tags"])
    end
    ppeDict = unpackPPEs ? JSON2.read(packedProps["ppeDict"], Dict{Symbol, MeanMaxPPE}) : Dict{Symbol, MeanMaxPPE}()
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})
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
    variable = DFGVariable{softtype}(Symbol(packedProps["label"]), timestamp, nstime, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractBigDataEntry}(), Ref(packedProps["solvable"]))

    if unpackBigData
        bigDataElemTypes = JSON2.read(packedProps["bigDataElemType"], Dict{Symbol, Symbol})
        bigDataIntermed = JSON2.read(packedProps["bigData"], Dict{Symbol, String})
        # Now rehydrate complete bigData type.
        for (k,bdeInter) in bigDataIntermed
            fullVal = JSON2.read(bdeInter, getfield(DistributedFactorGraphs, bigDataElemTypes[k]))
            variable.bigData[k] = fullVal
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
    props["timestamp"] = string(f.timestamp)
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
    label = packedProps["label"]
    timestamp = DateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))
    tags = JSON2.read(packedProps["tags"], Vector{Symbol})

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
    _variableOrderSymbols = JSON2.read(packedProps["_variableOrderSymbols"], Vector{Symbol})
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
        @error "Unable to deserialize soft type $(d.softtype)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error err
    end
    return st
end
