module GraphsDFGs

using Graphs
using DocStringExtensions
using UUIDs
using JSON
using OrderedCollections

using ...DistributedFactorGraphs
using ...DistributedFactorGraphs:
    Agent,
    refAgents,
    getAgent,
    LabelNotFoundError,
    LabelExistsError,
    MergeConflictError,
    Graphroot,
    AbstractGraphVariable,
    AbstractGraphFactor,
    NoSolverParams,
    filterDFG!,
    getSolvable,
    getStateKind,
    getGraphLabel,
    isInitialized,
    Bloblets,
    addBloblet!,
    addBloblets!,
    getBloblet,
    getBloblets,
    mergeBloblet!,
    mergeBloblets!,
    deleteBloblet!,
    deleteBloblets!,
    listBloblets,
    listNeighbors,
    hasBloblet,
    Blobentries,
    refTags,
    listTags,
    patch!,
    mergeTags!,
    deleteTags!,
    refStates,
    refBlobstores,
    hasBlobentry,
    hasBlobstore

include("FactorGraphs/FactorGraphs.jl")
using .FactorGraphs

# export SymbolEdge, is_directed, has_edge
# Imports
include("entities/GraphsDFG.jl")
include("services/agent_ops.jl")
include("services/graph_ops.jl")
include("services/state_ops.jl")
include("services/variable_ops.jl")
include("services/factor_ops.jl")
include("services/blobentry_ops.jl")
include("services/bloblet_ops.jl")
include("services/blobstore_ops.jl")
include("services/tag_ops.jl")

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
