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
using JSON3
using StructTypes
using LinearAlgebra
using SparseArrays
using UUIDs
using Pkg
using TensorCast
using ProgressMeter
using SHA
using FileIO

import Distributions
import Tar
import CodecZlib

using OrderedCollections: OrderedDict

using CSV
using Tables

# used for @defVariable
import ManifoldsBase
using ManifoldsBase: AbstractManifold, manifold_dimension
export AbstractManifold, manifold_dimension

using RecursiveArrayTools: ArrayPartition
export ArrayPartition
using StaticArrays

import Base: getindex

using InteractiveUtils: subtypes

##==============================================================================
# Exports
##==============================================================================

# v1 name, signiture, return, and error checked
export getFactor, getBlobentry, getGraphBlobentry

export addVariable!, addFactor!, addBlobentry!

export deleteVariable!

# v1 name, signiture, and return

# v1 name only
export getVariable, getBlob, addBlob!

export hasVariable, hasFactor

# getBlob TODO do we want all of them easy portable vs convenience?
# getBlob(::AbstractBlobstore, ::UUID)
# getBlob(::AbstractBlobstore, ::Blobentry)
# getBlob(::AbstractDFG, ::Blobentry)

# TODO get,add,delete|Blob still needs immutability discussion. but errors checked, tests needs updating though.

# TODO not yet implemented in DFG
# addAgentBlobentry!
# addGraphBlobentry!

##
const DFG = DistributedFactorGraphs
export DFG

export GraphsDFGs, GraphsDFG

##
export getVariableState, getFactorState # FIXME these were questioned and being reviewed again for name, other than that they are checked.

##------------------------------------------------------------------------------
## DFG
##------------------------------------------------------------------------------
export AbstractDFG
export AbstractParams, NoSolverParams
export AbstractBlobstore

# accessors & crud
export getDFGInfo
export getDescription,
    setDescription!,
    getSolverParams,
    setSolverParams!,
    getAgentMetadata,
    setAgentMetadata!,
    getGraphMetadata,
    setGraphMetadata!,
    getAddHistory

export getGraphBlobentries,
    addGraphBlobentry!,
    addGraphBlobentries!,
    mergeGraphBlobentry!,
    deleteGraphBlobentry!,
    getAgentBlobentry,
    getAgentBlobentries,
    addAgentBlobentry!,
    addAgentBlobentries!,
    mergeAgentBlobentry!,
    deleteAgentBlobentry!,
    listGraphBlobentries,
    listAgentBlobentries

export getBlobstore,
    addBlobstore!, updateBlobstore!, deleteBlobstore!, emptyBlobstore!, listBlobstores

# TODO Not sure these are needed or should work everywhere, implement in cloud?
# NOTE not exporiting these for now. For consistency `get` and `set` might work better.
# export updateAgentMetadata!,
#     updateGraphMetadata!, deleteAgentMetadata!, deleteGraphMetadata!
# export emptyAgentMetadata!, emptyGraphMetadata!

# Graph Types: exported from modules
export InMemoryDFGTypes, LocalDFG

# AbstractDFG Interface
export exists,
    addVariables!,
    addFactors!,
    mergeVariable!,
    mergeFactor!,
    deleteVariable!,
    deleteFactor!,
    listVariables,
    listFactors,
    listSolveKeys,
    listSupersolves,
    getVariables,
    getFactors,
    isVariable,
    isFactor

export getindex

export isConnected

export getBiadjacencyMatrix

export getSummaryGraph

# Abstract Nodes
export DFGNode, AbstractDFGVariable, AbstractDFGFactor

# Variables
export VariableCompute, VariableSummary, VariableSkeleton, VariableDFG

# Factors
export FactorCompute, FactorSummary, FactorSkeleton, FactorDFG

# Common
export getSolvable, setSolvable!, isSolvable
export getVariableLabelNumber

# accessors
export getLabel, getTimestamp, setTimestamp, getTags, setTags!

export getAgentLabel, getGraphLabel

# Node Data
export isSolveInProgress, getSolveInProgress

# CRUD & SET
export listTags, mergeTags!, removeTags!, emptyTags!

##------------------------------------------------------------------------------
# Variable
##------------------------------------------------------------------------------
# Abstract Variable Data
export VariableStateType

# accessors
export getSolverDataDict
export getVariableType, getVariableTypeName

export getObservation

export getVariableType

# VariableType functions
export getDimension, getManifold, getPointType
export getPointIdentity, getPoint, getCoordinates

# Small Data CRUD
export SmallDataTypes
export getMetadata,
    setMetadata!,
    addMetadata!,
    updateMetadata!,
    deleteMetadata!,
    listMetadata,
    emptyMetadata!

# CRUD & SET
export getVariableStates,
    addVariableState!,
    mergeVariableState!,
    deleteVariableState!,
    listVariableStates

# PPE
##------------------------------------------------------------------------------
# PPE TYPES
export AbstractPointParametricEst
export MeanMaxPPE
export getPPEMax, getPPEMean, getPPESuggested, getLastUpdatedTimestamp

# accessors

export getPPEDict, getVariablePPEDict, getVariablePPE

# CRUD & SET
export getPPE,
    getPPEs, getVariablePPE, addPPE!, updatePPE!, deletePPE!, listPPEs, mergePPEs! #TODO look at rename to just mergePPE to match with cloud?

# Variable Node Data
##------------------------------------------------------------------------------
export VariableState, PackedVariableState

export packVariableState, unpackVariableState

export getSolvedCount,
    isSolved, setSolvedCount!, isInitialized, isMarginalized, setMarginalized!

export listNeighborhood, listNeighbors
export findFactorsBetweenNaive
export copyGraph!, deepcopyGraph, deepcopyGraph!, buildSubgraph, mergeGraph!

# Entry Blob Data
##------------------------------------------------------------------------------

export hasBlobentry,
    getfirstBlobentry,
    addBlobentry!,
    addBlobentries!,
    mergeBlobentry!,
    deleteBlobentry!,
    listBlobentrySequence,
    mergeBlobentries!
export incrDataLabelSuffix

export getBlobentries
export getBlobentriesVariables
# convenience wrappers
# aliases
export packBlob, unpackBlob
export @format_str # exported from FileIO

##------------------------------------------------------------------------------
# Factors
##------------------------------------------------------------------------------
# Factor Data
export AbstractFactorObservation, AbstractPackedFactorObservation
export PriorObservation, RelativeObservation
export FactorSolverCache

# accessors
export getVariableOrder
export getFactorType, getFactorFunction

# Serialization type conversion
export convertPackedType, convertStructType

export pack, unpack, packDistribution, unpackDistribution

##------------------------------------------------------------------------------
## Other utility functions
##------------------------------------------------------------------------------

# Sort
export natural_lt, sortDFG

# Validation
export isValidLabel

## List
export ls, lsf, ls2
export lsWho
export isPrior, lsfPriors
export hasTags, hasTagsNeighbors

## Finding
export findClosestTimestamp, findVariableNearTimestamp

# Serialization
export packVariable, unpackVariable, packFactor, unpackFactor
export rebuildFactorCache!
export @defVariable

# File import and export
export saveDFG, loadDFG!, loadDFG
export toDot, toDotFile

# shortest path
export findShortestPathDijkstra
export isPathFactorsHomogeneous

# Comparisons
export compare,
    compareField,
    compareFields,
    compareAll,
    compareVariable,
    compareFactor,
    compareAllVariables,
    compareSimilarVariables,
    compareSimilarFactors,
    compareFactorGraphs

## Deprecated exports should be listed in Deprecated.jl if possible, otherwise here

## CustomPrinting.jl
export printFactor, printVariable, printNode

# Data Blobs
export InMemoryBlobstore
export FolderStore
export Blobentry
export updateBlob!, deleteBlob!, hasBlob, listBlobentries
export listBlobs
export Blobentry
# export copyStore
export getId, getHash, getTimestamp
# convenience wrappers
export getData, addData!, updateData!, deleteData!

export plotDFG

## TODO maybe move to DFG
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
## Files Includes
##==============================================================================

# Entities
include("errors.jl")

include("entities/AbstractDFG.jl")

# Data Blob extensions
include("DataBlobs/entities/BlobEntry.jl")
include("DataBlobs/entities/BlobStores.jl")

include("entities/DFGFactor.jl")

include("entities/DFGVariable.jl")

include("entities/Agent.jl")

include("services/AbstractDFG.jl")

#Blobs
include("DataBlobs/services/BlobEntry.jl")
include("DataBlobs/services/BlobStores.jl")
include("DataBlobs/services/BlobPacking.jl")
include("DataBlobs/services/HelpersDataWrapEntryBlob.jl")

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

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

# Custom show and printing for variable factor etc.
include("services/CustomPrinting.jl")

# To be moved as necessary.
include("Common.jl")

include("weakdeps_prototypes.jl")

#TODO start off as just an alias before deprecating
# Starting Variable-level nouns-adjective standardisation 
export SkeletonDFGVariable
const SkeletonDFGVariable = VariableSkeleton

export DFGVariableSummary
const DFGVariableSummary = VariableSummary

export DFGVariable
const DFGVariable = VariableCompute

export PackedVariable
const PackedVariable = VariableDFG
export Variable
const Variable = VariableDFG

# Starting Factor-level noun-adjective standardisation 
export SkeletonDFGFactor
const SkeletonDFGFactor = FactorSkeleton

export DFGFactorSummary
const DFGFactorSummary = FactorSummary

export DFGFactor
const DFGFactor = FactorCompute

export PackedFactor
const PackedFactor = FactorDFG
export Factor
const Factor = FactorDFG

end
