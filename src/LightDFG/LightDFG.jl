module LightDFGs

using LightGraphs
using DocStringExtensions

import ...DistributedFactorGraphs: AbstractDFG, DFGNode, AbstractDFGVariable, AbstractDFGFactor, AbstractDFGSummary, AbstractParams, NoSolverParams, DFGVariable, DFGFactor

# import DFG functions to extend
import ...DistributedFactorGraphs:  setSolverParams,
                                    getFactor,
                                    setDescription,
                                    getLabelDict,
                                    getUserData,
                                    setUserData,
                                    getRobotData,
                                    setRobotData,
                                    getSessionData,
                                    setSessionData,
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
                                    getAdjacencyMatrixSparse,
                                    _getDuplicatedEmptyDFG

include("FactorGraphs/FactorGraphs.jl")
using .FactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/LightDFG.jl")
include("services/LightDFG.jl")

# Exports
export LightDFG


end
