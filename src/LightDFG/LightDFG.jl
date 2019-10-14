module LightDFGs

using LightGraphs
using DocStringExtensions

import ...DistributedFactorGraphs: AbstractDFG, DFGNode, AbstractDFGVariable, AbstractDFGFactor, AbstractDFGSummary, AbstractParams, NoSolverParams, DFGVariable, DFGFactor

# import DFG functions to extend
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
                                    getNeighbors,
                                    getSubgraphAroundNode,
                                    getSubgraph,
                                    getAdjacencyMatrix,
                                    getAdjacencyMatrixSparse

include("FactorGraphs/FactorGraphs.jl")
using .FactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/LightDFG.jl")
include("services/LightDFG.jl")

# Exports
export LightDFG


end
