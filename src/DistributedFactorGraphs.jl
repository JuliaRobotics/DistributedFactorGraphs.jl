module DistributedFactorGraphs

using
  Graphs,
  DocStringExtensions

const VoidUnion{T} = Union{Void, T}

include("FactorGraphTypes.jl")
include("FGOSUtils.jl")

end
