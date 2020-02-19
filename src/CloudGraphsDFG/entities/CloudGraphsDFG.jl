import Base.show

mutable struct Neo4jInstance
  connection::Neo4j.Connection
  graph::Neo4j.Graph
end

mutable struct CloudGraphsDFG{T <: AbstractParams} <: AbstractDFG
    neo4jInstance::Neo4jInstance
    userId::String
    robotId::String
    sessionId::String
    encodePackedTypeFunc
    getPackedTypeFunc
    decodePackedTypeFunc
    rebuildFactorMetadata!
    addHistory::Vector{Symbol}
    solverParams::T # Solver parameters
end

"""
    $(SIGNATURES)
Create a new CloudGraphs-based DFG factor graph using a Neo4j.Connection.
"""
function CloudGraphsDFG{T}(neo4jConnection::Neo4j.Connection,
                            userId::String,
                            robotId::String,
                            sessionId::String,
                            encodePackedTypeFunc,
                            getPackedTypeFunc,
                            decodePackedTypeFunc,
                            rebuildFactorMetadata!;
                            solverParams::T=NoSolverParams()) where T <: AbstractParams
    graph = Neo4j.getgraph(neo4jConnection)
    neo4jInstance = Neo4jInstance(neo4jConnection, graph)
    return CloudGraphsDFG{T}(neo4jInstance, userId, robotId, sessionId, encodePackedTypeFunc, getPackedTypeFunc, decodePackedTypeFunc, rebuildFactorMetadata!, Symbol[], solverParams)
end
"""
    $(SIGNATURES)
Create a new CloudGraphs-based DFG factor graph by specifying the Neo4j connection information.
"""
function CloudGraphsDFG{T}(host::String,
                            port::Int,
                            dbUser::String,
                            dbPassword::String,
                            userId::String,
                            robotId::String,
                            sessionId::String,
                            encodePackedTypeFunc,
                            getPackedTypeFunc,
                            decodePackedTypeFunc,
                            rebuildFactorMetadata!;
                            solverParams::T=NoSolverParams()) where T <: AbstractParams
    neo4jConnection = Neo4j.Connection(host, port=port, user=dbUser, password=dbPassword);
    return CloudGraphsDFG{T}(neo4jConnection, userId, robotId, sessionId, encodePackedTypeFunc, getPackedTypeFunc, decodePackedTypeFunc, rebuildFactorMetadata!, solverParams=solverParams)
end


function show(io::IO, c::CloudGraphsDFG)
    println(io, "CloudGraphsDFG:")
    println(io, " - Neo4J instance: $(c.neo4jInstance.connection.host)")
    println(io, " - Session: $(c.userId):$(c.robotId):$(c.sessionId)")
end
