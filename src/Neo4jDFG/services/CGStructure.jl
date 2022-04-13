# return ::Bool
function isValidLabel(abstractNode::N) where N <: AbstractCGNode
    id = String(abstractNode.id)
    return all(t -> t != uppercase(id), _invalidIds) && match(_validLabelRegex, id) !== nothing
end

# Fastest way I can think to convert the data into a dict
#TODO: Probably should be made more efficient...definitely should be made more efficient
#  return ::Dict{String, Any}
function _convertNodeToDict(abstractNode::N) where N <: AbstractCGNode
    cp = deepcopy(abstractNode)
    data = length(cp.data) != 0 ? JSON2.write(cp.data) : "{}"
    ser = JSON2.read(JSON2.write(abstractNode), Dict{String, Any})
    ser["data"] = base64encode(data)
    ser["_version"] = _getDFGVersion()
    return ser
end

#TODO: Refactor, #HACK :D (but it works!)
# return ::Session
function _convertDictToSession(dict::Dict{String, Any})
    data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
    session = Session(
        Symbol(dict["id"]),
        Symbol(dict["robotId"]),
        Symbol(dict["userId"]),
        dict["name"],
        dict["description"],
        data,
        dict["createdTimestamp"],
        dict["lastUpdatedTimestamp"])
    return session
end
#TODO: Refactor, #HACK :D (but it works!)
# returns ::Robot
function _convertDictToRobot(dict::Dict{String, Any})
    data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
    robot = Robot(
        Symbol(dict["id"]),
        Symbol(dict["userId"]),
        dict["name"],
        dict["description"],
        data,
        dict["createdTimestamp"],
        dict["lastUpdatedTimestamp"])
    return robot
end
#TODO: Refactor, #HACK :D (but it works!)
# returns ::User
function _convertDictToUser(dict::Dict{String, Any})
    data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
    user = User(
        Symbol(dict["id"]),
        dict["name"],
        dict["description"],
        data,
        dict["createdTimestamp"],
        dict["lastUpdatedTimestamp"])
    return user
end

# returns ::User
function createUser(dfg::Neo4jDFG, user::User)
    Symbol(dfg.userId) != user.id && error("DFG user ID must match user's ID")
    !isValidLabel(user) && error("Node cannot have an ID '$(user.id)'.")

    props = _convertNodeToDict(user)
    # TODO: Switch to _queryNeo4j
    retNode = _createNode(dfg.neo4jInstance, ["USER", String(user.id)], props, nothing)
    return user
end

# returns ::Robot
function createRobot(dfg::Neo4jDFG, robot::Robot)
    Symbol(dfg.robotId) != robot.id && error("DFG robot ID must match robot's ID")
    Symbol(dfg.userId) != robot.userId && error("DFG user ID must match robot's user ID")
    !isValidLabel(robot) && error("Node cannot have an ID '$(robot.id)'.")

    # Find the parent
    parents = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER:`$(dfg.userId)`)")
    length(parents) == 0 && error("Cannot find user '$(dfg.userId)'")
    length(parents) > 1 && error("Found multiple users '$(dfg.userId)'")

    # Already exists?
    length(_getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:`$(dfg.userId)`:`$(robot.id)`)")) != 0 &&
        error("Robot '$(robot.id)' already exists for user '$(robot.userId)'")

    props = _convertNodeToDict(robot)
    # TODO: Switch to _queryNeo4j
    retNode = _createNode(dfg.neo4jInstance, ["ROBOT", String(robot.userId), String(robot.id)], props, parents[1], :ROBOT)
    return robot
end

# returns ::Session
function createSession(dfg::Neo4jDFG, session::Session)
    Symbol(dfg.robotId) != session.robotId && error("DFG robot ID must match session's robot ID")
    Symbol(dfg.userId) != session.userId && error("DFG user ID must match session's->robot's->user ID")
    !isValidLabel(session) && error("Node cannot have an ID '$(session.id)'.")

    # Find the parent
    parents = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:`$(dfg.robotId)`:`$(dfg.userId)`)")
    length(parents) == 0 && error("Cannot find robot '$(dfg.robotId)' for user '$(dfg.userId)'")
    length(parents) > 1 && error("Found multiple robots '$(dfg.robotId)' for user '$(dfg.userId)'")

    # Already exists?
    length(_getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:`$(session.userId)`:`$(session.robotId)`:`$(session.id)`)")) != 0 &&
        error("Session '$(session.id)' already exists for robot '$(session.robotId)' and user '$(session.userId)'")

    props = _convertNodeToDict(session)
    # TODO: Switch to _queryNeo4j
    retNode = _createNode(dfg.neo4jInstance, ["SESSION", String(session.userId), String(session.robotId), String(session.id)], props, parents[1], :SESSION)
    return session
end

"""
$(SIGNATURES)
Shortcut method to create the user, robot, and session if it doesn't already exist.

Notes
- return `::Session`
"""
function createDfgSessionIfNotExist(dfg::Neo4jDFG)
    strip(dfg.userId) == "" && error("User ID is not populated in DFG.")
    strip(dfg.robotId) == "" && error("Robot ID is not populated in DFG.")
    strip(dfg.sessionId) == "" && error("Session ID is not populated in DFG.")
    user = User(Symbol(dfg.userId), dfg.userId, "Description for $(dfg.userId)", Dict{Symbol, String}())
    robot = Robot(Symbol(dfg.robotId), Symbol(dfg.userId), dfg.robotId, "Description for $(dfg.userId):$(dfg.robotId)", Dict{Symbol, String}())
    session = Session(Symbol(dfg.sessionId), Symbol(dfg.robotId), Symbol(dfg.userId), dfg.sessionId, dfg.description, Dict{Symbol, String}())

    _getNodeCount(dfg.neo4jInstance, [dfg.userId, "USER"]) == 0 && createUser(dfg, user)
    _getNodeCount(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"]) == 0 && createRobot(dfg, robot)
    if _getNodeCount(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"]) == 0
        return createSession(dfg, session)
    else
        return getSession(dfg)
    end
end

"""
$(SIGNATURES)
List all sessions for the specified DFG's robot and user.
Returns nothing if it isn't found.

Notes
- Returns `Vector{Session}`
"""
function lsSessions(dfg::Neo4jDFG)
    sessionNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:`$(dfg.robotId)`:`$(dfg.userId)`)")
    return map(s -> _convertDictToSession(Neo4j.getnodeproperties(s)), sessionNodes)
end

"""
$(SIGNATURES)
List all robots for the specified DFG's user.
Returns nothing if it isn't found.

Notes
- Returns `::Vector{Robot}`
"""
function lsRobots(dfg::Neo4jDFG)
    robotNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:`$(dfg.userId)`)")
    return map(s -> _convertDictToRobot(Neo4j.getnodeproperties(s)), robotNodes)
end

"""
$(SIGNATURES)
List all users.
Returns nothing if it isn't found.

Notes
- Returns `::Vector{User}`
"""
function lsUsers(dfg::Neo4jDFG)
    userNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER)")
    return map(s -> _convertDictToUser(Neo4j.getnodeproperties(s)), userNodes)
end

"""
$(SIGNATURES)
Get a session specified by userId:robotId:sessionId.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{Session, Nothing}`
"""
function getSession(dfg::Neo4jDFG, userId::Symbol, robotId::Symbol, sessionId::Symbol)
    !isValidLabel(userId) && error("Can't retrieve session with user ID '$(userId)'.")
    !isValidLabel(robotId) && error("Can't retrieve session with robot ID '$(robotId)'.")
    !isValidLabel(sessionId) && error("Can't retrieve session with session ID '$(sessionId)'.")
    sessionNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:`$(sessionId)`:`$(robotId)`:`$(userId)`)")
    length(sessionNode) == 0 && return nothing
    length(sessionNode) > 1 && error("There look to be $(length(sessionNode)) sessions identified for $(sessionId):$(robotId):$(userId)")
    return _convertDictToSession(Neo4j.getnodeproperties(sessionNode[1]))
end

"""
$(SIGNATURES)
Get the session specified by the DFG object.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{Nothing, Session}`
"""
function getSession(dfg::Neo4jDFG)
    return getSession(dfg, Symbol(dfg.userId), Symbol(dfg.robotId), Symbol(dfg.sessionId))
end

"""
$(SIGNATURES)
Get a robot specified by userId:robotId.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{Robot, Nothing}`
"""
function getRobot(dfg::Neo4jDFG, userId::Symbol, robotId::Symbol)
    !isValidLabel(userId) && error("Can't retrieve robot with user ID '$(userId)'.")
    !isValidLabel(robotId) && error("Can't retrieve robot with robot ID '$(robotId)'.")
    robotNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:`$(robotId)`:`$(userId)`)")
    length(robotNode) == 0 && return nothing
    length(robotNode) > 1 && error("There look to be $(length(robotNode)) robots identified for $(robotId):$(userId)")
    return _convertDictToRobot(Neo4j.getnodeproperties(robotNode[1]))
end

"""
$(SIGNATURES)
Get the robot specified by the DFG object.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{Nothing, Robot}`
"""
function getRobot(dfg::Neo4jDFG)
    return getRobot(dfg, Symbol(dfg.userId), Symbol(dfg.robotId))
end

"""
$(SIGNATURES)
Get a user specified by userId.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{User, Nothing}`
"""
function getUser(dfg::Neo4jDFG, userId::Symbol)
    !isValidLabel(userId) && error("Can't retrieve user with user ID '$(userId)'.")
    userNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER:`$(userId)`)")
    length(userNode) == 0 && return nothing
    length(userNode) > 1 && error("There look to be $(length(userNode)) robots identified for $(userId)")
    return _convertDictToUser(Neo4j.getnodeproperties(userNode[1]))
end

"""
$(SIGNATURES)
Get the user specified by the DFG object.
Returns nothing if it isn't found.

Notes
- Returns either `::Union{Nothing, User}`
"""
function getUser(dfg::Neo4jDFG)
    return getUser(dfg, Symbol(dfg.userId))
end


"""
    $(SIGNATURES)
DANGER: Clears the whole session from the database.

Notes
- Returns `::Nothing`
"""
function clearSession!!(dfg::Neo4jDFG)
    # Perform detach+deletion
    _queryNeo4j(dfg.neo4jInstance, "match (node:`$(dfg.userId)`:`$(dfg.robotId)`:`$(dfg.sessionId)`) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Clears the whole robot + sessions from the database.

Notes
- Returns `::Nothing`
"""
function clearRobot!!(dfg::Neo4jDFG)
    # Perform detach+deletion
    _queryNeo4j(dfg.neo4jInstance, "match (node:`$(dfg.userId)`:`$(dfg.robotId)`) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Clears the whole user + robot + sessions from the database.

Notes
- Returns `::Nothing`
"""
function clearUser!!(dfg::Neo4jDFG)
    # Perform detach+deletion
    _queryNeo4j(dfg.neo4jInstance, "match (node:`$(dfg.userId)`) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Copies and overwrites the destination session.
If no destination specified then it creates a unique one.

Notes
- Returns `::Neo4jDFG `
"""
function copySession!(sourceDFG::Neo4jDFG, destDFG::Union{Nothing, <:Neo4jDFG})
    if destDFG == nothing
        destDFG = _getDuplicatedEmptyDFG(sourceDFG)
    end
    _copyIntoGraph!(sourceDFG, destDFG, union(listVariables(sourceDFG), listFactors(sourceDFG)), true)
    return destDFG
end
"""
    $(SIGNATURES)
DANGER: Copies the source to a new unique destination.

Notes
- Returns `::Neo4jDFG`
"""
copySession!(sourceDFG::Neo4jDFG) = copySession!(sourceDFG, nothing)
