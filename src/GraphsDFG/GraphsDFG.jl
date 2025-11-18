module GraphsDFGs

using Graphs
using DocStringExtensions
using UUIDs
using JSON
using OrderedCollections

using ...DistributedFactorGraphs
using ...DistributedFactorGraphs:
    Agent,
    LabelNotFoundError,
    LabelExistsError,
    Graphroot,
    AbstractGraphVariable,
    AbstractGraphFactor,
    NoSolverParams,
    filterDFG!,
    getSolvable,
    getVariableType,
    getAgentLabel,
    getGraphLabel,
    isInitialized,
    Bloblets,
    Blobentries,
    FolderStore,
    refTags,
    listTags

# import DFG functions to extend
import ...DistributedFactorGraphs:
    setSolverParams!,
    getFactor,
    # getLabelDict,
    addVariable!,
    getVariable,
    addFactor!,
    getSolverParams,
    hasVariable,
    hasFactor,
    isVariable,
    isFactor,
    mergeVariable!,
    mergeFactor!,
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
    toDot,
    toDotFile,
    findShortestPathDijkstra,
    getGraphBlobentry,
    getGraphBlobentries,
    addGraphBlobentry!,
    addGraphBlobentries!,
    listGraphBlobentries,
    listAgentBlobentries,
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
