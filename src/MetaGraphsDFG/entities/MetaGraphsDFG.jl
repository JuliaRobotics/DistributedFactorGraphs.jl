# Starting of with Graph.jl implementation. There are a lot of overlap with metagraphs and some data can be moved there.
"""
$(TYPEDEF)
Encapsulation structure for a DFGNode (Variable or Factor) in LightGraphs.jl graph.
"""
mutable struct LightGraphsNode
    index::Int
    dfgNode::DFGNode
end

const LFGType = MetaGraph{Int64,Float64}

mutable struct MetaGraphsDFG{T <: AbstractParams} <: AbstractDFG
    g::LFGType
    description::String
    userId::String
    robotId::String
    sessionId::String
    userData::Dict{Symbol, String}
    robotData::Dict{Symbol, String}
    sessionData::Dict{Symbol, String}
    #NOTE Removed nodeCounter
    # nodeCounter::Int64
    #NOTE using matagraphs labels
    # labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

#TODO? do we not want props such as userId, robotId, sessionId, etc...
function MetaGraphsDFG{T}(g::LFGType=MetaGraph();
                           description::String="LightGraphs.jl implementation",
                           userId::String="User ID",
                           robotId::String="Robot ID",
                           sessionId::String="Session ID",
                           userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                           params::T=NoSolverParams()) where T <: AbstractParams
    set_prop!(g, :description, description)
    set_prop!(g, :userId, userId)
    set_prop!(g, :robotId, robotId)
    set_prop!(g, :sessionId, sessionId)
    set_indexing_prop!(g, :label)
    MetaGraphsDFG{T}(g, description, userId, robotId, sessionId, userData, robotData, sessionData, Symbol[], params)
end

Base.propertynames(x::MetaGraphsDFG, private::Bool=false) =
    (:g, :description, :userId, :robotId, :sessionId, :nodeCounter, :labelDict, :addHistory, :solverParams)
        # (private ? fieldnames(typeof(x)) : ())...)

Base.getproperty(x::MetaGraphsDFG,f::Symbol) = begin
    if f == :nodeCounter
        @warn "Field nodeCounter depreciated. returning number of nodes"
        nv(x.g)
    elseif f == :labelDict
        @warn "Field labelDict depreciated. Consider using exists(dfg,label) or getLabelDict(dfg) instead. Returning internals copy"
        copy(x.g.metaindex[:label])
    else
        getfield(x,f)
    end
end

"""
$(TYPEDEF)
Basic Structure for just the LightGraphs object and keys
"""
struct LightGraphsSkeleton
    G::LightGraphs.SimpleGraph
    labels::Dict{Symbol, Int}
end

LightGraphsSkeleton(dfg::MetaGraphsDFG) = LightGraphsSkeleton(dfg.g.graph, dfg.g.metaindex[:label])
