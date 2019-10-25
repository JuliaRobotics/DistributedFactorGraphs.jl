# Additional exports
export copySession!
# Please be careful with these
# With great power comes great "Oh crap, I deleted everything..."
export clearSession!!, clearRobot!!, clearUser!!


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
