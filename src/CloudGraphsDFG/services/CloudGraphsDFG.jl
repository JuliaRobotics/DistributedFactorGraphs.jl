
"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::CloudGraphsDFG)::CloudGraphsDFG
    count = 0
    sessionId = dfg.sessionId*"_$count"
    while true #do..while loop
        count += 1
        sessionId = dfg.sessionId*"_$count"
        _getNodeCount(dfg.neo4jInstance, [dfg.userId, dfg.robotId, sessionId]) == 0 && break
    end
    @debug "Unique+empty copy session name: $sessionId"
    return CloudGraphsDFG{typeof(dfg.solverParams)}(
        dfg.neo4jInstance.connection,
        dfg.userId,
        dfg.robotId,
        sessionId,
        dfg.description,
        solverParams=deepcopy(dfg.solverParams))
end

# Accessors
function getDescription(dfg::CloudGraphsDFG)
    return _getNodeProperty(
        dfg.neo4jInstance,
        [dfg.sessionId, dfg.robotId, dfg.userId, "SESSION"],
        "description")
end
function setDescription!(dfg::CloudGraphsDFG, description::String)
    count = _setNodeProperty(dfg.neo4jInstance,
                            [dfg.sessionId, dfg.robotId, dfg.userId, "SESSION"],
                            "description",
                            description)
    @assert(count == 1)
    dfg.description = description
    return getDescription(dfg)
end

##==============================================================================
## User/Robot/Session Data CRUD
##==============================================================================


function getUserData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
    propVal = _getNodeProperty(dfg.neo4jInstance, _getLabelsForType(dfg, User), "data")
    return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setUserData!(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Dict{Symbol, String}
    count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, "USER"], "data", base64encode(JSON2.write(data)))
    @assert(count == 1)
    return  getUserData(dfg)
end

function getRobotData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
    propVal = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"], "data")
    return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setRobotData!(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Dict{Symbol, String}
    count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, "ROBOT"], "data", base64encode(JSON2.write(data)))
    @assert(count == 1)
    return  getRobotData(dfg)
end

function getSessionData(dfg::CloudGraphsDFG)::Dict{Symbol, String}
    propVal = _getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"], "data")
    return JSON2.read(String(base64decode(propVal)), Dict{Symbol, String})
end
function setSessionData!(dfg::CloudGraphsDFG, data::Dict{Symbol, String})::Dict{Symbol, String}
    count = _setNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, "SESSION"], "data", base64encode(JSON2.write(data)))
    @assert(count == 1)
    return  getSessionData(dfg)
end

# New API
getUserData(dfg::CloudGraphsDFG, key::Symbol) = getUserData(dfg::CloudGraphsDFG)[key]
getRobotData(dfg::CloudGraphsDFG, key::Symbol)::String = getRobotData(dfg::CloudGraphsDFG)[key]
getSessionData(dfg::CloudGraphsDFG, key::Symbol)::String = getSessionData(dfg::CloudGraphsDFG)[key]

function updateUserData!(dfg::CloudGraphsDFG, pair::Pair{Symbol,String})
    data = getUserData(dfg::CloudGraphsDFG)
    push!(data, pair)
    setUserData!(dfg, data)
end

function updateRobotData!(dfg::CloudGraphsDFG, pair::Pair{Symbol,String})
    data = getRobotData(dfg::CloudGraphsDFG)
    push!(data, pair)
    setRobotData!(dfg, data)
end

function updateSessionData!(dfg::CloudGraphsDFG, pair::Pair{Symbol,String})
    data = getSessionData(dfg::CloudGraphsDFG)
    push!(data, pair)
    setSessionData!(dfg, data)
end

function deleteUserData!(dfg::CloudGraphsDFG, key::Symbol)
    data = getUserData(dfg::CloudGraphsDFG)
    delval = pop!(data, key)
    setUserData!(dfg, data)
    return delval
end

function deleteRobotData!(dfg::CloudGraphsDFG, key::Symbol)
    data = getRobotData(dfg::CloudGraphsDFG)
    delval = pop!(data, key)
    setRobotData!(dfg, data)
    return delval
end

function deleteSessionData!(dfg::CloudGraphsDFG, key::Symbol)
    data = getSessionData(dfg::CloudGraphsDFG)
    delval = pop!(data, key)
    setSessionData!(dfg, data)
    return delval
end


function emptyUserData!(dfg::CloudGraphsDFG)
    return setUserData!(dfg, Dict{Symbol, String}())
end

function emptyRobotData!(dfg::CloudGraphsDFG)
    return setRobotData!(dfg, Dict{Symbol, String}())
end

function emptySessionData!(dfg::CloudGraphsDFG)
    return setSessionData!(dfg, Dict{Symbol, String}())
end


##==============================================================================
## CRUD Interfaces
##==============================================================================
##------------------------------------------------------------------------------
## Variable And Factor CRUD
##------------------------------------------------------------------------------

function exists(dfg::CloudGraphsDFG, label::Symbol)
    # Otherwise try get it
    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, label)
    nodeId != nothing && return true
    return false
end
function exists(dfg::CloudGraphsDFG, node::N) where N <: DFGNode
    return exists(dfg, node.label)
end

isVariable(dfg::CloudGraphsDFG, sym::Symbol)::Bool =
    _getNodeCount(dfg.neo4jInstance, ["VARIABLE", dfg.userId, dfg.robotId, dfg.sessionId, String(sym)]) == 1

isFactor(dfg::CloudGraphsDFG, sym::Symbol)::Bool =
    _getNodeCount(dfg.neo4jInstance, ["FACTOR", dfg.userId, dfg.robotId, dfg.sessionId, String(sym)]) == 1

function addVariable!(dfg::CloudGraphsDFG, variable::DFGVariable)::DFGVariable
    if exists(dfg, variable)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end
    props = packVariable(dfg, variable)

    neo4jNode = Neo4j.createnode(dfg.neo4jInstance.graph, props);
    Neo4j.updatenodelabels(neo4jNode, union([string(variable.label), "VARIABLE", dfg.userId, dfg.robotId, dfg.sessionId], variable.tags))

    # Attach the node to the session sentinel.
    _bindSessionNodeToSessionData(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, string(variable.label))

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return variable
end


function addFactor!(dfg::CloudGraphsDFG, factor::DFGFactor)::DFGFactor
    if exists(dfg, factor)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end

    variableIds = factor._variableOrderSymbols
    variables = map(vId -> getVariable(dfg, vId), variableIds)

    # Construct the properties to save
    props = packFactor(dfg, factor)

    # TODO - Pack this into a transaction.
    neo4jNode = Neo4j.createnode(dfg.neo4jInstance.graph, props);
    Neo4j.updatenodelabels(neo4jNode, union([string(factor.label), "FACTOR", dfg.userId, dfg.robotId, dfg.sessionId], factor.tags))

    # Add all the relationships - get them to cache them + make sure the links are correct
    for variable in variables
        v = getVariable(dfg, variable.label)
        vNode = Neo4j.getnode(
            dfg.neo4jInstance.graph,
            _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, variable.label))
        Neo4j.createrel(neo4jNode, vNode, "FACTORGRAPH")
    end

    # Attach the node to the session sentinel.
    _bindSessionNodeToSessionData(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, string(factor.label))

    return factor
end

function getVariable(dfg::CloudGraphsDFG, label::Union{Symbol, String})::DFGVariable
    if typeof(label) == String
        label = Symbol(label)
    end
    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, label, nodeType="VARIABLE")
    if nodeId == nothing
        error("Unable to retrieve the ID for variable '$label'. Please check your connection to the database and that the variable exists.")
    end

    props = getnodeproperties(dfg.neo4jInstance.graph, nodeId)
    variable = unpackVariable(dfg, props)

    # TODO - make this get PPE's in batch
    for ppe in listPPEs(dfg, label)
        variable.ppeDict[ppe] = getPPE(dfg, label, ppe)
    end
    return variable
end

function getFactor(dfg::CloudGraphsDFG, label::Union{Symbol, String})::DFGFactor
    if typeof(label) == String
        label = Symbol(label)
    end
    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, label, nodeType="FACTOR")
    if nodeId == nothing
        error("Unable to retrieve the ID for factor '$label'. Please check your connection to the database and that the factor exists.")
    end

    props = getnodeproperties(dfg.neo4jInstance.graph, nodeId)
    factor = unpackFactor(dfg, props)

    # Lastly, rebuild the metadata
    factor = rebuildFactorMetadata!(dfg, factor)

    return factor
end

function updateVariable!(dfg::CloudGraphsDFG, variable::DFGVariable)::DFGVariable
    if !exists(dfg, variable)
        @warn "Variable label '$(variable.label)' does not exist in the factor graph, adding"
        return addVariable!(dfg, variable)
    end
    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, variable.label)

    # TODO: Do this with a single query and/or a single transaction.
    neo4jNode = Neo4j.getnode(dfg.neo4jInstance.graph, nodeId)
    props = packVariable(dfg, variable)
    Neo4j.updatenodeproperties(neo4jNode, props)
    Neo4j.updatenodelabels(neo4jNode, union([string(variable.label), "VARIABLE", dfg.userId, dfg.robotId, dfg.sessionId], variable.tags))
    return variable
end

function mergeVariableData!(dfg::CloudGraphsDFG, sourceVariable::DFGVariable)::DFGVariable
    if !exists(dfg, sourceVariable)
        error("Source variable '$(sourceVariable.label)' doesn't exist in the graph.")
    end
    for (k,v) in sourceVariable.ppeDict
        # TODO what is happening inside, is this truely an update or is it a merge? (API consistency hounds are apon you)
        updatePPE!(dfg, getLabel(sourceVariable), v, k)
    end
    for (k,v) in sourceVariable.solverDataDict
        updateVariableSolverData!(dfg, getLabel(sourceVariable), v, k)
    end
    return sourceVariable
end


function updateFactor!(dfg::CloudGraphsDFG, factor::DFGFactor)::DFGFactor
    if !exists(dfg, factor)
        @warn "Factor label '$(factor.label)' does not exist in the factor graph, adding"
        return addFactor!(dfg, factor)
    end

    neighborsList = JSON2.read(
        _getNodeProperty(dfg.neo4jInstance, _getLabelsForInst(dfg, factor), "_variableOrderSymbols"),
        Vector{Symbol})

    # Confirm that we're not updating the neighbors
    neighborsList != factor._variableOrderSymbols && error("Cannot update the factor, the neighbors are not the same.")

    # TODO: Optimize this as a single query with a single transaction.
    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance, dfg.userId, dfg.robotId, dfg.sessionId, factor.label)
    neo4jNode = Neo4j.getnode(dfg.neo4jInstance.graph, nodeId)
    props = packFactor(dfg, factor)
    Neo4j.updatenodeproperties(neo4jNode, props)
    Neo4j.updatenodelabels(neo4jNode, union([string(factor.label), "FACTOR", dfg.userId, dfg.robotId, dfg.sessionId], factor.tags))

    return factor
end

function deleteVariable!(dfg::CloudGraphsDFG, label::Symbol)#::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    variable = getVariable(dfg, label)
    if variable == nothing
        error("Unable to retrieve the ID for variable '$label'. Please check your connection to the database and that the variable exists.")
    end

    deleteNeighbors = true # reserved, orphaned factors are not supported at this time
    if deleteNeighbors
        neigfacs = map(l->deleteFactor!(dfg, l), getNeighbors(dfg, label))
    end

    # Perform detach+deletion
    _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:$label:$(join(_getLabelsForType(dfg, DFGVariable),':'))) detach delete node ")

    # Clearing history
    dfg.addHistory = symdiff(dfg.addHistory, [label])
    return variable, neigfacs
end

#Alias
deleteVariable!(dfg::CloudGraphsDFG, variable::DFGVariable) = deleteVariable!(dfg, variable.label)

function deleteFactor!(dfg::CloudGraphsDFG, label::Symbol)::DFGFactor
    factor = getFactor(dfg, label)
    if factor == nothing
        error("Unable to retrieve the ID for factor '$label'. Please check your connection to the database and that the factor exists.")
    end

    # Perform detach+deletion
    _getNeoNodesFromCyphonQuery(dfg.neo4jInstance, "(node:$label:$(join(_getLabelsForType(dfg, DFGFactor),':'))) detach delete node ")

    # Clearing history
    dfg.addHistory = symdiff(dfg.addHistory, [label])
    return factor
end

# Alias
deleteFactor!(dfg::CloudGraphsDFG, factor::DFGFactor)::DFGFactor = deleteFactor!(dfg, factor.label)

function getVariables(dfg::CloudGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{DFGVariable}
    variableIds = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
    # TODO: Optimize to use tags in query here!
    variables = map(vId->getVariable(dfg, vId), variableIds)
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, variables )
        return variables[mask]
    end
    return variables
end

function listVariables(dfg::CloudGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol}
    # Optimized for DB call
    tagsFilter = length(tags) > 0 ? " and "*join("node:".*String.(tags), " or ") : ""
    if regexFilter == nothing
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGVariable),':'))) where node.solvable >= $solvable $tagsFilter")
    else
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGVariable),':'))) where node.label =~ '$(regexFilter.pattern)' and node.solvable >= $solvable $tagsFilter")
    end
end

function getFactors(dfg::CloudGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{DFGFactor}
    # TODO: Use optimized cypher query.
    factorIds = listFactors(dfg, regexFilter, solvable=solvable)
    return map(vId->getFactor(dfg, vId), factorIds)
end

function listFactors(dfg::CloudGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol}
    # Optimized for DB call
    length(tags) > 0 && (@error "Filter on tags not implemented for CloudGraphsDFG")
    if regexFilter == nothing
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGFactor),':'))) where node.solvable >= $solvable")
    else
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGFactor),':'))) where node.label =~ '$(regexFilter.pattern)' and node.solvable >= $solvable")
    end
end

function isConnected(dfg::CloudGraphsDFG)::Bool
    # If the total number of nodes == total number of distinct connected nodes, then it is fully connected
    # Total nodes
    varIds = listVariables(dfg)
    factIds = listFactors(dfg)
    length(varIds) + length(factIds) == 0 && return false

    # Total distinct connected nodes - thank you Neo4j for 0..* awesomeness!!
    # TODO: Deprecated matching technique and it's technically an expensive call - optimize.
    query = """
        match (n:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(varIds[1]))-[FACTORGRAPH*]-(node:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId))
        WHERE (n:VARIABLE OR n:FACTOR OR node:VARIABLE OR node:FACTOR) and not (node:SESSION or n:SESSION) and not (n:PPE) and not (node:PPE)
        WITH collect(n)+collect(node) as nodelist
        unwind nodelist as nodes
        return count(distinct nodes)"""
    @debug "[Query] $query"
    result = _queryNeo4j(dfg.neo4jInstance, query)
    # Neo4j.jl data structure sometimes feels brittle... like below
    return result.results[1]["data"][1]["row"][1] == length(varIds) + length(factIds)
end

function getNeighbors(dfg::CloudGraphsDFG, node::T; solvable::Int=0)::Vector{Symbol}  where T <: DFGNode
    query = "(n:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(node.label))-[r:FACTORGRAPH]-(node) where (node:VARIABLE or node:FACTOR) and node.solvable >= $solvable"
    @debug "[Query] $query"
    neighbors = _getLabelsFromCyphonQuery(dfg.neo4jInstance, query)
    # If factor, need to do variable ordering TODO, Do we? does it matter if we always use _variableOrderSymbols in calculations?
    if T <: DFGFactor
        neighbors = intersect(node._variableOrderSymbols, neighbors)
    end
    return neighbors
end

function getNeighbors(dfg::CloudGraphsDFG, label::Symbol; solvable::Int=0)::Vector{Symbol}
    query = "(n:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(label))-[r:FACTORGRAPH]-(node) where (node:VARIABLE or node:FACTOR) and node.solvable >= $solvable"
    @debug "[Query] $query"
    neighbors = _getLabelsFromCyphonQuery(dfg.neo4jInstance, query)
    # If factor, need to do variable ordering TODO, Do we? does it matter if we always use _variableOrderSymbols in calculations?
    if isFactor(dfg, label)
        # Server is authority
        serverOrder = Symbol.(JSON2.read(_getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, String(label)], "_variableOrderSymbols")))
        neighbors = intersect(serverOrder, neighbors)
    end
    return neighbors
end

function getSubgraphAroundNode(dfg::CloudGraphsDFG, node::DFGNode, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::AbstractDFG=_getDuplicatedEmptyDFG(dfg); solvable::Int=0)::AbstractDFG
    distance < 1 && error("getSubgraphAroundNode() only works for distance > 0")

    # Thank you Neo4j for 0..* awesomeness!!
    neighborList = _getLabelsFromCyphonQuery(dfg.neo4jInstance,
        """
        (n:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(node.label))-[FACTORGRAPH*0..$distance]-(node:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId))
        WHERE (n:VARIABLE OR n:FACTOR OR node:VARIABLE OR node:FACTOR)
        and not (node:SESSION)
        and (node.solvable >= $solvable or node:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(node.label))""" # Always return the root node
        )

    # Copy the section of graph we want
    _copyIntoGraph!(dfg, addToDFG, neighborList, includeOrphanFactors)
    return addToDFG
end


function getSubgraph(dfg::CloudGraphsDFG,
                     variableFactorLabels::Vector{Symbol},
                     includeOrphanFactors::Bool=false,
                     addToDFG::G=_getDuplicatedEmptyDFG(dfg) )::G where {G <: AbstractDFG}
    # Making a copy session if not specified

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)

    return addToDFG
end

function getBiadjacencyMatrix(dfg::CloudGraphsDFG; solvable::Int=0)::NamedTuple{(:B, :varLabels, :facLabels),Tuple{SparseMatrixCSC,Vector{Symbol}, Vector{Symbol}}}
    varLabels = listVariables(dfg, solvable=solvable)
    factLabels = listFactors(dfg, solvable=solvable)
    vDict = Dict(varLabels .=> [1:length(varLabels)...])
    fDict = Dict(factLabels .=> [1:length(factLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    # Now ask for all relationships for this session graph
    loadtx = transaction(dfg.neo4jInstance.connection)
    query = """
    START n=node(*)
    MATCH (n:$(join(_getLabelsForType(dfg, DFGVariable),':')))-[r:FACTORGRAPH]-(m:$(join(_getLabelsForType(dfg, DFGFactor),':')))
    where n.solvable >= $solvable and m.solvable >= $solvable
    RETURN n.label as variable, m.label as factor;"""
    @debug "[Query] $query"
    nodes = loadtx(query; submit=true)
    # Have to finish the transaction
    commit(loadtx)
    if length(nodes.errors) > 0
        error(string(nodes.errors))
    end
    # Add in the relationships
    varRel = Symbol.(map(node -> node["row"][1], nodes.results[1]["data"]))
    factRel = Symbol.(map(node -> node["row"][2], nodes.results[1]["data"]))
    for i = 1:length(varRel)
        adjMat[fDict[factRel[i]], vDict[varRel[i]]] = 1
    end

    return (B=adjMat, varLabels=varLabels, facLabels=factLabels)
end

### PPEs with DB calls

function listVarSubnodesForType(dfg::CloudGraphsDFG, variablekey::Symbol, dfgType::Type, keyToReturn::String; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    query = "match (ppe:$(join(_getLabelsForType(dfg, dfgType, parentKey=variablekey),':'))) return ppe.$keyToReturn"
    @debug "[Query] listVarSubnodesForType query:\r\n$query"
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

function getVarSubnodeProperties(dfg::CloudGraphsDFG, variablekey::Symbol, dfgType::Type, nodeKey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    query = "match (node:$(join(_getLabelsForType(dfg, dfgType, parentKey=variablekey),':')):$nodeKey) return properties(node)"
    @debug "[Query] getVarSubnodeProperties query:\r\n$query"
    result = nothing
    if currentTransaction != nothing
        result = currentTransaction(query; submit=true)
    else
        tx = transaction(dfg.neo4jInstance.connection)
        tx(query)
        result = commit(tx)
    end
    length(result.errors) > 0 && error(string(result.errors))
    length(result.results[1]["data"]) != 1 && error("Cannot find PPE '$nodeKey' for variable '$variablekey'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot find PPE '$nodeKey' for variable '$variablekey'")
    return result.results[1]["data"][1]["row"][1]
end

function _matchmergeVarSubnode!(
        dfg::CloudGraphsDFG,
        variablekey::Symbol,
        packedProperties::Dict{String, Any},
        relationshipKey::Symbol,
        nodeLabels::Vector{String},
        nodeKey::Symbol=:default;
        currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    query = """
                MATCH (var:$variablekey:$(join(_getLabelsForType(dfg, DFGVariable, parentKey=variablekey),':')))
                MERGE (subnode:$(join(nodeLabels,':')))
                SET subnode = $(_dictToNeo4jProps(packedProperties))
                CREATE UNIQUE (var)-[:$relationshipKey]->(subnode)
                RETURN properties(subnode)"""
    @debug "[Query] _matchmergeVarSubnode! query:\r\n$query"
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
    match (node:$nodekey:$(join(nodeLabels,':')))
    with node, properties(node) as props
    detach delete node
    return props
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

function listPPEs(dfg::CloudGraphsDFG, variablekey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    return listVarSubnodesForType(dfg, variablekey, MeanMaxPPE, "solverKey"; currentTransaction=currentTransaction)
end

function getPPE(dfg::CloudGraphsDFG, variablekey::Symbol, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::AbstractPointParametricEst
    properties = getVarSubnodeProperties(dfg, variablekey, MeanMaxPPE, ppekey; currentTransaction=currentTransaction)
    return unpackPPE(dfg, properties)
end

function listVariableSolverData(dfg::CloudGraphsDFG, variablekey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    return listVarSubnodesForType(dfg, variablekey, VariableNodeData, "solverKey"; currentTransaction=currentTransaction)
end

function getVariableSolverData(dfg::CloudGraphsDFG, variablekey::Symbol, solverkey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    properties = getVarSubnodeProperties(dfg, variablekey, VariableNodeData, solverkey; currentTransaction=currentTransaction)
    return unpackVariableNodeData(dfg, properties)
end


function addPPE!(dfg::CloudGraphsDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::AbstractPointParametricEst where P <: AbstractPointParametricEst
    if ppekey in listPPEs(dfg, variablekey, currentTransaction=currentTransaction)
        error("PPE '$(ppekey)' already exists")
    end
    return unpackPPE(dfg, _matchmergeVarSubnode!(
        dfg,
        variablekey,
        packPPE(dfg, ppe),
        :PPE,
        _getLabelsForInst(dfg, ppe, parentKey=variablekey),
        ppekey,
        currentTransaction=currentTransaction))
end

function addVariableSolverData!(dfg::CloudGraphsDFG,
                                variablekey::Symbol,
                                vnd::VariableNodeData,
                                solvekey::Symbol=:default;
                                currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    if solvekey in listVariableSolverData(dfg, variablekey, currentTransaction=currentTransaction)
        error("Solver data '$(solvekey)' already exists")
    end
    return unpackVariableNodeData(dfg, _matchmergeVarSubnode!(
        dfg,
        variablekey,
        packVariableNodeData(dfg, vnd),
        :SOLVERDATA,
        _getLabelsForInst(dfg, vnd, parentKey=variablekey),
        solvekey,
        currentTransaction=currentTransaction))
end

function updatePPE!(dfg::CloudGraphsDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::P where P <: AbstractPointParametricEst
    if !(ppekey in listPPEs(dfg, variablekey, currentTransaction=currentTransaction))
        @warn "PPE '$(ppekey)' does not exist, adding"
    end
    return unpackPPE(dfg, _matchmergeVarSubnode!(
        dfg,
        variablekey,
        packPPE(dfg, ppe),
        :PPE,
        _getLabelsForInst(dfg, ppe, parentKey=variablekey),
        ppekey,
        currentTransaction=currentTransaction))
end

function updatePPE!(dfg::CloudGraphsDFG, sourceVariables::Vector{<:DFGVariable}, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    tx = currentTransaction == nothing ? transaction(dfg.neo4jInstance.connection) : currentTransaction
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(var, ppekey), ppekey, currentTransaction=tx)
    end
    if currentTransaction == nothing
        result = commit(tx)
    end
    return nothing
end

function deletePPE!(dfg::CloudGraphsDFG, variablekey::Symbol, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::AbstractPointParametricEst
    props = _deleteVarSubnode!(
        dfg,
        variablekey,
        :PPE,
        _getLabelsForType(dfg, MeanMaxPPE, parentKey=variablekey),
        ppekey,
        currentTransaction=currentTransaction)
    return unpackPPE(dfg, props)
end

### Updated functions from AbstractDFG
### These functions write back as you add the data.

# function addVariableSolverData!(dfg::CloudGraphsDFG,
#                                 variablekey::Symbol,
#                                 vnd::VariableNodeData,
#                                 solvekey::Symbol=:default)::VariableNodeData
#     # TODO: Switch out to their own nodes, don't get the whole variable
#     var = getVariable(dfg, variablekey)
#     if haskey(var.solverDataDict, solvekey)
#         error("VariableNodeData '$(solvekey)' already exists")
#     end
#     var.solverDataDict[solvekey] = vnd
#
#     # TODO: Cleanup and consolidate as one function.
#     solverDataDict = JSON2.write(Dict(keys(var.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(var.solverDataDict))))
#     _setNodeProperty(
#         dfg.neo4jInstance,
#         _getLabelsForInst(dfg, var),
#         "solverDataDict",
#         solverDataDict)
#     return vnd
# end

function updateVariableSolverData!(dfg::CloudGraphsDFG,
                                   variablekey::Symbol,
                                   vnd::VariableNodeData,
                                   solvekey::Symbol=:default,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[])::VariableNodeData
    # TODO: Switch out to their own nodes, don't get the whole variable
    var = getVariable(dfg, variablekey)
    if !haskey(var.solverDataDict, solvekey)
        @warn "VariableNodeData '$(solvekey)' does not exist, adding"
    end

    # Unnecessary for cloud, but (probably) being (too) conservative (just because).
    usevnd = useCopy ? deepcopy(vnd) : vnd
    # should just one, or many pointers be updated?
    if haskey(var.solverDataDict, solvekey) && isa(var.solverDataDict[solvekey], VariableNodeData) && length(fields) != 0
      # change multiple pointers inside the VND var.solverDataDict[solvekey]
      for field in fields
        destField = getfield(var.solverDataDict[solvekey], field)
        srcField = getfield(usevnd, field)
        if isa(destField, Array) && size(destField) == size(srcField)
          # use broadcast (in-place operation)
          destField .= srcField
        else
          # change pointer of destination VND object member
          setfield!(var.solverDataDict[solvekey], field, srcField)
        end
      end
    else
      # change a single pointer in var.solverDataDict
      var.solverDataDict[solvekey] = usevnd
    end

    # TODO: Cleanup and consolidate
    solverDataDict = JSON2.write(Dict(keys(var.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(var.solverDataDict))))
    _setNodeProperty(
        dfg.neo4jInstance,
        _getLabelsForInst(dfg, var),
        "solverDataDict",
        solverDataDict)
    return var.solverDataDict[solvekey]
end

function updateVariableSolverData!(dfg::CloudGraphsDFG,
                                   sourceVariables::Vector{<:DFGVariable},
                                   solvekey::Symbol=:default,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[] )
    # TODO: Switch out to their own nodes, don't get the whole variable
    #TODO: Do in bulk for speed.
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solvekey), solvekey, useCopy, fields)
    end
end

function deleteVariableSolverData!(dfg::CloudGraphsDFG, variablekey::Symbol, solvekey::Symbol=:default)::VariableNodeData
    # TODO: Switch out to their own nodes, don't get the whole variable
    var = getVariable(dfg, variablekey)

    if !haskey(var.solverDataDict, solvekey)
        error("VariableNodeData '$(solvekey)' does not exist")
    end
    vnd = pop!(var.solverDataDict, solvekey)
    # TODO: Cleanup and consolidate... yadda yadda just do it already :)
    solverDataDict = JSON2.write(Dict(keys(var.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(var.solverDataDict))))
    _setNodeProperty(
        dfg.neo4jInstance,
        _getLabelsForInst(dfg, var),
        "solverDataDict",
        solverDataDict)
    return vnd
end

function mergeVariableSolverData!(dfg::CloudGraphsDFG, sourceVariable::DFGVariable)
    # TODO: Switch out to their own nodes, don't get the whole variable
    var = getVariable(dfg, sourceVariable.label)

    merge!(var.solverDataDict, deepcopy(sourceVariable.solverDataDict))

    # TODO: Cleanup and consolidate
    solverDataDict = JSON2.write(Dict(keys(var.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(var.solverDataDict))))
    _setNodeProperty(
        dfg.neo4jInstance,
        _getLabelsForInst(dfg, var),
        "solverDataDict",
        solverDataDict)
    return var
end

function getSolvable(dfg::CloudGraphsDFG, sym::Symbol)
    prop = _getNodeProperty(
        dfg.neo4jInstance,
        union(_getLabelsForType(dfg, isVariable(dfg, sym) ? DFGVariable : DFGFactor),[String(sym)]),
        "solvable")
    return prop
end

function setSolvable!(dfg::CloudGraphsDFG, sym::Symbol, solvable::Int)::Int
    prop = _setNodeProperty(
        dfg.neo4jInstance,
        union(_getLabelsForType(dfg, isVariable(dfg, sym) ? DFGVariable : DFGFactor),[String(sym)]),
        "solvable",
        solvable)
    return solvable
end


##==============================================================================
## TAGS as a set, list, merge, remove, empty
## CloudGraphsDFG functions
##==============================================================================
function mergeTags!(dfg::CloudGraphsDFG, sym::Symbol, tags::Vector{Symbol})

    if isVariable(dfg,sym)
        getNode = getVariable
        updateNode! = updateVariable!
    else
        getNode = getFactor
        updateNode! = updateFactor!
    end

    node = getNode(dfg, sym)
    union!(getTags(node), tags)

    updateNode!(dfg, node)

    return getTags(getNode(dfg, sym))

end

function removeTags!(dfg::CloudGraphsDFG, sym::Symbol, tags::Vector{Symbol})

    if isVariable(dfg,sym)
        getNode = getVariable
        updateNode! = updateVariable!
    else
        getNode = getFactor
        updateNode! = updateFactor!
    end

    node = getNode(dfg, sym)
    setdiff!(getTags(node), tags)

    updateNode!(dfg, node)

    return getTags(getNode(dfg, sym))

end

function emptyTags!(dfg::CloudGraphsDFG, sym::Symbol)

    if isVariable(dfg,sym)
        getNode = getVariable
        updateNode! = updateVariable!
    else
        getNode = getFactor
        updateNode! = updateFactor!
    end

    node = getNode(dfg, sym)
    empty!(getTags(node))

    updateNode!(dfg, node)

    return getTags(getNode(dfg, sym))

end



function RESERVED_mergeTags!(dfg::CloudGraphsDFG, sym::Symbol, tags::Vector{Symbol})

    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance,
                                            dfg.userId,
                                            dfg.robotId,
                                            dfg.sessionId,
                                            sym)

    neo4jNode = Neo4j.getnode(dfg.neo4jInstance.graph, nodeId)

    addnodelabels(neo4jNode, string.(tags))

    return Set(setdiff(Symbol.(getnodelabels(neo4jNode)), Symbol.([dfg.userId, dfg.robotId, dfg.sessionId]), [sym]))

end


function RESERVED_removeTags!(dfg::CloudGraphsDFG, sym::Symbol, tags::Vector{Symbol})

    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance,
                                            dfg.userId,
                                            dfg.robotId,
                                            dfg.sessionId,
                                            sym)

    neo4jNode = Neo4j.getnode(dfg.neo4jInstance.graph, nodeId)

    shouldStay = Symbol.([dfg.userId, dfg.robotId, dfg.sessionId]) ∪ [sym, :VARIABLE, :FACTOR]

    for tag in tags
        if tag in shouldStay
            @warn("Label:$tag is not allowed to be removed from tags and will be ignored.")
        else
            deletenodelabel(neo4jNode, string(tag))
        end
    end

    return Set(setdiff(Symbol.(getnodelabels(neo4jNode)), shouldStay))

end


function RESERVED_emptyTags!(dfg::CloudGraphsDFG, sym::Symbol)

    nodeId = _tryGetNeoNodeIdFromNodeLabel(dfg.neo4jInstance,
                                            dfg.userId,
                                            dfg.robotId,
                                            dfg.sessionId,
                                            sym)

    neo4jNode = Neo4j.getnode(dfg.neo4jInstance.graph, nodeId)

    shouldStay = Symbol.([dfg.userId, dfg.robotId, dfg.sessionId]) ∪ [sym, :VARIABLE, :FACTOR]
    tags = setdiff(Symbol.(getnodelabels(neo4jNode)), shouldStay)
    # tags = Symbol.(getnodelabels(neo4jNode))

    return removeTags!(dfg, sym, tags)
end
