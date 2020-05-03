module GraphsDFGs

using Graphs
using DocStringExtensions
using UUIDs

using ...DistributedFactorGraphs

# import DFG functions to extend
import ...DistributedFactorGraphs:  setSolverParams!,
                                    getFactor,
                                    setDescription!,
                                    # getLabelDict,
                                    getUserData,
                                    setUserData!,
                                    getRobotData,
                                    setRobotData!,
                                    getSessionData,
                                    setSessionData!,
                                    addVariable!,
                                    getVariable,
                                    getAddHistory,
                                    addFactor!,
                                    getSolverParams,
                                    exists,
                                    isVariable,
                                    isFactor,
                                    getDescription,
                                    updateVariable!,
                                    updateFactor!,
                                    deleteVariable!,
                                    deleteFactor!,
                                    getVariables,
                                    listVariables,
                                    ls,
                                    getFactors,
                                    listFactors,
                                    lsf,
                                    isConnected,
                                    getNeighbors,
                                    buildSubgraph,
                                    copyGraph!,
                                    getBiadjacencyMatrix,
                                    _getDuplicatedEmptyDFG,
                                    toDot,
                                    toDotFile

# Imports
include("entities/GraphsDFG.jl")
include("services/GraphsDFG.jl")

# Exports
export GraphsDFG

end
