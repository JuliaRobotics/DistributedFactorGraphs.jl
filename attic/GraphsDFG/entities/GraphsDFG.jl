"""
$(TYPEDEF)
Encapsulation structure for a DFGNode (Variable or Factor) in Graphs.jl graph.
"""
mutable struct GraphsNode
    index::Int
    dfgNode::DFGNode
end
const FGType = Graphs.GenericIncidenceList{GraphsNode,Graphs.Edge{GraphsNode},Dict{Int,GraphsNode},Dict{Int,Array{Graphs.Edge{GraphsNode},1}}}

mutable struct GraphsDFG{T <: AbstractParams} <: AbstractDFG{T}
    g::FGType
    description::String
    userId::String
    robotId::String
    sessionId::String
    userData::Dict{Symbol, String}
    robotData::Dict{Symbol, String}
    sessionData::Dict{Symbol, String}
    nodeCounter::Int64
    labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    # GraphsDFG{T}(x...) where T <: AbstractParams = new{T}(x...)
end


function GraphsDFG( g::FGType=Graphs.incdict(GraphsNode,is_directed=false),
                    d::String="Graphs.jl implementation",
                    n::Int64=0,
                    l::Dict{Symbol, Int64}=Dict{Symbol, Int64}(),
                    a::Vector{Symbol}=Symbol[];
                    userId::String = "DefaultUser",
                    robotId::String = "DefaultRobot",
                    sessionId::String = "Session_$(string(uuid4())[1:6])",
                    userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                    robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                    sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                    params::T=NoSolverParams()) where T <: AbstractParams
    # Validate the userId, robotId, and sessionId
    Base.depwarn("GraphsDFG is voetstoots and will no longer be maintaind, use LightDFG", :GraphsDFG)
    !isValidLabel(userId) && error("'$userId' is not a valid User ID")
    !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
    !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")
    return GraphsDFG{T}(g, d, userId, robotId, sessionId, userData, robotData, sessionData, n, l, a, params)
end

function GraphsDFG{T}(  g::FGType=Graphs.incdict(GraphsNode,is_directed=false),
                        d::String="Graphs.jl implementation",
                        n::Int64=0,
                        l::Dict{Symbol, Int64}=Dict{Symbol, Int64}(),
                        a::Vector{Symbol}=Symbol[];
                        userId::String = "DefaultUser",
                        robotId::String = "DefaultRobot",
                        sessionId::String = "Session_$(string(uuid4())[1:6])",
                        userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                        robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                        sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                        params::T=T()) where T <: AbstractParams
    # Validate the userId, robotId, and sessionId
    Base.depwarn("GraphsDFG is voetstoots and will no longer be maintaind, use LightDFG", :GraphsDFG)
    !isValidLabel(userId) && error("'$userId' is not a valid User ID")
    !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
    !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")
    return GraphsDFG{T}(g, d, userId, robotId, sessionId, userData, robotData, sessionData, n, l, a, params)
end

GraphsDFG(description::String,
          userId::String,
          robotId::String,
          sessionId::String,
          userData::Dict{Symbol, String},
          robotData::Dict{Symbol, String},
          sessionData::Dict{Symbol, String},
          solverParams::AbstractParams) =
          GraphsDFG(Graphs.incdict(GraphsNode,is_directed=false), description, userId, robotId, sessionId, userData, robotData, sessionData, 0, Dict{Symbol, Int64}(), Symbol[], solverParams)
