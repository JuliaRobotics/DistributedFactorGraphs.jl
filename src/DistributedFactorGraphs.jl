module DistributedFactorGraphs

using
  DocStringExtensions

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")
include("entities/DFGAPI.jl")

export DFGAPI
export DFGFactor, GenericFunctionNodeData, FunctionNodeData, PackedFunctionNodeData
export DFGVariable, ContinuousScalar, ContinuousMultivariate, VariableNodeData, PackedVariableNodeData

end
