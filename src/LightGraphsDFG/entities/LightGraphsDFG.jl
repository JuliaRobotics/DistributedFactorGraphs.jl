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

mutable struct LightGraphsDFG{T <: AbstractParams} <: AbstractDFG
    g::LFGType
    description::String
    userId::String
    robotId::String
    sessionId::String
    #TODO Remove nodeCounter
    nodeCounter::Int64 #TODO pos 'n paar van die veranderlikes dalk aan na MetaGraphs calls
    #TODO verander na label vector of gebruik matagrapsh sin
    labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

#TODO? do we not want props such as userId, robotId, sessionId, etc...
function LightGraphsDFG{T}(g::LFGType=MetaGraph(),
                           d::String="LightGraphs.jl implementation",
                           userId::String="User ID",
                           robotId::String="Robot ID",
                           sessionId::String="Session ID",
                           n::Int64=0,
                           l::Dict{Symbol, Int64}=Dict{Symbol, Int64}(),
                           a::Vector{Symbol}=Symbol[];
                           params::T=NoSolverParams()) where T <: AbstractParams
    set_prop!(g, :description, d)
    set_prop!(g, :userId, userId)
    set_prop!(g, :robotId, robotId)
    set_prop!(g, :sessionId, sessionId)
    set_indexing_prop!(g, :label)
    LightGraphsDFG{T}(g, d, userId, robotId, sessionId, n, l, a, params)
end
