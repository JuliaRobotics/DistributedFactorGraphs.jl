import Base.show

mutable struct Neo4jInstance
  connection::Neo4j.Connection
  graph::Neo4j.Graph
end

mutable struct CloudGraphsDFG{T <: AbstractParams} <: AbstractDFG
    neo4jInstance::Neo4jInstance
    description::String
    userId::String
    robotId::String
    sessionId::String
    encodePackedTypeFunc
    getPackedTypeFunc
    decodePackedTypeFunc
    labelDict::Dict{Symbol, Int64}
    variableCache::Dict{Symbol, DFGVariable}
    factorCache::Dict{Symbol, DFGFactor}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    useCache::Bool
end

function show(io::IO, c::CloudGraphsDFG)
    println("CloudGraphsDFG:")
    println(" - Neo4J instance: $(c.neo4jInstance.connection.host)")
    println(" - Session: $(c.userId):$(c.robotId):$(c.sessionId)")
    println(" - Caching: $(c.useCache)")
end
