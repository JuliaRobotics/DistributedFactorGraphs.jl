using Neo4j
using Base64

# Entities
include("entities/CloudGraphsDFG.jl")
include("entities/CGStructure.jl")

# Services
include("services/CommonFunctions.jl")
include("services/CGStructure.jl")
include("services/CloudGraphsDFG.jl")

# Exports
export Neo4jInstance, CloudGraphsDFG
export exists
export clearSession!
export getLabelDict, getDescription, setDescription, getAddHistory, getSolverParams, setSolverParams

export getAddHistory, getDescription, getLabelDict
export addVariable!, addFactor!
export ls, lsf, getVariables, getFactors, getVariableIds, getFactorIds
export getVariable, getFactor
export updateVariable!, updateFactor!, mergeUpdateVariableSolverData!
export deleteVariable!, deleteFactor!
export getAdjacencyMatrix
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected, hasOrphans
export toDot, toDotFile
