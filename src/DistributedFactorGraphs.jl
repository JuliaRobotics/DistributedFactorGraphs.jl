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
using Distributions
using Reexport
using JSON2
using LinearAlgebra
using SparseArrays


##==============================================================================
# Exports
##==============================================================================

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
export InMemoryDFGTypes
# LightDFG
# GraphsDFG

# CloudGraphsDFG
# FileDFG

# AbstractDFG Interface
export exists,
       addVariable!, addFactor!,
       getVariable, getFactor,
       updateVariable!, updateFactor!,
       deleteVariable!, deleteFactor!,
       listVariables, listFactors,
       getVariables, getFactors,
       isVariable, isFactor

export isFullyConnected, hasOrphans

export getBiadjacencyMatrix

#summary structure #TODO Abstract name here is confusing
export AbstractDFGSummary

export getSummary, getSummaryGraph

# Abstract Nodes
export DFGNode, AbstractDFGVariable, AbstractDFGFactor

# Variables
export DFGVariable, DFGVariableSummary, SkeletonDFGVariable

# Factors
export DFGFactor, DFGFactorSummary, SkeletonDFGFactor

# Common
export DFGNodeParams
export getSolvable, setSolvable!, isSolvable
export getInternalId

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
export getSofttype

export getSolverData

export getVariableType

export getSmallData, setSmallData!


# CRUD & SET
export getVariableSolverData,
       addVariableSolverData!,
       updateVariableSolverData!,
       deleteVariableSolverData!,
       listVariableSolverData,
       mergeVariableSolverData!


# PPE
##------------------------------------------------------------------------------
# PPE TYPES
export AbstractPointParametricEst
export MeanMaxPPE
export getMaxPPE, getMeanPPE, getSuggestedPPE, getLastUpdatedTimestamp

# accessors

export getPPEDict

# CRUD & SET
export getPPE,
       addPPE!,
       updatePPE!,
       deletePPE!,
       listPPE,
       mergePPEs! #TODO look at rename to just mergePPE to match with cloud?


# Variable Node Data
##------------------------------------------------------------------------------
export VariableNodeData, PackedVariableNodeData

export packVariableNodeData, unpackVariableNodeData

export getSolvedCount, isSolved, setSolvedCount!, isInitialized

export getNeighborhood, getSubgraph, getSubgraphAroundNode, getNeighbors, _getDuplicatedEmptyDFG

# Big Data
##------------------------------------------------------------------------------
export addBigDataEntry!, getBigDataEntry, updateBigDataEntry!, deleteBigDataEntry!, getBigDataEntries, getBigDataKeys


##------------------------------------------------------------------------------
# Factors
##------------------------------------------------------------------------------
# Factor Data
export GenericFunctionNodeData
export InferenceType, PackedInferenceType, FunctorInferenceType, ConvolutionObject
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize

# accessors
export getVariableOrder
export getFactorType, getFactorFunction

# Node Data
export mergeVariableData!, mergeGraphVariableData!

##------------------------------------------------------------------------------
## Other utility funtions
##------------------------------------------------------------------------------

# Sort
export natural_lt, sortDFG

## List
export ls, lsf
export lsTypes, lsfTypes
export lsWho, lsfWho
export isPrior, lsfPriors
export hasTags, hasTagsNeighbors

## Finding
export findClosestTimestamp, findVariableNearTimestamp

# Serialization
export setSerializationModule!, getSerializationModule
export packVariable, unpackVariable, packFactor, unpackFactor

# File import and export
export saveDFG, loadDFG
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


## Deprecated.jl should be listed there


## needsahome.jl

export buildSubgraphFromLabels!
export printFactor, printVariable

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
include("GraphsDFG/GraphsDFG.jl")
include("LightDFG/LightDFG.jl")
@reexport using .LightDFGs
#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG, LightDFG}

# Common includes
include("services/CommonAccessors.jl")
include("services/Serialization.jl")
include("services/DFGVariable.jl")
include("services/DFGFactor.jl")
include("Deprecated.jl")
include("services/CompareUtils.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

include("CloudGraphsDFG/CloudGraphsDFG.jl")

# Needs a home.
include("needsahome.jl")

function __init__()
    @require GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231" begin
        @info "Including Plots"
        include("DFGPlots/DFGPlots.jl")
        @reexport using .DFGPlots
    end

end

# To be moved as necessary.
include("Common.jl")

# Big data extensions
include("BigData/BigData.jl")

end
