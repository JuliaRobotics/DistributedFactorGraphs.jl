
# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

##==============================================================================
## Variable Packing and unpacking
##==============================================================================
function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
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

function unpackVariable(dfg::G, packedProps::Dict{String, Any})::DFGVariable where G <: AbstractDFG
    label = Symbol(packedProps["label"])
    timestamp = DateTime(packedProps["timestamp"])
    tags =  JSON2.read(packedProps["tags"], Vector{Symbol})
    #TODO this will work for some time, but unpacking in an <: AbstractPointParametricEst would be lekker.
    ppeDict = JSON2.read(packedProps["ppeDict"], Dict{Symbol, MeanMaxPPE})
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})
    bigDataElemTypes = JSON2.read(packedProps["bigDataElemType"], Dict{Symbol, Symbol})
    bigDataIntermed = JSON2.read(packedProps["bigData"], Dict{Symbol, String})
    softtypeString = packedProps["softtype"]
    softtype = getTypeFromSerializationModule(dfg, Symbol(softtypeString))
    softtype == nothing && error("Cannot deserialize softtype '$softtypeString' in variable '$label'")

    packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
    solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpackVariableNodeData(dfg, p), values(packed)))

    # Rebuild DFGVariable using the first solver softtype in solverData
    variable = DFGVariable{softtype}(Symbol(packedProps["label"]), timestamp, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractBigDataEntry}(), DFGNodeParams(packedProps["solvable"],0))

    # Now rehydrate complete bigData type.
    for (k,bdeInter) in bigDataIntermed
        fullVal = JSON2.read(bdeInter, getfield(DistributedFactorGraphs, bigDataElemTypes[k]))
        variable.bigData[k] = fullVal
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
                                d.solvedCount)
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
    st(), d.initialized, d.inferdim, d.ismargin, d.dontmargin, d.solveInProgress, d.solvedCount)
end

##==============================================================================
## Factor Packing and unpacking
##==============================================================================

function packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["timestamp"] = string(f.timestamp)
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
    factor = DFGFactor{typeof(fullFactorData.fnc)}(Symbol(label), 0, timestamp)

    union!(factor.tags, tags)
    # factor.data = fullFactorData #TODO
    setSolverData!(factor, fullFactorData)
    factor._variableOrderSymbols = _variableOrderSymbols
    setSolvable!(factor, solvable)

    # Note, once inserted, you still need to call IIF.rebuildFactorMetadata!
    return factor
end


##==============================================================================
## Serialization
##==============================================================================

"""
    $(SIGNATURES)

Deserialization of IncrementalInference objects require discovery of foreign types.

Example:

Template to tunnel types from a user module:
```julia
# or more generic solution -- will always try Main if available
IIF.setSerializationNamespace!(Main)

# or a specific package such as RoME if you import all variable and factor types into a specific module.
using RoME
IIF.setSerializationNamespace!(RoME)
```
"""
function setSerializationModule!(dfg::G, mod::Module)::Nothing where G <: AbstractDFG
    @warn "Setting serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is being ignored."
end

function getSerializationModule(dfg::G)::Module where G <: AbstractDFG
    @warn "Retrieving serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is returning Main"
    return Main
end

"""
  $(SIGNATURES)
Get a type from the serialization module inside DFG.
"""
function getTypeFromSerializationModule(dfg::G, moduleType::Symbol) where G <: AbstractDFG
    st = nothing
    mainmod = getSerializationModule(dfg)
    mainmod == nothing && error("Serialization module is null - please call setSerializationNamespace!(\"Main\" => Main) in your main program.")
    try
        st = getfield(mainmod, Symbol(moduleType))
    catch ex
        @error "Unable to deserialize soft type $(d.softtype)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error err
    end
    return st
end

"""
$(SIGNATURES)
Pack a PPE into a Dict{String, Any}.
"""
function packPPE(dfg::G, ppe::P)::Dict{String, Any} where {G <: AbstractDFG, P <: AbstractPointParametricEst}
    packedPPE = JSON.parse(JSON.json(ppe)) #TODO: Maybe better way to serialize as dictionary?
    packedPPE[TYPEKEY] = string(typeof(ppe)) # Append the type
    return packedPPE
end

"""
$(SIGNATURES)
Unpack a Dict{String, Any} into a PPE.
"""
function unpackPPE(dfg::G, packedPPE::Dict{String, Any})::AbstractPointParametricEst where G <: AbstractDFG
    !haskey(packedPPE, TYPEKEY) && error("Cannot find type key '$TYPEKEY' in packed PPE data")
    type = pop!(packedPPE, TYPEKEY)
    (type == nothing || type == "") && error("Cannot deserialize PPE, type key is empty")
    ppe = Unmarshal.unmarshal(
            DistributedFactorGraphs.getTypeFromSerializationModule(dfg, Symbol(type)),
            packedPPE)
    return ppe
end
