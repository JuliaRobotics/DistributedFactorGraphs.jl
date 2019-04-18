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

# Include the Graphs.jl API.
include("services/GraphsDFG.jl")

end
