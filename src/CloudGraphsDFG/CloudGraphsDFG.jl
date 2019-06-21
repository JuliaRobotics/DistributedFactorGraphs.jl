using Neo4j

# Entities
include("entities/CloudGraphsDFG.jl")

# Services
include("services/CommonFunctions.jl")
include("services/CloudGraphsDFG.jl")

# Exports
export Neo4jInstance, CloudGraphsDFG
export exists
export clearSession!
export getLabelDict, getDescription, setDescription, getInnerGraph, getAddHistory, getSolverParams, setSolverParams

export getAddHistory, getDescription, getLabelDict
export addVariable!, addFactor!
export ls, lsf, getVariables, getFactors, getVariableIds, getFactorIds
export getVariable, getFactor
export updateVariable!, updateFactor!
export deleteVariable!, deleteFactor!
export getAdjacencyMatrix
export getAdjacencyMatrixDataFrame
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected, hasOrphans
export toDot, toDotFile
