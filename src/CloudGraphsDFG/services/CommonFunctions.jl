alphaOnlyMatchRegex = r"^[a-zA-Z0-9_]*$"

"""
$(SIGNATURES)
Returns the transaction for a given query.
NOTE: Must commit(transaction) after you're done.
"""
function _queryNeo4j(neo4jInstance::Neo4jInstance, query::String; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    @debug "[Query] $(currentTransaction != nothing ? "[TRANSACTION]" : "") $query"
    if currentTransaction == nothing
        loadtx = transaction(neo4jInstance.connection)
        loadtx(query)
        # Have to finish the transaction
        result = commit(loadtx)
    else
        result = currentTransaction(query; submit=true)
    end
    length(result.errors) > 0 && error(string(result.errors))
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

function _getNodeCount(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String}; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Int
    query = "match (n:$(join(nodeLabels, ":"))) return count(n)"
    result = _queryNeo4j(neo4jInstance, query, currentTransaction=currentTransaction)
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
function _getNeoNodesFromCyphonQuery(neo4jInstance::Neo4jInstance, matchCondition::String, orderProperty::String=""; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Neo4j.Node}
    # TODO: Burn this function to the ground.
    # 2. Perform the transaction
    query = "match $matchCondition return id(node) $(orderProperty != "" ? "order by node.$orderProperty" : "")";
    result = _queryNeo4j(neo4jInstance, query, currentTransaction=currentTransaction)
    if length(result.errors) > 0
        error(string(nodes.errors))
    end
    # 3. Format the result
    # TODO: Fix, this is awful.
    nodes = map(node -> getnode(neo4jInstance.graph, node["row"][1]), result.results[1]["data"])
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
Try get a Neo4j node ID from a node label.
"""
function _tryGetNeoNodeIdFromNodeLabel(
        neo4jInstance::Neo4jInstance,
        userId::String, robotId::String, sessionId::String,
        nodeLabel::Symbol;
        nodeType::Union{Nothing, String}=nothing,
        currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Union{Nothing, Int}
    @debug "Looking up symbolic node ID where n.label = '$nodeLabel'..."
    if nodeType == nothing
        nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:$userId:$robotId:$sessionId) where exists(node.label) and node.label = \"$(string(nodeLabel))\"", currentTransaction=currentTransaction)
    else
        nodes = _getNeoNodesFromCyphonQuery(neo4jInstance, "(node:$nodeType:$userId:$robotId:$sessionId) where exists(node.label) and node.label = \"$(string(nodeLabel))\"", currentTransaction=currentTransaction)
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

Build a Cypher-compliant set of properies from a subnode type.
Note: Individual values are serialized if they are not already.
If the additional properties is provided, the additional
properties will be added in verbatim when serializing.
"""
function _structToNeo4jProps(inst::Union{User, Robot, Session, PVND, N, APPE, ABDE},
                             addProps::Dict{String, String}=Dict{String, String}();
                             cypherNodeName::String="subnode")::String where
        {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractBigDataEntry, PVND <: PackedVariableNodeData}
    props = Dict{String, String}()
    io = IOBuffer()
    for fieldname in fieldnames(typeof(inst))
        field = getfield(inst, fieldname)
        val = nothing
        # Neo4j type conversion if possible - keep timestamps timestamps, etc.
        if field isa DateTime
            val = "datetime(\"$(string(ZonedDateTime(field, tz"UTC")))\")"
        else
            val = JSON2.write(field)
        end
        # TODO: Switch this to decorator pattern
        if typeof(inst) <: DFGNode
            fieldname == :solverDataDict && continue
            fieldname == :ppeDict && continue
            fieldname == :bigData && continue
            if fieldname == :smallData
                val = "\"$(JSON2.write(inst.smallData))\""
            end
            if fieldname == :solvable
                val = field.x
            end
            if fieldname == :nstime
                val = field.value
            end
            if fieldname == :softtype
                val = string(typeof(getSofttype(inst)))
            end
        end
        write(io, "$cypherNodeName.$fieldname=$val,")
    end
    # The additional properties
    for (k, v) in addProps
        write(io, "$cypherNodeName.$k= $v,")
    end
    # The node type
    write(io, "$cypherNodeName._type=\"$(typeof(inst))\"")
    # Ref String(): "When possible, the memory of v will be used without copying when the String object is created.
    # This is guaranteed to be the case for byte vectors returned by take!" # Apparent replacement for takebuf_string()
    return String(take!(io))
end

"""
$(SIGNATURES)

Get the Neo4j labels for any node type.
"""
function _getLabelsForType(dfg::CloudGraphsDFG,
        type::Type;
        parentKey::Union{Nothing, Symbol}=nothing)::Vector{String}
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
                            inst::Union{User, Robot, Session, VariableNodeData, N, APPE, ABDE};
                            parentKey::Union{Nothing, Symbol}=nothing)::Vector{String} where
                            {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractBigDataEntry}
    labels = _getLabelsForType(dfg, typeof(inst), parentKey=parentKey)
    typeof(inst) <: DFGVariable && push!(labels, String(getLabel(inst)))
    typeof(inst) <: DFGFactor && push!(labels, String(getLabel(inst)))
    typeof(inst) <: AbstractPointParametricEst && push!(labels, String(inst.solverKey))
    typeof(inst) <: VariableNodeData && push!(labels, String(inst.solverKey))
    typeof(inst) <: AbstractBigDataEntry && push!(labels, String(inst.key))
    return labels
end

## Common CRUD calls for subnode types (PPEs, VariableSolverData, BigData)

function _listVarSubnodesForType(dfg::CloudGraphsDFG, variablekey::Symbol, dfgType::Type, keyToReturn::String; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    query = "match (subnode:$(join(_getLabelsForType(dfg, dfgType, parentKey=variablekey),':'))) return subnode.$keyToReturn"
    @debug "[Query] _listVarSubnodesForType query:\r\n$query"
    result = nothing
    if currentTransaction != nothing
        result = currentTransaction(query; submit=true)
    else
        tx = transaction(dfg.neo4jInstance.connection)
        tx(query)
        result = commit(tx)
    end
    length(result.errors) > 0 && error(string(result.errors))
    vals = map(d -> d["row"][1], result.results[1]["data"])
    return Symbol.(vals)
end

function _getVarSubnodeProperties(dfg::CloudGraphsDFG, variablekey::Symbol, dfgType::Type, nodeKey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    query = "match (subnode:$(join(_getLabelsForType(dfg, dfgType, parentKey=variablekey),':')):$nodeKey) return properties(subnode)"
    @debug "[Query] _getVarSubnodeProperties query:\r\n$query"
    result = nothing
    if currentTransaction != nothing
        result = currentTransaction(query; submit=true)
    else
        tx = transaction(dfg.neo4jInstance.connection)
        tx(query)
        result = commit(tx)
    end
    length(result.errors) > 0 && error(string(result.errors))
    length(result.results[1]["data"]) != 1 && error("Cannot find subnode '$nodeKey' for variable '$variablekey'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot find subnode '$nodeKey' for variable '$variablekey'")
    return result.results[1]["data"][1]["row"][1]
end

function _matchmergeVariableSubnode!(
        dfg::CloudGraphsDFG,
        variablekey::Symbol,
        nodeLabels::Vector{String},
        subnode::Union{APPE, ABDE, PVND},
        relationshipKey::Symbol;
        addProps::Dict{String, String}=Dict{String, String}(),
        currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing) where
        {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractBigDataEntry, PVND <: PackedVariableNodeData}

    query = """
                MATCH (var:$variablekey:$(join(_getLabelsForType(dfg, DFGVariable, parentKey=variablekey),':')))
                MERGE (var)-[:$relationshipKey]->(subnode:$(join(nodeLabels,':')))
                ON CREATE SET $(_structToNeo4jProps(subnode, addProps))
                ON MATCH SET $(_structToNeo4jProps(subnode, addProps))
                RETURN properties(subnode)"""
    @debug "[Query] _matchmergeVariableSubnode! query:\r\n$query"
    result = nothing
    if currentTransaction != nothing
        result = currentTransaction(query; submit=true) # TODO: Maybe we should submit (; submit = true) for the results to fail early?
    else
        tx = transaction(dfg.neo4jInstance.connection)
        tx(query)
        result = commit(tx)
    end
    length(result.errors) > 0 && error(string(result.errors))
    length(result.results[1]["data"]) != 1 && error("Cannot find subnode '$(ppe.solverKey)' for variable '$variablekey'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot find subnode '$(ppe.solverKey)' for variable '$variablekey'")
    return result.results[1]["data"][1]["row"][1]
end

function _deleteVarSubnode!(
        dfg::CloudGraphsDFG,
        variablekey::Symbol,
        relationshipKey::Symbol,
        nodeLabels::Vector{String},
        nodekey::Symbol=:default;
        currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    query = """
    MATCH (node:$nodekey:$(join(nodeLabels,':')))
    WITH node, properties(node) as props
    DETACH DELETE node
    RETURN props
    """
    @debug "[Query] _deleteVarSubnode delete query:\r\n$query"
    result = nothing
    if currentTransaction != nothing
        result = currentTransaction(query; submit=true) # TODO: Maybe we should submit (; submit = true) for the results to fail early?
    else
        tx = transaction(dfg.neo4jInstance.connection)
        tx(query)
        result = commit(tx)
    end
    length(result.errors) > 0 && error(string(result.errors))
    length(result.results[1]["data"]) != 1 && error("Cannot find subnode '$nodekey' for variable '$variablekey'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot find subnode '$nodekey' for variable '$variablekey'")
    return result.results[1]["data"][1]["row"][1]
end
