
"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on LightGraphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct LightDFG{T <: AbstractParams, V <: AbstractDFGVariable, F <:AbstractDFGFactor} <: AbstractDFG
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
                           userId::String="User ID",
                           robotId::String="Robot ID",
                           sessionId::String="Session ID",
                           userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           params::T=T()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor}

    LightDFG{T,V,F}(g, description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], params)
end

# LightDFG{T}(; kwargs...) where T <: AbstractParams = LightDFG{T,DFGVariable,DFGFactor}(;kwargs...)
"""
    $(SIGNATURES)

Create an in-memory LightDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
LightDFG{T}(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}(); kwargs...) where T <: AbstractParams =
        LightDFG{T,DFGVariable,DFGFactor}(g; kwargs...)

LightDFG(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}(); params::T=NoSolverParams(), kwargs...)  where T =
        LightDFG{T,DFGVariable,DFGFactor}(g; params=params, kwargs...)


LightDFG(description::String,
         userId::String,
         robotId::String,
         sessionId::String,
         userData::Dict{Symbol, String},
         robotData::Dict{Symbol, String},
         sessionData::Dict{Symbol, String},
         solverParams::AbstractParams) =
         LightDFG(FactorGraph{Int,DFGVariable,DFGFactor}(), description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], solverParams)


# Fully depcrecate nodeCounter and labelDict
# Base.propertynames(x::LightDFG, private::Bool=false) =
#     (:g, :description, :userId, :robotId, :sessionId, :nodeCounter, :labelDict, :addHistory, :solverParams)
#         # (private ? fieldnames(typeof(x)) : ())...)
#
# Base.getproperty(x::LightDFG,f::Symbol) = begin
#     if f == :nodeCounter
#         @error "Field nodeCounter deprecated. returning number of nodes"
#         nv(x.g)
#     elseif f == :labelDict
#         @error "Field labelDict deprecated. Consider using exists(dfg,label) or getLabelDict(dfg) instead. Returning internals copy"
#         #TODO: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/111
#         copy(x.g.labels.sym_int)
#     else
#         getfield(x,f)
#     end
# end
