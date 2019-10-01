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
export DFGNode, DFGVariable, DFGFactor
export InferenceType, PackedInferenceType, FunctorInferenceType, InferenceVariable, ConvolutionObject
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize
export label, timestamp, tags, estimates, estimate, data, solverData, getData, solverDataDict, setSolverData, internalId, smallData, bigData
export DFGVariableSummary, DFGFactorSummary, AbstractDFGSummary

# Services/AbstractDFG Exports
export hasFactor, hasVariable, isInitialized, getFactorFunction, isVariable, isFactor
export updateGraphSolverData!

# Solver (IIF) Exports
export VariableNodeData, PackedVariableNodeData, VariableEstimate
export GenericFunctionNodeData#, FunctionNodeData
export getSerializationModule, setSerializationModule!
export pack, unpack

#Interfaces
export getAdjacencyMatrixSparse

# File import and export
export saveDFG, loadDFG

# Summary functions
export getSummary, getSummaryGraph

# Common includes
include("services/AbstractDFG.jl")
include("services/DFGVariable.jl")
include("services/DFGFactor.jl")

# Include the Graphs.jl API.
include("GraphsDFG/GraphsDFG.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

# Include the LightGraphs.jl (MetaGraphs.jl) API.
include("MetaGraphsDFG/MetaGraphsDFG.jl")

include("SymbolDFG/SymbolDFG.jl")
@reexport using .SymbolDFGs

include("LightDFG/LightDFG.jl")
@reexport using .LightDFGs

function __init__()
    @require Neo4j="d2adbeaf-5838-5367-8a2f-e46d570981db" begin
        # Include the Cloudgraphs API
        include("CloudGraphsDFG/CloudGraphsDFG.jl")
    end

    @require GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231" begin
        include("DFGPlots/DFGPlots.jl")
        @reexport using .DFGPlots
    end

end

# To be moved as necessary.
include("Common.jl")

end
