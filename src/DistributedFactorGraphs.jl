module DistributedFactorGraphs

using Base
using DocStringExtensions
using Requires
using Dates
using Distributions
using Reexport
using JSON2
using LinearAlgebra

# Entities
include("entities/AbstractTypes.jl")
include("entities/DFGFactor.jl")
include("entities/DFGVariable.jl")

export AbstractDFG
export AbstractParams, NoSolverParams
export DFGNode

export DFGFactor
export InferenceType, PackedInferenceType, FunctorInferenceType, InferenceVariable, ConvolutionObject

export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize

export DFGVariable
export label, timestamp, tags, estimates, estimate, solverData, solverDataDict, id, smallData, bigData
export setSolverData
export label, data, id

# Solver (IIF) Exports
export VariableNodeData, PackedVariableNodeData, VariableEstimate
export GenericFunctionNodeData#, FunctionNodeData
export getSerializationModule, setSerializationModule!
export pack, unpack

# Common includes
include("services/AbstractDFG.jl")
include("services/DFGVariable.jl")

# Include the Graphs.jl API.
include("GraphsDFG/GraphsDFG.jl")

# Include the FilesDFG API.
include("FileDFG/FileDFG.jl")

export saveDFG, loadDFG

function __init__()
    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        if isdefined(Main, :DataFrames)
            """
                $(SIGNATURES)
            Get an adjacency matrix for the DFG as a DataFrame.
            Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
            The first column is the factor headings.
            """
            function getAdjacencyMatrixDataFrame(dfg::GraphsDFG)::Main.DataFrames.DataFrame
                varLabels = sort(map(v->v.label, getVariables(dfg)))
                factLabels = sort(map(f->f.label, getFactors(dfg)))
                adjDf = DataFrames.DataFrame(:Factor => Union{Missing, Symbol}[])
                for varLabel in varLabels
                    adjDf[varLabel] = Union{Missing, Symbol}[]
                end
                for (i, factLabel) in enumerate(factLabels)
                    push!(adjDf, [factLabel, DataFrames.missings(length(varLabels))...])
                    factVars = getNeighbors(dfg, getFactor(dfg, factLabel))
                    map(vLabel -> adjDf[vLabel][i] = factLabel, factVars)
                end
                return adjDf
            end
        end
    end

  @require Neo4j="d2adbeaf-5838-5367-8a2f-e46d570981db" begin
    # Include the Cloudgraphs API
    include("CloudGraphsDFG/CloudGraphsDFG.jl")
  end
end

# not sure where to put
include("Common.jl")
include("NeedsAHome.jl")

end
