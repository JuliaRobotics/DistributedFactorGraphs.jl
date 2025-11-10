"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on Graphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct GraphsDFG{
    T <: AbstractDFGParams,
    V <: AbstractGraphVariable,
    F <: AbstractGraphFactor,
} <: AbstractDFG{V, F}
    g::FactorGraph{Int, V, F}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, AbstractBlobstore}
    graph::GraphRoot
    agent::Agent
end

DFG.getAgent(dfg::GraphsDFG) = dfg.agent
DFG.getGraphLabel(dfg::GraphsDFG) = dfg.graph.label
DFG.getDescription(dfg::GraphsDFG) = dfg.graph.description

"""
    $(SIGNATURES)

Create an in-memory GraphsDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function GraphsDFG{T, V, F}(
    g::FactorGraph{Int, V, F} = FactorGraph{Int, V, F}();
    addHistory::Vector{Symbol} = Symbol[],
    solverParams::T = T(),
    blobStores = Dict{Symbol, AbstractBlobstore}(),
    # graph
    graphLabel::Symbol = Symbol("graph_", string(uuid4())[1:6]),
    graphDescription::String = "",
    graphTags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    graphBloblets::Bloblets = Bloblets(),
    graphBlobEntries = Blobentries(),
    graph::GraphRoot = GraphRoot(
        graphLabel,
        graphDescription,
        graphTags,
        graphBloblets,
        graphBlobEntries,
    ),
    # agent
    agentLabel::Symbol = :DefaultAgent,
    agentDescription::String = "",
    agentTags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    agentBloblets::Bloblets = Bloblets(),
    agentBlobEntries = Blobentries(),
    agent::Agent = Agent(
        agentLabel,
        agentDescription,
        agentTags,
        agentBloblets,
        agentBlobEntries,
    ),
    #TODO deprecated v0.29
    graphMetadata = nothing,
    agentMetadata = nothing,
) where {T <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    if !isnothing(graphMetadata)
        @warn "The `graphMetadata` keyword argument is obsolete, use graphBloblets."
    end
    if !isnothing(agentMetadata)
        @warn "The `agentMetadata` keyword argument is obsolete, use agentBloblets."
    end

    # Validate the graphLabel and agentLabel
    !DFG.isValidLabel(graphLabel) &&
        throw(ArgumentError("'$graphLabel' is not a valid label"))
    !DFG.isValidLabel(agentLabel) &&
        throw(ArgumentError("'$agentLabel' is not a valid label"))

    return GraphsDFG{T, V, F}(g, addHistory, solverParams, blobStores, graph, agent)
end

# GraphsDFG{T}(; kwargs...) where T <: AbstractDFGParams = GraphsDFG{T,VariableCompute,FactorDFG}(;kwargs...)
function GraphsDFG{T}(
    g::FactorGraph{Int, VariableCompute, FactorDFG} = FactorGraph{
        Int,
        VariableCompute,
        FactorDFG,
    }();
    kwargs...,
) where {T <: AbstractDFGParams}
    return GraphsDFG{T, VariableCompute, FactorDFG}(g; kwargs...)
end

function GraphsDFG(
    g::FactorGraph{Int, VariableCompute, FactorDFG} = FactorGraph{
        Int,
        VariableCompute,
        FactorDFG,
    }();
    solverParams::T = NoSolverParams(),
    kwargs...,
) where {T}
    return GraphsDFG{T, VariableCompute, FactorDFG}(g; solverParams, kwargs...)
end
