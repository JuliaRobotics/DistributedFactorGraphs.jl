
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

function exists(dfg::CloudGraphsDFG, label::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    return _getNodeCount(dfg.neo4jInstance, String.([dfg.userId, dfg.robotId, dfg.sessionId, label]), currentTransaction=currentTransaction) > 0
end
function exists(dfg::CloudGraphsDFG, node::N; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing) where N <: DFGNode
    return exists(dfg, node.label, currentTransaction=currentTransaction)
end

isVariable(dfg::CloudGraphsDFG, sym::Symbol)::Bool =
    _getNodeCount(dfg.neo4jInstance, ["VARIABLE", dfg.userId, dfg.robotId, dfg.sessionId, String(sym)]) == 1

isFactor(dfg::CloudGraphsDFG, sym::Symbol)::Bool =
    _getNodeCount(dfg.neo4jInstance, ["FACTOR", dfg.userId, dfg.robotId, dfg.sessionId, String(sym)]) == 1

#Optimization
function getVariableType(dfg::CloudGraphsDFG, lbl::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    st = _getNodeProperty(dfg.neo4jInstance, union(_getLabelsForType(dfg, DFGVariable), [String(lbl)]), "variableType", currentTransaction=currentTransaction)
    @debug "Trying to find variableType: $st"
    variableType = getTypeFromSerializationModule(st)
    return variableType()
end

function addVariable!(dfg::CloudGraphsDFG, variable::DFGVariable)
    if exists(dfg, variable)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end

    ret = updateVariable!(dfg, variable, warn_if_absent=false)

    # Do a variable update
    return ret
end

function updateVariable!(dfg::CloudGraphsDFG, variable::DFGVariable; warn_if_absent::Bool=true)
    exist = exists(dfg, variable)
    warn_if_absent && !exist && @warn "Variable label '$(variable.label)' does not exist in the factor graph, adding"

    # Create/update the base variable
    # NOTE: We are not merging the variable.tags into the labels anymore. We can index by that but not
    # going to pollute the graph with unnecessary (and potentially dangerous) labels.
    addProps = Dict("variableType" => "\"$(DistributedFactorGraphs.typeModuleName(getVariableType(variable)))\"")
    query = """
    MATCH (session:$(join(_getLabelsForType(dfg, Session), ":")))
    MERGE (node:$(join(_getLabelsForInst(dfg, variable), ":")))
    ON CREATE SET $(_structToNeo4jProps(variable, addProps, cypherNodeName="node"))
    ON MATCH SET $(_structToNeo4jProps(variable, addProps, cypherNodeName="node"))
    MERGE (node)<-[:SESSIONDATA]-(session)
    RETURN node
    """

    # Start the transaction
    tx = transaction(dfg.neo4jInstance.connection)
    try
        result = _queryNeo4j(dfg.neo4jInstance, query, currentTransaction=tx)
        # On merge we may not get data back.
        # length(result.results[1]["data"]) != 1 && error("Cannot update or add variable '$(getLabel(variable))'")
        # length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot update or add variable '$(getLabel(variable))'")

        # Merge the PPE's, SolverData, and BigData
        mergeVariableData!(dfg, variable; currentTransaction=tx, warn_if_absent=false)

        commit(tx)
    catch ex
        @warn "Rolling back transaction because of error: $(string(ex))"
        rollback(tx)
        throw(ex)
    end

    if !exist
        # Track insertion
        push!(dfg.addHistory, variable.label)
    end

    return variable
end

function addFactor!(dfg::CloudGraphsDFG, factor::DFGFactor)
    # TODO: Refactor
    if exists(dfg, factor)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end

    # Do a variable update
    return updateFactor!(dfg, factor, warn_if_absent=false)
end

function getVariable(dfg::CloudGraphsDFG, label::Union{Symbol, String})
    query = "MATCH (node:$(join(_getLabelsForType(dfg, DFGVariable, parentKey=label), ":"))) return properties(node)"
    result = _queryNeo4j(dfg.neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && error("Cannot get variable '$label'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot get variable '$label'")
    props = result.results[1]["data"][1]["row"][1]

    variable = unpackVariable(dfg, props, unpackPPEs=false, unpackSolverData=false, unpackBigData=false)

    # TODO - make this get PPE's and solverdata in batch
    for ppe in listPPEs(dfg, label)
        variable.ppeDict[ppe] = getPPE(dfg, label, ppe)
    end
    for solveKey in listVariableSolverData(dfg, label)
        variable.solverDataDict[solveKey] = getVariableSolverData(dfg, label, solveKey)
    end
    dataSet = getDataEntries(dfg, label)
    for v in dataSet
        variable.dataDict[v.label] = v
    end

    return variable
end

function mergeVariableData!(dfg::CloudGraphsDFG, sourceVariable::DFGVariable; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing, warn_if_absent::Bool=true)
    if warn_if_absent && !exists(dfg, sourceVariable, currentTransaction=currentTransaction)
        error("Source variable '$(sourceVariable.label)' doesn't exist in the graph.")
    end
    for (k,v) in sourceVariable.ppeDict
        updatePPE!(dfg, getLabel(sourceVariable), v, currentTransaction=currentTransaction)
    end
    for (k,v) in sourceVariable.solverDataDict
        updateVariableSolverData!(dfg, getLabel(sourceVariable), v, currentTransaction=currentTransaction)
    end
    for (k,v) in sourceVariable.dataDict
        updateDataEntry!(dfg, getLabel(sourceVariable), v, currentTransaction=currentTransaction)
    end
    return sourceVariable
end

function getFactor(dfg::CloudGraphsDFG, label::Union{Symbol, String})
    query = "MATCH (node:$(join(_getLabelsForType(dfg, DFGFactor, parentKey=label), ":"))) return properties(node)"
    result = _queryNeo4j(dfg.neo4jInstance, query)
    length(result.results[1]["data"]) != 1 && error("Cannot get factor '$label'")
    length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot get factor '$label'")
    props = result.results[1]["data"][1]["row"][1]

    return rebuildFactorMetadata!(dfg, unpackFactor(dfg, props))
end

function updateFactor!(dfg::CloudGraphsDFG, factor::DFGFactor; warn_if_absent::Bool=true)
    exist = exists(dfg, factor)
    warn_if_absent && !exist && @warn "Factor label '$(factor.label)' does not exist in the factor graph, adding"

    if exist
        # Check that the neighbors are the same
        neighborsList = Symbol.(
            _getNodeProperty(dfg.neo4jInstance, _getLabelsForInst(dfg, factor), "_variableOrderSymbols"))
        # Confirm that we're not updating the neighbors
        neighborsList != factor._variableOrderSymbols && error("Cannot update the factor, the neighbors are not the same.")
    end

    # Check that all variables exist
    for vlabel in factor._variableOrderSymbols
        !exists(dfg, vlabel) && error("Variable '$(vlabel)' not found in graph when creating Factor '$(factor.label)'")
    end

    props = packFactor(dfg, factor)

    # Create/update the factor
    # NOTE: We are no merging the factor tags into the labels anymore. We can index by that but not
    # going to pollute the graph with unnecessary (and potentially dangerous) labels.
    fnctype = getSolverData(factor).fnc.usrfnc!
    addProps = Dict(
        "fnctype" => "\"$(String(_getname(fnctype)))\"")
    query = """
    MATCH (session:$(join(_getLabelsForType(dfg, Session), ":")))
    MERGE (node:$(join(_getLabelsForInst(dfg, factor), ":")))
    ON CREATE SET $(_structToNeo4jProps(factor, addProps, cypherNodeName="node"))
    ON MATCH SET $(_structToNeo4jProps(factor, addProps, cypherNodeName="node"))
    MERGE (node)<-[:SESSIONDATA]-(session)
    RETURN node
    """
    @debug "[Query] updateFactor! query:\r\n$query"

    tx = transaction(dfg.neo4jInstance.connection)
    try
        result = _queryNeo4j(dfg.neo4jInstance, query, currentTransaction=tx)
        # On return we may not get data if it already exists.
        # length(result.results[1]["data"]) != 1 && error("Cannot update or add factor '$(getLabel(factor))'")
        # length(result.results[1]["data"][1]["row"]) != 1 && error("Cannot update or add facator '$(getLabel(factor))'")

        # Create the relationships to the variables
        query = """
        MATCH (factor:$(join(_getLabelsForInst(dfg, factor), ":"))),
        (var:$(join(_getLabelsForType(dfg, DFGVariable), ":")))
        where var.label in [$(join(map(v->"\"$v\"", factor._variableOrderSymbols), ","))]
        MERGE (factor)<-[:FACTORGRAPH]-(var)
        RETURN factor
        """
        result = _queryNeo4j(dfg.neo4jInstance, query, currentTransaction=tx)

        commit(tx)
    catch ex
        @warn "Rolling back transaction because of error: $(string(ex))"
        rollback(tx)
        throw(ex)
    end

    return factor
end

function deleteVariable!(dfg::CloudGraphsDFG, label::Symbol)#::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    variable = getVariable(dfg, label)
    if variable == nothing
        error("Unable to retrieve the ID for variable '$label'. Please check your connection to the database and that the variable exists.")
    end
    # Get neighbors to return... this is pretty expensive.
    neigfacs = map(f -> getFactor(dfg, f), getNeighbors(dfg, variable))

    deleteNeighbors = true # reserved, orphaned factors are not supported at this time
    # Very 'assertive' deletion - delete the variable, all PPE's, solver data, data, and related factors in a single bound.
    query = """
    MATCH (node:$(join(_getLabelsForType(dfg, DFGVariable, parentKey=label),':')))--(m)
    WHERE (m:PPE OR m:SOLVERDATA OR m:DATA $(deleteNeighbors ? "OR m:FACTOR" : ""))
    DETACH DELETE node, m
    """
    _queryNeo4j(dfg.neo4jInstance, query)

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
    query = """
    MATCH (node:$(join(_getLabelsForType(dfg, DFGFactor, parentKey=label),':')))
    DETACH DELETE node
    """
    _queryNeo4j(dfg.neo4jInstance, query)

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
    tagsFilter = length(tags) > 0 ? " and ("*join("\"".*String.(tags).*"\" in node.tags", " or ")*") " : ""
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
    tagsFilter = length(tags) > 0 ? " and ("*join("\"".*String.(tags).*".\" in node.tags", " or ")*") " : ""
    if regexFilter == nothing
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGFactor),':'))) where node.solvable >= $solvable")
    else
        return _getLabelsFromCyphonQuery(dfg.neo4jInstance, "(node:$(join(_getLabelsForType(dfg, DFGFactor),':'))) where node.label =~ '$(regexFilter.pattern)' and node.solvable >= $solvable $tagsFilter")
    end
end

function isConnected(dfg::CloudGraphsDFG)::Bool
    # # If the total number of nodes == total number of distinct connected nodes, then it is fully connected
    # # Total nodes
    # varIds = listVariables(dfg)
    # factIds = listFactors(dfg)
    # length(varIds) + length(factIds) == 0 && return false

    # # Total distinct connected nodes - thank you Neo4j for 0..* awesomeness!!
    # # TODO: Deprecated matching technique and it's technically an expensive call - optimize.
    # query = """
    #     match (n:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId):$(varIds[1]))-[FACTORGRAPH*]-(node:$(dfg.userId):$(dfg.robotId):$(dfg.sessionId))
    #     WHERE (n:VARIABLE OR n:FACTOR OR node:VARIABLE OR node:FACTOR) and not (node:SESSION or n:SESSION) and not (n:PPE) and not (node:PPE)
    #     WITH collect(n)+collect(node) as nodelist
    #     unwind nodelist as nodes
    #     return count(distinct nodes)"""
    # @debug "[Query] $query"
    # result = _queryNeo4j(dfg.neo4jInstance, query)
    # # Neo4j.jl data structure sometimes feels brittle... like below
    # return result.results[1]["data"][1]["row"][1] == length(varIds) + length(factIds)
   return isConnected(SkeletonDFG(dfg))
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
    neighbors = _getLabelsFromCyphonQuery(dfg.neo4jInstance, query)
    # If factor, need to do variable ordering TODO, Do we? does it matter if we always use _variableOrderSymbols in calculations?
    if isFactor(dfg, label)
        # Server is authorixty
        serverOrder = Symbol.(_getNodeProperty(dfg.neo4jInstance, [dfg.userId, dfg.robotId, dfg.sessionId, String(label)], "_variableOrderSymbols"))
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

### PPE CRUD

"""
$(SIGNATURES)
Unpack a Dict{String, Any} into a PPE.
"""
function _unpackPPE(dfg::G, packedPPE::Dict{String, Any})::AbstractPointParametricEst where G <: AbstractDFG
    # Cleanup Zoned timestamp, which is always UTC
    if packedPPE["lastUpdatedTimestamp"][end] == 'Z'
        packedPPE["lastUpdatedTimestamp"] = packedPPE["lastUpdatedTimestamp"][1:end-1]
    end

    !haskey(packedPPE, "_type") && error("Cannot find type key '$TYPEKEY' in packed PPE data")
    type = pop!(packedPPE, "_type")
    (type == nothing || type == "") && error("Cannot deserialize PPE, type key is empty")
    ppe = Unmarshal.unmarshal(
            DistributedFactorGraphs.getTypeFromSerializationModule(dfg, Symbol(type)),
            packedPPE)
    return ppe
end

function listPPEs(dfg::CloudGraphsDFG, variablekey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    return _listVarSubnodesForType(dfg, variablekey, MeanMaxPPE, "solveKey"; currentTransaction=currentTransaction)
end

function getPPE(dfg::CloudGraphsDFG, variablekey::Symbol, ppekey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::AbstractPointParametricEst
    properties = _getVarSubnodeProperties(dfg, variablekey, MeanMaxPPE, ppekey; currentTransaction=currentTransaction)
    return _unpackPPE(dfg, properties)
end

function _generateAdditionalProperties(variableType::ST, ppe::P)::Dict{String, String} where {P <: AbstractPointParametricEst, ST <: InferenceVariable}
    addProps = Dict{String, String}()
    # Try get the projectCartesian function for this variableType
    projectCartesianFunc = nothing
    if isdefined(Main, :projectCartesian)
        # Try find a signature that matches
        if applicable(Main.projectCartesian, variableType, Vector{Float64}())
            projectCartesianFunc = Main.projectCartesian
        end
    end
    if projectCartesianFunc === nothing
        @warn "There is no cartesianProjection function for $(typeof(variableType)), so no cartesian entries will be added. Please add a projectCartesian function for this variableType."
        return addProps
    end
    for field in DistributedFactorGraphs.getEstimateFields(ppe)
        est = getfield(ppe, field)
        cart = Main.projectCartesian(variableType, est) # Assuming we've imported the variables into Main
        addProps["$(field)_cart3"] = "point({x:$(cart[1]),y:$(cart[2]),z:$(cart[3])})" # Need to look at 3D too soon.
    end
    return addProps
end

function addPPE!(dfg::CloudGraphsDFG,
                 variablekey::Symbol,
                 ppe::P;
                 currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::AbstractPointParametricEst where
                 {P <: AbstractPointParametricEst}
    if ppe.solveKey in listPPEs(dfg, variablekey, currentTransaction=currentTransaction)
        error("PPE '$(ppe.solveKey)' already exists")
    end
    variableType = getVariableType(dfg, variablekey)
    # Add additional properties for the PPE
    addProps = _generateAdditionalProperties(variableType, ppe)
    return _unpackPPE(dfg, _matchmergeVariableSubnode!(
        dfg,
        variablekey,
        _getLabelsForInst(dfg, ppe, parentKey=variablekey),
        ppe,
        :PPE,
        addProps=addProps,
        currentTransaction=currentTransaction))
end

function updatePPE!(
        dfg::CloudGraphsDFG,
        variablekey::Symbol,
        ppe::AbstractPointParametricEst;
        currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing,
        warn_if_absent::Bool=true)

    if warn_if_absent && !(ppe.solveKey in listPPEs(dfg, variablekey, currentTransaction=currentTransaction))
        @warn "PPE '$(ppe.solveKey)' does not exist, adding"
    end
    variableType = getVariableType(dfg, variablekey, currentTransaction=currentTransaction)
    # Add additional properties for the PPE
    addProps = _generateAdditionalProperties(variableType, ppe)
    return _unpackPPE(dfg, _matchmergeVariableSubnode!(
        dfg,
        variablekey,
        _getLabelsForInst(dfg, ppe, parentKey=variablekey),
        ppe,
        :PPE,
        addProps=addProps,
        currentTransaction=currentTransaction))
end

function updatePPE!(dfg::CloudGraphsDFG, sourceVariables::Vector{<:DFGVariable}, ppekey::Symbol=:default; 
                    currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing,
                    warn_if_absent::Bool=true)
    
    tx = currentTransaction === nothing ? transaction(dfg.neo4jInstance.connection) : currentTransaction
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(var, ppekey), currentTransaction=tx, warn_if_absent=warn_if_absent)
    end
    if currentTransaction === nothing
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
    return _unpackPPE(dfg, props)
end

## DataEntry CRUD

function getDataEntries(dfg::CloudGraphsDFG, label::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    entries = Dict{Symbol, BlobStoreEntry}()
    # TODO: Optimize if necessary.
    delist = listDataEntries(dfg, label, currentTransaction=currentTransaction)
    return getDataEntry.(dfg, label, delist; currentTransaction=currentTransaction)

end

function listDataEntries(dfg::CloudGraphsDFG, label::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    return _listVarSubnodesForType(
        dfg, 
        label, 
        BlobStoreEntry, 
        "label"; 
        currentTransaction=currentTransaction)
end

function getDataEntry(dfg::CloudGraphsDFG, label::Symbol, key::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    properties = _getVarSubnodeProperties(
        dfg, label, 
        BlobStoreEntry, 
        key; 
        currentTransaction=currentTransaction)
    
    #FIXME
    properties["createdTimestamp"] = DistributedFactorGraphs.getStandardZDTString(properties["createdTimestamp"])
    
    return Unmarshal.unmarshal(
        BlobStoreEntry,
        properties)
end

function addDataEntry!(dfg::CloudGraphsDFG, label::Symbol, bde::BlobStoreEntry; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    if bde.label in listDataEntries(dfg, label, currentTransaction=currentTransaction)
        error("Data label '$(bde.label)' already exists")
    end
    packed = _matchmergeVariableSubnode!(
        dfg,
        label,
        _getLabelsForInst(dfg, bde, parentKey=label),
        bde,
        :DATA,
        currentTransaction=currentTransaction)
    
    #FIXME
    packed["createdTimestamp"] = DistributedFactorGraphs.getStandardZDTString(packed["createdTimestamp"])

    return Unmarshal.unmarshal(
            BlobStoreEntry,
            packed)
end

function updateDataEntry!(dfg::CloudGraphsDFG, label::Symbol,  bde::BlobStoreEntry;
                          currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing,
                          warn_if_absent::Bool=true)
    if warn_if_absent && !(bde.label in listDataEntries(dfg, label, currentTransaction=currentTransaction))
        @warn "Data label '$(bde.label)' does not exist, adding"
    end
    packed = _matchmergeVariableSubnode!(
        dfg,
        label,
        _getLabelsForInst(dfg, bde, parentKey=label),
        bde,
        :DATA,
        currentTransaction=currentTransaction)

    #FIXME
    packed["createdTimestamp"] = DistributedFactorGraphs.getStandardZDTString(packed["createdTimestamp"])

    return Unmarshal.unmarshal(
            BlobStoreEntry,
            packed)
end

function deleteDataEntry!(dfg::CloudGraphsDFG, label::Symbol, key::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)
    props = _deleteVarSubnode!(
        dfg,
        label,
        :DATA,
        _getLabelsForType(dfg, BlobStoreEntry, parentKey=label),
        key,
        currentTransaction=currentTransaction)
    
    #FIXME
    props["createdTimestamp"] = DistributedFactorGraphs.getStandardZDTString(props["createdTimestamp"])

    return Unmarshal.unmarshal(
        BlobStoreEntry,
        props)
end

## VariableSolverData CRUD

"""
$(SIGNATURES)
Unpack a Dict{String, Any} into a PPE.
"""
function _unpackVariableNodeData(dfg::G, packedDict::Dict{String, Any})::VariableNodeData where G <: AbstractDFG
    packedVND = Unmarshal.unmarshal(PackedVariableNodeData, packedDict)
    return unpackVariableNodeData(dfg, packedVND)
end

function listVariableSolverData(dfg::CloudGraphsDFG, variablekey::Symbol; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::Vector{Symbol}
    return _listVarSubnodesForType(dfg, variablekey, VariableNodeData, "solveKey"; currentTransaction=currentTransaction)
end

function getVariableSolverData(dfg::CloudGraphsDFG, variablekey::Symbol, solveKey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    properties = _getVarSubnodeProperties(dfg, variablekey, VariableNodeData, solveKey; currentTransaction=currentTransaction)
    return _unpackVariableNodeData(dfg, properties)
end

function addVariableSolverData!(dfg::CloudGraphsDFG,
                                variablekey::Symbol,
                                vnd::VariableNodeData;
                                currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    if vnd.solveKey in listVariableSolverData(dfg, variablekey, currentTransaction=currentTransaction)
        error("Solver data '$(vnd.solveKey)' already exists")
    end
    retPacked = _matchmergeVariableSubnode!(
        dfg,
        variablekey,
        _getLabelsForInst(dfg, vnd, parentKey=variablekey),
        packVariableNodeData(dfg, vnd),
        :SOLVERDATA,
        currentTransaction=currentTransaction)
    return _unpackVariableNodeData(dfg, retPacked)
end

function updateVariableSolverData!(dfg::CloudGraphsDFG,
                                variablekey::Symbol,
                                vnd::VariableNodeData,
                                useCopy::Bool=true,
                                fields::Vector{Symbol}=Symbol[];
                                warn_if_absent::Bool=true,
                                currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    if warn_if_absent && !(vnd.solveKey in listVariableSolverData(dfg, variablekey, currentTransaction=currentTransaction))
        @warn "Solver data '$(vnd.solveKey)' does not exist, adding rather than updating."
    end
    # TODO: Update this to use the selective parameters from fields.
    retPacked = _matchmergeVariableSubnode!(
        dfg,
        variablekey,
        _getLabelsForInst(dfg, vnd, parentKey=variablekey),
        packVariableNodeData(dfg, vnd),
        :SOLVERDATA,
        currentTransaction=currentTransaction)
    return _unpackVariableNodeData(dfg, retPacked)
end

function deleteVariableSolverData!(dfg::CloudGraphsDFG, variablekey::Symbol, solveKey::Symbol=:default; currentTransaction::Union{Nothing, Neo4j.Transaction}=nothing)::VariableNodeData
    retPacked = _deleteVarSubnode!(
        dfg,
        variablekey,
        :SOLVERDATA,
        _getLabelsForType(dfg, VariableNodeData, parentKey=variablekey),
        solveKey,
        currentTransaction=currentTransaction)
    return _unpackVariableNodeData(dfg, retPacked)
end

# TODO: Do we need the useCopy,
# function updateVariableSolverData!(dfg::CloudGraphsDFG,
#                                    variablekey::Symbol,
#                                    vnd::VariableNodeData,
#                                    solvekey::Symbol=:default,
#                                    useCopy::Bool=true,
#                                    fields::Vector{Symbol}=Symbol[])::VariableNodeData
#     # TODO: Switch out to their own nodes, don't get the whole variable
#     var = getVariable(dfg, variablekey)
#     if !haskey(var.solverDataDict, solvekey)
#         @warn "VariableNodeData '$(solvekey)' does not exist, adding"
#     end
#
#     # Unnecessary for cloud, but (probably) being (too) conservative (just because).
#     usevnd = useCopy ? deepcopy(vnd) : vnd
#     # should just one, or many pointers be updated?
#     if haskey(var.solverDataDict, solvekey) && isa(var.solverDataDict[solvekey], VariableNodeData) && length(fields) != 0
#       # change multiple pointers inside the VND var.solverDataDict[solvekey]
#       for field in fields
#         destField = getfield(var.solverDataDict[solvekey], field)
#         srcField = getfield(usevnd, field)
#         if isa(destField, Array) && size(destField) == size(srcField)
#           # use broadcast (in-place operation)
#           destField .= srcField
#         else
#           # change pointer of destination VND object member
#           setfield!(var.solverDataDict[solvekey], field, srcField)
#         end
#       end
#     else
#       # change a single pointer in var.solverDataDict
#       var.solverDataDict[solvekey] = usevnd
#     end
#
#     # TODO: Cleanup and consolidate
#     solverDataDict = JSON2.write(Dict(keys(var.solverDataDict) .=> map(vnd -> packVariableNodeData(dfg, vnd), values(var.solverDataDict))))
#     _setNodeProperty(
#         dfg.neo4jInstance,
#         _getLabelsForInst(dfg, var),
#         "solverDataDict",
#         solverDataDict)
#     return var.solverDataDict[solvekey]
# end

function updateVariableSolverData!(dfg::CloudGraphsDFG,
                                   sourceVariables::Vector{<:DFGVariable},
                                   solvekey::Symbol=:default,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[];
                                   warn_if_absent::Bool=true )
    #TODO: Do in bulk for speed.
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solvekey), solvekey, useCopy, fields; warn_if_absent=warn_if_absent)
    end
end

function mergeVariableSolverData!(dfg::CloudGraphsDFG, sourceVariable::DFGVariable)
    for solveKey in listVariableSolverData(dfg, sourceVariable.label)
        updateVariableSolverData!(
            dfg,
            sourceVariable.label,
            getVariableSolverData(dfg, sourceVariable, solveKey),
            solveKey)
    end
end

## Solvable

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


##==============================================================================
## Skeleton DFG Constructor
##==============================================================================
# TODO tags
function _getSkeletonFactors(dfg::CloudGraphsDFG)
    neo4jInstance = dfg.neo4jInstance
    query = "match (node:$(join(_getLabelsForType(dfg, DFGFactor),':'))) return distinct(node.label),node._variableOrderSymbols"
    result = _queryNeo4j(neo4jInstance, query)
    facs = map(node -> SkeletonDFGFactor(Symbol(node["row"][1]),Symbol.(node["row"][2])), result.results[1]["data"])
    return facs
end
# TODO tags
function _getSkeletonVariables(dfg::CloudGraphsDFG)
    return SkeletonDFGVariable.(ls(dfg))
end

export SkeletonDFG
function SkeletonDFG(cfg::CloudGraphsDFG)
    sfg = LightDFG{NoSolverParams, SkeletonDFGVariable, SkeletonDFGFactor}()
    addVariable!.(sfg, _getSkeletonVariables(cfg))
    addFactor!.(sfg, _getSkeletonFactors(cfg))
    return sfg
end