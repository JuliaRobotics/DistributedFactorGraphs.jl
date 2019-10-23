# Additional exports
export copySession!
# Please be careful with these
# With great power comes great "Oh crap, I deleted everything..."
export clearSession!!, clearRobot!!, clearUser!!
export createSession, createRobot, createUser
export existsSession, existsRobot, existsUser
export getSession, getRobot, getUser
export updateSession, updateRobot, updateUser
export listSessions, listRobots, listUsers

function _isValid(abstractNode::N)::Bool where N <: AbstractCGNode
	invalidIds = ["USER", "ROBOT", "SESSION", "VARIABLE", "FACTOR", "ENVIRONMENT"]
	return all(t -> t != uppercase(String(abstractNode.id)), invalidIds)
end

# Fastest way I can think to convert the data into a dict
#TODO: Probably should be made more efficient...definitely should be made more efficient
function _convertNodeToDict(abstractNode::N)::Dict{String, Any} where N <: AbstractCGNode
	cp = deepcopy(abstractNode)
	data = length(cp.data) != 0 ? JSON2.write(cp.data) : "{}"
	ser = JSON2.read(JSON2.write(abstractNode), Dict{String, Any})
	ser["data"] = data
	return ser
end

#TODO: Refactor, #HACK :D (but it works!)
function _convertDictToSession(dict::Dict{String, Any})::Session
	sessionData = JSON2.read(dict["data"], Dict{Symbol, String})
	session = Session(
		Symbol(dict["id"]),
		Symbol(dict["robotId"]),
		Symbol(dict["userId"]),
		dict["name"],
		dict["description"],
		sessionData)
	return session
end

function createUser(dfg::CloudGraphsDFG, user::User)::User
	Symbol(dfg.userId) != user.id && error("DFG user ID must match user's ID")
	!_isValid(user) && error("Node cannot have an ID '$(user.id)'.")

	props = _convertNodeToDict(user)
	retNode = _createNode(dfg.neo4jInstance, ["USER", String(user.id)], props, nothing)
	return user
end

function createRobot(dfg::CloudGraphsDFG, robot::Robot)::Robot
	Symbol(dfg.robotId) != robot.id && error("DFG robot ID must match robot's ID")
	Symbol(dfg.userId) != robot.userId && error("DFG user ID must match robot's user ID")
	!_isValid(robot) && error("Node cannot have an ID '$(robot.id)'.")

	# Find the parent
	parents = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER:$(dfg.userId))")
	length(parents) == 0 && error("Cannot find user '$(dfg.userId)'")
	length(parents) > 1 && error("Found multiple users '$(dfg.userId)'")

	# Already exists?
	length(_getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:$(dfg.userId):$(robot.id))")) != 0 &&
		error("Robot '$(robot.id)' already exists for user '$(robot.userId)'")

	props = _convertNodeToDict(robot)
	retNode = _createNode(dfg.neo4jInstance, ["ROBOT", String(robot.userId), String(robot.id)], props, parents[1], :ROBOT)
	return robot
end

function createSession(dfg::CloudGraphsDFG, session::Session)::Session
	Symbol(dfg.robotId) != session.robotId && error("DFG robot ID must match session's robot ID")
	Symbol(dfg.userId) != session.userId && error("DFG user ID must match session's->robot's->user ID")
	!_isValid(session) && error("Node cannot have an ID '$(session.id)'.")

	# Find the parent
	parents = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:$(dfg.robotId):$(dfg.userId))")
	length(parents) == 0 && error("Cannot find robot '$(dfg.robotId)' for user '$(dfg.userId)'")
	length(parents) > 1 && error("Found multiple robots '$(dfg.robotId)' for user '$(dfg.userId)'")

	# Already exists?
	length(_getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:$(session.userId):$(session.robotId):$(session.id))")) != 0 &&
		error("Session '$(session.id)' already exists for robot '$(session.robotId)' and user '$(session.userId)'")

	props = _convertNodeToDict(session)
	retNode = _createNode(dfg.neo4jInstance, ["SESSION", String(session.userId), String(session.robotId), String(session.id)], props, parents[1], :SESSION)
	return session
end

function listSessions(dfg::CloudGraphsDFG)::Vector{Session}
	sessionNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:$(dfg.robotId):$(dfg.userId))")
	return map(s -> _convertDictToSession(Neo4j.getnodeproperties(s)), sessionNodes)
end

"""
    $(SIGNATURES)
DANGER: Clears the whole session from the database.
"""
function clearSession!!(dfg::CloudGraphsDFG)::Nothing
    # Perform detach+deletion
    _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId)) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    empty!(dfg.variableCache)
    empty!(dfg.factorCache)
    empty!(dfg.labelDict)
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Clears the whole robot + sessions from the database.
"""
function clearRobot!!(dfg::CloudGraphsDFG)::Nothing
    # Perform detach+deletion
    _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:$(dfg.userId):$(dfg.robotId)) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    empty!(dfg.variableCache)
    empty!(dfg.factorCache)
    empty!(dfg.labelDict)
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Clears the whole user + robot + sessions from the database.
"""
function clearUser!!(dfg::CloudGraphsDFG)::Nothing
    # Perform detach+deletion
    _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:$(dfg.userId)) detach delete node ")

    # Clearing history
    dfg.addHistory = Symbol[]
    empty!(dfg.variableCache)
    empty!(dfg.factorCache)
    empty!(dfg.labelDict)
    return nothing
end

"""
    $(SIGNATURES)
DANGER: Copies and overwrites the destination session.
If no destination specified then it creates a unique one.
"""
function copySession!(sourceDFG::CloudGraphsDFG, destDFG::Union{Nothing, CloudGraphsDFG})::CloudGraphsDFG
    if destDFG == nothing
        destDFG = _getDuplicatedEmptyDFG(sourceDFG)
    end
    _copyIntoGraph!(sourceDFG, destDFG, union(getVariableIds(sourceDFG), getFactorIds(sourceDFG)), true)
    return destDFG
end
"""
    $(SIGNATURES)
DANGER: Copies the source to a new unique destination.
"""
copySession!(sourceDFG::CloudGraphsDFG)::CloudGraphsDFG = copySession!(sourceDFG, nothing)


getUserData(dfg::CloudGraphsDFG)::Dict{Symbol, String} = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, "USER"])
function setUserData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	error("Not implemented yet")
	return true
end
getRobotData(dfg::CloudGraphsDFG)::Dict{Symbol, String} = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"])
function setRobotData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	error("Not implemented yet")
	return true
end
getSessionData(dfg::CloudGraphsDFG)::Dict{Symbol, String} = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"])
function setSessionData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	error("Not implemented yet")
	return true
end
