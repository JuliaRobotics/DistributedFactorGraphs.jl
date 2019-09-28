import Base: ==, convert

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

  return VariableNodeData(M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    st, d.initialized, d.inferdim, d.ismargin, d.dontmargin )
end

function compare(a::VariableNodeData, b::VariableNodeData)
    TP = true
    TP = TP && a.val == b.val
    TP = TP && a.bw == b.bw
    TP = TP && a.BayesNetOutVertIDs == b.BayesNetOutVertIDs
    TP = TP && a.dimIDs == b.dimIDs
    TP = TP && a.dims == b.dims
    TP = TP && a.eliminated == b.eliminated
    TP = TP && a.BayesNetVertID == b.BayesNetVertID
    TP = TP && a.separator == b.separator
    TP = TP && abs(a.inferdim - b.inferdim) < 1e-14
    TP = TP && a.ismargin == b.ismargin
    TP = TP && a.softtype == b.softtype
    return TP
end

function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return DistributedFactorGraphs.compare(a,b)
end

function convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.estimateDict), v._internalId)
end
