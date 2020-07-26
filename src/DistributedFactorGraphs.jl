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
using DocStringExtensions
using Requires
using Dates
using TimeZones
using Distributions
using Reexport
using JSON
using Unmarshal
using JSON2 # JSON2 requires all properties to be in correct sequence, can't guarantee that from DB.
using LinearAlgebra
using SparseArrays
using UUIDs


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

# accessors & crud
export getUserId, getRobotId, getSessionId
export getDFGInfo
export getDescription, setDescription!,
       getSolverParams, setSolverParams!,
       getUserData, setUserData!,
       getRobotData, setRobotData!,
       getSessionData, setSessionData!,
       getAddHistory

# TODO Not sure these are needed or should work everywhere, implement in cloud?
export updateUserData!, updateRobotData!, updateSessionData!, deleteUserData!, deleteRobotData!, deleteSessionData!
export emptyUserData!, emptyRobotData!, emptySessionData!

# Graph Types: exported from modules or @reexport
export InMemoryDFGTypes, DefaultDFG

# AbstractDFG Interface
export exists,
       addVariable!, addFactor!,
       getVariable, getFactor,
       updateVariable!, updateFactor!,
       deleteVariable!, deleteFactor!,
       listVariables, listFactors,
       listSolveKeys, listSupersolves,
       getVariables, getFactors,
       isVariable, isFactor

export isConnected

export getBiadjacencyMatrix

#summary structure
export DFGSummary

export getSummary, getSummaryGraph

# Abstract Nodes
export DFGNode, AbstractDFGVariable, AbstractDFGFactor

# Variables
export DFGVariable, DFGVariableSummary, SkeletonDFGVariable

# Factors
export DFGFactor, DFGFactorSummary, SkeletonDFGFactor

# Common
export getSolvable, setSolvable!, isSolvable
export getInternalId
export getVariableLabelNumber

# accessors
export getLabel, getTimestamp, setTimestamp, setTimestamp!, getTags, setTags!

# Node Data
export isSolveInProgress, getSolveInProgress

# CRUD & SET
export listTags, mergeTags!, removeTags!, emptyTags!

#this isn't acttually implemented. TODO remove or implement
export addTags!

##------------------------------------------------------------------------------
# Variable
##------------------------------------------------------------------------------
# Abstract Variable Data
export InferenceVariable

# accessors
export getSolverDataDict, setSolverData!
export getSofttype, getSofttypename

export getSolverData

export getVariableType

export getSmallData, setSmallData!


# CRUD & SET
export getVariableSolverData,
       addVariableSolverData!,
       updateVariableSolverData!,
       deleteVariableSolverData!,
       listVariableSolverData,
       mergeVariableSolverData!,
       deepcopySolvekeys!,
       deepcopySupersolve!


# PPE
##------------------------------------------------------------------------------
# PPE TYPES
export AbstractPointParametricEst
export MeanMaxPPE
export getMaxPPE, getMeanPPE, getSuggestedPPE, getLastUpdatedTimestamp

# accessors

export getPPEDict, getVariablePPEDict, getVariablePPE

# CRUD & SET
export getPPE,
       getVariablePPE,
       addPPE!,
       updatePPE!,
       deletePPE!,
       listPPEs,
       mergePPEs! #TODO look at rename to just mergePPE to match with cloud?


# Variable Node Data
##------------------------------------------------------------------------------
export VariableNodeData, PackedVariableNodeData

export packVariableNodeData, unpackVariableNodeData

export getSolvedCount, isSolved, setSolvedCount!, isInitialized

export getNeighborhood, getNeighbors, _getDuplicatedEmptyDFG
export findFactorsBetweenNaive
export copyGraph!, deepcopyGraph, deepcopyGraph!, buildSubgraph, mergeGraph!
# Big Data
##------------------------------------------------------------------------------
export addDataEntry!, getDataEntry, updateDataEntry!, deleteDataEntry!, getDataEntries, listDataEntries, hasDataEntry, hasDataEntry
# convenience wrappers
export addDataEntry!, getDataEntryBlob
# aliases
export addData!, fetchData, fetchDataEntryBlob


##------------------------------------------------------------------------------
# Factors
##------------------------------------------------------------------------------
# Factor Data
export GenericFunctionNodeData, PackedFunctionNodeData, FunctionNodeData
export FunctorInferenceType, PackedInferenceType
export AbstractPrior, AbstractRelativeFactor, AbstractRelativeFactorMinimize
export FactorOperationalMemory

# accessors
export getVariableOrder
export getFactorType, getFactorFunction

# Node Data
export mergeVariableData!, mergeGraphVariableData!

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
export lsWho, lsfWho
export isPrior, lsfPriors
export hasTags, hasTagsNeighbors

## Finding
export findClosestTimestamp, findVariableNearTimestamp

# Serialization
export packVariable, unpackVariable, packFactor, unpackFactor
export rebuildFactorMetadata!

# File import and export
export saveDFG, loadDFG!
export toDot, toDotFile

# Comparisons
export
    compare,
    compareField,
    compareFields,
    compareAll,
    compareAllSpecial,
    compareVariable,
    compareFactor,
    compareAllVariables,
    compareSimilarVariables,
    compareSubsetFactorGraph,
    compareSimilarFactors,
    compareFactorGraphs


## Deprecated exports should be listed in Deprecated.jl if possible, otherwise here

## CustomPrinting.jl
export printFactor, printVariable, printNode

##==============================================================================
## Files Includes
##==============================================================================

# Entities

include("entities/AbstractDFG.jl")

include("entities/DFGFactor.jl")

include("entities/DFGVariable.jl")

include("entities/AbstractDFGSummary.jl")

include("services/AbstractDFG.jl")

# In Memory Types
# include("../attic/GraphsDFG/GraphsDFG.jl")
# @reexport using .GraphsDFGs
include("LightDFG/LightDFG.jl")
@reexport using .LightDFGs
#supported in Memory fg types
# const InMemoryDFGTypes = Union{GraphsDFG, LightDFG}
const InMemoryDFGTypes = LightDFG
const DefaultDFG = LightDFG

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

# Data Blob extensions
include("DataBlobs/DataBlobs.jl")

function __init__()
    @require GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231" begin
        @info "Including Plots"
        include("DFGPlots/DFGPlots.jl")
        @reexport using .DFGPlots
    end

    # if get(ENV, "DFG_USE_CGDFG", "") == "true"
        @info "Detected ENV[\"DFG_USE_CGDFG\"]: Including optional CloudGraphsDFG (LGPL) Driver"
        Base.include(DistributedFactorGraphs, joinpath(@__DIR__, "CloudGraphsDFG/CloudGraphsDFG.jl"))
        @eval DistributedFactorGraphs @reexport using .CloudGraphsDFGs
    # end
end


end
