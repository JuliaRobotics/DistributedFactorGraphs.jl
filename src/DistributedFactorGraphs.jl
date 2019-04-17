module DistributedFactorGraphs

using Base
using DocStringExtensions
using Requires

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")

export AbstractDFG
export DFGNode
export DFGFactor
export DFGVariable

# Exports for actual graph operations - we need a complete list here
export addVariable!
export addFactor!
export ls, lsf, getVariables, getFactors
export getVariable, getFactor
export updateVariable, updateFactor
export getAdjacencyMatrix
export getAdjacencyMatrixDataFrame
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected

# Include the Graphs.jl API.
include("services/GraphsDFG.jl")

end
