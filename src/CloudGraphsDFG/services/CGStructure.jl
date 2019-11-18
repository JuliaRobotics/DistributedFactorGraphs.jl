# Additional exports
export copySession!
# Please be careful with these
# With great power comes great "Oh crap, I deleted everything..."
export clearSession!!, clearRobot!!, clearUser!!
export createSession, createRobot, createUser, createDfgSessionIfNotExist
export existsSession, existsRobot, existsUser
export getSession, getRobot, getUser
export updateSession, updateRobot, updateUser
export lsSessions, lsRobots, lsUsers

global _invalidIds = ["USER", "ROBOT", "SESSION", "VARIABLE", "FACTOR", "ENVIRONMENT", "PPE", "BIGDATA"]
global _validLabelRegex = r"^[a-zA-Z]\w*$"

function _isValid(id::Union{Symbol, String})::Bool
	if typeof(id) == Symbol
		id = String(id)
	end
	return all(t -> t != uppercase(id), _invalidIds) && match(_validLabelRegex, id) != nothing
end

function _isValid(abstractNode::N)::Bool where N <: AbstractCGNode
	id = String(abstractNode.id)
	return all(t -> t != uppercase(id), _invalidIds) && match(_validLabelRegex, id) != nothing
end

# Fastest way I can think to convert the data into a dict
#TODO: Probably should be made more efficient...definitely should be made more efficient
function _convertNodeToDict(abstractNode::N)::Dict{String, Any} where N <: AbstractCGNode
	cp = deepcopy(abstractNode)
	data = length(cp.data) != 0 ? JSON2.write(cp.data) : "{}"
	ser = JSON2.read(JSON2.write(abstractNode), Dict{String, Any})
	ser["data"] = base64encode(data)
	return ser
end

#TODO: Refactor, #HACK :D (but it works!)
function _convertDictToSession(dict::Dict{String, Any})::Session
	data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
	session = Session(
		Symbol(dict["id"]),
		Symbol(dict["robotId"]),
		Symbol(dict["userId"]),
		dict["name"],
		dict["description"],
		data)
	return session
end
#TODO: Refactor, #HACK :D (but it works!)
function _convertDictToRobot(dict::Dict{String, Any})::Robot
	data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
	robot = Robot(
		Symbol(dict["id"]),
		Symbol(dict["userId"]),
		dict["name"],
		dict["description"],
		data)
	return robot
end
#TODO: Refactor, #HACK :D (but it works!)
function _convertDictToUser(dict::Dict{String, Any})::User
	data = JSON2.read(String(base64decode(dict["data"])), Dict{Symbol, String})
	user = User(
		Symbol(dict["id"]),
		dict["name"],
		dict["description"],
		data)
	return user
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

"""
$(SIGNATURES)
Shortcut method to create the user, robot, and session if it doesn't already exist.
"""
function createDfgSessionIfNotExist(dfg::CloudGraphsDFG)::Session
	strip(dfg.userId) == "" && error("User ID is not populated in DFG.")
	strip(dfg.robotId) == "" && error("Robot ID is not populated in DFG.")
	strip(dfg.sessionId) == "" && error("Session ID is not populated in DFG.")
	user = User(Symbol(dfg.userId), dfg.userId, "Description for $(dfg.userId)", Dict{Symbol, String}())
	robot = Robot(Symbol(dfg.robotId), Symbol(dfg.userId), dfg.robotId, "Description for $(dfg.userId):$(dfg.robotId)", Dict{Symbol, String}())
	session = Session(Symbol(dfg.sessionId), Symbol(dfg.robotId), Symbol(dfg.userId), dfg.sessionId, "Description for $(dfg.userId):$(dfg.robotId):$(dfg.sessionId)", Dict{Symbol, String}())

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
"""
function lsSessions(dfg::CloudGraphsDFG)::Vector{Session}
	sessionNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:$(dfg.robotId):$(dfg.userId))")
	return map(s -> _convertDictToSession(Neo4j.getnodeproperties(s)), sessionNodes)
end

"""
$(SIGNATURES)
List all robots for the specified DFG's user.
Returns nothing if it isn't found.
"""
function lsRobots(dfg::CloudGraphsDFG)::Vector{Robot}
	robotNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:$(dfg.userId))")
	return map(s -> _convertDictToRobot(Neo4j.getnodeproperties(s)), robotNodes)
end

"""
$(SIGNATURES)
List all users.
Returns nothing if it isn't found.
"""
function lsUsers(dfg::CloudGraphsDFG)::Vector{User}
	userNodes = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER)")
	return map(s -> _convertDictToUser(Neo4j.getnodeproperties(s)), userNodes)
end

"""
$(SIGNATURES)
Get a session specified by userId:robotId:sessionId.
Returns nothing if it isn't found.
"""
function getSession(dfg::CloudGraphsDFG, userId::Symbol, robotId::Symbol, sessionId::Symbol)::Union{Session, Nothing}
	!_isValid(userId) && error("Can't receive session with user ID '$(userId)'.")
	!_isValid(robotId) && error("Can't receive session with robot ID '$(robotId)'.")
	!_isValid(sessionId) && error("Can't receive session with session ID '$(sessionId)'.")
	sessionNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:SESSION:$(sessionId):$(robotId):$(userId))")
	length(sessionNode) == 0 && return nothing
	length(sessionNode) > 1 && error("There look to be $(length(sessionNode)) sessions identified for $(sessionId):$(robotId):$(userId)")
	return _convertDictToSession(Neo4j.getnodeproperties(sessionNode[1]))
end

"""
$(SIGNATURES)
Get the session specified by the DFG object.
Returns nothing if it isn't found.
"""
function getSession(dfg::CloudGraphsDFG)::Union{Nothing, Session}
	return getSession(dfg, Symbol(dfg.userId), Symbol(dfg.robotId), Symbol(dfg.sessionId))
end

"""
$(SIGNATURES)
Get a robot specified by userId:robotId.
Returns nothing if it isn't found.
"""
function getRobot(dfg::CloudGraphsDFG, userId::Symbol, robotId::Symbol)::Union{Robot, Nothing}
	!_isValid(userId) && error("Can't receive session with user ID '$(userId)'.")
	!_isValid(robotId) && error("Can't receive session with robot ID '$(robotId)'.")
	robotNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:ROBOT:$(robotId):$(userId))")
	length(robotNode) == 0 && return nothing
	length(robotNode) > 1 && error("There look to be $(length(robotNode)) robots identified for $(robotId):$(userId)")
	return _convertDictToRobot(Neo4j.getnodeproperties(robotNode[1]))
end

"""
$(SIGNATURES)
Get the robot specified by the DFG object.
Returns nothing if it isn't found.
"""
function getRobot(dfg::CloudGraphsDFG)::Union{Nothing, Robot}
	return getRobot(dfg, Symbol(dfg.userId), Symbol(dfg.robotId))
end

"""
$(SIGNATURES)
Get a user specified by userId.
Returns nothing if it isn't found.
"""
function getUser(dfg::CloudGraphsDFG, userId::Symbol)::Union{User, Nothing}
	!_isValid(userId) && error("Can't receive session with user ID '$(userId)'.")
	userNode = _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:USER:$(userId))")
	length(userNode) == 0 && return nothing
	length(userNode) > 1 && error("There look to be $(length(userNode)) robots identified for $(userId)")
	return _convertDictToUser(Neo4j.getnodeproperties(userNode[1]))
end

"""
$(SIGNATURES)
Get the user specified by the DFG object.
Returns nothing if it isn't found.
"""
function getUser(dfg::CloudGraphsDFG)::Union{Nothing, User}
	return getUser(dfg, Symbol(dfg.userId))
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


function getUserData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
	propVal = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, "USER"], "data")
	return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setUserData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, "USER"], "data", base64encode(JSON2.write(data)))
	return count == 1
end
function getRobotData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
	propVal = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"], "data")
	return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setRobotData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"], "data", base64encode(JSON2.write(data)))
	return count == 1
end
function getSessionData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
	propVal = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"], "data")
	return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setSessionData(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Bool
	count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"], "data", base64encode(JSON2.write(data)))
	return count == 1
end
