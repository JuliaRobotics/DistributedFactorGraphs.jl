
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
    userId::String
    robotId::String
    sessionId::String
    userData::Dict{Symbol, String}
    robotData::Dict{Symbol, String}
    sessionData::Dict{Symbol, String}
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
function GraphsDFG{T,V,F}(g::FactorGraph{Int,V,F}=FactorGraph{Int,V,F}();
                           description::String="Graphs.jl implementation",
                           userId::String="DefaultUser",
                           robotId::String="DefaultRobot",
                           sessionId::String="Session_$(string(uuid4())[1:6])",
                           userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           solverParams::T=T(),
                           blobstores=Dict{Symbol, AbstractBlobStore}()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor}
   # Validate the userId, robotId, and sessionId
   !isValidLabel(userId) && error("'$userId' is not a valid User ID")
   !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
   !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")
   return GraphsDFG{T,V,F}(g, description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams, blobstores)
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
    return GraphsDFG{T,DFGVariable,DFGFactor}(g; solverParams=solverParams, kwargs...)
end


GraphsDFG(description::String,
         userId::String,
         robotId::String,
         sessionId::String,
         userData::Dict{Symbol, String},
         robotData::Dict{Symbol, String},
         sessionData::Dict{Symbol, String},
         solverParams::AbstractParams,
         blobstores=Dict{Symbol, AbstractBlobStore}()) =
         GraphsDFG(FactorGraph{Int,DFGVariable,DFGFactor}(), description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams, blobstores)


GraphsDFG{T,V,F}(description::String,
                userId::String,
                robotId::String,
                sessionId::String,
                userData::Dict{Symbol, String},
                robotData::Dict{Symbol, String},
                sessionData::Dict{Symbol, String},
                solverParams::T,
                blobstores=Dict{Symbol, AbstractBlobStore}()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor} =
                GraphsDFG(FactorGraph{Int,V,F}(), description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams, blobstores)
