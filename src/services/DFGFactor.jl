import Base: convert, ==

function convert(::Type{DFGFactorSummary}, f::DFGFactor)
    return DFGFactorSummary(f.label, f.timestamp, deepcopy(f.tags), f._dfgNodeParams._internalId, deepcopy(f._variableOrderSymbols))
end

function packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["timestamp"] = string(f.timestamp)
    props["tags"] = JSON2.write(f.tags)
    # Pack the node data
    fnctype = f.data.fnc.usrfnc!
    try
        packtype = getfield(_getmodule(fnctype), Symbol("Packed$(_getname(fnctype))"))
        packed = convert(PackedFunctionNodeData{packtype}, f.data)
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

function unpackFactor(dfg::G, packedProps::Dict{String, Any})::DFGFactor where G <: AbstractDFG
    label = packedProps["label"]
    timestamp = DateTime(packedProps["timestamp"])
    tags = JSON2.read(packedProps["tags"], Vector{Symbol})

    data = packedProps["data"]
    datatype = packedProps["fnctype"]
    @debug "DECODING Softtype = '$unpackedTypeName' for factor '$label'"
    packtype = getTypeFromSerializationModule(dfg, Symbol("Packed"*datatype))

    packed = nothing
    fullFactor = nothing
    try
        packed = JSON2.read(data, GenericFunctionNodeData{packtype,String})
        fullFactor = getSerializationModule(dfg).decodePackedType(dfg, packed)
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
    factor = DFGFactor{typeof(fullFactor.fnc), Symbol}(Symbol(label), 0, timestamp)

    union!(factor.tags, tags)
    factor.data = fullFactor #TODO setSolverData!(factor, fullFactor)
    factor._variableOrderSymbols = _variableOrderSymbols
    setSolvable!(factor, solvable)

    # GUARANTEED never to bite us in the ass in the future...
    # ... TODO: refactor if changed: https://github.com/JuliaRobotics/IncrementalInference.jl/issues/350
    factor.data.fncargvID = deepcopy(_variableOrderSymbols)

    # Note, once inserted, you still need to call IIF.rebuildFactorMetadata!
    return factor
end

# # Compare FunctionNodeData
# function compare(a::GenericFunctionNodeData{T1,S},b::GenericFunctionNodeData{T2,S}) where {T1, T2, S}
#   # TODO -- beef up this comparison to include the gwp
#   TP = true
#   TP = TP && a.fncargvID == b.fncargvID
#   TP = TP && a.eliminated == b.eliminated
#   TP = TP && a.potentialused == b.potentialused
#   TP = TP && a.edgeIDs == b.edgeIDs
#   TP = TP && a.frommodule == b.frommodule
#   # TP = TP && typeof(a.fnc) == typeof(b.fnc)
#   return TP
# end

#FIXME
# """
#     $(SIGNATURES)
# Equality check for DFGFactor.
# """
# function ==(a::DFGFactor, b::DFGFactor)::Bool
#     return compareFactor(a, b)
# end

# Accessors

"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getSolverData(f::F) where F <: DFGFactor
  return f.solverData
end
