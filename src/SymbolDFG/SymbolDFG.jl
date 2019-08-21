module SymbolDFGs

using LightGraphs
using SparseArrays
using DocStringExtensions

import ...DistributedFactorGraphs: AbstractDFG, DFGNode, AbstractParams, NoSolverParams, DFGVariable, DFGFactor
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
                                    getNeighbors,
                                    getSubgraphAroundNode,
                                    getSubgraph,
                                    getAdjacencyMatrix,
                                    getAdjacencyMatrixSparse

include("SymbolFactorGraphs/SymbolFactorGraphs.jl")
using .SymbolFactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/SymbolDFG.jl")
include("services/SymbolDFG.jl")

# Exports
export SymbolDFG


end
