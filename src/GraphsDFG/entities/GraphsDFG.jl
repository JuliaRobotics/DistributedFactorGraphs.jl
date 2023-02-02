
"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on Graphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct GraphsDFG{T <: AbstractParams, V <: AbstractDFGVariable, F <:AbstractDFGFactor} <: AbstractDFG{T}
    g::FactorGraph{Int, V, F}
    description::String
    userLabel::String
    robotLabel::String
    sessionLabel::String
    userData::Dict{Symbol, String}
    robotData::Dict{Symbol, String}
    sessionData::Dict{Symbol, String}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, <:AbstractBlobStore}
end

"""
    $(SIGNATURES)

Create an in-memory GraphsDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function GraphsDFG{T,V,F}(
    g::FactorGraph{Int,V,F}=FactorGraph{Int,V,F}();
    description::String="Graphs.jl implementation",
    userLabel::String="DefaultUser",
    robotLabel::String="DefaultRobot",
    sessionLabel::String="Session_$(string(uuid4())[1:6])",
    userData::Dict{Symbol, String} = Dict{Symbol, String}(),
    robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
    sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
    solverParams::T=T(),
    blobstores=Dict{Symbol, AbstractBlobStore}(),
    # deprecating
    userId::Union{Nothing, String} = nothing,
    robotId::Union{Nothing, String} = nothing,
    sessionId::Union{Nothing, String} = nothing,
) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor}
    # Validate the userLabel, robotLabel, and sessionLabel
    if userId !== nothing
        @error "Obsolete use of userId::String with GraphsDFG, use userLabel::String instead" maxlog=10
        userLabel = userId
    end
    if robotId !== nothing
        @error "Obsolete use of robotId::String with GraphsDFG, use robotLabel::String instead" maxlog=10
        robotLabel = robotId
    end
    if sessionId !== nothing
        @error "Obsolete use of sessionId::String with GraphsDFG, use sessionLabel::String instead" maxlog=10
        sessionLabel = sessionId
    end

    !isValidLabel(userLabel) && error("'$userLabel' is not a valid User label")
    !isValidLabel(robotLabel) && error("'$robotLabel' is not a valid Robot label")
    !isValidLabel(sessionLabel) && error("'$sessionLabel' is not a valid Session label")
    return GraphsDFG{T,V,F}(g, description, userLabel, robotLabel, sessionLabel, userData, robotData, sessionData, Symbol[], solverParams, blobstores)
end

# GraphsDFG{T}(; kwargs...) where T <: AbstractParams = GraphsDFG{T,DFGVariable,DFGFactor}(;kwargs...)

"""
    $(SIGNATURES)

Create an in-memory GraphsDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function GraphsDFG{T}(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                     kwargs...) where T <: AbstractParams
    return GraphsDFG{T,DFGVariable,DFGFactor}(g; kwargs...)
end

function GraphsDFG(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                  solverParams::T=NoSolverParams(), kwargs...) where T
    return GraphsDFG{T,DFGVariable,DFGFactor}(g; solverParams, kwargs...)
end


GraphsDFG(description::String,
         userLabel::String,
         robotLabel::String,
         sessionLabel::String,
         userData::Dict{Symbol, String},
         robotData::Dict{Symbol, String},
         sessionData::Dict{Symbol, String},
         solverParams::AbstractParams,
         blobstores=Dict{Symbol, AbstractBlobStore}()) =
         GraphsDFG(FactorGraph{Int,DFGVariable,DFGFactor}(), description, userLabel, robotLabel, sessionLabel, userData, robotData, sessionData, Symbol[], solverParams, blobstores)


GraphsDFG{T,V,F}(description::String,
                userLabel::String,
                robotLabel::String,
                sessionLabel::String,
                userData::Dict{Symbol, String},
                robotData::Dict{Symbol, String},
                sessionData::Dict{Symbol, String},
                solverParams::T,
                blobstores=Dict{Symbol, AbstractBlobStore}()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor} =
                GraphsDFG(FactorGraph{Int,V,F}(), description, userLabel, robotLabel, sessionLabel, userData, robotData, sessionData, Symbol[], solverParams, blobstores)
