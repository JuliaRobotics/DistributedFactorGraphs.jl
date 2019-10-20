using Graphs

# Imports
include("entities/GraphsDFG.jl")
include("services/GraphsDFG.jl")

# Exports
export GraphsDFG
export exists
export getLabelDict, getDescription, setDescription, getAddHistory, getSolverParams, setSolverParams

export getAddHistory, getDescription, getLabelDict
export addVariable!, addFactor!
export ls, lsf, getVariables, getFactors, getVariableIds, getFactorIds
export getVariable, getFactor
export updateVariable!, updateFactor!, updateVariableSolverData!
export deleteVariable!, deleteFactor!
export getAdjacencyMatrix
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected, hasOrphans
export toDot, toDotFile
