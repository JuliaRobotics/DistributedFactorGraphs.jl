
# For visualization
import Graphs: attributes, vertex_index
# Export attributes, these are enumerates as properties for the variables and factors
# REF: http://www.graphviz.org/documentation/
function attributes(v::GraphsNode, g::T)::AttributeDict where T <:GenericIncidenceList
    AttributeDict(
        "label" => v.dfgNode.label,
        "color" => v.dfgNode isa DFGVariable ? "red" : "blue",
        "shape" => v.dfgNode isa DFGVariable ? "ellipse" : "box",
        "fillcolor" => v.dfgNode isa DFGVariable ? "red" : "blue"
        )
end

# This is insanely important - if we don't provide a valid index, the edges don't work correctly.
vertex_index(v::GraphsNode) = v.index

# Accessors
getLabelDict(dfg::GraphsDFG) = dfg.labelDict
getDescription(dfg::GraphsDFG) = dfg.description
setDescription(dfg::GraphsDFG, description::String) = dfg.description = description
getInnerGraph(dfg::GraphsDFG) = dfg.g
getAddHistory(dfg::GraphsDFG) = dfg.addHistory
getSolverParams(dfg::GraphsDFG) = dfg.solverParams
function setSolverParams(dfg::GraphsDFG, solverParams::T) where T <: AbstractParams
    dfg.solverParams = solverParams
end

# Get user, robot, and session "small" data.
getUserData(dfg::GraphsDFG)::Dict{Symbol, String} = return dfg.userData
function setUserData(dfg::GraphsDFG, data::Dict{Symbol, String})::Bool
	dfg.userData = data
	return true
end
getRobotData(dfg::GraphsDFG)::Dict{Symbol, String} = return dfg.robotData
function setRobotData(dfg::GraphsDFG, data::Dict{Symbol, String})::Bool
	dfg.robotData = data
	return true
end
getSessionData(dfg::GraphsDFG)::Dict{Symbol, String} = return dfg.sessionData
function setSessionData(dfg::GraphsDFG, data::Dict{Symbol, String})::Bool
	dfg.sessionData = data
	return true
end

"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::GraphsDFG)::GraphsDFG
    newDfg = GraphsDFG{typeof(dfg.solverParams)}(;
		userId=dfg.userId, robotId=dfg.robotId, sessionId=dfg.sessionId,
		params=deepcopy(dfg.solverParams))
	newDfg.description ="(Copy of) $(dfg.description)"
	return newDfg
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::GraphsDFG, node::N) where N <: DFGNode
    return haskey(dfg.labelDict, node.label)
end
exists(dfg::GraphsDFG, nId::Symbol) = haskey(dfg.labelDict, nId)


"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::GraphsDFG, variable::DFGVariable)::Bool
    if haskey(dfg.labelDict, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end
    dfg.nodeCounter += 1
    variable._internalId = dfg.nodeCounter
    v = GraphsNode(dfg.nodeCounter, variable)
    Graphs.add_vertex!(dfg.g, v)
    push!(dfg.labelDict, variable.label=>variable._internalId)
    # Track insertion
    push!(dfg.addHistory, variable.label)

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::GraphsDFG, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool
    if haskey(dfg.labelDict, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    for v in variables
        if !(v.label in keys(dfg.labelDict))
            error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
        end
    end
    dfg.nodeCounter += 1
    factor._internalId = dfg.nodeCounter
    factor._variableOrderSymbols = map(v->v.label, variables)
    fNode = GraphsNode(dfg.nodeCounter, factor)
    f = Graphs.add_vertex!(dfg.g, fNode)
    # Add index
    push!(dfg.labelDict, factor.label=>factor._internalId)
    # Add the edges...
    for variable in variables
        v = dfg.g.vertices[variable._internalId]
        edge = Graphs.make_edge(dfg.g, v, f)
        Graphs.add_edge!(dfg.g, edge)
    end
    # Track insertion
    # push!(dfg.addHistory, factor.label)

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::GraphsDFG, variableIds::Vector{Symbol}, factor::DFGFactor)::Bool
    variables = map(vId -> getVariable(dfg, vId), variableIds)
    return addFactor!(dfg, variables, factor)
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its underlying integer ID.
"""
function getVariable(dfg::GraphsDFG, variableId::Int64)::DFGVariable
    @warn "This may be slow, rather use by getVariable(dfg, label)"
    #TODO: This may be slow (O(n)), can we make it better?
    if !(variableId in values(dfg.labelDict))
        error("Variable ID '$(variableId)' does not exist in the factor graph")
    end
    return dfg.g.vertices[variableId].dfgNode
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::GraphsDFG, label::Union{Symbol, String})::DFGVariable
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.vertices[dfg.labelDict[label]].dfgNode
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its underlying integer ID.
"""
function getFactor(dfg::GraphsDFG, factorId::Int64)::DFGFactor
    @warn "This may be slow, rather use by getFactor(dfg, label)"
    #TODO: This may be slow (O(n)), can we make it better?
    if !(factorId in values(dfg.labelDict))
        error("Factor ID '$(factorId)' does not exist in the factor graph")
    end
    return dfg.g.vertices[factorId].dfgNode
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::GraphsDFG, label::Union{Symbol, String})::DFGFactor
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.vertices[dfg.labelDict[label]].dfgNode
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::GraphsDFG, variable::DFGVariable)::DFGVariable
    if !haskey(dfg.labelDict, variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
    dfg.g.vertices[dfg.labelDict[variable.label]].dfgNode = variable
    return variable
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::GraphsDFG, factor::DFGFactor)::DFGFactor
    if !haskey(dfg.labelDict, factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
    dfg.g.vertices[dfg.labelDict[factor.label]].dfgNode = factor
    return factor
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::GraphsDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    variable = dfg.g.vertices[dfg.labelDict[label]].dfgNode
    delete_vertex!(dfg.g.vertices[dfg.labelDict[label]], dfg.g)
    delete!(dfg.labelDict, label)
    return variable
end

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::GraphsDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    factor = dfg.g.vertices[dfg.labelDict[label]].dfgNode
    delete_vertex!(dfg.g.vertices[dfg.labelDict[label]], dfg.g)
    delete!(dfg.labelDict, label)
    return factor
end

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable}
    variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, Graphs.vertices(dfg.g)))
    if regexFilter != nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
	if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, variables )
        return variables[mask]
    end
	return variables
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
	factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, Graphs.vertices(dfg.g)))
	if regexFilter != nothing
		factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
	end
	return factors
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::GraphsDFG)::Bool
    return length(Graphs.connected_components(dfg.g)) == 1
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::GraphsDFG, node::T; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.labelDict, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end
    vert = dfg.g.vertices[dfg.labelDict[node.label]]
    neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
    # Additional filtering
    neighbors = ready != nothing ? filter(v -> v.dfgNode.ready == ready, neighbors) : neighbors
    neighbors = backendset != nothing ? filter(v -> v.dfgNode.backendset == backendset, neighbors) : neighbors
    # Variable sorting (order is important)
    if node isa DFGFactor
        order = intersect(node._variableOrderSymbols, map(v->v.dfgNode.label, neighbors))
        return order
    end

    return map(n -> n.dfgNode.label, neighbors)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::GraphsDFG, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.labelDict, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end
    vert = dfg.g.vertices[dfg.labelDict[label]]
    neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
    # Additional filtering
    neighbors = ready != nothing ? filter(v -> v.dfgNode.ready == ready, neighbors) : neighbors
    neighbors = backendset != nothing ? filter(v -> v.dfgNode.backendset == backendset, neighbors) : neighbors
    # Variable sorting when using a factor (function order is important)
    if vert.dfgNode isa DFGFactor
        vert.dfgNode._variableOrderSymbols
        order = intersect(vert.dfgNode._variableOrderSymbols, map(v->v.dfgNode.label, neighbors))
        return order
    end

    return map(n -> n.dfgNode.label, neighbors)
end

# function _copyIntoGraph!(sourceDFG::GraphsDFG, destDFG::GraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing
#     # Split into variables and factors
#     verts = map(id -> sourceDFG.g.vertices[sourceDFG.labelDict[id]], variableFactorLabels)
#     sourceVariables = filter(n -> n.dfgNode isa DFGVariable, verts)
#     sourceFactors = filter(n -> n.dfgNode isa DFGFactor, verts)
#
#     # Now we have to add all variables first,
#     for variable in sourceVariables
#         if !haskey(destDFG.labelDict, variable.dfgNode.label)
#             addVariable!(destDFG, deepcopy(variable.dfgNode))
#         end
#     end
#     # And then all factors to the destDFG.
#     for factor in sourceFactors
#         if !haskey(destDFG.labelDict, factor.dfgNode.label)
#             # Get the original factor variables (we need them to create it)
#             neighVarIds = getNeighbors(sourceDFG, factor.dfgNode.label) #OLD: in_neighbors(factor, sourceDFG.g)
#             # Find the labels and associated neighVarIds in our new subgraph
#             factVariables = DFGVariable[]
#             for neighVarId in neighVarIds
#                 if haskey(destDFG.labelDict, neighVarId)
#                     push!(factVariables, getVariable(destDFG, neighVarId))
#                     #otherwise ignore
#                 end
#             end
#
#             # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
#             if includeOrphanFactors || length(factVariables) == length(neighVarIds)
#                 addFactor!(destDFG, factVariables, deepcopy(factor.dfgNode))
#             end
#         end
#     end
#     return nothing
# end

"""
    $(SIGNATURES)
Retrieve a deep subgraph copy around a given variable or factor.
Optionally provide a distance to specify the number of edges should be followed.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraphAroundNode(dfg::GraphsDFG{P}, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::GraphsDFG=GraphsDFG{P}())::GraphsDFG where {P <: AbstractParams, T <: DFGNode}
    if !haskey(dfg.labelDict, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    # Build a list of all unique neighbors inside 'distance'
    neighborList = Dict{Symbol, Any}()
    push!(neighborList, node.label => dfg.g.vertices[dfg.labelDict[node.label]])
    curList = Dict{Symbol, Any}(node.label => dfg.g.vertices[dfg.labelDict[node.label]])
    for dist in 1:distance
        newNeighbors = Dict{Symbol, Any}()
        for (key, node) in curList
            neighbors = in_neighbors(node, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
            for neighbor in neighbors
                if !haskey(neighborList, neighbor.dfgNode.label)
                    push!(neighborList, neighbor.dfgNode.label => neighbor)
                    push!(newNeighbors, neighbor.dfgNode.label => neighbor)
                end
            end
        end
        curList = newNeighbors
    end

    # Copy the section of graph we want
    _copyIntoGraph!(dfg, addToDFG, collect(keys(neighborList)), includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::GraphsDFG)::String
	return Graphs.to_dot(dfg.g)
end
