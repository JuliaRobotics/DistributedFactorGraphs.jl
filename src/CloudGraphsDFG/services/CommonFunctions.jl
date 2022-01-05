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
    result = _queryNeo4j(neo4jInstance, query)
    nodeIds = map(node -> node["row"][1], result.results[1]["data"])
    return Symbol.(nodeIds)
end


"""
$(SIGNATURES)
Get a node property - returns nothing if not found
"""
function _getNodeProperty(neo4jInstance::Neo4jInstance, nodeLabels::Vector{String}, property::String; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    query = "match (n:$(join(nodeLabels, ":"))) return n.$property"
    result = _queryNeo4j(neo4jInstance, query, currentTransaction=currentTransaction)
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

Build a Cypher-compliant set of properies from a subnode type.
Note: Individual values are serialized if they are not already.
If the additional properties is provided, the additional
properties will be added in verbatim when serializing.

Returns: `::String`

Related

_Neo4jTo???
"""
function _structToNeo4jProps(inst::Union{<:User, <:Robot, <:Session, PVND, N, APPE, ABDE},
                            addProps::Dict{<:AbstractString, <:AbstractString}=Dict{String, String}();
                            cypherNodeName::String="subnode") where
        {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractDataEntry, PVND <: PackedVariableNodeData}
    props = Dict{String, String}()
    io = IOBuffer()
    for fieldname in fieldnames(typeof(inst))
        field = getfield(inst, fieldname)
        val = nothing
        # Neo4j type conversion if possible - keep timestamps timestamps, etc.
        if field isa ZonedDateTime
            val = "datetime(\"$(string(field))\")"
            # val = "datetime(\"$(Dates.format(field, "yyyy-mm-ddTHH:MM:SS.ssszzz"))\")"
        end
        if field isa UUID
            val = "\"$(string(field))\""
        end
        # TODO: Switch this to decorator pattern
        if inst isa DFGNode # typeof(inst) <: DFGNode
            # Variables
            fieldname == :solverDataDict && continue
            fieldname == :ppeDict && continue
            fieldname == :dataDict && continue
            if fieldname == :smallData
                packedJson = JSON2.write(field)
                val = "\"$(replace(packedJson, "\"" => "\\\""))\""
            end
            if fieldname == :solvable
                val = field.x
            end
            if fieldname == :nstime
                val = field.value
            end
            if fieldname == :variableType
                val = DistributedFactorGraphs.typeModuleName(getVariableType(inst))
            end
            # Factors
            # TODO: Consolidate with packFactor in Serialization.jl - https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/525
            if fieldname == :solverData
                fnctype = getSolverData(inst).fnc.usrfnc!
                val = _packSolverData( inst, fnctype; replaceBackslashes=true )
                # try
                #     packtype = convertPackedType(fnctype)
                #     packed = convert(PackedFunctionNodeData{packtype}, getSolverData(inst))
                #     packedJson = JSON2.write(packed)
                #     val = "\"$(replace(packedJson, "\"" => "\\\""))\"" # Escape slashes too
                # catch ex
                #     io = IOBuffer()
                #     showerror(io, ex, catch_backtrace())
                #     err = String(take!(io))
                #     msg = "Error while packing '$(inst.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
                #     error(msg)
                # end
                fieldname = :data #Keeping with FileDFG format
            end
        end
        # Fallback, default to JSON2
        if val === nothing
            val = JSON2.write(field)
        end
        write(io, "$cypherNodeName.$fieldname=$val,")
    end
    # The additional properties
    for (k, v) in addProps
        write(io, "$cypherNodeName.$k= $v,")
    end
    # Write in the version and node type
    write(io, "$cypherNodeName._version=\"$(_getDFGVersion())\"")
    # Ref String(): "When possible, the memory of v will be used without copying when the String object is created.
    # This is guaranteed to be the case for byte vectors returned by take!" 
    # Apparent replacement for takebuf_string()
    return String(take!(io))
end

"""
$(SIGNATURES)

Get the Neo4j labels for any node type.
"""
function _getLabelsForType(dfg::CloudGraphsDFG,
        type::Type;
        parentKey::Union{Nothing, Symbol}=nothing)
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
    type <: AbstractDataEntry &&
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
                            {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractDataEntry}
    labels = _getLabelsForType(dfg, typeof(inst), parentKey=parentKey)
    typeof(inst) <: DFGVariable && push!(labels, String(getLabel(inst)))
    typeof(inst) <: DFGFactor && push!(labels, String(getLabel(inst)))
    typeof(inst) <: AbstractPointParametricEst && push!(labels, String(inst.solveKey))
    typeof(inst) <: VariableNodeData && push!(labels, String(inst.solveKey))
    typeof(inst) <: AbstractDataEntry && push!(labels, String(inst.label))
    return labels
end

## Common CRUD calls for subnode types (PPEs, VariableSolverData, BigData)

function _listVarSubnodesForType(dfg::CloudGraphsDFG, variablekey::Symbol, dfgType::Type, keyToReturn::String; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
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
        {N <: DFGNode, APPE <: AbstractPointParametricEst, ABDE <: AbstractDataEntry, PVND <: PackedVariableNodeData}

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
    length(result.results[1]["data"]) != 1 && error("Cannot find subnode '$(ppe.solveKey)' for variable '$variablekey'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot find subnode '$(ppe.solveKey)' for variable '$variablekey'")
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
