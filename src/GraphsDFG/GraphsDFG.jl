module GraphsDFGs

using Graphs
using DocStringExtensions
using UUIDs
using JSON3
using OrderedCollections
using StructTypes

using ...DistributedFactorGraphs
using ...DistributedFactorGraphs: Agent

# import DFG functions to extend
import ...DistributedFactorGraphs:
    setSolverParams!,
    getFactor,
    # getLabelDict,
    getAgentMetadata,
    setAgentMetadata!,
    getGraphMetadata,
    setGraphMetadata!,
    addVariable!,
    getVariable,
    getAddHistory,
    addFactor!,
    getSolverParams,
    exists,
    isVariable,
    isFactor,
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
    listNeighbors,
    buildSubgraph,
    copyGraph!,
    getBiadjacencyMatrix,
    _getDuplicatedEmptyDFG,
    toDot,
    toDotFile,
    findShortestPathDijkstra,
    getGraphBlobEntry,
    getGraphBlobEntries,
    addGraphBlobEntry!,
    addGraphBlobEntries!,
    listGraphBlobEntries,
    listAgentBlobEntries,
    getTypeDFGVariables,
    getTypeDFGFactors

include("FactorGraphs/FactorGraphs.jl")
using .FactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/GraphsDFG.jl")
include("services/GraphsDFG.jl")
include("services/GraphsDFGSerialization.jl")

# Exports
export GraphsDFG

end
