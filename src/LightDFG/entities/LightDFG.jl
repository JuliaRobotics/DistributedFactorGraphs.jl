
"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on LightGraphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct LightDFG{T <: AbstractParams, V <: AbstractDFGVariable, F <:AbstractDFGFactor} <: AbstractDFG{T}
    g::FactorGraph{Int, V, F}
    description::String
    userId::String
    robotId::String
    sessionId::String
    userData::Dict{Symbol, String}
    robotData::Dict{Symbol, String}
    sessionData::Dict{Symbol, String}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

"""
    $(SIGNATURES)

Create an in-memory LightDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function LightDFG{T,V,F}(g::FactorGraph{Int,V,F}=FactorGraph{Int,V,F}();
                           description::String="LightGraphs.jl implementation",
                           userId::String="DefaultUser",
                           robotId::String="DefaultRobot",
                           sessionId::String="Session_$(string(uuid4())[1:6])",
                           userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           solverParams::T=T()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor}
   # Validate the userId, robotId, and sessionId
   !isValidLabel(userId) && error("'$userId' is not a valid User ID")
   !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
   !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")
   return LightDFG{T,V,F}(g, description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams)
end

# LightDFG{T}(; kwargs...) where T <: AbstractParams = LightDFG{T,DFGVariable,DFGFactor}(;kwargs...)

"""
    $(SIGNATURES)

Create an in-memory LightDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function LightDFG{T}(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                     params=nothing,
                     kwargs...) where T <: AbstractParams

    #TODO remove params deprecation error in v0.9
    if params != nothing
        @warn "keyword `params` is deprecated, please use solverParams"
        return LightDFG{T,DFGVariable,DFGFactor}(g; solverParams = params, kwargs...)
    end
    return LightDFG{T,DFGVariable,DFGFactor}(g; kwargs...)
end

function LightDFG(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                  solverParams::T=NoSolverParams(), params=nothing, kwargs...) where T
    #TODO remove params deprecation error in v0.9
    if params != nothing
        @warn "keyword `params` is deprecated, please use solverParams"
        return LightDFG{typeof(params),DFGVariable,DFGFactor}(g; solverParams=params, kwargs...)
    end
    return LightDFG{T,DFGVariable,DFGFactor}(g; solverParams=solverParams, kwargs...)
end


LightDFG(description::String,
         userId::String,
         robotId::String,
         sessionId::String,
         userData::Dict{Symbol, String},
         robotData::Dict{Symbol, String},
         sessionData::Dict{Symbol, String},
         solverParams::AbstractParams) =
         LightDFG(FactorGraph{Int,DFGVariable,DFGFactor}(), description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams)


LightDFG{T,V,F}(description::String,
                userId::String,
                robotId::String,
                sessionId::String,
                userData::Dict{Symbol, String},
                robotData::Dict{Symbol, String},
                sessionData::Dict{Symbol, String},
                solverParams::T) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor} =
                LightDFG(FactorGraph{Int,V,F}(), description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams)
