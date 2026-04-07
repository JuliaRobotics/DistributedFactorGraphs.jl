"""
DistributedFactorGraphs.jl provides a flexible factor graph API for use in the Caesar.jl ecosystem.

The package supplies:

- A standardized API for interacting with factor graphs
- Implementations of the API for in-memory and database-driven operation
- Visualization extensions to validate the underlying graph

"""
module DistributedFactorGraphs

##==============================================================================
## imports
##==============================================================================

using Base
using Base64
using DocStringExtensions
using Dates
using Random
using TimeZones
using TimesDates
using JSON
export StructUtils # export for use in macros
using LinearAlgebra
using SparseArrays
using UUIDs
using Pkg
using TensorCast
using ProgressMeter
using SHA
using FileIO
using MIMEs: mime_from_extension, extension_from_mime

import Distributions #TODO this was unused before (if we move SerializingDistributions.jl out we can maybe remove the Distributions dependency?)
import Tar
import CodecZlib

using OrderedCollections: OrderedDict, LittleDict

using CSV
using Tables

# used for @defStateType
import ManifoldsBase
using ManifoldsBase: AbstractManifold, manifold_dimension
export AbstractManifold

using RecursiveArrayTools: ArrayPartition
export ArrayPartition
using StaticArrays

using InteractiveUtils: subtypes

using StructUtils: @kwarg, @tags
public @tags
public @kwarg

##==============================================================================
# Exports
##==============================================================================
##------------------------------------------------------------------------------
## Abstract types and their aliases
##------------------------------------------------------------------------------
export AbstractDFG
export AbstractDFGParams, DFGParams
export AbstractBlobstore, Blobstore
export AbstractGraphNode, GraphNode
export AbstractGraphVariable, GraphVariable
export AbstractGraphFactor, GraphFactor
export AbstractObservation, Observation
export AbstractPriorObservation, PriorObservation
export AbstractRelativeObservation, RelativeObservation
export AbstractFactorCache, FactorCache
export AbstractStateType, StateType

##------------------------------------------------------------------------------
## Types
##------------------------------------------------------------------------------
#TODO types are not yet stable - also, we might not export all types
# Variables
export VariableDFG
# export VariableSummary #TODO not finalized yet.
export VariableSkeleton
# Factors
export FactorDFG
# export FactorSummary TODO not finalized yet.
export FactorSkeleton

export Blobentry

export State
export Agent

##------------------------------------------------------------------------------
## Functions
##------------------------------------------------------------------------------
##==============================================================================
## CRUD Matrix
# export addVariable!,          getVariable,          mergeVariable!,          deleteVariable!
# export addVariables!,         getVariables,         mergeVariables!,         deleteVariables!
# export addFactor!,            getFactor,            mergeFactor!,            deleteFactor!
# export addFactors!,           getFactors,           mergeFactors!,           deleteFactors!

# export addState!,             getState,             mergeState!,             deleteState!
# export addStates!,            getStates,            mergeStates!,            deleteStates!

# export addVariableBlobentry!,   getVariableBlobentry,   mergeVariableBlobentry!,   deleteVariableBlobentry!
# export addVariableBlobentries!, getVariableBlobentries, mergeVariableBlobentries!, deleteVariableBlobentries!
# export addGraphBlobentry!,    getGraphBlobentry,    mergeGraphBlobentry!,    deleteGraphBlobentry!
# export addGraphBlobentries!,  getGraphBlobentries,  mergeGraphBlobentries!,  deleteGraphBlobentries!
# export addAgentBlobentry!,    getAgentBlobentry,    mergeAgentBlobentry!,    deleteAgentBlobentry!
# export addAgentBlobentries!,  getAgentBlobentries,  mergeAgentBlobentries!,  deleteAgentBlobentries!
# export addFactorBlobentry!,   getFactorBlobentry,   mergeFactorBlobentry!,   deleteFactorBlobentry!
# export addFactorBlobentries!, getFactorBlobentries, mergeFactorBlobentries!, deleteFactorBlobentries!

# export addVariableBloblet!,  getVariableBloblet,  mergeVariableBloblet!,  deleteVariableBloblet!
# export addVariableBloblets!, getVariableBloblets, mergeVariableBloblets!, deleteVariableBloblets!
# export addFactorBloblet!,    getFactorBloblet,    mergeFactorBloblet!,    deleteFactorBloblet!
# export addFactorBloblets!,   getFactorBloblets,   mergeFactorBloblets!,   deleteFactorBloblets!
# export addAgentBloblet!,     getAgentBloblet,     mergeAgentBloblet!,     deleteAgentBloblet!
# export addAgentBloblets!,    getAgentBloblets,    mergeAgentBloblets!,    deleteAgentBloblets!
# export addGraphBloblet!,     getGraphBloblet,     mergeGraphBloblet!,     deleteGraphBloblet!
# export addGraphBloblets!,    getGraphBloblets,    mergeGraphBloblets!,    deleteGraphBloblets!

# list
# export listVariables, listFactors, listStates, listVariableBlobentries, listFactorBlobEntries, listGraphBlobentries, listAgentBlobentries
# export listVariableBloblets, listFactorBloblets, listAgentBloblets, listGraphBloblets

# tags
# export listVariableTags, mergeVariableTags!, deleteVariableTags!
# export listFactorTags, mergeFactorTags!, deleteFactorTags!
# export listGraphTags, mergeGraphTags!, deleteGraphTags!
# export listAgentTags, mergeAgentTags!, deleteAgentTags!

# has
# export hasVariable, hasFactor, hasState
# export hasVariableBlobentry, hasFactorBlobentry, hasGraphBlobentry, hasAgentBlobentry
# export hasVariableBloblet, hasFactorBloblet, hasGraphBloblet, hasAgentBloblet
# export hasVariableTags, hasFactorTags, hasGraphTags, hasAgentTags

# v1 name, signiture, return, and error checked
export addVariable!
export getVariable
export mergeVariable!
export deleteVariable!

export addVariables!
export getVariables
export mergeVariables!
export deleteVariables!

export addFactor!
export getFactor
export deleteFactor!
export mergeFactor!

export addFactors!
export getFactors
export mergeFactors!
export deleteFactors!

export addState!
export getState
export mergeState!
export deleteState!

export addStates!
export getStates # TODO state filters not implemented yet
export mergeStates!
export deleteStates!

# has
export hasVariable
export hasState
export hasFactor

## list
export listVariables
export listFactors
export listStates

##
public getObservation

##------------------------------------------------------------------------------
# Tags
export listVariableTags
export mergeVariableTags!
export deleteVariableTags!
export hasVariableTags

export listFactorTags
export mergeFactorTags!
export deleteFactorTags!
export hasFactorTags

export listGraphTags
export mergeGraphTags!
export deleteGraphTags!
export hasGraphTags

export listAgentTags
export mergeAgentTags!
export deleteAgentTags!
export hasAgentTags

##------------------------------------------------------------------------------
## Blobentries
##------------------------------------------------------------------------------
export addVariableBlobentry!
export getVariableBlobentry
export mergeVariableBlobentry!
export deleteVariableBlobentry!

export addVariableBlobentries!
export getVariableBlobentries
export mergeVariableBlobentries!
export deleteVariableBlobentries!

export addFactorBlobentry!
export getFactorBlobentry
export mergeFactorBlobentry!
export deleteFactorBlobentry!

export addFactorBlobentries!
export getFactorBlobentries
export mergeFactorBlobentries!
export deleteFactorBlobentries!

export addGraphBlobentry!
export getGraphBlobentry
export mergeGraphBlobentry!
export deleteGraphBlobentry!

export addGraphBlobentries!
export getGraphBlobentries
export mergeGraphBlobentries!
export deleteGraphBlobentries!

export addAgentBlobentry!
export getAgentBlobentry
export mergeAgentBlobentry!
export deleteAgentBlobentry!

export addAgentBlobentries!
export getAgentBlobentries
export mergeAgentBlobentries!
export deleteAgentBlobentries!

export listVariableBlobentries
export listFactorBlobentries
export listGraphBlobentries
export listAgentBlobentries

export hasVariableBlobentry
export hasFactorBlobentry
export hasGraphBlobentry
export hasAgentBlobentry

##------------------------------------------------------------------------------
## Bloblets
##------------------------------------------------------------------------------
export Bloblet
export getVariableBloblet
export addVariableBloblet!
export mergeVariableBloblet!
export deleteVariableBloblet!

export addVariableBloblets!
export getVariableBloblets
export mergeVariableBloblets!
export deleteVariableBloblets!

export addFactorBloblet!
export getFactorBloblet
export mergeFactorBloblet!
export deleteFactorBloblet!

export addFactorBloblets!
export getFactorBloblets
export mergeFactorBloblets!
export deleteFactorBloblets!

export getGraphBloblet
export addGraphBloblet!
export mergeGraphBloblet!
export deleteGraphBloblet!

export addGraphBloblets!
export getGraphBloblets
export mergeGraphBloblets!
export deleteGraphBloblets!

export getAgentBloblet
export addAgentBloblet!
export mergeAgentBloblet!
export deleteAgentBloblet!

export addAgentBloblets!
export getAgentBloblets
export mergeAgentBloblets!
export deleteAgentBloblets!

export listVariableBloblets
export listFactorBloblets
export listGraphBloblets
export listAgentBloblets

export hasVariableBloblet
export hasFactorBloblet
export hasGraphBloblet
export hasAgentBloblet

## v1 name, signiture, and return

## v1 name only

##------------------------------------------------------------------------------
## Blobstores and Blobs
##------------------------------------------------------------------------------
export getBlobstore
export addBlobstore!
export deleteBlobstore!
export listBlobstores

# TODO get,add,delete|Blob still needs immutability discussion. but errors checked, tests needs updating though.
export getBlob
# getBlob TODO do we want all of them easy portable vs convenience?
# getBlob(::AbstractBlobstore, ::UUID)
# getBlob(::AbstractBlobstore, ::Blobentry)
# getBlob(::AbstractDFG, ::Blobentry)
export addBlob!
export deleteBlob!
export listBlobs
export hasBlob

##------------------------------------------------------------------------------

##
const DFG = DistributedFactorGraphs
export DFG

export GraphsDFGs
export GraphsDFG

##==============================================================================
## Common Accessors 
##==============================================================================
export getLabel

public getId

##==============================================================================
## Internal or not yet ready
##==============================================================================
##------------------------------------------------------------------------------
## Types
##------------------------------------------------------------------------------
public InMemoryDFGTypes
public LocalDFG
public FolderStore

##------------------------------------------------------------------------------
## Tags
##------------------------------------------------------------------------------
# tags is a set: get/list, merge, delete (we don't have add but merge)

public listTags
public mergeTags!
public deleteTags!
# public emptyTags!

##------------------------------------------------------------------------------
## FileDFG
##------------------------------------------------------------------------------
# File import and export
export saveDFG
export loadDFG!
export loadDFG

##------------------------------------------------------------------------------
## Aliases
##------------------------------------------------------------------------------
#TODO is ls alias or more of a shorthand with extra functionality?
# if shorthand kind of function it is likeley only DFG
# public ls # alias for listVariables
# public lsf # alias for listFactors

##------------------------------------------------------------------------------
## Other utility functions
##------------------------------------------------------------------------------

## Agent CRUD (now in AbstractDFG services)
export addAgent!
export deleteAgent!
export listAgents
export getAgent
export hasAgent
# export mergeAgent!
# public refAgents

## TODO maybe move to DFG from SDK
# addGraph!
# deleteGraph!
# listGraphs
# getGraphs
# getModel
# getModels
# addModel!

##==============================================================================
export @format_str # exported from FileIO

export @defStateType #TODO Should this be exported?

public refStates
public getStateKind

public pack, unpack

# list of unstable functions not exported any more
# will move to public or deprecate over time
const unstable_functions::Vector{Symbol} = [
    :VariableSummary,
    :FactorSummary,
    :listNeighborhood,
    :listNeighbors,
    :findPath,
    :findPaths,
    :InMemoryBlobstore,
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
    :getGraphLabel, #TODO check and mark as public
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
    :getVariableLabelNumber,# TODO somewhat used, do we deprecate?
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
    :setTags!,
    :VariableCompute,
    :AbstractPackedBelief,
    :PackedBelief,
    :AbstractPackedObservation,
    :PackedObservation,
    :updateMetadata!,## TODO deprecated or obsolete
    :getFactorState, # FIXME getFactorState were questioned and being reviewed again for name, other than that they are checked.
    :packDistribution,
    :unpackDistribution,
    :hasTagsNeighbors,
    # :updateBlobstore!,## TODO deprecated or obsolete
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

##==============================================================================

##==============================================================================
## Files Includes
##==============================================================================

# Entities
include("errors.jl")

include("entities/AbstractDFG.jl")
include("entities/Bloblet.jl")

# Data Blob extensions
include("DataBlobs/entities/BlobEntry.jl")
include("DataBlobs/entities/BlobStores.jl")

include("serialization/DFGStructStyles.jl")
include("serialization/PackedSerialization.jl")
include("serialization/DistributionSerialization.jl")

include("entities/DFGFactor.jl")
# include("serialization/FactorSerialization.jl")

include("entities/DFGVariable.jl")
include("serialization/StateSerialization.jl")

include("entities/Agent_and_Graph.jl")

include("services/AbstractDFG.jl")
include("services/list.jl")
include("services/find.jl")
include("services/CommonAccessors.jl")
include("Common.jl")

#Blobs
include("DataBlobs/services/BlobEntry.jl")
include("DataBlobs/services/BlobStores.jl")
include("DataBlobs/services/BlobPacking.jl")
include("DataBlobs/services/BlobWrappers.jl")

#FIXME
function getSolvable end
function getStateKind end
function isInitialized end
function listTags end
# In Memory Types
include("GraphsDFG/GraphsDFG.jl")
using .GraphsDFGs

#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG}
const LocalDFG = GraphsDFG

include("services/Tags.jl")
include("services/Bloblet.jl")

# Common includes
include("services/DFGVariable.jl")
include("services/DFGFactor.jl")
include("Deprecated.jl")
include("services/CompareUtils.jl")

# include("services/Sync.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

# Custom show and printing for variable factor etc.
include("services/CustomPrinting.jl")

include("weakdeps_prototypes.jl")

end
