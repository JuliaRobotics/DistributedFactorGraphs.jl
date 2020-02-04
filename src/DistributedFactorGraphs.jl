module DistributedFactorGraphs

using Base
using DocStringExtensions
using Requires
using Dates
using Distributions
using Reexport
using JSON2
using LinearAlgebra
using SparseArrays

# Entities
include("entities/AbstractDFG.jl")

include("entities/DFGFactor.jl")
include("entities/DFGFactorSummary.jl")
include("entities/SkeletonDFGFactor.jl")

include("entities/DFGVariable.jl")
include("entities/DFGVariableSummary.jl")
include("entities/SkeletonDFGVariable.jl")

include("entities/AbstractDFGSummary.jl")

# Solver data
export InferenceType, PackedInferenceType, FunctorInferenceType, InferenceVariable, ConvolutionObject
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize

# Graph Types
export AbstractDFG
export AbstractParams, NoSolverParams
export DFGNode, DFGVariable, DFGFactor, AbstractDFGVariable, AbstractDFGFactor
export DFGNodeParams
export SkeletonDFGVariable, SkeletonDFGFactor
export label, getTimestamp, setTimestamp!, setTimestamp, tags, setTags!, data, softtype, solverData, getData, solverDataDict, setSolverData, setSolverData!, internalId, smallData, setSmallData!, bigData
export getSolvedCount, isSolved, setSolvedCount!
export DFGVariableSummary, DFGFactorSummary, AbstractDFGSummary
export getNeighborhood, getSubgraph, getSubgraphAroundNode

export getUserId, getRobotId, getSessionId

# Define variable levels
const VariableDataLevel0 = Union{DFGVariable, DFGVariableSummary, SkeletonDFGVariable}
const VariableDataLevel1 = Union{DFGVariable, DFGVariableSummary}
const VariableDataLevel2 = Union{DFGVariable}

# Define factor levels
const FactorDataLevel0 = Union{DFGFactor, DFGFactorSummary, SkeletonDFGFactor}
const FactorDataLevel1 = Union{DFGFactor, DFGFactorSummary}
const FactorDataLevel2 = Union{DFGFactor}

# Data levels
const DataLevel0 = Union{VariableDataLevel0, FactorDataLevel0}
const DataLevel1 = Union{VariableDataLevel1, FactorDataLevel1}
const DataLevel2 = Union{VariableDataLevel2, FactorDataLevel2}

# Accessors
# Level 0
export getLabel, getTimestamp, setTimestamp!, getTags, setTags!
# Level 1
export getMaxPPE, getMeanPPE, getSuggestedPPE, getVariablePPE, getVariablePPEs, getPPEs #, getEstimates
export listPPE, getPPE, addPPE!, updatePPE!, deletePPE!
export getSofttype
# Level 2
export getData, getSolverData, getSolverDataDict, setSolverData!, getInternalId
export listVariableSolverData, getVariableSolverData, addVariableSolverData!, updateVariableSolverData!, deleteVariableSolverData!

export getSmallData, setSmallData!, bigData
export addBigDataEntry!, getBigDataEntry, updateBigDataEntry!, deleteBigDataEntry!, getBigDataEntries, getBigDataKeys

# Find a home
export getVariableOrder

# Services/AbstractDFG Exports
export isInitialized, getFactorFunction, isVariable, isFactor
export isSolveInProgress, getSolvable, setSolvable!, getSolveInProgress
export mergeUpdateVariableSolverData!, mergeUpdateGraphSolverData!

# Solver (IIF) Exports
export VariableNodeData, PackedVariableNodeData
export GenericFunctionNodeData
export getSerializationModule, setSerializationModule!
export pack, unpack
# Resolve with above
export packVariable, unpackVariable, packFactor, unpackFactor

# PPE exports
export AbstractPointParametricEst
export MeanMaxPPE

# AbstractDFG Interface
#--------
export setSerializationModule!, getSerializationModule
export getDescription, setDescription!, getAddHistory, getSolverParams, setSolverParams!
export getUserData, setUserData!, getRobotData, setRobotData!, getSessionData, setSessionData!

# Not sure these are going to work everywhere, TODO implement in cloud?
export updateUserData!, updateRobotData!, updateSessionData!, deleteUserData!, deleteRobotData!, deleteSessionData!
export emptyUserData!, emptyRobotData!, emptySessionData!


export exists, addVariable!, addFactor!, getVariable, getFactor, updateVariable!, updateFactor!, deleteVariable!, deleteFactor!
export getVariables, getVariableIds, getFactors, getFactorIds, ls, lsf
export isFullyConnected, hasOrphans
export getNeighbors, _getDuplicatedEmptyDFG, getSubgraphAroundNode, getSubgraph
export getBiadjacencyMatrix

export toDot, toDotFile
#--------

# File import and export
export saveDFG, loadDFG

# Summary functions
export getSummary, getSummaryGraph

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

# Common includes
include("services/AbstractDFG.jl")
include("services/DFGVariable.jl")
include("services/DFGFactor.jl")
include("CommonAccessors.jl")
include("Deprecated.jl")
include("services/CompareUtils.jl")

# Include the Graphs.jl API.
include("GraphsDFG/GraphsDFG.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

# In the attic until it's needed again.
# include("SymbolDFG/SymbolDFG.jl")
# using .SymbolDFGs

include("LightDFG/LightDFG.jl")
@reexport using .LightDFGs

include("CloudGraphsDFG/CloudGraphsDFG.jl")

#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG, LightDFG}
export InMemoryDFGTypes

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
