module SymbolDFGs

using LightGraphs
using DocStringExtensions

# import DFG functions to exstend
import ...DistributedFactorGraphs:  setSolverParams,
                                    getInnerGraph,
                                    getFactor,
                                    setDescription,
                                    getLabelDict,
                                    addVariable!,
                                    getVariable,
                                    getAddHistory,
                                    addFactor!,
                                    getSolverParams,
                                    exists,
                                    getDescription,
                                    updateVariable!,
                                    updateFactor!,
                                    deleteVariable!,
                                    deleteFactor!,
                                    getVariables,
                                    getVariableIds,
                                    ls,
                                    getFactors,
                                    getFactorIds,
                                    lsf,
                                    isFullyConnected,
                                    hasOrphans,
                                    getNeighbors

include("SymbolFactorGraphs/SymbolFactorGraphs.jl")
using .SymbolFactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/SymbolDFG.jl")
include("services/SymbolDFG.jl")

# Exports
export SymbolDFG

export exists
export getLabelDict, getDescription, setDescription, getInnerGraph, getAddHistory, getSolverParams, setSolverParams
#
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

end
