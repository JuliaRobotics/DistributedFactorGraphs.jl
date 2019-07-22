# For visualization
# import Graphs: attributes, vertex_index
# # Export attributes, these are enumerates as properties for the variables and factors
# # REF: http://www.graphviz.org/documentation/
# function attributes(v::LightGraphsNode, g::T)::AttributeDict where T <:GenericIncidenceList
#     AttributeDict(
#         "label" => v.dfgNode.label,
#         "color" => v.dfgNode isa DFGVariable ? "red" : "blue",
#         "shape" => v.dfgNode isa DFGVariable ? "box" : "ellipse",
#         "fillcolor" => v.dfgNode isa DFGVariable ? "red" : "blue"
#         )
# end
#
# # This is insanely important - if we don't provide a valid index, the edges don't work correctly.
# vertex_index(v::LightGraphsNode) = v.index

# Accessors
getLabelDict(dfg::LightGraphsDFG) = dfg.labelDict
getDescription(dfg::LightGraphsDFG) = dfg.description
setDescription(dfg::LightGraphsDFG, description::String) = dfg.description = description
getInnerGraph(dfg::LightGraphsDFG) = dfg.g
getAddHistory(dfg::LightGraphsDFG) = dfg.addHistory
getSolverParams(dfg::LightGraphsDFG) = dfg.solverParams

# setSolverParams(dfg::LightGraphsDFG, solverParams) = dfg.solverParams = solverParams
function setSolverParams(dfg::LightGraphsDFG, solverParams::P) where P <: AbstractParams
  dfg.solverParams = solverParams
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::LightGraphsDFG, node::N) where N <: DFGNode
    return haskey(dfg.labelDict, node.label)
end
exists(dfg::LightGraphsDFG, nId::Symbol) = haskey(dfg.labelDict, nId)


"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::LightGraphsDFG, variable::DFGVariable)::Bool
    if haskey(dfg.labelDict, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end
    dfg.nodeCounter += 1

	#TODO kyk na nv(fg) dink nie die gaan in LightGraphs werk nie
    variable._internalId = dfg.nodeCounter
	# ek dink die node id gaan verlore gaan
	# v = LightGraphsNode(dfg.nodeCounter, variable)
	#dalk eerder op die baseer?

	#TODO ons kan of aparte velde stoor of die variable net so
	if false
		props = Dict{Symbol, Any}()
	    props[:timestamp] = variable.timestamp
	    props[:tags] = variable.tags
	    props[:estimateDict] = variable.estimateDict
	    props[:solverDataDict] = variable.solverDataDict
	    props[:smallData] = variable.smallData
	    props[:ready] = variable.ready
	    props[:backendset] = variable.backendset
	else
		# props = Dict{:Symbol, Any}()
		# props[:tags] = variable.tags
		# props[:variable] = variable
		props = Dict(:variable=>variable)
	end
	retval = MetaGraphs.add_vertex!(dfg.g, :label, variable.label)
	retval && MetaGraphs.set_props!(dfg.g, nv(dfg.g), props)

	#TODO die ID gaan heeltyd verander, ek dink sover gebruik label direk as index
    push!(dfg.labelDict, variable.label=>variable._internalId)
    # Track insertion
    push!(dfg.addHistory, variable.label)

    return retval
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::LightGraphsDFG, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool
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
    # fNode = LightGraphsNode(dfg.nodeCounter, factor)
    # f = Graphs.add_vertex!(dfg.g, fNode)

	#TODO something like this or the next props definition
	# props = Dict{:Symbol, Any}()
	# props[:tags] = factor.tags
	# props[:factor] = factor

	props = Dict(:factor=>factor)

	retval = add_vertex!(dfg.g, :label, factor.label)
	retval && set_props!(dfg.g, nv(dfg.g), props)

    # Add index
    push!(dfg.labelDict, factor.label=>factor._internalId)
    # Add the edges...
    for variable in variables
        # v = dfg.g.vertices[variable._internalId]
        # edge = Graphs.make_edge(dfg.g, v, f)
        # Graphs.add_edge!(dfg.g, edge)
		retval && add_edge!(dfg.g, dfg.g[variable.label,:label], dfg.g[factor.label,:label])
    end
    # Track insertion
    # push!(dfg.addHistory, factor.label)

    return retval
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::LightGraphsDFG, variableIds::Vector{Symbol}, factor::DFGFactor)::Bool
    variables = map(vId -> getVariable(dfg, vId), variableIds)
    return addFactor!(dfg, variables, factor)
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its underlying integer ID.
"""
function getVariable(dfg::LightGraphsDFG, variableId::Int64)::DFGVariable
    return get_prop(dfg.g, variableId, :variable)
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::LightGraphsDFG, label::Union{Symbol, String})::DFGVariable
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    return get_prop(dfg.g, dfg.g[label,:label], :variable)
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its underlying integer ID.
"""
function getFactor(dfg::LightGraphsDFG, factorId::Int64)::DFGFactor
    # if !(factorId in values(dfg.labelDict))
    #     error("Factor ID '$(factorId)' does not exist in the factor graph")
    # end
    return get_prop(dfg.g, factorId, :factor)
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::LightGraphsDFG, label::Union{Symbol, String})::DFGFactor
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return get_prop(dfg.g, dfg.g[label,:label], :factor)
end


## TODO UNTESTED!!!!!!!!!!!!!!
"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::LightGraphsDFG, variable::DFGVariable)::DFGVariable
    if !haskey(dfg.labelDict, variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
    # dfg.g.vertices[dfg.labelDict[variable.label]].dfgNode = variable
	set_props!(dfg.g, dfg.g[label,:label], :variable, variable)
    return variable
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::LightGraphsDFG, factor::DFGFactor)::DFGFactor
    if !haskey(dfg.labelDict, factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
    # dfg.g.vertices[dfg.labelDict[factor.label]].dfgNode = factor
	set_props!(dfg.g, dfg.g[label,:label], :factor, factor)
    return factor
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::LightGraphsDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    # variable = dfg.g.vertices[dfg.labelDict[label]].dfgNode
    # delete_vertex!(dfg.g.vertices[dfg.labelDict[label]], dfg.g)
	variable = get_prop(dfg.g, dfg.g[label,:label], :variable)
	rem_vertex!(dfg.g, dfg.g[label,:label])
    delete!(dfg.labelDict, label)
    return variable
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
deleteVariable!(dfg::LightGraphsDFG, variable::DFGVariable)::DFGVariable = deleteVariable(dfg, variable.label)

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::LightGraphsDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    # factor = dfg.g.vertices[dfg.labelDict[label]].dfgNode
    # delete_vertex!(dfg.g.vertices[dfg.labelDict[label]], dfg.g)
	factor = get_prop(dfg.g, dfg.g[label,:label], :factor)
	rem_vertex!(dfg.g, dfg.g[label,:label])
    delete!(dfg.labelDict, label)
    return factor
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
deleteFactor!(dfg::LightGraphsDFG, factor::DFGFactor)::DFGFactor = deleteFactor!(dfg, factor.label)

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable}

	# variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
	variableIds = collect(filter_vertices(dfg.g, :variable))
	variables = map(vId->getVariable(dfg, vId), variableIds)
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
Get a list of IDs of the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.

Example
```julia
getVariableIds(dfg, r"l", tags=[:APRILTAG;])
```

Related

ls
"""
function getVariableIds(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol}
  vars = getVariables(dfg, regexFilter, tags=tags)
  # mask = map(v -> length(intersect(v.tags, tags)) > 0, vars )
  map(v -> v.label, vars)
end

# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
ls(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} = getVariableIds(dfg, regexFilter, tags=tags)

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
	# factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
	factorIds = collect(filter_vertices(dfg.g, :factor))
	factors = map(vId->getFactor(dfg, vId), factorIds)
	if regexFilter != nothing
		factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
	end
	return factors
end

"""
    $(SIGNATURES)
Get a list of the IDs of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
getFactorIds(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = map(f -> f.label, getFactors(dfg, regexFilter))

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
# Alias
lsf(dfg::LightGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = getFactorIds(dfg, regexFilter)

"""
	$(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::LightGraphsDFG, label::Symbol)::Vector{Symbol}
  return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::LightGraphsDFG)::Bool
    return length(connected_components(dfg.g)) == 1
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
hasOrphans(dfg::LightGraphsDFG)::Bool = !isFullyConnected(dfg)


"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::LightGraphsDFG, node::T; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.labelDict, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end
    vert = dfg.g.vertices[dfg.labelDict[node.label]]
    neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
    # Additional filtering
    neighbors = ready != nothing ? filter(v -> v.ready == ready, neighbors) : neighbors
    neighbors = backendset != nothing ? filter(v -> v.backendset == backendset, neighbors) : neighbors
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
function getNeighbors(dfg::LightGraphsDFG, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.labelDict, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end
    vert = dfg.g.vertices[dfg.labelDict[label]]
    neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
    # Additional filtering
    neighbors = ready != nothing ? filter(v -> v.ready == ready, neighbors) : neighbors
    neighbors = backendset != nothing ? filter(v -> v.backendset == backendset, neighbors) : neighbors
    # Variable sorting when using a factor (function order is important)
    if vert.dfgNode isa DFGFactor
        vert.dfgNode._variableOrderSymbols
        order = intersect(vert.dfgNode._variableOrderSymbols, map(v->v.dfgNode.label, neighbors))
        return order
    end

    return map(n -> n.dfgNode.label, neighbors)
end

# Aliases
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::LightGraphsDFG, node::T)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, node)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::LightGraphsDFG, label::Symbol)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, label)
end

function _copyIntoGraph!(sourceDFG::LightGraphsDFG, destDFG::LightGraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing
    # Split into variables and factors
    verts = map(id -> sourceDFG.g.vertices[sourceDFG.labelDict[id]], variableFactorLabels)
    sourceVariables = filter(n -> n.dfgNode isa DFGVariable, verts)
    sourceFactors = filter(n -> n.dfgNode isa DFGFactor, verts)

    # Now we have to add all variables first,
    for variable in sourceVariables
        if !haskey(destDFG.labelDict, variable.dfgNode.label)
            addVariable!(destDFG, deepcopy(variable.dfgNode))
        end
    end
    # And then all factors to the destDFG.
    for factor in sourceFactors
        if !haskey(destDFG.labelDict, factor.dfgNode.label)
            # Get the original factor variables (we need them to create it)
            variables = in_neighbors(factor, sourceDFG.g)
            # Find the labels and associated variables in our new subgraph
            factVariables = DFGVariable[]
            for variable in variables
                if haskey(destDFG.labelDict, variable.dfgNode.label)
                    push!(factVariables, getVariable(destDFG, variable.dfgNode.label))
                    #otherwise ignore
                end
            end

            # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
            if includeOrphanFactors || length(factVariables) == length(variables)
                addFactor!(destDFG, factVariables, deepcopy(factor.dfgNode))
            end
        end
    end
    return nothing
end

"""
    $(SIGNATURES)
Retrieve a deep subgraph copy around a given variable or factor.
Optionally provide a distance to specify the number of edges should be followed.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraphAroundNode(dfg::LightGraphsDFG{P}, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::LightGraphsDFG=LightGraphsDFG{P}())::LightGraphsDFG where {P <: AbstractParams, T <: DFGNode}
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
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::LightGraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::LightGraphsDFG=LightGraphsDFG())::LightGraphsDFG
    for label in variableFactorLabels
        if !haskey(dfg.labelDict, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}.
Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
The first row and first column are factor and variable headings respectively.
"""
function getAdjacencyMatrix(dfg::LightGraphsDFG)::Matrix{Union{Nothing, Symbol}}
    varLabels = sort(map(v->v.label, getVariables(dfg)))
    factLabels = sort(map(f->f.label, getFactors(dfg)))
    vDict = Dict(varLabels .=> [1:length(varLabels)...].+1)

    adjMat = Matrix{Union{Nothing, Symbol}}(nothing, length(factLabels)+1, length(varLabels)+1)
    # Set row/col headings
    adjMat[2:end, 1] = factLabels
    adjMat[1, 2:end] = varLabels
    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = getNeighbors(dfg, getFactor(dfg, factLabel))
        map(vLabel -> adjMat[fIndex+1,vDict[vLabel]] = factLabel, factVars)
    end
    return adjMat
end

"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::LightGraphsDFG)::String
    m = PipeBuffer()
    write(m,Graphs.to_dot(dfg.g))
    data = take!(m)
    close(m)
    return String(data)
end

"""
    $(SIGNATURES)
Produces a dot file of the graph for visualization.
Download XDot to see the data

Note
- Default location "/tmp/dfg.dot" -- MIGHT BE REMOVED
- Can be viewed with the `xdot` system application.
- Based on graphviz.org
"""
function toDotFile(dfg::LightGraphsDFG, fileName::String="/tmp/dfg.dot")::Nothing
    open(fileName, "w") do fid
        write(fid,Graphs.to_dot(dfg.g))
    end
    return nothing
end

# function __init__()
#     @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
#         if isdefined(Main, :DataFrames)
#             """
#                 $(SIGNATURES)
#             Get an adjacency matrix for the DFG as a DataFrame.
#             Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
#             The first column is the factor headings.
#             """
#             function getAdjacencyMatrixDataFrame(dfg::LightGraphsDFG)::Main.DataFrames.DataFrame
#                 varLabels = sort(map(v->v.label, getVariables(dfg)))
#                 factLabels = sort(map(f->f.label, getFactors(dfg)))
#                 adjDf = DataFrames.DataFrame(:Factor => Union{Missing, Symbol}[])
#                 for varLabel in varLabels
#                     adjDf[varLabel] = Union{Missing, Symbol}[]
#                 end
#                 for (i, factLabel) in enumerate(factLabels)
#                     push!(adjDf, [factLabel, DataFrames.missings(length(varLabels))...])
#                     factVars = getNeighbors(dfg, getFactor(dfg, factLabel))
#                     map(vLabel -> adjDf[vLabel][i] = factLabel, factVars)
#                 end
#                 return adjDf
#             end
#         end
#     end
# end



#################################################################################
