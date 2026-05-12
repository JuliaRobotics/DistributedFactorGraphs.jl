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
    solverParams::T # Solver parameters #TODO resolve #1205 first
    blobproviders::OrderedDict{Symbol, AbstractBlobprovider} #TODO note v0.29 changed from blobstores
    graph::Graphroot
    agents::OrderedDict{Symbol, Agent} #TODO note v0.29 added multiple agents, agent -> agents
end

DFG.refAgents(dfg::GraphsDFG) = dfg.agents
DFG.getGraphLabel(dfg::GraphsDFG) = dfg.graph.label
DFG.getDescription(dfg::GraphsDFG) = dfg.graph.description

function GraphsDFG{T, V, F}(
    g::FactorGraph{Int, V, F} = FactorGraph{Int, V, F}();
    # addHistory::Vector{Symbol} = Symbol[],
    solverParams::T = T(),
    blobproviders = OrderedDict{Symbol, AbstractBlobprovider}(),
    # graph
    graphLabel::Symbol = :workspace,
    graphDescription::String = "",
    graphTags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    graphBloblets::Bloblets = Bloblets(),
    graphBlobentries = Blobentries(),
    graph::Graphroot = Graphroot(;
        label = graphLabel,
        description = graphDescription,
        tags = graphTags,
        bloblets = graphBloblets,
        blobentries = graphBlobentries,
    ),
    agents::OrderedDict{Symbol, Agent} = OrderedDict{Symbol, Agent}(),
    #TODO deprecated v0.29
    graphMetadata = nothing,
    agentMetadata = nothing,
    kwargs...,
) where {T <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    !isnothing(graphMetadata) && Base.depwarn(
        "The `graphMetadata` keyword argument is obsolete, use graphBloblets.",
        :GraphsDFG,
    )
    !isnothing(agentMetadata) && Base.depwarn(
        "The `agentMetadata` keyword argument is obsolete, use agentBloblets.",
        :GraphsDFG,
    )

    !isempty(kwargs) && Base.depwarn(
        "`agent...` keyword arguments are deprecated, use the `agents` kwargs or addAgent!",
        :GraphsDFG,
    )

    #TODO move to Graphroot constructor.
    !DFG.isValidLabel(graphLabel) &&
        throw(ArgumentError("'$graphLabel' is not a valid label"))

    return GraphsDFG{T, V, F}(g, solverParams, blobproviders, graph, agents)
end

# GraphsDFG{T}(; kwargs...) where T <: AbstractDFGParams = GraphsDFG{T,VariableDFG,FactorDFG}(;kwargs...)
function GraphsDFG{T}(
    g::FactorGraph{Int, VariableDFG, FactorDFG} = FactorGraph{Int, VariableDFG, FactorDFG}();
    kwargs...,
) where {T <: AbstractDFGParams}
    return GraphsDFG{T, VariableDFG, FactorDFG}(g; kwargs...)
end

function GraphsDFG(
    g::FactorGraph{Int, VariableDFG, FactorDFG} = FactorGraph{Int, VariableDFG, FactorDFG}();
    solverParams::T = NoSolverParams(),
    kwargs...,
) where {T}
    return GraphsDFG{T, VariableDFG, FactorDFG}(g; solverParams, kwargs...)
end

function GraphsDFG(
    fg::GraphsDFG;
    g = fg.g,
    solverParams = fg.solverParams,
    blobproviders = fg.blobproviders,
    graph = fg.graph,
    agents = fg.agents,
)
    return GraphsDFG(g, solverParams, blobproviders, graph, agents)
end
