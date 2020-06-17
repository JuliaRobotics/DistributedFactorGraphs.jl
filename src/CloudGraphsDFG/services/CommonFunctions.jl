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
Create a node and optionally specify a parent.
Note: Using symbols so that the labels obey Neo4j requirements
"""
function _createNode(neo4jInstance::Neo4jInstance, labels::Vector{String}, properties::Dict{String, Any}, parentNode::Union{Nothing, Neo4j.Node}, relationshipLabel::Symbol=:NOTHING)::Neo4j.Node
    createdNode = Neo4j.createnode(neo4jInstance.graph, properties)
    addnodelabels(createdNode, labels)
    parentNode == nothing && return createdNode
    # Otherwise create the relationship
    createrel(parentNode, createdNode, String(relationshipLabel))
    return createdNode
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
    @debug "[Query] $query"
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
    @debug "[Query] $query"
    result = _queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && error("No data returned from the query.")
    length(result.results[1]["data"][1]["row"]) != 1 && error("No data returned from the query.")
    return result.results[1]["data"][1]["row"][1]
end

"""
$(SIGNATURES)
Set a node property - returns count of changed nodes.
"""
function _setNodeProperty(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String}, property::String, value::Union{String, Int, Float64})
    if value isa String
        value = "\""*replace(value, "\"" => "\\\"")*"\"" # Escape strings
    end
    query = """
    match (n:$(join(nodeLabels, ":")))
    set n.$property = $value
    return count(n)"""
    @debug "[Query] $query"
    result = _queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && return 0
    length(result.results[1]["data"][1]["row"]) != 1 && return 0
    return result.results[1]["data"][1]["row"][1]
end

"""
$(SIGNATURES)
Get a node's tags
"""
function _getNodeTags(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String})::Union{Nothing, Vector{String}}
    query = "match (n:$(join(nodeLabels, ":"))) return labels(n)"
    result = _queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && return nothing
    return result.results[1]["data"][1]["row"][1]
end

function _getNodeCount(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String})::Int
    query = "match (n:$(join(nodeLabels, ":"))) return count(n)"
    result = _queryNeo4j(neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && return 0
    length(result.results[1]["data"][1]["row"]) != 1 && return 0
    return result.results[1]["data"][1]["row"][1]
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
Utility function to get a Neo4j node sessions for a robot.
"""
function _getSessionNeoNodesForRobot(neo4jInstance::Neo4jInstance, userId::String, robotId::String)::Vector{Neo4j.Node}
    # 2. Perform the transaction
    nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(u:USER:$userId)-[:ROBOT]->(r:ROBOT:$robotId)-[:SESSION]->(node:SESSION)", "id")
    return nodes
end

"""
$(SIGNATURES)
Bind the SESSION node to the variable or factor.
Checks for existence.
"""
function _bindSessionNodeToSessionData(neo4jInstance::Neo4jInstance, userId::String, robotId::String, sessionId::String, nodeLabel::String)::Nothing
    # 2. Perform the transaction
    loadtx = transaction(neo4jInstance.connection)
    query = """
    match (session:SESSION:$userId:$robotId:$sessionId),
    (n:$userId:$robotId:$sessionId:$nodeLabel
    {label: '$nodeLabel'})
    WHERE NOT (session)-[:SESSIONDATA]->()
    CREATE (session)-[:SESSIONDATA]->(n) return id(n)
    """;
    loadtx(query; submit=true)
    commit(loadtx)
    return nothing
end

"""
$(SIGNATURES)
Try get a Neo4j node ID from a node label.
"""
function _tryGetNeoNodeIdFromNodeLabel(neo4jInstance::Neo4jInstance, userId::String, robotId::String, sessionId::String, nodeLabel::Symbol; nodeType::Union{Nothing, String}=nothing)::Union{Nothing, Int}
    @debug "Looking up symbolic node ID where n.label = '$nodeLabel'..."
    if nodeType == nothing
        nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:$userId:$robotId:$sessionId) where exists(node.label) and node.label = \"$(string(nodeLabel))\"")
    else
        nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:$nodeType:$userId:$robotId:$sessionId) where exists(node.label) and node.label = \"$(string(nodeLabel))\"")
    end

    if length(nodes) != 1
        return nothing
    end
    nodeId = nodes[1].id
    @debug "Found NeoNode ID = $nodeId..."
    return nodeId
end

"""
$(SIGNATURES)
Gets the searchable labels for any CGDFG type.
"""

"""
$(SIGNATURES)

Build a Cypher-compliant set of properies from a JSON dictionary.
Note individual values are serialized if they are not already.
"""
function _dictToNeo4jProps(dict::Dict{String, Any})::String
    # TODO: Use an IO buffer/stream for this
    return "{" * join(map((k) -> "$k: $(JSON.json(dict[k]))", collect(keys(dict))), ", ")*"}"
end

"""
$(SIGNATURES)

Get the Neo4j labels for any node type.
"""
function _getLabelsForType(dfg::CloudGraphsDFG, type::Type; parentKey::Union{Nothing, Symbol}=nothing)::Vector{String}
    # Simple validation
    isempty(dfg.userId) && error("The DFG object's userID is empty, please specify a user ID.")
    isempty(dfg.robotId) && error("The DFG object's robotID is empty, please specify a robot ID.")
    isempty(dfg.sessionId) && error("The DFG object's sessionId is empty, please specify a session ID.")

    labels = []
    type == User && (labels = [dfg.userId, "USER"])
    type == Robot && (labels = [dfg.userId, dfg.robotId, "ROBOT"])
    type == Session && (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"])
    type <: DFGVariable &&
        (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "VARIABLE"])
    type <: DFGFactor &&
        (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "FACTOR"])
    type <: AbstractPointParametricEst &&
        (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "PPE"])
    type <: VariableNodeData &&
        (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "SOLVERDATA"])
    type <: AbstractBigDataEntry &&
        (labels = [dfg.userId, dfg.robotId, dfg.sessionId, "DATA"])
    # Some are children of nodes, so add that in if it's set.
    parentKey != nothing && push!(labels, String(parentKey))
    return labels
end

"""
$(SIGNATURES)

Get the Neo4j labels for any node instance.
"""
function _getLabelsForInst(dfg::CloudGraphsDFG,
                            inst::Union{User, Robot, Session, N, APPE, ABDE, AVND}; parentKey::Union{Nothing, Symbol}=nothing)::Vector{String} where
                            {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractBigDataEntry, AVND <: VariableNodeData}
    labels = _getLabelsForType(dfg, typeof(inst), parentKey=parentKey)
    typeof(inst) <: DFGVariable && push!(labels, String(getLabel(inst)))
    typeof(inst) <: DFGFactor && push!(labels, String(getLabel(inst)))
    typeof(inst) <: AbstractPointParametricEst && push!(labels, String(inst.solverKey))
    # typeof(inst) <: VariableNodeData && push!(labels, String(inst.solverKey))
    typeof(inst) <: AbstractBigDataEntry && push!(labels, String(inst.key))
    return labels
end
