
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
    userLabel::String
    robotLabel::String
    sessionLabel::String
    userData::Dict{Symbol, SmallDataTypes}
    robotData::Dict{Symbol, SmallDataTypes}
    sessionData::Dict{Symbol, SmallDataTypes}
    userBlobEntries::OrderedDict{Symbol, BlobEntry}
    robotBlobEntries::OrderedDict{Symbol, BlobEntry}
    sessionBlobEntries::OrderedDict{Symbol, BlobEntry}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, AbstractBlobStore}
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
    description::String = "Graphs.jl implementation",
    userLabel::String = "DefaultUser",
    robotLabel::String = "DefaultRobot",
    sessionLabel::String = "Session_$(string(uuid4())[1:6])",
    userData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    robotData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    sessionData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    userBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    robotBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    sessionBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    addHistory::Vector{Symbol} = Symbol[],
    solverParams::T = T(),
    blobStores = Dict{Symbol, AbstractBlobStore}(),
) where {T <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    # Validate the userLabel, robotLabel, and sessionLabel
    !isValidLabel(userLabel) && error("'$userLabel' is not a valid User label")
    !isValidLabel(robotLabel) && error("'$robotLabel' is not a valid Robot label")
    !isValidLabel(sessionLabel) && error("'$sessionLabel' is not a valid Session label")

    return GraphsDFG{T, V, F}(
        g,
        description,
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

GraphsDFG(
    description::String,
    userLabel::String,
    robotLabel::String,
    sessionLabel::String,
    userData::Dict{Symbol, SmallDataTypes},
    robotData::Dict{Symbol, SmallDataTypes},
    sessionData::Dict{Symbol, SmallDataTypes},
    solverParams::AbstractParams,
    blobStores = Dict{Symbol, AbstractBlobStore}(),
) = GraphsDFG{typeof(solverParams), DFGVariable, DFGFactor}(
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
