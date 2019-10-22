alphaOnlyMatchRegex = r"^[a-zA-Z0-9_]*$"

"""
$(SIGNATURES)
Returns the transaction for a given query.
NOTE: Must commit(transaction) after you're done.
"""
function _queryNeo4j(neo4jInstance::Neo4jInstance, query::String)
    loadtx = transaction(neo4jInstance.connection)
    result = loadtx(query; submit=true)
    if length(result.errors) > 0
        error(string(result.errors))
    end
    # Have to finish the transaction
    commit(loadtx)
    return result
end

"""
$(SIGNATURES)
Returns the list of CloudGraph nodes that matches the Cyphon query.
The nodes of interest should be labelled 'node' because the query will use the return of id(node)
#Example
matchCondition = '(u:User)-[:ROBOT]->(n:Robot:NewRobot)-[:SESSION]->(node:Session)'.
Will return all sessions because of 'node:Session'.
If orderProperty is not ==, then 'order by n.{orderProperty} will be appended to the query'.
So can make orderProperty = label or id.
"""
function _getLabelsFromCyphonQuery(neo4jInstance::Neo4jInstance, matchCondition::String, orderProperty::String="")::Vector{Symbol}
    query = "match $matchCondition return distinct(node.label) $(orderProperty != "" ? "order by node.$orderProperty" : "")";
    result = _queryNeo4j(neo4jInstance, query)
    nodeIds = map(node -> node["row"][1], result.results[1]["data"])
    return Symbol.(nodeIds)
end

"""
$(SIGNATURES)
Get a node property - returns nothing if not found
"""
function _getNodeProperty(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String}, property::String)
    query = "match (n:$(join(nodeLabels, ":"))) return n.$property"
    result = DistributedFactorGraphs._queryNeo4j(neo4jInstance, query)

    return result.results[1]["data"][1]["row"][1]
end

"""
$(SIGNATURES)
Get a node's tags
"""
function _getNodeTags(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String})::Union{Nothing, Vector{String}}
    query = "match (n:$(join(nodeLabels, ":"))) return labels(n)"
    result = DistributedFactorGraphs._queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && return nothing
    return result.results[1]["data"][1]["row"][1]
end

function _getNodeCount(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String})::Int
    query = "match (n:$(join(nodeLabels, ":"))) return count(n)"
    result = DistributedFactorGraphs._queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && return 0
    return parse(Int, result.results[1]["data"][1]["row"][1])
end
"""
$(SIGNATURES)
Returns the list of CloudGraph nodes that matches the Cyphon query.
The nodes of interest should be labelled 'node' because the query will use the return of id(node)
#Example
matchCondition = '(u:User)-[:ROBOT]->(n:Robot:NewRobot)-[:SESSION]->(node:Session)'.
Will return all sessions because of 'node:Session'.
If orderProperty is not ==, then 'order by n.{orderProperty} will be appended to the query'.
So can make orderProperty = label or id.
"""
function _getNeoNodesFromCyphonQuery(neo4jInstance::Neo4jInstance, matchCondition::String, orderProperty::String="")::Vector{Neo4j.Node}
    # 2. Perform the transaction
    loadtx = transaction(neo4jInstance.connection)
    query = "match $matchCondition return id(node) $(orderProperty != "" ? "order by node.$orderProperty" : "")";
    nodes = loadtx(query; submit=true)
    if length(nodes.errors) > 0
        error(string(nodes.errors))
    end
    # 3. Format the result
    nodes = map(node -> getnode(neo4jInstance.graph, node["row"][1]), nodes.results[1]["data"])
    # Have to finish the transaction
    commit(loadtx)
    return nodes
end

"""
$(SIGNATURES)
Utility function to get a Neo4j node for a robot.
"""
function _getRobotNeoNodeForUser(neo4jInstance::Neo4jInstance, userId::String, robotId::String)::Neo4j.Node
    # 2. Perform the transactionfunction _getLatestPoseForSession(userId::String, robotId::String, sessionId::String)::Neo4j.Node
    nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(u:USER:$userId)-[:ROBOT]->(node:ROBOT:$robotId)")
    if(length(nodes) != 1)
        throw("Expected a single robot with ID '$robotId', retrieved $(length(nodes)). Should only be a single node")
    end
    return nodes[1]
end

"""
$(SIGNATURES)
Utility function to get a user root node given an ID.
"""
function _getUserNeoNode(neo4jInstance::Neo4jInstance, userId::String)::Neo4j.Node
    # 2. Perform the transaction
    nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:USER:$userId)")
    if(length(nodes) != 1)
        error("Expected one user node with labels $userId and USER, received $(length(nodes)).")
    end
    return nodes[1]
end


"""
$(SIGNATURES)
Utility function to get a Neo4j node sessions for a robot.
"""
function _getSessionNeoNodesForRobot(neo4jInstance::Neo4jInstance, userId::String, robotId::String)::Vector{Neo4j.Node}
    # 2. Perform the transaction
    nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(u:USER:$userId)-[:ROBOT]->(r:ROBOT:$robotId)-[:SESSION]->(node:SESSION)", "id")
    return nodes
end

"""
$(SIGNATURES)
Bind the SESSION node to the inital variable.
Doesn't check existence so please don't call twice.
"""
function _bindSessionNodeToInitialVariable(neo4jInstance::Neo4jInstance, userId::String, robotId::String, sessionId::String, initialVariableLabel::String)::Nothing
    # 2. Perform the transaction
    loadtx = transaction(neo4jInstance.connection)
    query = """
    match (session:SESSION:$userId:$robotId:$sessionId),
    (var:VARIABLE:$userId:$robotId:$sessionId
    {label: '$initialVariableLabel'})
    CREATE (session)-[:VARIABLE]->(var) return id(var)
    """;
    loadtx(query; submit=true)
    commit(loadtx)
    return nothing
end

# """
# $(SIGNATURES)
# Create a session for a robot.
# """
# function _createSessionForRobot(userId::String, robotId::String, newSession::SessionDetailsRequest)::SessionDetailsResponse
#     # 1. Make sure the session doesn't exist.
#     sessions = _getSessionNeoNodesForRobot(userId, robotId)
#     for session in sessions
#         sessionLabels = getnodelabels(session)
#         if(newSession.id in sessionLabels)
#             error("Session $newSession.id cannot be created for robot $robotId, it already exists")
#         end
#     end
#     # 1b. Get the parent robot Neo4j node.
#     robotNode = _getRobotNeoNodeForUser(userId, robotId)
#
#     # 2. Create the correct response.
#     props = JSON.parse(JSON.json(newSession))
#     props["createdTimestamp"] = string(Dates.now(Dates.UTC))
#     props["lastSolvedTimestamp"] = string(Dates.DateTime(0))
#     props["userId"] = userId
#     props["robotId"] = robotId
#     props["solveCount"] = 1
#     props["solveTimes"] = [0]
#     props["isSolverEnabled"] = true # If false then the pilotfish won't pick up on it.
#
#     # 3. Create the session
#     cloudGraph = Main.App.NaviConfig.cgConnection
#     createdSessionNode = Neo4j.createnode(cloudGraph.neo4j.graph, props)
#     addnodelabels(createdSessionNode, ["SESSION", newSession.id, userId, robotId])
#     createrel(robotNode, createdSessionNode, "SESSION") #From USER to ROBOT
#
#     # 4. Initialize the factor graph
#     # Now start up our factor graph.
#     newSession.initialPoseType
#     if newSession.initialPoseType != nothing
#         labels=[newSession.id, robotId, userId]
#         fg = Caesar.initfg(sessionname=newSession.id, cloudgraph=cloudGraph)
#         # TODO: Cache refactoring discussion.
#         fg.stateless = true # so that we don't update local elements
#
#         poseType = nothing
#         if newSession.initialPoseType != "" && newSession.shouldInitialize
#             poseType = eval(Meta.parse(newSession.initialPoseType))
#             # Initialize the factor graph and insert first pose.
#             nodesyms = initFactorGraph!(fg, labels=labels, ready=0, firstPoseType=poseType)
#             varSymbol  = nodesyms[1]
#             factSymbol = nodesyms[2]
#
#             # Create a relationship for session -> first pose
#             _bindSessionNodeToInitialVariable(userId, robotId, newSession.id, String(varSymbol))
#
#             # Set the node symbols to ready
#             _setReadyStatus(userId, robotId, newSession.id, string.(nodesyms), true)
#         end
#     end
#
#     # 5. Format the result
#     props["nodeCount"] = 0
#     props["userId"] = userId
#     props["robotId"] = robotId
#     props["links"] = Dict{String, String}("self" => "/api/v0/users/$userId/robots/$robotId/sessions/$(newSession.id)", "nodes" => "/api/v0/users/$userId/robots/$robotId/sessions/$(newSession.id)/nodes")
#     model = Unmarshal.unmarshal(SessionDetailsResponse, props)
#     return model
# end

# """
# $(SIGNATURES)
# Function to delete a session.
# """
# function _deleteSession(userId::String, robotId::String, sessionId::String)::Nothing
#     cloudGraph = Main.App.NaviConfig.cgConnection
#     loadtx = transaction(cloudGraph.neo4j.connection)
#     query = "match (n:$userId:$robotId:$sessionId) detach delete n";
#     nodes = loadtx(query; submit=true)
#     commit(loadtx)
#     return nothing
# end

"""
$(SIGNATURES)
Utility function to get a Neo4j node for a session.
"""
function _getSessionNeoNodeForRobot(userId::String, robotId::String, sessionId::String)::Neo4j.Node
    sessions = _getSessionNeoNodesForRobot(userId, robotId)
    for session in sessions
        sessionLabels = getnodelabels(session)
        if(sessionId in sessionLabels)
            return session
        end
    end
    error("Cannot find session $sessionId associated with robot $robotId and user $userId")
end

# """
# $(SIGNATURES)
# Returns all Synchrony nodes for a given session.
# """
# function _getSynchronyNodesForSession(userId::String, robotId::String, sessionId::String)::Vector{NodeModel}
#     # 2. Perform the transaction
#     cloudGraph = Main.App.NaviConfig.cgConnection
#     loadtx = transaction(cloudGraph.neo4j.connection)
#     query = "match (n:$userId:$robotId:$sessionId:VARIABLE) return id(n), n.label, n.MAP_est";
#     nodes = loadtx(query; submit=true)
#     # Have to finish the transaction
#     commit(loadtx)
#
#     if length(nodes.results[1]["data"]) == 0
#         return Vector{NodeModel}() # Empty
#     end
#
#     # 3. Format the result
#     # Convert the mapEsts
#     nodes = map(r -> NodeModel(r["row"][1], r["row"][2], r["row"][3] != nothing ? Float64.(r["row"][3]) : nothing, Dict{String, String}("self" => "/api/v0/users/$userId/robots/$robotId/sessions/$sessionId/nodes/$(r["row"][1])")), nodes.results[1]["data"])
#     return nodes
# end

"""
$(SIGNATURES)
Try get a Neo4j node ID from a node label.
"""
function _tryGetNeoNodeIdFromNodeLabel(neo4jInstance::Neo4jInstance, userId::String, robotId::String, sessionId::String, nodeLabel::Symbol)::Union{Nothing, Int}
    @debug "Looking up symbolic node ID where n.label = '$nodeLabel'..."
    nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:$userId:$robotId:$sessionId) where exists(node.label) and node.label = \"$(string(nodeLabel))\"")
    if(length(nodes) != 1)
        return nothing
    end
    nodeId = nodes[1].id
    @debug "Found NeoNode ID = $nodeId..."
    return nodeId
end


"""
$(SIGNATURES)
Get a Neo4j node ID from a node label.
"""
function _getNeoNodeIdFromNodeLabel(neo4jInstance::Neo4jInstance, userId::String, robotId::String, sessionId::String, nodeLabel::Symbol)::Int
    nodeId = _tryGetNeoNodeIdFromNodeLabel(neo4jInstance, userId, robotId, sessionId, nodeLabel)
    if(nodeId == nothing)
        error("Cannot find a single symbolic node for label '$nodeLabel', received $(length(nodes)) nodes...")
    end
    return nodeId
end

"""
$(SIGNATURES)
Get a specific node given the Neo4j node ID.
"""
function _getSynchronyNodeFromId(userId::String, robotId::String, sessionId::String, nodeId::Union{Int, String})::NodeDetails
    cloudGraph = Main.App.NaviConfig.cgConnection

    if(typeof(nodeId) == String)
        nodeId = _getNeoNodeIdFromNodeLabel(userId, robotId, sessionId, nodeId)
    end

    node = CloudGraphs.get_vertex(cloudGraph, nodeId, false)

    # 3. Format the result
    rootPath = "/api/v0/users/$userId/robots/$robotId/sessions/$sessionId/nodes/$nodeId"
    node = NodeDetails(
        nodeId,
        haskey(node.properties, "label") ? node.properties["label"] : "",
        node.exVertexId,
        :softtype in fieldnames(typeof(node.packed)) ? string(typeof(node.packed.softtype)) : "",
        node.properties,
        node.packed,
        node.labels,
        Dict{String, String}("self" => rootPath, "data" => rootPath*"/data"))
    if !(robotId in node.labels) ||
        !(sessionId in node.labels) ||
        !(userId in node.labels)
        # Making sure user is asking for their session nodes.
        error("Node not found")
    end
    return(node)
end

"""
$(SIGNATURES)
Sets the ready status of the complete session.
"""
function _setSessionReadyStatus(userId::String, robotId::String, sessionId::String, ready::Bool)::Nothing
    # 2. Perform the transaction
    cloudGraph = Main.App.NaviConfig.cgConnection
    loadtx = transaction(cloudGraph.neo4j.connection)
    query = "match (n:$userId:$robotId:$sessionId) where exists(n.ready) set n.ready=$(ready ? 1 : 0) return count(n)";
    loadtx(query; submit=true)
    commit(loadtx)
    return nothing
end


"""
$(SIGNATURES)
Convert Vector{<:AbstractString} to square braced single quoted list of elements ready for Cypher query use"
"""
function _stringArrToCyphonList(stra::Vector{<:AbstractString})
    qs = "["
    for el in stra
        qs *= "'"*el*"', "
    end
    qs = chop(chop(qs))
    qs *= "]"
    return qs
end

"""
$(SIGNATURES)
Returns the BigDataElements for the node.
"""
function _getDataEntriesForNode(nodeId::Int)::Vector{BigDataElement}
    cloudGraph = Main.App.NaviConfig.cgConnection
    node = CloudGraphs.get_vertex(cloudGraph, nodeId, false)
    return node.bigData.dataElements
end

"""
$(SIGNATURES)
Sets the ready status of the complete session.
"""
function _setReadyStatus(userId::String, robotId::String, sessionId::String, nodeLabels::Vector{String}, ready::Bool)::Nothing
    # 2. Perform the transaction
    cloudGraph = Main.App.NaviConfig.cgConnection

    loadtx = transaction(cloudGraph.neo4j.connection)
    query = "match (n:$userId:$robotId:$sessionId) where exists(n.ready) and exists(n.label) and n.label in $(_stringArrToCyphonList(nodeLabels)) set n.ready=$(ready ? 1 : 0) return count(n)";
    loadtx(query; submit=true)
    commit(loadtx)
    return nothing
end

"""
$(SIGNATURES)
Validate all given inputs and return the results.
Error if any missing or blank.
Returns: A list of strings/ints/floats of all the inputs.
"""
function _validateHttpInputs(requiredInputs::Vector{Symbol}, params::Dict{Symbol, Any})::Vector{Any}
    rets = Vector{Any}()
    for input in requiredInputs
        input = haskey(params, input) ? params[input] : ""
        if(typeof(input) == String && isempty(lstrip(input)))
            error("'$(string(input))' is empty string.")
        end
        typeof(input) == String && !occursin(alphaOnlyMatchRegex, input) && error("$input is not alphanumeric, please only use alphanumeric and underscores for parameters.")
        push!(rets, input)
    end
    return rets
end

function _isCallIsFromApiGateway(params::Dict{Symbol, Any})::Bool
    # Simple security for making sure only API gateway is used because it populates this header.
    testEndpoint = true
    if haskey(ENV, "securityDisabled")
        if ENV["securityDisabled"] == "true"
            testEndpoint = false
        end
    end
    if testEndpoint == true
        requestKey = :REQUEST
        if !haskey(params, requestKey)
            return false
        end
        request = params[requestKey]
        request.headers
        if !haskey(request.headers, "secapi")
            return false #Response(401)
        end
        if request.headers["secapi"] != "001ac"
            return false
        end
    end
    # Otherwise ok.
    return true
end

function readAndReturnFile(filename::String, mimeType::String="application/octet-stream")::HTTP.Response
    if !isfile(filename)
        error("The file to be returned does not exist - $filename")
    end

    s = open(filename, "r");
    data = read(s);
    close(s);

    headers = Dict{AbstractString, AbstractString}( "Server" => "Julia/$VERSION",
                    "Content-Type"     => mimeType,
                    "Date"             => Dates.format(now(Dates.UTC), Dates.RFC1123Format) )
    return HTTP.Response(200, headers; body=data)
end

function jsonReponse(jsonData::String; returnCode::Int=200)::HTTP.Response
    headers = Dict{AbstractString, AbstractString}( "Server" => "Julia/$VERSION",
                    "Content-Type"     => "application/json",
                    "Date"             => Dates.format(now(Dates.UTC), Dates.RFC1123Format) )
    return HTTP.Response(returnCode, headers; body=jsonData)
end

"""
Try to gracefully handle errors.
"""
function handleError(ex::Any)::HTTP.Response
    @show ex
    io = IOBuffer()
    showerror(io, ex, catch_backtrace())
    err = String(take!(io))
    @error "Error! $err"
    msg = (:msg in fieldnames(typeof(ex)) ? ex.msg : err)
    return jsonReponse(msg; returnCode=400)
end

"""
Push a graph change notification.
"""
function _addGraphChangeNotification(userId::String, robotId::String, sessionId::String, isWholeGraph::Bool)::Bool
    conn = Main.App.NaviConfig.redisConnection
    if !Redis.is_connected(conn)
        # Reinvigorate connection
        @warn "[AQP] Redis connection failed - reestablishing a connection!"
        conn = Redis.RedisConnection(host=conn.host, port=conn.port, db=conn.db, password=conn.password)
        Main.App.NaviConfig.redisConnection = conn
    end

    # 2. Perform the transaction
    @info "Pushing graph change notification..."
    gc = Main.App.NaviConfig.GraphChange(userId, robotId, sessionId, isWholeGraph)
    Main.App.NaviConfig.addGraphChange(conn, gc)
    return true
end
