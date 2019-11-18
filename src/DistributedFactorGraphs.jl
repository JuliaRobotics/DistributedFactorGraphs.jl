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
export label, timestamp, tags, estimates, estimate, data, softtype, solverData, getData, solverDataDict, setSolverData, internalId, smallData, bigData
export DFGVariableSummary, DFGFactorSummary, AbstractDFGSummary

#Skeleton types
export SkeletonDFGVariable, SkeletonDFGFactor

#graph small data
export getUserData, setUserData, getRobotData, setRobotData, getSessionData, setSessionData
export pushUserData!, pushRobotData!, pushSessionData!, popUserData!, popRobotData!, popSessionData!

# Services/AbstractDFG Exports
export hasFactor, hasVariable, isInitialized, getFactorFunction, isVariable, isFactor
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
include("services/CompareUtils.jl")

include("BigData.jl")

# Include the Graphs.jl API.
include("GraphsDFG/GraphsDFG.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

# Include the LightGraphs.jl (MetaGraphs.jl) API.
include("MetaGraphsDFG/MetaGraphsDFG.jl")

include("SymbolDFG/SymbolDFG.jl")
using .SymbolDFGs

include("LightDFG/LightDFG.jl")
@reexport using .LightDFGs

include("CloudGraphsDFG/CloudGraphsDFG.jl")

#supported in Memory fg types
const InMemoryDFGTypes = Union{GraphsDFG, LightDFG}
export InMemoryDFGTypes

function __init__()
    @require GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231" begin
        @info "Including Plots"
        include("DFGPlots/DFGPlots.jl")
        @reexport using .DFGPlots
    end

end

# To be moved as necessary.
include("Common.jl")

end
