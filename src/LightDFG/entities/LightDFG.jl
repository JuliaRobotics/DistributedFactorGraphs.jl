
mutable struct LightDFG{T <: AbstractParams, V <: DFGNode, F <:DFGNode} <: AbstractDFG
    g::FactorGraph{Int, V, F}
    description::String
    userId::String
    robotId::String
    sessionId::String
    #NOTE does not exist
    # nodeCounter::Int64
    #NOTE does not exist
    # labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

#TODO? do we not want props such as userId, robotId, sessionId, etc...
function LightDFG{T,V,F}(g::FactorGraph{Int,V,F}=FactorGraph{Int,V,F}();
                           description::String="LightGraphs.jl implementation",
                           userId::String="User ID",
                           robotId::String="Robot ID",
                           sessionId::String="Session ID",
                           params::T=NoSolverParams()) where {T <: AbstractParams, V <:DFGNode, F<:DFGNode}

    LightDFG{T,V,F}(g, description, userId, robotId, sessionId, Symbol[], params)
end

# LightDFG{T}(; kwargs...) where T <: AbstractParams = LightDFG{T,DFGVariable,DFGFactor}(;kwargs...)

LightDFG{T}(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}(); kwargs...) where T <: AbstractParams = LightDFG{T,DFGVariable,DFGFactor}(g; kwargs...)

Base.propertynames(x::LightDFG, private::Bool=false) =
    (:g, :description, :userId, :robotId, :sessionId, :nodeCounter, :labelDict, :addHistory, :solverParams)
        # (private ? fieldnames(typeof(x)) : ())...)

Base.getproperty(x::LightDFG,f::Symbol) = begin
    if f == :nodeCounter
        @error "Depreciated? returning number of nodes"
        nv(x.g)
    elseif f == :labelDict
        @error "Depreciated? Concider using exists(dfg,label) instead. Returing internals copy"
        copy(x.g.labels.sym_int)
    else
        getfield(x,f)
    end
end
