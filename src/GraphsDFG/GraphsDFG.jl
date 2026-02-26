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
    getStateKind,
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
    listAgentBlobentries

include("FactorGraphs/FactorGraphs.jl")
using .FactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/GraphsDFG.jl")
include("services/GraphsDFG.jl")

# Exports
export GraphsDFG

#FIXME maybe add a trait based on solver data for rebuilding factor cache and dispatch on it.
function DFG.rebuildFactorCache!(
    dfg::GraphsDFG{NoSolverParams},
    factor::FactorDFG,
    neighbors = [],
)
    @warn(
        "FactorCache not built, rebuildFactorCache! is not implemented for $(typeof(dfg)). `rebuildFactorCache!` is available in IncrementalInference.",
        maxlog = 1
    )
    return nothing
end

end
