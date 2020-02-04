using LightGraphs
using MetaGraphs

# Imports
include("entities/MetaGraphsDFG.jl")
include("services/MetaGraphsDFG.jl")
include("DFGPlots.jl")

# Exports
# Deprecated -
# export MetaGraphsDFG
export exists
export getLabelDict, getDescription, setDescription, getAddHistory, getSolverParams, setSolverParams
#
export getAddHistory, getDescription, getLabelDict
export addVariable!, addFactor!
export ls, lsf, getVariables, getFactors, getVariableIds, getFactorIds
export getVariable, getFactor
export updateVariable!, updateFactor!
export deleteVariable!, deleteFactor!
export getIncidenceMatrix, getIncidenceMatrixSparse
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected, hasOrphans
export toDot, toDotFile
