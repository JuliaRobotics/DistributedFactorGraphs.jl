"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on Graphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct GraphsDFG{
    T <: AbstractParams,
    V <: AbstractDFGVariable,
    F <: AbstractDFGFactor,
} <: AbstractDFG{T}
    g::FactorGraph{Int, V, F}
    description::String
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, AbstractBlobstore}
    # new structure to replace URS
    graphLabel::Symbol # graph (session) label
    graphTags::Vector{Symbol}
    graphMetadata::Dict{Symbol, SmallDataTypes} # graph (session) metadata
    graphBlobEntries::OrderedDict{Symbol, Blobentry} #graph (session) blob entries
    agent::Agent # (robot)
end

DFG.getAgent(dfg::GraphsDFG) = dfg.agent

DFG.getGraphLabel(dfg::GraphsDFG) = dfg.graphLabel
DFG.getMetadata(dfg::GraphsDFG) = dfg.graphMetadata
function DFG.setMetadata!(dfg::GraphsDFG, metadata::Dict{Symbol, SmallDataTypes})
    # with set old data should be removed, but care is taken to make sure its not the same object
    dfg.graphMetadata !== metadata && empty!(dfg.graphMetadata)
    return merge!(dfg.graphMetadata, metadata)
end

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
    # factor graph TODO maybe move to FactorGraph or make a new Graph struct to hold these (similar to Agent) 
    graphLabel::Symbol = Symbol("factorgraph_", string(uuid4())[1:6]),
    graphTags::Vector{Symbol} = Symbol[],
    graphMetadata = Dict{Symbol, SmallDataTypes}(),
    graphBlobEntries = OrderedDict{Symbol, Blobentry}(),
    description::String = "",
    graphDescription::String = description,
    # agent
    agentLabel::Symbol = :DefaultAgent,
    agentDescription::String = "",
    agentTags::Vector{Symbol} = Symbol[],
    agentMetadata = Dict{Symbol, SmallDataTypes}(),
    agentBlobEntries = OrderedDict{Symbol, Blobentry}(),
    agent::Agent = Agent(
        agentLabel,
        agentDescription,
        agentTags,
        agentMetadata,
        agentBlobEntries,
    ),
) where {T <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}

    # Validate the graphLabel and agentLabel
    !isValidLabel(graphLabel) && error("'$graphLabel' is not a valid label")
    !isValidLabel(agentLabel) && error("'$agentLabel' is not a valid label")

    return GraphsDFG{T, V, F}(
        g,
        graphDescription,
        addHistory,
        solverParams,
        blobStores,
        # new fields
        graphLabel,
        graphTags,
        graphMetadata,
        graphBlobEntries,
        agent,
    )
end

# GraphsDFG{T}(; kwargs...) where T <: AbstractParams = GraphsDFG{T,VariableCompute,FactorCompute}(;kwargs...)
function GraphsDFG{T}(
    g::FactorGraph{Int, VariableCompute, FactorCompute} = FactorGraph{
        Int,
        VariableCompute,
        FactorCompute,
    }();
    kwargs...,
) where {T <: AbstractParams}
    return GraphsDFG{T, VariableCompute, FactorCompute}(g; kwargs...)
end

function GraphsDFG(
    g::FactorGraph{Int, VariableCompute, FactorCompute} = FactorGraph{
        Int,
        VariableCompute,
        FactorCompute,
    }();
    solverParams::T = NoSolverParams(),
    kwargs...,
) where {T}
    return GraphsDFG{T, VariableCompute, FactorCompute}(g; solverParams, kwargs...)
end
