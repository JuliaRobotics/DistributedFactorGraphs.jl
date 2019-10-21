import Base: ==, convert

function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
    props["tags"] = JSON2.write(v.tags)
    props["estimateDict"] = JSON2.write(v.estimateDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> pack(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["ready"] = v.ready
    props["backendset"] = v.backendset
    return props
end

function unpackVariable(dfg::G, packedProps::Dict{String, Any})::DFGVariable where G <: AbstractDFG
    label = Symbol(packedProps["label"])
    timestamp = DateTime(packedProps["timestamp"])
    tags =  JSON2.read(packedProps["tags"], Vector{Symbol})
    estimateDict = JSON2.read(packedProps["estimateDict"], Dict{Symbol, Dict{Symbol, VariableEstimate}})
    smallData = nothing
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})

    packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
    solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(dfg, p), values(packed)))

    # Rebuild DFGVariable
    variable = DFGVariable(Symbol(packedProps["label"]))
    variable.timestamp = timestamp
    variable.tags = tags
    variable.estimateDict = estimateDict
    variable.solverDataDict = solverData
    variable.smallData = smallData
    variable.ready = packedProps["ready"]
    variable.backendset = packedProps["backendset"]

    return variable
end

function pack(dfg::G, d::VariableNodeData)::PackedVariableNodeData where G <: AbstractDFG
  @debug "Dispatching conversion variable -> packed variable for type $(string(d.softtype))"
  return PackedVariableNodeData(d.val[:],size(d.val,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                d.softtype != nothing ? string(d.softtype) : nothing, d.initialized, d.inferdim, d.ismargin, d.dontmargin)
end

function unpack(dfg::G, d::PackedVariableNodeData)::VariableNodeData where G <: AbstractDFG
  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  @debug "Dispatching conversion packed variable -> variable for type $(string(d.softtype))"
  st = nothing #IncrementalInference.ContinuousMultivariate # eval(parse(d.softtype))
  mainmod = getSerializationModule(dfg)
  mainmod == nothing && error("Serialization module is null - please call setSerializationNamespace!(\"Main\" => Main) in your main program.")
  try
      if d.softtype != ""
          unpackedTypeName = split(d.softtype, "(")[1]
          unpackedTypeName = split(unpackedTypeName, '.')[end]
          @debug "DECODING Softtype = $unpackedTypeName"
          st = getfield(mainmod, Symbol(unpackedTypeName))()
      end
  catch ex
      @error "Unable to deserialize soft type $(d.softtype)"
      io = IOBuffer()
      showerror(io, ex, catch_backtrace())
      err = String(take!(io))
      @error err
  end
  @debug "Net conversion result: $st"

  if st == nothing
      error("The variable doesn't seem to have a softtype. It needs to set up with an InferenceVariable from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().")
  end

  return VariableNodeData(M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    st, d.initialized, d.inferdim, d.ismargin, d.dontmargin )
end

function compare(a::VariableNodeData, b::VariableNodeData)
    a.val != b.val && @debug("val is not equal")==nothing && return false
    a.bw != b.bw && @debug("bw is not equal")==nothing && return false
    a.BayesNetOutVertIDs != b.BayesNetOutVertIDs && @debug("BayesNetOutVertIDs is not equal")==nothing && return false
    a.dimIDs != b.dimIDs && @debug("dimIDs is not equal")==nothing && return false
    a.dims != b.dims && @debug("dims is not equal")==nothing && return false
    a.eliminated != b.eliminated && @debug("eliminated is not equal")==nothing && return false
    a.BayesNetVertID != b.BayesNetVertID && @debug("BayesNetVertID is not equal")==nothing && return false
    a.separator != b.separator && @debug("separator is not equal")==nothing && return false
    a.initialized != b.initialized && @debug("initialized is not equal")==nothing && return false
    abs(a.inferdim - b.inferdim) > 1e-14 && @debug("inferdim is not equal")==nothing && return false
    a.ismargin != b.ismargin && @debug("ismargin is not equal")==nothing && return false
    a.dontmargin != b.dontmargin && @debug("dontmargin is not equal")==nothing && return false
    typeof(a.softtype) != typeof(b.softtype) && @debug("softtype is not equal")==nothing && return false
    return true
end

"""
    $(SIGNATURES)
Equality check for VariableNodeData.
"""
function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return DistributedFactorGraphs.compare(a,b)
end

"""
    $(SIGNATURES)
Equality check for VariableEstimate.
"""
function ==(a::VariableEstimate, b::VariableEstimate)::Bool
  a.solverKey != b.solverKey && @debug("solverKey are not equal")==nothing && return false
  a.ppeType != b.ppeType && @debug("type is not equal")==nothing && return false
  a.estimate != b.estimate && @debug("estimate are not equal")==nothing && return false
  a.lastUpdatedTimestamp != b.lastUpdatedTimestamp && @debug("lastUpdatedTimestamp is not equal")==nothing && return false
  return true
end

"""
    $(SIGNATURES)
Equality check for DFGVariable.
"""
function ==(a::DFGVariable, b::DFGVariable)::Bool
  a.label != b.label && @debug("label is not equal")==nothing && return false
  a.timestamp != b.timestamp && @debug("timestamp is not equal")==nothing && return false
  a.tags != b.tags && @debug("tags is not equal")==nothing && return false
  symdiff(keys(a.estimateDict), keys(b.estimateDict)) != Set(Symbol[]) && @debug("estimateDict keys are not equal")==nothing && return false
  for k in keys(a.estimateDict)
    a.estimateDict[k] != b.estimateDict[k] && @debug("estimateDict[$k] is not equal")==nothing && return false
  end
  symdiff(keys(a.solverDataDict), keys(b.solverDataDict)) != Set(Symbol[]) && @debug("solverDataDict keys are not equal")==nothing && return false
  for k in keys(a.solverDataDict)
    a.solverDataDict[k] != b.solverDataDict[k] && @debug("solverDataDict[$k] is not equal")==nothing && return false
  end
  a.smallData != b.smallData && @debug("smallData is not equal")==nothing && return false
  a.bigData != b.bigData && @debug("bigData is not equal")==nothing && return false
  a.ready != b.ready && @debug("ready is not equal")==nothing && return false
  a.backendset != b.backendset && @debug("backendset is not equal")==nothing && return false
  a._internalId != b._internalId && @debug("_internalId is not equal")==nothing && return false
  return true
end

"""
    $(SIGNATURES)
Convert a DFGVariable to a DFGVariableSummary.
"""
function convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.estimateDict), Symbol(typeof(getSofttype(v))), v._internalId)
end
