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
using TimeZones
using Distributions
using Reexport
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
import Tar
import CodecZlib

using OrderedCollections
export OrderedDict

using CSV
using Tables

# used for @defVariable
import ManifoldsBase
import ManifoldsBase: AbstractManifold, manifold_dimension
export AbstractManifold, manifold_dimension

import RecursiveArrayTools: ArrayPartition
export ArrayPartition
using StaticArrays

import Base: getindex

##==============================================================================
# Exports
##==============================================================================
const DFG = DistributedFactorGraphs
export DFG
##------------------------------------------------------------------------------
## DFG
##------------------------------------------------------------------------------
export AbstractDFG
export AbstractParams, NoSolverParams
export AbstractBlobStore

# accessors & crud
export getUserLabel, getRobotLabel, getSessionLabel
export getDFGInfo
export getDescription,
    setDescription!,
    getSolverParams,
    setSolverParams!,
    getUserData,
    setUserData!,
    getRobotData,
    setRobotData!,
    getSessionData,
    setSessionData!,
    getAddHistory

export getGraphBlobEntry,
    getGraphBlobEntries,
    addGraphBlobEntry!,
    addGraphBlobEntries!,
    updateGraphBlobEntry!,
    deleteGraphBlobEntry!,
    getAgentBlobEntry,
    getAgentBlobEntries,
    addAgentBlobEntry!,
    addAgentBlobEntries!,
    updateAgentBlobEntry!,
    deleteAgentBlobEntry!,
    listGraphBlobEntries,
    listAgentBlobEntries

export getBlobStore,
    addBlobStore!, updateBlobStore!, deleteBlobStore!, emptyBlobStore!, listBlobStores

# TODO Not sure these are needed or should work everywhere, implement in cloud?
export updateUserData!,
    updateRobotData!,
    updateSessionData!,
    deleteUserData!,
    deleteRobotData!,
    deleteSessionData!
export emptyUserData!, emptyRobotData!, emptySessionData!

# Graph Types: exported from modules or @reexport
export InMemoryDFGTypes, LocalDFG

# AbstractDFG Interface
export exists,
    addVariable!,
    addFactor!,
    getVariable,
    getFactor,
    updateVariable!,
    updateFactor!,
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

#summary structure
export DFGSummary

export getSummary, getSummaryGraph

# Abstract Nodes
export DFGNode, AbstractDFGVariable, AbstractDFGFactor

# Variables
export DFGVariable, DFGVariableSummary, SkeletonDFGVariable, PackedVariable

# Factors
export DFGFactor, DFGFactorSummary, SkeletonDFGFactor, PackedFactor

# Common
export getSolvable, setSolvable!, isSolvable
export getVariableLabelNumber

# accessors
export getLabel, getTimestamp, setTimestamp, setTimestamp!, getTags, setTags!

# Node Data
export isSolveInProgress, getSolveInProgress

# CRUD & SET
export listTags, mergeTags!, removeTags!, emptyTags!

##------------------------------------------------------------------------------
# Variable
##------------------------------------------------------------------------------
# Abstract Variable Data
export InferenceVariable

# accessors
export getSolverDataDict, setSolverData!
export getVariableType, getVariableTypeName

export getSolverData

export getVariableType

# VariableType functions
export getDimension, getManifold, getPointType
export getPointIdentity, getPoint, getCoordinates

# Small Data CRUD
export SmallDataTypes,
    getSmallData,
    addSmallData!,
    updateSmallData!,
    deleteSmallData!,
    listSmallData,
    emptySmallData!
export getSmallData, setSmallData!

# CRUD & SET
export getVariableSolverData,
    addVariableSolverData!,
    updateVariableSolverData!,
    deleteVariableSolverData!,
    listVariableSolverData,
    mergeVariableSolverData!,
    cloneSolveKey!

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
export VariableNodeData, PackedVariableNodeData

export packVariableNodeData, unpackVariableNodeData

export getSolvedCount,
    isSolved, setSolvedCount!, isInitialized, isMarginalized, setMarginalized!

export getNeighborhood, listNeighbors, _getDuplicatedEmptyDFG
export findFactorsBetweenNaive
export copyGraph!, deepcopyGraph, deepcopyGraph!, buildSubgraph, mergeGraph!

# Entry Blob Data
##------------------------------------------------------------------------------

export hasBlobEntry,
    getBlobEntry,
    getBlobEntryFirst,
    addBlobEntry!,
    updateBlobEntry!,
    deleteBlobEntry!,
    listBlobEntrySequence,
    mergeBlobEntries!
export incrDataLabelSuffix

export getBlobEntries
export getBlobEntriesVariables
# convenience wrappers
# aliases
export addBlob!
export packBlob, unpackBlob

##------------------------------------------------------------------------------
# Factors
##------------------------------------------------------------------------------
# Factor Data
export GenericFunctionNodeData, PackedFunctionNodeData, FunctionNodeData
export AbstractFactor, AbstractPackedFactor
export AbstractPrior, AbstractRelative, AbstractRelativeMinimize, AbstractManifoldMinimize
export FactorOperationalMemory

# accessors
export getVariableOrder
export getFactorType, getFactorFunction

# Node Data
export mergeVariableData!, mergeGraphVariableData!

# Serialization type conversion
export convertPackedType, convertStructType

export reconstFactorData

##------------------------------------------------------------------------------
## Other utility functions
##------------------------------------------------------------------------------

# Sort
export natural_lt, sortDFG

# Validation
export isValidLabel

## List
export ls, lsf, ls2
export lsTypes, lsfTypes, lsTypesDict, lsfTypesDict
export lsWho
export isPrior, lsfPriors
export hasTags, hasTagsNeighbors

## Finding
export findClosestTimestamp, findVariableNearTimestamp

# Serialization
export packVariable, unpackVariable, packFactor, unpackFactor
export rebuildFactorMetadata!
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
    compareAllSpecial,
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
export InMemoryBlobStore
export FolderStore
export BlobEntry
export getBlob, addBlob!, updateBlob!, deleteBlob!, hasBlob, listBlobEntries
export listBlobs
export BlobEntry
# export copyStore
export getId, getHash, getTimestamp
# convenience wrappers
export getData, addData!, updateData!, deleteData!

export plotDFG

##==============================================================================
## Files Includes
##==============================================================================

# Entities

include("entities/AbstractDFG.jl")

# Data Blob extensions
include("DataBlobs/entities/BlobEntry.jl")
include("DataBlobs/entities/BlobStores.jl")

include("entities/DFGFactor.jl")

include("entities/DFGVariable.jl")

include("entities/AbstractDFGSummary.jl")

include("entities/Agent.jl")

include("services/AbstractDFG.jl")

#Blobs
include("DataBlobs/services/BlobEntry.jl")
include("DataBlobs/services/BlobStores.jl")
include("DataBlobs/services/BlobPacking.jl")
include("DataBlobs/services/HelpersDataWrapEntryBlob.jl")

# In Memory Types
include("GraphsDFG/GraphsDFG.jl")
@reexport using .GraphsDFGs

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

function plotDFG end

end
