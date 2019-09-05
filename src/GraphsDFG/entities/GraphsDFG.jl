"""
$(TYPEDEF)
Encapsulation structure for a DFGNode (Variable or Factor) in Graphs.jl graph.
"""
mutable struct GraphsNode
    index::Int
    dfgNode::DFGNode
end
const FGType = Graphs.GenericIncidenceList{GraphsNode,Graphs.Edge{GraphsNode},Dict{Int,GraphsNode},Dict{Int,Array{Graphs.Edge{GraphsNode},1}}}

mutable struct GraphsDFG{T <: AbstractParams} <: AbstractDFG
    g::FGType
    description::String
    userId::String
    robotId::String
    sessionId::String
    nodeCounter::Int64
    labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
end

GraphsDFG{T}(   g::FGType=Graphs.incdict(GraphsNode,is_directed=false),
                d::String="Graphs.jl implementation",
                n::Int64=0,
                l::Dict{Symbol, Int64}=Dict{Symbol, Int64}(),
                a::Vector{Symbol}=Symbol[];
                userId::String = "UserID",
                robotId::String = "robotID",
                sessionId::String = "sessionID",
                params::T=NoSolverParams()) where T <: AbstractParams = GraphsDFG{T}(g, d, userId, robotId, sessionId, n, l, a, params)
