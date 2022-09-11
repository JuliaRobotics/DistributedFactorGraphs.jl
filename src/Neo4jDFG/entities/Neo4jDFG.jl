import Base.show

mutable struct Neo4jInstance
  connection::Neo4j.Connection
  graph::Neo4j.Graph
end

mutable struct Neo4jDFG{T <: AbstractParams} <: AbstractDFG{T}
    neo4jInstance::Neo4jInstance
    userId::String
    robotId::String
    sessionId::String
    description::String #TODO Maybe remove description
    addHistory::Vector{Symbol}
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, AbstractBlobStore}

    # inner constructor for all constructors in common
    function Neo4jDFG{T}(neo4jInstance::Neo4jInstance,
                               userId::String,
                               robotId::String,
                               sessionId::String,
                               description::String,
                               addHistory::Vector{Symbol},
                               solverParams::T;
                               createSessionNodes::Bool=true,
                               userData::Dict{Symbol, String} = Dict{Symbol, String}(),
                               robotData::Dict{Symbol, String} = Dict{Symbol, String}(),
                               sessionData::Dict{Symbol, String} = Dict{Symbol, String}(),
                               blobStores::Dict{Symbol, AbstractBlobStore} = Dict{Symbol, AbstractBlobStore}()) where T <: AbstractParams
        # Validate the userId, robotId, and sessionId
        !isValidLabel(userId) && error("'$userId' is not a valid User ID")
        !isValidLabel(robotId) && error("'$robotId' is not a valid Robot ID")
        !isValidLabel(sessionId) && error("'$sessionId' is not a valid Session ID")

        dfg = new{T}(neo4jInstance, userId, robotId, sessionId, description, addHistory, solverParams, blobStores)
        # Create the session if it doesn't already exist
        if createSessionNodes
            createDfgSessionIfNotExist(dfg)
        end

        return dfg
    end
end

"""
    $(SIGNATURES)
Create a new CloudGraphs-based DFG factor graph using a Neo4j.Connection or by specifying the Neo4j connection information
"""
function Neo4jDFG{T}(neo4jConnection::Neo4j.Connection,
                           userId::String,
                           robotId::String,
                           sessionId::String,
                           description::String;
                           solverParams::T=NoSolverParams(),
                           kwargs...) where T <: AbstractParams

    graph = Neo4j.getgraph(neo4jConnection)
    neo4jInstance = Neo4jInstance(neo4jConnection, graph)

    return Neo4jDFG{T}(neo4jInstance, userId, robotId, sessionId, description, Symbol[], solverParams; kwargs...)

end

function Neo4jDFG{T}(host::String,
                           port::Int,
                           dbUser::String,
                           dbPassword::String,
                           userId::String,
                           robotId::String,
                           sessionId::String,
                           description::String;
                           kwargs...) where T <: AbstractParams
    neo4jConnection = Neo4j.Connection(host, port=port, user=dbUser, password=dbPassword)
    return Neo4jDFG{T}(neo4jConnection, userId, robotId, sessionId, description; kwargs...)
end

# construct using the default settings for localhost
function Neo4jDFG(; hostname="localhost",
                          port=7474,
                          username="neo4j",
                          password="test",
                          userId::String="DefaultUser",
                          robotId::String="DefaultRobot",
                          sessionId::String="Session_$(string(uuid4())[1:6])", #TODO randstring(['a':'z';'A':'Z'],1) ipv Session
                          description::String="Neo4jDFG implementation",
                          solverParams::T=NoSolverParams(),
                          kwargs...) where T <: AbstractParams

    return Neo4jDFG{T}(hostname,
                             port,
                             username,
                             password,
                             userId,
                             robotId,
                             sessionId,
                             description;
                             solverParams=solverParams,
                             kwargs...)
end

function Neo4jDFG(description::String,
                        userId::String,
                        robotId::String,
                        sessionId::String,
                        userData::Dict{Symbol, String},
                        robotData::Dict{Symbol, String},
                        sessionData::Dict{Symbol, String},
                        solverParams::AbstractParams;
                        host::String = "localhost",
                        port::Int = 7474,
                        dbUser::String = "neo4j",
                        dbPassword::String = "test")

    return Neo4jDFG{typeof(solverParams)}(host,
                                                port,
                                                dbUser,
                                                dbPassword,
                                                userId,
                                                robotId,
                                                sessionId,
                                                description;
                                                solverParams=solverParams,
                                                userData=userData,
                                                robotData=robotData,
                                                sessionData=sessionData)


end

function show(io::IO, ::MIME"text/plain", c::Neo4jDFG)
    println(io, "Neo4jDFG:")
    println(io, " - Neo4J instance: $(c.neo4jInstance.connection.host)")
    println(io, " - Session: $(c.userId):$(c.robotId):$(c.sessionId)")
    println(io, " - Description: ", c.description)
    println(io, " - Blob Stores: ", listBlobStores(c))
end
