### TODO: Discussions
# * What is sofftype, and do we want to make it extensible now?
# * Using longs (not GUIDS) for ID's - that work with everyone?
# * BigData and SmallData are referenced in DFGVariable but I don't
#   believe they should be retrieved every time. Thoughts?
# * Is ContinuousScalar used anywhere? Seems like == ContinuousMultivariate(1)
# * Right now InferenceVariable is declared here. Is that fair?
#   I.e. IncrementalInference's InferenceVariable type hierarchy starts here

### Discussion
# * Do edgeIds need to be defined twice - both in DFGFactor and GFND?
#   The higher up the better.
# * What is GenericWrapParam? Looks like it should have been deprecated.
###
###
module DistributedFactorGraphs

using Base
using DocStringExtensions

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")
include("entities/DFGAPI.jl")
include("entities/DistributedFactorGraph.jl")
include("services/DistributedFactorGraph.jl")

export DFGAPI
export DistributedFactorGraph

export DFGNode
export DFGFactor, GenericFunctionNodeData, FunctionNodeData, PackedFunctionNodeData
export DFGVariable, ContinuousScalar, ContinuousMultivariate, VariableNodeData, PackedVariableNodeData

# Exports for actual graph operations - we need a complete list here
export addV!, addF!, getV, getF, deleteV!, deleteF!, neightbors, ls, subgraph, adjacencyMatrix

# Basis of variable and factor - moved from IncrementalInference
export InferenceType, PackedInferenceType, FunctorInferenceType, InferenceVariable

# Include the Graphs.jl API.
include("services/GraphsjlAPI.jl")

end
