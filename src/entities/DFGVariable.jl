
### TODO: Discussions
# * What is sofftype, and do we want to make it extensible now?
# * Using longs (not GUIDS) for ID's - that work with everyone?
# * BigData and SmallData are referenced in DFGVariable but I don't
#   believe they should be retrieved every time. Thoughts?
# * Is ContinuousScalar used anywhere? Seems like == ContinuousMultivariate(1)
###

struct ContinuousScalar <: InferenceVariable
  dims::Int
  labels::Vector{String}
  ContinuousScalar() = new(1, String[])
end
struct ContinuousMultivariate <: InferenceVariable
  dims::Int
  labels::Vector{String}
  ContinuousMultivariate() = new()
  ContinuousMultivariate(x) = new(x, String[])
end

"""
Data contained in a DFGVariable.
"""
mutable struct VariableNodeData
  initval::Array{Float64,2}
  initstdev::Array{Float64,2}
  val::Array{Float64,2}
  bw::Array{Float64,2}
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1}
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  groundtruth::Union{Void, Dict{ Tuple{Symbol, Vector{Float64}} } } # not packed yet
  softtype::InferenceVariable
  initialized::Bool
  VariableNodeData() = new()
  function VariableNodeData(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11)
    warn("Deprecated use of VariableNodeData(11 param), use 13 parameters instead")
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11, nothing, true) # TODO ensure this is initialized true is working for most cases
  end
  VariableNodeData(x1::Array{Float64,2},
                   x2::Array{Float64,2},
                   x3::Array{Float64,2},
                   x4::Array{Float64,2},
                   x5::Vector{Int},
                   x6::Vector{Int},
                   x7::Int,
                   x8::Bool,
                   x9::Int,
                   x10::Vector{Int},
                   x11::Union{Void, Dict{ Tuple{Symbol, Vector{Float64}} } },
                   x12::InferenceVariable,
                   x13::Bool) =
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13)
end

"""
A variable in a factor graph.
"""
mutable struct DFGVariable <: DFGNode
    id::Int64
    label::String
    nodeData::VariableNodeData
    bigDataEntries::Vector{String} #Big data entries
    smallData::Dict{String, Any} # All small data.
end

"""
Packed type for VariableNodeData.
"""
mutable struct PackedVariableNodeData
  vecinitval::Array{Float64,1}
  diminitval::Int
  vecinitstdev::Array{Float64,1}
  diminitdev::Int
  vecval::Array{Float64,1}
  dimval::Int
  vecbw::Array{Float64,1}
  dimbw::Int
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1}
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  # groundtruth::VoidUnion{ Dict{ Tuple{Symbol, Vector{Float64}} } }
  softtype::String
  initialized::Bool
  PackedVariableNodeData() = new()
  PackedVariableNodeData(x1::Vector{Float64},
                         x2::Int,
                         x3::Vector{Float64},
                         x4::Int,
                         x5::Vector{Float64},
                         x6::Int,
                         x7::Vector{Float64},
                         x8::Int,
                         x9::Vector{Int},
                         x10::Vector{Int},
                         x11::Int,
                         x12::Bool,
                         x13::Int,
                         x14::Vector{Int},
                         x15::String,
                         x16::Bool) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16)
end

"""
Converter: VariableNodeData -> PackedVariableNodeData
"""
function convert(::Type{PackedVariableNodeData}, d::VariableNodeData)
  return PackedVariableNodeData(d.initval[:],size(d.initval,1),
                              d.initstdev[:],size(d.initstdev,1),
                              d.val[:],size(d.val,1),
                              d.bw[:], size(d.bw,1),
                              d.BayesNetOutVertIDs,
                              d.dimIDs, d.dims, d.eliminated,
                              d.BayesNetVertID, d.separator,
                              string(d.softtype), d.initialized)
end
"""
Converter: PackedVariableNodeData -> VariableNodeData
"""
function convert(::Type{VariableNodeData}, d::PackedVariableNodeData)

  r1 = d.diminitval
  c1 = r1 > 0 ? floor(Int,length(d.vecinitval)/r1) : 0
  M1 = reshape(d.vecinitval,r1,c1)

  r2 = d.diminitdev
  c2 = r2 > 0 ? floor(Int,length(d.vecinitstdev)/r2) : 0
  M2 = reshape(d.vecinitstdev,r2,c2)

  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  st = IncrementalInference.ContinuousMultivariate # eval(parse(d.softtype))

  return VariableNodeData(M1,M2,M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    nothing, st, d.initialized )
end

"""
Comparator for VariableNodeData.
"""
function compare(a::VariableNodeData,b::VariableNodeData)
    TP = true
    TP = TP && a.initval == b.initval
    TP = TP && a.initstdev == b.initstdev
    TP = TP && a.val == b.val
    TP = TP && a.bw == b.bw
    TP = TP && a.BayesNetOutVertIDs == b.BayesNetOutVertIDs
    TP = TP && a.dimIDs == b.dimIDs
    TP = TP && a.dims == b.dims
    TP = TP && a.eliminated == b.eliminated
    TP = TP && a.BayesNetVertID == b.BayesNetVertID
    TP = TP && a.separator == b.separator
    return TP
end

"""
Comparator overload for VariableNodeData.
"""
function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return DistributedFactorGraphs.compare(a,b)
end
