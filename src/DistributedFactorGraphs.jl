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

import Distributions #TODO this was unused before (if we move SerializingDistributions.jl out we can maybe remove the Distributions dependency?)
import Tar
import CodecZlib

using OrderedCollections: OrderedDict, LittleDict

using CSV
using Tables

# used for @defStateType
import ManifoldsBase
using ManifoldsBase: AbstractManifold, manifold_dimension
export AbstractManifold, manifold_dimension

using RecursiveArrayTools: ArrayPartition
export ArrayPartition
using StaticArrays

using InteractiveUtils: subtypes

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
export AbstractPackedObservation, PackedObservation
export AbstractObservation, Observation
export AbstractPriorObservation, PriorObservation
export AbstractRelativeObservation, RelativeObservation
export AbstractFactorCache, FactorCache
export AbstractStateType, StateType
export AbstractPackedBelief, PackedBelief

##------------------------------------------------------------------------------
## Types
##------------------------------------------------------------------------------
#TODO types are not yet stable - also, we might not export types such as VariableCompute
# Variables
export VariableCompute, VariableDFG, VariableSummary, VariableSkeleton
# Factors
export FactorDFG, FactorSummary, FactorSkeleton

export Blobentry

export State

##------------------------------------------------------------------------------
## Functions
##------------------------------------------------------------------------------
# v1 name, signiture, return, and error checked
export addVariable!
export mergeVariable!
export deleteVariable!
export addVariables!
export getVariables

export addFactor!
export getFactor
export deleteFactor!
export addFactors!
export getFactors

export addState!
export getState
export mergeState!
export deleteState!
export addStates!
export mergeStates!
export deleteStates!

export addBlobentry!
export getBlobentry
export mergeBlobentry!
export deleteBlobentry!
export addBlobentries!

## list
export listVariables
export listFactors
export listStates

##
export getGraphBlobentry

export getObservation

## v1 name, signiture, and return

## v1 name only

##------------------------------------------------------------------------------
# Variable
##------------------------------------------------------------------------------
export getVariable
export hasVariable
export mergeVariables!
##------------------------------------------------------------------------------
## State
##------------------------------------------------------------------------------
export getStates

##------------------------------------------------------------------------------
# Factor
##------------------------------------------------------------------------------
export mergeFactor!
export mergeFactors!
export hasFactor

##------------------------------------------------------------------------------
## Blobentries
##------------------------------------------------------------------------------
export addBlobentries!
export addGraphBlobentry!
export addGraphBlobentries!
export addAgentBlobentry!
export addAgentBlobentries!

export getBlobentries
export getGraphBlobentries
export getAgentBlobentry
export getAgentBlobentries

export mergeBlobentries!
export mergeGraphBlobentry!
export mergeGraphBlobentries!
export mergeAgentBlobentry!
export mergeAgentBlobentries!

export deleteGraphBlobentry!
export deleteAgentBlobentry!
export deleteGraphBlobentries!
export deleteAgentBlobentries!

export listBlobentries
export listGraphBlobentries
export listAgentBlobentries

export hasBlobentry
export hasGraphBlobentry
export hasAgentBlobentry

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
## CRUD Matrix
# export addVariable!,          getVariable,          mergeVariable!,          deleteVariable!
# export addVariables!,         getVariables,         mergeVariables!,         deleteVariables!
# export addFactor!,            getFactor,            mergeFactor!,            deleteFactor!
# export addFactors!,           getFactors,           mergeFactors!,           deleteFactors!

# export addState!,             getState,             mergeState!,             deleteState!
# export addStates!,            getStates,            mergeStates!,            deleteStates!

# export addBlobentry!,         getBlobentry,         mergeBlobentry!,         deleteBlobentry! # historic for VariableBlobentry
# export addBlobentries!,       getBlobentries,       mergeBlobentries!,       deleteBlobentries!
# export addGraphBlobentry!,    getGraphBlobentry,    mergeGraphBlobentry!,    deleteGraphBlobentry!
# export addGraphBlobentries!,  getGraphBlobentries,  mergeGraphBlobentries!,  deleteGraphBlobentries!
# export addAgentBlobentry!,    getAgentBlobentry,    mergeAgentBlobentry!,    deleteAgentBlobentry!
# export addAgentBlobentries!,  getAgentBlobentries,  mergeAgentBlobentries!,  deleteAgentBlobentries!
#TODO blob entries not implemented on factors yet
# export addFactorBlobentry!,   getFactorBlobentry,   mergeFactorBlobentry!,   deleteFactorBlobentry!
# export addFactorBlobentries!, getFactorBlobentries, mergeFactorBlobentries!, deleteFactorBlobentries!

# TODO first pass progress
# export addVariableMetadata!,  getVariableMetadata,  mergeVariableMetadata!,  deleteVariableMetadata!
# export addFactorMetadata!,    getFactorMetadata,    mergeFactorMetadata!,    deleteFactorMetadata!
# export addAgentMetadata!,     getAgentMetadata,     mergeAgentMetadata!,     deleteAgentMetadata!
# export addGraphMetadata!,     getGraphMetadata,     mergeGraphMetadata!,     deleteGraphMetadata!

# export addVariableBlobentryMetadata!, getVariableBlobentryMetadata, mergeVariableBlobentryMetadata!, deleteVariableBlobentryMetadata!
# export addFactorBlobentryMetadata!,   getFactorBlobentryMetadata,   mergeFactorBlobentryMetadata!,   deleteFactorBlobentryMetadata!
# export addAgentBlobentryMetadata!,    getAgentBlobentryMetadata,    mergeAgentBlobentryMetadata!,    deleteAgentBlobentryMetadata!
# export addGraphBlobentryMetadata!,    getGraphBlobentryMetadata,    mergeGraphBlobentryMetadata!,    deleteGraphBlobentryMetadata!

## list
# export listVariables, listFactors, listStates, listBlobentries, listFactorBlobEntries, listGraphBlobentries, listAgentBlobentries
# not implemented yet (maybe not for DFG v1.0 yet):
# export listVariableMetadata, listFactorMetadata, listAgentMetadata, listGraphMetadata
# export listVariableBlobentryMetadata, listFactorBlobentryMetadata, listAgentBlobentryMetadata, listGraphBlobentryMetadata

##==============================================================================
## Common Accessors 
##==============================================================================
export getLabel

# might only be public
export getId

##==============================================================================
## Internal or not yet ready
##==============================================================================
##------------------------------------------------------------------------------
## Types
##------------------------------------------------------------------------------
export InMemoryDFGTypes
export LocalDFG
export FolderStore

##------------------------------------------------------------------------------
## Tags
##------------------------------------------------------------------------------
# tags is a set: get/list, merge, empty, and remove (we don't have add but merge)
export getTags
export listTags
export mergeTags!
export emptyTags!
export removeTags! #TODO do we want this one
export hasTags

##------------------------------------------------------------------------------
## Bloblets
##------------------------------------------------------------------------------
# currently these refer to variable Bloblets
#TODO Bloblet CRUD
# export getVariableBloblet
# export addVariableBloblet!
# export deleteVariableBloblet!
# export listVariableBloblets

# export getAgentBloblet
# export getGraphBloblet

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
export ls # alias for listVariables
export lsf # alias for listFactors

##------------------------------------------------------------------------------
## Other utility functions
##------------------------------------------------------------------------------

export listNeighborhood
export listNeighbors

## TODO maybe move to DFG from SDK
# addAgent!
# deleteAgent!
# listAgents
# addGraph!
# deleteGraph!
# listGraphs
# getAgents
# getModel
# getModels
# addModel!
# getGraphs

##==============================================================================
export @format_str # exported from FileIO

export @defStateType #TODO Should this be exported?

# list of unstable functions not exported any more
# will move to public or deprecate over time
const unstable_functions::Vector{Symbol} = [
    :InMemoryBlobstore,
    :MetadataTypes, #maybe make public after metadata stable
    :getFactorState, # FIXME getFactorState were questioned and being reviewed again for name, other than that they are checked.
    :exists,
    :emptyMetadata!, #TODO maybe deprecate for just deleteMetadata!
    :emptyBlobstore!, #TODO maybe deprecate for just deleteBlobstore!
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
    :findVariableNearTimestamp,
    :findShortestPathDijkstra,
    :findFactorsBetweenNaive,
    :getAgentLabel,
    :getGraphLabel,
    :getVariableTypeName,
    :getVariableType,
    :getDescription,
    :getAddHistory,
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
    :getSolveInProgress,#TODO unused, do we deprecate?
    :hasTagsNeighbors,
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
    :pack,
    :packDistribution,
    :packVariable,
    # :packFactor,
    :packBlob,
    :packState,
    :unpack,
    :unpackDistribution,
    :unpackVariable,
    # :unpackFactor,
    :unpackBlob,
    :unpackState,
    :ls2,
    :lsfPriors,
    :listBlobentrySequence,# TODO somewhat used, do we deprecate?
    :natural_lt, #TODO do we  stable functions such as natural_lt or just mark as public
    :sortDFG, #TODO do we  stable functions such as natural_lt or just mark as public
    :mergeGraph!,
    :buildSubgraph,
    :incrDataLabelSuffix,# TODO somewhat used, do we deprecate?
    :updateBlobstore!,## TODO deprecated or obsolete
    :updateMetadata!,## TODO deprecated or obsolete
    :updateBlob!,## TODO deprecated or obsolete

    # set # TODO what to do here, maybe `ref` verb + setproperty.  
    :setSolverParams!,
    :setDescription!,
    :setSolvable!,
    :setTags!,
    :setSolvedCount!,
    :setMarginalized!,
    # no set on these

    #deprecated in v0.29
    :setTimestamp,
    :setMetadata!, # no set, use add merge
    :setAgentMetadata!,
    :setGraphMetadata!,
    # :getSolverDataDict,# obsolete

    #Deprecated in v0.28
    :AbstractRelativeMinimize,
    :AbstractManifoldMinimize,
    :AbstractPrior,
    :AbstractRelative,
    :InferenceVariable,
    :InferenceType,
    :PackedSamplableBelief,
    :getVariableState,
    :addVariableState!,
    :mergeVariableState!,
    :deleteVariableState!,
    :listVariableStates,
    :VariableState,
    :VariableStateType,
    :copytoVariableState!,
    :setSolverData!,
    :getBlobentriesVariables,
    :mergeVariableData!,
    :mergeGraphVariableData!,
    :getData,
    :addData!,
    :updateData!,
    :deleteData!,
    :SkeletonDFGVariable,
    :DFGVariableSummary,
    :PackedVariable,
    :Variable,
    :DFGVariable,
    :SkeletonDFGFactor,
    :DFGFactorSummary,
    :DFGFactor,
    :PackedFactor,
    :Factor,
    :AbstractPointParametricEst,
    # :MeanMaxPPE,
    # :getPPEMax,
    # :getPPEMean,
    # :getPPESuggested,
    # :getLastUpdatedTimestamp,
    # :getPPEDict,
    # :getVariablePPEDict,
    # :getVariablePPE,
    :listSolveKeys,
    :listSupersolves,
    # :getPPE,
    # :getPPEs,
    # :getVariablePPE,
    # :addPPE!,
    # :updatePPE!,
    # :deletePPE!,
    # :listPPEs,
    # :mergePPEs!,
    Symbol("@defVariable"),
    :SmallDataTypes,
    :NoSolverParams,
    :AbstractParams,
    # Deprecated in v0.27
    # :AbstractFactor,
    # :AbstractPackedFactor,
    # :FactorOperationalMemory,
    # :VariableNodeData,
    # :updateVariableSolverData!,
    # :getSolverData,
    # :setSolverData!,
    # :reconstFactorData,
    # :_packSolverData,
    # :GenericFunctionNodeData,
    # :PackedFunctionNodeData,
    # :FunctionNodeData,
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

include("entities/Agent_and_Graph.jl")

include("services/AbstractDFG.jl")

#Blobs
include("DataBlobs/services/BlobEntry.jl")
include("DataBlobs/services/BlobStores.jl")
include("DataBlobs/services/BlobPacking.jl")
include("DataBlobs/services/BlobWrappers.jl")

# To be moved as necessary.
include("Common.jl")

function getSolvable end
function getVariableType end
function isInitialized end
# In Memory Types
include("GraphsDFG/GraphsDFG.jl")
using .GraphsDFGs

#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG}
const LocalDFG = GraphsDFG

# Common includes
include("services/CommonAccessors.jl")
include("services/Serialization.jl")
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
