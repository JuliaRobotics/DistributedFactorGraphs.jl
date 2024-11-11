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
    # ------ deprecated fields ---------
    userLabel::Union{Nothing, String}
    robotLabel::Union{Nothing, String}
    sessionLabel::Union{Nothing, String}
    userData::Union{Nothing, Dict{Symbol, SmallDataTypes}}
    robotData::Union{Nothing, Dict{Symbol, SmallDataTypes}}
    sessionData::Union{Nothing, Dict{Symbol, SmallDataTypes}}
    userBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}}
    robotBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}}
    sessionBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}}
    # ---------------------------------
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, AbstractBlobStore}
    # new structure to replace URS
    graphLabel::Symbol # graph (session) label
    graphTags::Vector{Symbol}
    graphMetadata::Dict{Symbol, SmallDataTypes} # graph (session) metadata
    graphBlobEntries::OrderedDict{Symbol, BlobEntry} #graph (session) blob entries
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

deprecatedDfgFields = [
    :userLabel,
    :robotLabel,
    :sessionLabel,
    :userData,
    :robotData,
    :sessionData,
    :userBlobEntries,
    :robotBlobEntries,
    :sessionBlobEntries,
]

function Base.propertynames(x::GraphsDFG, private::Bool = false)
    return setdiff(fieldnames(GraphsDFG), deprecatedDfgFields)
end

# deprected in v0.25
function Base.getproperty(dfg::GraphsDFG, f::Symbol)
    if f in deprecatedDfgFields
        Base.depwarn(
            "Field $f is deprecated as part of removing user/robot/session. Replace with Agent or Factorgraph [Label/Metadata/BlobEntries].",
            :getproperty,
        )
    end
    return getfield(dfg, f)
end

function Base.setproperty!(dfg::GraphsDFG, f::Symbol, val)
    if f in deprecatedDfgFields
        Base.depwarn(
            "Field $f is deprecated as part of removing user/robot/session. Replace with Agent or Factorgraph [Label/Metadata/BlobEntries].",
            :setproperty!,
        )
    end
    return setfield!(dfg, f, val)
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
    blobStores = Dict{Symbol, AbstractBlobStore}(),
    # factor graph TODO maybe move to FactorGraph or make a new Graph struct to hold these (similar to Agent) 
    graphLabel::Symbol = Symbol("factorgraph_", string(uuid4())[1:6]),
    graphTags::Vector{Symbol} = Symbol[],
    graphMetadata = Dict{Symbol, SmallDataTypes}(),
    graphBlobEntries = OrderedDict{Symbol, BlobEntry}(),
    description::String = "",
    graphDescription::String = description,
    # agent
    agentLabel::Symbol = :DefaultAgent,
    agentDescription::String = "",
    agentTags::Vector{Symbol} = Symbol[],
    agentMetadata = Dict{Symbol, SmallDataTypes}(),
    agentBlobEntries = OrderedDict{Symbol, BlobEntry}(),
    agent::Agent = Agent(
        agentLabel,
        agentDescription,
        agentTags,
        agentMetadata,
        agentBlobEntries,
    ),

    #Deprecated fields
    userLabel::Union{Nothing, String} = nothing,
    robotLabel::Union{Nothing, String} = nothing,
    sessionLabel::Union{Nothing, String} = nothing,
    userData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing,
    robotData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing,
    sessionData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing,
    userBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing,
    robotBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing,
    sessionBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing,
) where {T <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    if any([
        !isnothing(userLabel),
        !isnothing(robotLabel),
        !isnothing(sessionLabel),
        !isnothing(userData),
        !isnothing(robotData),
        !isnothing(sessionData),
        !isnothing(userBlobEntries),
        !isnothing(robotBlobEntries),
        !isnothing(sessionBlobEntries),
    ])
        #deprecated in v0.25
        Base.depwarn(
            "Kwargs with user/robot/session is deprecated. Replace with agent[Label/Metadata/BlobEntries] or graph[Label/Metadata/BlobEntries].",
            :GraphsDFG,
        )
    end

    # Validate the userLabel, robotLabel, and sessionLabel
    !isValidLabel(graphLabel) && error("'$graphLabel' is not a valid label")
    !isValidLabel(agentLabel) && error("'$agentLabel' is not a valid label")

    return GraphsDFG{T, V, F}(
        g,
        graphDescription,
        userLabel,
        robotLabel,
        sessionLabel,
        userData,
        robotData,
        sessionData,
        userBlobEntries,
        robotBlobEntries,
        sessionBlobEntries,
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

# GraphsDFG{T}(; kwargs...) where T <: AbstractParams = GraphsDFG{T,DFGVariable,DFGFactor}(;kwargs...)
function GraphsDFG{T}(
    g::FactorGraph{Int, DFGVariable, DFGFactor} = FactorGraph{Int, DFGVariable, DFGFactor}();
    kwargs...,
) where {T <: AbstractParams}
    return GraphsDFG{T, DFGVariable, DFGFactor}(g; kwargs...)
end

function GraphsDFG(
    g::FactorGraph{Int, DFGVariable, DFGFactor} = FactorGraph{Int, DFGVariable, DFGFactor}();
    solverParams::T = NoSolverParams(),
    kwargs...,
) where {T}
    return GraphsDFG{T, DFGVariable, DFGFactor}(g; solverParams, kwargs...)
end

function GraphsDFG(
    description::String,
    userLabel::String,
    robotLabel::String,
    sessionLabel::String,
    userData::Dict{Symbol, SmallDataTypes},
    robotData::Dict{Symbol, SmallDataTypes},
    sessionData::Dict{Symbol, SmallDataTypes},
    solverParams::AbstractParams,
    blobStores = Dict{Symbol, AbstractBlobStore}(),
)
    #deprecated in v0.25
    Base.depwarn(
        "user/robot/session is deprecated. Replace with agent[Label/Metadata/BlobEntries] or graph[Label/Metadata/BlobEntries].",
        :GraphsDFG,
    )
    return GraphsDFG{typeof(solverParams), DFGVariable, DFGFactor}(
        FactorGraph{Int, DFGVariable, DFGFactor}();
        description,
        userLabel,
        robotLabel,
        sessionLabel,
        userData,
        robotData,
        sessionData,
        solverParams,
        blobStores,
    )
end

function GraphsDFG{T, V, F}(
    description::String,
    userLabel::String,
    robotLabel::String,
    sessionLabel::String,
    userData::Dict{Symbol, SmallDataTypes},
    robotData::Dict{Symbol, SmallDataTypes},
    sessionData::Dict{Symbol, SmallDataTypes},
    solverParams::T,
    blobStores = Dict{Symbol, AbstractBlobStore}(),
) where {T <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}

    #deprecated in v0.25
    Base.depwarn(
        "user/robot/session is deprecated. Replace with agent[Label/Metadata/BlobEntries] or graph[Label/Metadata/BlobEntries].",
        :GraphsDFG,
    )
    return GraphsDFG{T, V, F}(
        FactorGraph{Int, V, F}();
        description,
        userLabel,
        robotLabel,
        sessionLabel,
        userData,
        robotData,
        sessionData,
        solverParams,
        blobStores,
    )
end
