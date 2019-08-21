

# Accessors
getLabelDict(dfg::LightDFG) = dfg.labelDict
getDescription(dfg::LightDFG) = dfg.description
setDescription(dfg::LightDFG, description::String) = dfg.description = description
getInnerGraph(dfg::LightDFG) = dfg.g
getAddHistory(dfg::LightDFG) = dfg.addHistory
getSolverParams(dfg::LightDFG) = dfg.solverParams

# setSolverParams(dfg::LightDFG, solverParams) = dfg.solverParams = solverParams
function setSolverParams(dfg::LightDFG, solverParams::P) where P <: AbstractParams
  dfg.solverParams = solverParams
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::LightDFG{P,V,F}, node::V) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode, N <: DFGNode}
	return haskey(dfg.g.variables, node.label)
end

function exists(dfg::LightDFG{P,V,F}, node::F) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode, N <: DFGNode}
	return haskey(dfg.g.factors, node.label)
end

exists(dfg::LightDFG, nId::Symbol) = haskey(dfg.g.labels, nId)

exists(dfg::LightDFG, node::DFGNode) = exists(dfg, node.label)



"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::LightDFG, variable::DFGVariable)::Bool
	#TODO should this be an error
	if haskey(dfg.g.variables, variable.label)
		error("Variable '$(variable.label)' already exists in the factor graph")
	end

	#NOTE Internal ID always set to zero as it is not needed?
    variable._internalId = 0

	FactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::LightDFG, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool
    # if haskey(dfg.g.metaindex[:label], factor.label)
    #     error("Factor '$(factor.label)' already exists in the factor graph")
    # end
	#TODO should this be an error
	if haskey(dfg.g.factors, factor.label)
		error("Factor '$(factor.label)' already exists in the factor graph")
	end
    # for v in variables
    #     if !(v.label in keys(dfg.g.metaindex[:label]))
    #         error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
    #     end
    # end

	#NOTE Internal ID always set to zero as it is not needed?
    factor._internalId = 0

	variableLabels = map(v->v.label, variables)

    factor._variableOrderSymbols = copy(variableLabels)


    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::LightDFG, variableLabels::Vector{Symbol}, factor::DFGFactor)::Bool
	#TODO should this be an error
	if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
	factor._internalId = 0

    factor._variableOrderSymbols = variableLabels

    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end


"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::LightDFG, label::Symbol)::DFGVariable
    return dfg.g.variables[label]
end

getVariable(dfg::LightDFG, label::String) = getVariable(dfg, Symbol(label))

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::LightDFG, label::Symbol)::DFGFactor
    return dfg.g.factors[label]
end

getFactor(dfg::LightDFG, label::String) = getFactor(dfg, Symbol(label))


"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::LightDFG, variable::DFGVariable)::DFGVariable
    if !haskey(dfg.g.variables, variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
	dfg.g.variables[variable.label] = variable
    return variable
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::LightDFG, factor::DFGFactor)::DFGFactor
    if !haskey(dfg.g.factors, factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
	dfg.g.factors[factor.label] = factor
    return factor
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::LightDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
	variable = dfg.g.variables[label]
	rem_vertex!(dfg.g, dfg.g.labels[label])

    return variable
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
deleteVariable!(dfg::LightDFG, variable::DFGVariable)::DFGVariable = deleteVariable!(dfg, variable.label)

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::LightDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
	factor = dfg.g.factors[label]
	variable = rem_vertex!(dfg.g,  dfg.g.labels[label])
    return factor
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
deleteFactor!(dfg::LightDFG, factor::DFGFactor)::DFGFactor = deleteFactor!(dfg, factor.label)

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable}

	# variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
	variables = collect(values(dfg.g.variables))
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

function getVariableIds(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol}

	# variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
	if length(tags) > 0
		return map(v -> v.label, getVariables(dfg, regexFilter, tags=tags))
	else
		variables = collect(keys(dfg.g.variables))
		regexFilter != nothing && (variables = filter(v -> occursin(regexFilter, String(v)), variables))
		return variables
    end
end


# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
ls(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} = getVariableIds(dfg, regexFilter, tags=tags)

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
	# factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
	factors = collect(values(dfg.g.factors))
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
function getFactorIds(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol}
	# factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
	factors = collect(keys(dfg.g.factors))
	if regexFilter != nothing
		factors = filter(f -> occursin(regexFilter, String(f)), factors)
	end
	return factors
end
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
# Alias
lsf(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = getFactorIds(dfg, regexFilter)

"""
	$(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::LightDFG, label::Symbol)::Vector{Symbol}
  return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::LightDFG)::Bool
    return length(connected_components(dfg.g)) == 1
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
hasOrphans(dfg::LightDFG)::Bool = !isFullyConnected(dfg)

function _isready(dfg::LightDFG, label::Symbol, ready::Int)::Bool

	haskey(dfg.g.variables, label) && (return dfg.g.variables[label].ready == ready)
	haskey(dfg.g.factors, label) && (return dfg.g.factors[label].ready == ready)

	#TODO should this be a breaking error?
	@error "Node not in factor or variable"
	return false
end

function _isbackendset(dfg::LightDFG, label::Symbol, backendset::Int)::Bool
	haskey(dfg.g.variables, label) && (return dfg.g.variables[label].backendset == backendset)
	haskey(dfg.g.factors, label) && (return dfg.g.factors[label].backendset == backendset)

	#TODO should this be a breaking error?
	@error "Node not a factor or variable"
	return false
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::LightDFG, node::DFGNode; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}
	label = node.label
    if !exists(dfg, label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

	neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
	neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    ready != nothing && filter!(lbl -> _isready(dfg, lbl, ready), neighbors_ll)
	backendset != nothing && filter!(lbl -> _isbackendset(dfg, lbl, backendset), neighbors_ll)

    # Variable sorting (order is important)
    if node isa DFGFactor
        order = intersect(node._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll
end


"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::LightDFG, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
	if !exists(dfg, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

	neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
	neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    ready != nothing && filter!(lbl -> _isready(dfg, lbl, ready), neighbors_ll)
	backendset != nothing && filter!(lbl -> _isbackendset(dfg, lbl, backendset), neighbors_ll)

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label]._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll

end

# Aliases
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::LightDFG, node::T)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, node)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::LightDFG, label::Symbol)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, label)
end

function _copyIntoGraph!(sourceDFG::LightDFG, destDFG::LightDFG, ns::Vector{Int}, includeOrphanFactors::Bool=false)::Nothing
	#kan ek die in bulk copy, soos graph en dan nuwe map maak
	# Add all variables first,
	labels = [sourceDFG.g.labels[i] for i in ns]

	for v in values(sourceDFG.g.variables)
	    if v.label in labels
			exists(destDFG, v) ? (@warn "_copyIntoGraph $(v.label) exists, ignoring") : addVariable!(destDFG, deepcopy(v))
	    end
	end

    # And then all factors to the destDFG.
    for f in values(sourceDFG.g.factors)
        if f.label in labels
            # Get the original factor variables (we need them to create it)
			neigh_ints = FactorGraphs.outneighbors(sourceDFG.g, sourceDFG.g.labels[f.label])

			neigh_labels = [sourceDFG.g.labels[i] for i in neigh_ints]
            # Find the labels and associated variables in our new subgraph
            factVariables = DFGVariable[]
            for v_lab in neigh_labels
                if haskey(destDFG.g.variables, v_lab)
                    push!(factVariables, getVariable(destDFG, v_lab))
                    #otherwise ignore
                end
            end

            # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
            if includeOrphanFactors || length(factVariables) == length(neigh_labels)
                exists(destDFG, f.label) ? (@warn "_copyIntoGraph $(f.label) exists, ignoring") : addFactor!(destDFG, factVariables, deepcopy(f))
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
function getSubgraphAroundNode(dfg::LightDFG, node::DFGNode, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::LightDFG=LightDFG{AbstractParams}())::LightDFG
    if !exists(dfg,node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

	# Get a list of all unique neighbors inside 'distance'
	ns = neighborhood(dfg.g, dfg.g.labels[node.label], distance)

	# Copy the section of graph we want
	_copyIntoGraph!(dfg, addToDFG, ns, includeOrphanFactors)
	return addToDFG

end


"""
    $(SIGNATURES)
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::LightDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::LightDFG=LightDFG{AbstractParams}())::LightDFG
    for label in variableFactorLabels
        if !exists(dfg, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

	variableFactorInts = [dfg.g.labels[s] for s in variableFactorLabels]

    _copyIntoGraph!(dfg, addToDFG, variableFactorInts, includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}.
Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
The first row and first column are factor and variable headings respectively.
"""
function getAdjacencyMatrix(dfg::LightDFG)::Matrix{Union{Nothing, Symbol}}
	#TODO Why does it need to be sorted?
	varLabels = sort(collect(keys(dfg.g.variables)))#ort(map(v->v.label, getVariables(dfg)))
    factLabels = sort(collect(keys(dfg.g.factors)))#sort(map(f->f.label, getFactors(dfg)))
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

function getAdjacencyMatrixSparse(dfg::LightDFG)::Tuple{LightGraphs.SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}
	varLabels = collect(keys(dfg.g.variables))
    factLabels = collect(keys(dfg.g.factors))
	varIndex = [dfg.g.labels[s] for s in varLabels]
	factIndex = [dfg.g.labels[s] for s in factLabels]

	adj = adjacency_matrix(dfg.g)

	adjvf = adj[factIndex, varIndex]
	return adjvf, varLabels, factLabels
end

#=
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::LightDFG)::String
	@error "toDot(dfg::LightDFG) is not sopported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
    m = PipeBuffer()
    MetaGraphs.savedot(m, dfg.g)
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
function toDotFile(dfg::LightDFG, fileName::String="/tmp/dfg.dot")::Nothing
	@error "toDotFile(dfg::LightDFG,filename) is not sopported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
    open(fileName, "w") do fid
        MetaGraphs.savedot(fid, dfg.g)
    end
    return nothing
end
=#
