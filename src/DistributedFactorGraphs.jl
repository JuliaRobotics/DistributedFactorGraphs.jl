"""
DistributedFactorGraphs.jl provides a flexible factor graph API for use in the Caesar.jl ecosystem.

The package supplies:

- A standardized API for interacting with factor graphs
- Implementations of the API for in-memory and database-driven operation
- Visualization extensions to validate the underlying graph

"""
module DistributedFactorGraphs

# ==============================================================================
# imports
# ==============================================================================

using Base
using Base64
using DocStringExtensions
using Dates
using Random
using TimeZones
using TimesDates
using JSON
using LinearAlgebra
using SparseArrays
using UUIDs
using Pkg
using TensorCast
using ProgressMeter
using SHA
using CRC32c: crc32c
using FileIO
using MIMEs: mime_from_extension, extension_from_mime

import Distributions #TODO this was unused before (if we move SerializingDistributions.jl out we can maybe remove the Distributions dependency?)
import Tar
import CodecZlib

using OrderedCollections: OrderedDict, LittleDict

using Tables

import Base.Filesystem: hardlink

# used for @defStateType
import ManifoldsBase
using ManifoldsBase: AbstractManifold, manifold_dimension

using RecursiveArrayTools: ArrayPartition
using StaticArrays

using InteractiveUtils: subtypes

using StructUtils: @kwarg, @tags

# ==============================================================================
# Exports - DFG not part of the cross language API but we export it for convenience in Julia
# ==============================================================================
# Re-exports
export StructUtils # export for use in macros
export AbstractManifold
export ArrayPartition
export @format_str   # from FileIO

# DFG exports
const DFG = DistributedFactorGraphs
export DFG               # module alias for DistributedFactorGraphs
export getLabel #TODO move
export @defStateType # macro to define custom variable types

# ------------------------------------------------------------------------------
#  Types
# ------------------------------------------------------------------------------
export GraphsDFG         # in-memory driver type
# Variables
export VariableDFG
# export VariableSummary #TODO not finalized yet.
export VariableSkeleton
# Factors
export FactorDFG
# export FactorSummary #TODO not finalized yet.
export FactorSkeleton

export State
export Blobentry
export Bloblet

export Agent

# ==============================================================================
# Exports — cross-language CRUD API
# ==============================================================================
# ------------------------------------------------------------------------------
#  Abstract types and their aliases
# ------------------------------------------------------------------------------
export AbstractDFG
export AbstractDFGParams, DFGParams
export AbstractBlobprovider, Blobprovider
export AbstractGraphNode, GraphNode
export AbstractGraphVariable, GraphVariable
export AbstractGraphFactor, GraphFactor
export AbstractObservation, Observation
export AbstractPriorObservation, PriorObservation
export AbstractRelativeObservation, RelativeObservation
export AbstractFactorCache, FactorCache
export AbstractStateType, StateType

# -----------------------------------------------------------------------------
#  Variable CRUD
# ------------------------------------------------------------------------------
export addVariable!, getVariable, mergeVariable!, deleteVariable!
export addVariables!, getVariables, mergeVariables!, deleteVariables!
export listVariables
export hasVariable

# Factor CRUD
export addFactor!, getFactor, mergeFactor!, deleteFactor!
export addFactors!, getFactors, mergeFactors!, deleteFactors!
export listFactors
export hasFactor

# State CRUD
export addState!, getState, mergeState!, deleteState!
export addStates!, getStates, mergeStates!, deleteStates!
export listStates
export hasState

# Agent CRUD
export addAgent!, getAgent, mergeAgent!, deleteAgent!
export addAgents!, getAgents, mergeAgents!, deleteAgents!
export listAgents
export hasAgent

# ------------------------------------------------------------------------------
# Variable Blobentries
# ------------------------------------------------------------------------------
export addVariableBlobentry!,
    getVariableBlobentry, mergeVariableBlobentry!, deleteVariableBlobentry!
export addVariableBlobentries!,
    getVariableBlobentries, mergeVariableBlobentries!, deleteVariableBlobentries!
export listVariableBlobentries
export hasVariableBlobentry

# Factor Blobentries
export addFactorBlobentry!,
    getFactorBlobentry, mergeFactorBlobentry!, deleteFactorBlobentry!
export addFactorBlobentries!,
    getFactorBlobentries, mergeFactorBlobentries!, deleteFactorBlobentries!
export listFactorBlobentries
export hasFactorBlobentry

# Graph Blobentries
export addGraphBlobentry!, getGraphBlobentry, mergeGraphBlobentry!, deleteGraphBlobentry!
export addGraphBlobentries!,
    getGraphBlobentries, mergeGraphBlobentries!, deleteGraphBlobentries!
export listGraphBlobentries
export hasGraphBlobentry

# Agent Blobentries
export addAgentBlobentry!, getAgentBlobentry, mergeAgentBlobentry!, deleteAgentBlobentry!
export addAgentBlobentries!,
    getAgentBlobentries, mergeAgentBlobentries!, deleteAgentBlobentries!
export listAgentBlobentries
export hasAgentBlobentry

# Model blobentries: interface defined in services/blobentry_ops.jl but no GraphsDFG implementation yet
# downstream libraries can still implement these and then export. Only export here once we have a stable API and GraphsDFG implementation.
# export addModelBlobentry!,  getModelBlobentry,  mergeModelBlobentry!,  deleteModelBlobentry!
# export addModelBlobentries!, getModelBlobentries, mergeModelBlobentries!, deleteModelBlobentries!
# export listModelBlobentries, hasModelBlobentry

# ------------------------------------------------------------------------------
# Bloblet
# ------------------------------------------------------------------------------
# Variable Bloblets
export addVariableBloblet!,
    getVariableBloblet, mergeVariableBloblet!, deleteVariableBloblet!
export addVariableBloblets!,
    getVariableBloblets, mergeVariableBloblets!, deleteVariableBloblets!
export listVariableBloblets
export hasVariableBloblet

# Factor Bloblets
export addFactorBloblet!, getFactorBloblet, mergeFactorBloblet!, deleteFactorBloblet!
export addFactorBloblets!, getFactorBloblets, mergeFactorBloblets!, deleteFactorBloblets!
export listFactorBloblets
export hasFactorBloblet

# Graph Bloblets
export addGraphBloblet!, getGraphBloblet, mergeGraphBloblet!, deleteGraphBloblet!
export addGraphBloblets!, getGraphBloblets, mergeGraphBloblets!, deleteGraphBloblets!
export listGraphBloblets
export hasGraphBloblet

# Agent Bloblets
export addAgentBloblet!, getAgentBloblet, mergeAgentBloblet!, deleteAgentBloblet!
export addAgentBloblets!, getAgentBloblets, mergeAgentBloblets!, deleteAgentBloblets!
export listAgentBloblets
export hasAgentBloblet

# ------------------------------------------------------------------------------
# Tags (set semantics: merge/delete/list/has)
# ------------------------------------------------------------------------------
export mergeVariableTags!, deleteVariableTags!, listVariableTags, hasVariableTags
export mergeFactorTags!, deleteFactorTags!, listFactorTags, hasFactorTags
export mergeGraphTags!, deleteGraphTags!, listGraphTags, hasGraphTags
export mergeAgentTags!, deleteAgentTags!, listAgentTags, hasAgentTags

# ------------------------------------------------------------------------------
# Blobprovider CRUD
# ------------------------------------------------------------------------------
export addBlobprovider!, getBlobprovider, mergeBlobprovider!, deleteBlobprovider!
export getBlobproviders, mergeBlobproviders!
export listBlobproviders
export hasBlobprovider

# ==============================================================================
# Public — stable API, not cross-language or advanced use
# ==============================================================================
# Julia re-exports needed for macros and type definitions
public @tags, @kwarg

# Julia-specific driver types and aliases
public GraphsDFGs        # submodule
public InMemoryDFGTypes  # Union{GraphsDFG}
public LocalDFG          # alias for GraphsDFG

# Common accessors (Julia convenience, other langs use field access)
public getId
public getObservation
public getStateKind
public refStates

# Node-level tag operations (generic, used internally by scoped tag exports)
public listTags
public mergeTags!
public deleteTags!

# Blob operations (cross-language concept, export later if needed)
public getBlob       # DFG-level: searches all mounted providers
public fetchBlob     # provider-level: fetch by multihash
public putBlob!      # provider-level: CAS write
public purgeBlob!    # provider-level: physical remove
public listBlobs     # provider-level: list all multihashes
public hasBlob       # provider/DFG-level: check existence
public verifyBlob    # utility: verify blob against blobentry hashes

# Blobprovider types
public FolderBlobprovider
public MemoryBlobprovider
public CachedBlobprovider
# Blobprovider internals
public refBlobproviders
public stashBlobproviders!   # persist provider configs as graph bloblet
public applyBlobproviders!   # restore provider configs from graph bloblet

# Serialization helpers
public pack, unpack

# ==============================================================================
# list of unstable functions not exported any more
# will move to public or deprecate over time
const unstable_functions::Vector{Symbol} = [
    # FileDFG — Julia-specific serialization
    #TODO these use the wrong signature and we can just overload julia's write/read or FileIo save/load, deprecate these in favor of read/write or save/load.
    :saveDFG,
    :loadDFG!,
    :loadDFG,
    #
    :getGraph,
    :VariableSummary,
    :FactorSummary,
    :listNeighborhood,
    :listNeighbors,
    :findPath,
    :findPaths,
    :exists,
    :compare,
    :compareField,
    :compareFields,
    :compareAll,
    :compareVariable,
    :compareFactor,
    :compareAllVariables,
    :compareSimilarVariables,
    :compareSimilarFactors,
    :compareFactorGraphs,
    :convertPackedType,
    :convertStructType,
    :copyGraph!,
    :deepcopyGraph,
    :deepcopyGraph!,
    :findClosestTimestamp,
    :findVariablesNearTimestamp,
    :findShortestPathDijkstra,
    :findFactorsBetweenNaive, # TODO not really used
    :getGraphLabel, #TODO check and maybe mark as public
    :getDescription,
    :getSolverParams,
    :getHash,
    :getTimestamp,
    :getSolvable,
    :getVariableOrder,
    :getSolvedCount,
    :getDimension,
    :getManifold,
    :getPointType,
    :getSummaryGraph,
    :getBiadjacencyMatrix,
    :getPointIdentity,
    :getPoint,
    :getCoordinates,
    :getfirstBlobentry,# TODO somewhat used, do we deprecate?
    :isVariable,
    :isFactor,
    :isConnected,
    :isPathFactorsHomogeneous,
    :isSolvable,
    :isSolved,
    :isInitialized,
    :isMarginalized,
    :isPrior,
    :isSolveInProgress,#TODO these are currently unused, do we deprecate?
    :printFactor,
    :printVariable,
    :printNode,
    :plotDFG,
    :packBlob,
    :hasTags,
    :unpackBlob,
    :getMimetype,
    :getDataFormat,
    :getMimetype,
    :emptyTags!,
    :ls,
    :lsf,
    :ls2,
    :lsfPriors,
    :listBlobentrySequence,# TODO somewhat used, do we deprecate?
    :natural_lt, #TODO do we export stable functions such as natural_lt or just mark as public
    :sortDFG, #TODO do we export stable functions such as natural_lt or just mark as public
    :mergeGraph!,
    :getSubgraph,
    :incrDataLabelSuffix,# TODO somewhat used, do we deprecate?

    # set # TODO what to do here, maybe `ref` verb + setproperty.  
    :setSolverParams!,
    :setDescription!,
    :setSolvable!,
    :setSolvedCount!,
    :setMarginalized!,
    # no set on these

    #deprecated in v0.29
    :getVariableLabelNumber,# TODO somewhat used, deprecated
    :setTags!,
    :VariableCompute,
    :AbstractPackedBelief,
    :PackedBelief,
    :AbstractPackedObservation,
    :PackedObservation,
    :updateMetadata!,# TODO deprecated or obsolete
    :getFactorState, # FIXME getFactorState were questioned and being reviewed again for name, other than that they are checked.
    :packDistribution,
    :unpackDistribution,
    :hasTagsNeighbors,
    # :updateBlobstore!,# TODO deprecated or obsolete
    # :emptyMetadata!, #TODO maybe deprecate for just deleteMetadata!
    # :emptyBlobstore!, #TODO maybe deprecate for just deleteBlobstore!
    :MetadataTypes, #maybe make public after metadata stable
    :getVariableTypeName,
    :getStateKind,
    :setTimestamp,
    :setAgentMetadata!,
    :setGraphMetadata!,
    # :getSolverDataDict,# obsolete
    :getAddHistory,
    :getSolveInProgress,#deprecated
]

macro usingDFG(unstable = false)
    pub_names = names(DistributedFactorGraphs)
    if unstable
        pub_names = union(pub_names, DFG.unstable_functions)
    end
    syms = [Expr(:., Symbol(n)) for n in pub_names]
    return Expr(:using, Expr(:(:), Expr(:(.), :DistributedFactorGraphs), syms...))
end

# ==============================================================================
# Files Includes
# ==============================================================================

# Entities
include("entities/AbstractDFG.jl")
include("entities/Multihash.jl")
include("entities/Error.jl")
include("entities/Blobprovider.jl")
include("entities/Bloblet.jl")
include("entities/Blobentry.jl")
include("entities/Tags.jl")
include("entities/Timestamp.jl")
include("entities/Agent_and_Graph.jl")
include("entities/Factor.jl")
include("entities/State.jl")
include("entities/Variable.jl")
include("entities/equality.jl")
# Services
include("services/AbstractDFG.jl")
include("services/blob_save_load.jl")
include("services/blobentry_ops.jl")
include("services/bloblet_ops.jl")
include("services/tag_ops.jl")
include("services/blobprovider_ops.jl")
include("services/compare.jl")
include("services/factor_ops.jl")
include("services/list.jl")
include("services/agent_ops.jl")
include("services/graph_ops.jl")
include("services/print.jl")
include("services/state_ops.jl")
include("services/discovery.jl")
include("services/variable_ops.jl")

# Modules and Drivers
include("Serialization/BlobPacking.jl")
include("Serialization/DFGStructStyles.jl")
include("Serialization/DistributionSerialization.jl")
include("Serialization/PackedSerialization.jl")
include("Serialization/StateSerialization.jl")

# In Memory Types
include("GraphsDFG/GraphsDFG.jl")
using .GraphsDFGs

#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG}
const LocalDFG = GraphsDFG

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")
# Blobprovider implementations
include("Blobproviders/Blobproviders.jl")

include("extension_stubs.jl")

include("Deprecated.jl")

end
