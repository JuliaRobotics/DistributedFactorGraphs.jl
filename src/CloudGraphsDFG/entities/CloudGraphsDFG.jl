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
    description::String
    encodePackedTypeFunc #TODO Is this planed to be used or deprecated?
    getPackedTypeFunc #TODO Is this planed to be used or deprecated?
    decodePackedTypeFunc #TODO Is this planed to be used or deprecated?
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
                            description::String,
                            encodePackedTypeFunc,
                            getPackedTypeFunc,
                            decodePackedTypeFunc,
                            rebuildFactorMetadata!;
                            solverParams::T=NoSolverParams(),
                            createSessionNodes::Bool=true) where T <: AbstractParams
    # Validate the userId, robotId, and sessionId
    !isValidLabel(userId) && error("'$userId' is not a valid User ID")
    !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
    !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")

    graph = Neo4j.getgraph(neo4jConnection)
    neo4jInstance = Neo4jInstance(neo4jConnection, graph)
    dfg = CloudGraphsDFG{T}(neo4jInstance, userId, robotId, sessionId, description, encodePackedTypeFunc, getPackedTypeFunc, decodePackedTypeFunc, rebuildFactorMetadata!, Symbol[], solverParams)
    # Create the session if it doesn't already exist
    createSessionNodes && createDfgSessionIfNotExist(dfg)
    return dfg
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
                           description::String,
                           encodePackedTypeFunc,
                           getPackedTypeFunc,
                           decodePackedTypeFunc,
                           rebuildFactorMetadata!;
                           solverParams::T=NoSolverParams(),
                           createSessionNodes::Bool=true) where T <: AbstractParams
    neo4jConnection = Neo4j.Connection(host, port=port, user=dbUser, password=dbPassword);
    return CloudGraphsDFG{T}(neo4jConnection, userId, robotId, sessionId, description, encodePackedTypeFunc, getPackedTypeFunc, decodePackedTypeFunc, rebuildFactorMetadata!, solverParams=solverParams, createSessionNodes=createSessionNodes)
end


function show(io::IO, c::CloudGraphsDFG)
    println(io, "CloudGraphsDFG:")
    println(io, " - Neo4J instance: $(c.neo4jInstance.connection.host)")
    println(io, " - Session: $(c.userId):$(c.robotId):$(c.sessionId)")
    println(io, " - Description: ", c.description)
end
