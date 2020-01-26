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
include("entities/DFGVariable.jl")
include("entities/AbstractDFGSummary.jl")

export AbstractDFG
export AbstractParams, NoSolverParams
export DFGNode, DFGVariable, DFGFactor, AbstractDFGVariable, AbstractDFGFactor
export InferenceType, PackedInferenceType, FunctorInferenceType, InferenceVariable, ConvolutionObject
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize
export getMaxPPE, getMeanPPE, getSuggestedPPE, getVariablePPE, getPPE, getVariablePPEs, getPPEs #, getEstimates
export timestamp # DEPRECATED
export getSolved, isSolved, setSolved!
export label, getTimestamp, setTimestamp!, tags, setTags!, estimates, estimate, data, softtype, solverData, getData, solverDataDict, setSolverData, setSolverData!, internalId, smallData, setSmallData!, bigData
export DFGVariableSummary, DFGFactorSummary, AbstractDFGSummary
export addBigDataEntry!, getBigDataEntry, updateBigDataEntry!, deleteBigDataEntry!, getBigDataEntries, getBigDataKeys
export getNeighborhood, getSubgraph, getSubgraphAroundNode

#Skeleton types
export SkeletonDFGVariable, SkeletonDFGFactor

#graph small data
export getUserData, setUserData, getRobotData, setRobotData, getSessionData, setSessionData
export pushUserData!, pushRobotData!, pushSessionData!, popUserData!, popRobotData!, popSessionData!

# Services/AbstractDFG Exports
export isInitialized, getFactorFunction, isVariable, isFactor
export isSolvable, isSolveInProgress, getSolvable, setSolvable!
export mergeUpdateVariableSolverData!, mergeUpdateGraphSolverData!

# Solver (IIF) Exports
export VariableNodeData, PackedVariableNodeData
export GenericFunctionNodeData#, FunctionNodeData
export getSerializationModule, setSerializationModule!
export pack, unpack
# Resolve with above
export packVariable, unpackVariable, packFactor, unpackFactor

#PPE exports
export AbstractPointParametricEst
export MeanMaxPPE

#Interfaces
export getAdjacencyMatrixSparse

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

include("SymbolDFG/SymbolDFG.jl")
using .SymbolDFGs

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
