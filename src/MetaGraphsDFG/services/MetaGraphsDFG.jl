# Accessors
getLabelDict(dfg::MetaGraphsDFG) = copy(dfg.g.metaindex[:label])
getDescription(dfg::MetaGraphsDFG) = dfg.description
setDescription(dfg::MetaGraphsDFG, description::String) = dfg.description = description
getInnerGraph(dfg::MetaGraphsDFG) = dfg.g
getAddHistory(dfg::MetaGraphsDFG) = dfg.addHistory
getSolverParams(dfg::MetaGraphsDFG) = dfg.solverParams

# setSolverParams(dfg::MetaGraphsDFG, solverParams) = dfg.solverParams = solverParams
function setSolverParams(dfg::MetaGraphsDFG, solverParams::P) where P <: AbstractParams
  dfg.solverParams = solverParams
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::MetaGraphsDFG, node::N) where N <: DFGNode
    return haskey(dfg.g.metaindex[:label], node.label)
end
exists(dfg::MetaGraphsDFG, nId::Symbol) = haskey(dfg.g.metaindex[:label], nId)


"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::MetaGraphsDFG, variable::DFGVariable)::Bool
    if haskey(dfg.g.metaindex[:label], variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end

	#NOTE Internal ID always set to zero as it is not needed?
    # variable._internalId = 0

	#If other properties are needed in the graph itself, maybe :tags
	# props = Dict{:Symbol, Any}()
	# props[:tags] = variable.tags
	# props[:variable] = variable
	props = Dict(:variable=>variable)

	MetaGraphs.add_vertex!(dfg.g, :label, variable.label) || return false
	MetaGraphs.set_props!(dfg.g, nv(dfg.g), props) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::MetaGraphsDFG, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool
    if haskey(dfg.g.metaindex[:label], factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    for v in variables
        if !(v.label in keys(dfg.g.metaindex[:label]))
            error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
        end
    end

    factor._variableOrderSymbols = map(v->v.label, variables)

	#NOTE something like this or the next props definition
	# props = Dict{:Symbol, Any}()
	# props[:tags] = factor.tags
	# props[:factor] = factor

	props = Dict(:factor=>factor)

	MetaGraphs.add_vertex!(dfg.g, :label, factor.label) || return false
	set_props!(dfg.g, nv(dfg.g), props) || return false

    # Add index
    # push!(dfg.labels, factor.label)
    # Add the edges...
    for variable in variables
		MetaGraphs.add_edge!(dfg.g, dfg.g[variable.label,:label], dfg.g[factor.label,:label]) || return false
    end

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::MetaGraphsDFG, variableIds::Vector{Symbol}, factor::DFGFactor)::Bool
    variables = map(vId -> getVariable(dfg, vId), variableIds)
    return addFactor!(dfg, variables, factor)
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its underlying integer ID.
"""
function getVariable(dfg::MetaGraphsDFG, variableId::Int64)::DFGVariable
    return get_prop(dfg.g, variableId, :variable)
end

function getVariable(g::MetaGraph, variableId::Int64)::DFGVariable
    return get_prop(g, variableId, :variable)
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::MetaGraphsDFG, label::Union{Symbol, String})::DFGVariable
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.g.metaindex[:label], label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    return get_prop(dfg.g, dfg.g[label,:label], :variable)
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its underlying integer ID.
"""
function getFactor(dfg::MetaGraphsDFG, factorId::Int64)::DFGFactor
    # if !(factorId in values(dfg.g.metaindex[:label]))
    #     error("Factor ID '$(factorId)' does not exist in the factor graph")
    # end
    return get_prop(dfg.g, factorId, :factor)
end

function getFactor(g::MetaGraph, factorId::Int64)::DFGFactor
    # if !(factorId in values(dfg.g.metaindex[:label]))
    #     error("Factor ID '$(factorId)' does not exist in the factor graph")
    # end
    return get_prop(g, factorId, :factor)
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::MetaGraphsDFG, label::Union{Symbol, String})::DFGFactor
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.g.metaindex[:label], label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return get_prop(dfg.g, dfg.g[label,:label], :factor)
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::MetaGraphsDFG, variable::DFGVariable)::DFGVariable
    if !haskey(dfg.g.metaindex[:label], variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
	set_prop!(dfg.g, dfg.g[variable.label,:label], :variable, variable)
    return variable
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::MetaGraphsDFG, factor::DFGFactor)::DFGFactor
    if !haskey(dfg.g.metaindex[:label], factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
	set_prop!(dfg.g, dfg.g[factor.label,:label], :factor, factor)
    return factor
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::MetaGraphsDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.g.metaindex[:label], label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
	variable = get_prop(dfg.g, dfg.g[label,:label], :variable)
	rem_vertex!(dfg.g, dfg.g[label,:label])

    return variable
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
deleteVariable!(dfg::MetaGraphsDFG, variable::DFGVariable)::DFGVariable = deleteVariable!(dfg, variable.label)

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::MetaGraphsDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.g.metaindex[:label], label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
	factor = get_prop(dfg.g, dfg.g[label,:label], :factor)
	MetaGraphs.rem_vertex!(dfg.g, dfg.g[label,:label])
    return factor
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
deleteFactor!(dfg::MetaGraphsDFG, factor::DFGFactor)::DFGFactor = deleteFactor!(dfg, factor.label)

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable}

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
function getVariableIds(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol}
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
ls(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} = getVariableIds(dfg, regexFilter, tags=tags)

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
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
getFactorIds(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = map(f -> f.label, getFactors(dfg, regexFilter))

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
# Alias
lsf(dfg::MetaGraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = getFactorIds(dfg, regexFilter)

"""
	$(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::MetaGraphsDFG, label::Symbol)::Vector{Symbol}
  return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::MetaGraphsDFG)::Bool
    return length(LightGraphs.connected_components(dfg.g)) == 1
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
hasOrphans(dfg::MetaGraphsDFG)::Bool = !isFullyConnected(dfg)

function _isready(dfg::MetaGraphsDFG, idx::Int, ready::Int)::Bool
	p = props(dfg.g, idx)
	haskey(p, :variable) && (return p[:variable].ready == ready)
	haskey(p, :factor) && (return p[:factor].ready == ready)

	#TODO should this be an error?
	@warn "Node not a factor or variable"
	return false
end

function _isbackendset(dfg::MetaGraphsDFG, idx::Int, backendset::Int)::Bool
	p = props(dfg.g, idx)
	haskey(p, :variable) && (return p[:variable].backendset == backendset)
	haskey(p, :factor) && (return p[:factor].backendset == backendset)

	#TODO should this be an error?
	@warn "Node not a factor or variable"
	return false
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::MetaGraphsDFG, node::T; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.g.metaindex[:label], node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

	neighbors = map(idx->get_prop(dfg.g, idx, :label),  LightGraphs.neighbors(dfg.g, dfg.g[node.label,:label]))
    # Additional filtering
    neighbors = ready != nothing ? filter(lbl -> _isready(dfg, dfg.g[lbl,:label], ready), neighbors) : neighbors
	neighbors = backendset != nothing ? filter(lbl -> _isbackendset(dfg, dfg.g[lbl,:label], backendset), neighbors) : neighbors

    # Variable sorting (order is important)
    if node isa DFGFactor
        order = intersect(node._variableOrderSymbols, neighbors)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::MetaGraphsDFG, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.g.metaindex[:label], label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

    # neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
	neighbors = map(idx->get_prop(dfg.g, idx, :label),  LightGraphs.neighbors(dfg.g, dfg.g[label,:label]))
    # Additional filtering
	neighbors = ready != nothing ? filter(lbl -> _isready(dfg, dfg.g[lbl,:label], ready), neighbors) : neighbors
	neighbors = backendset != nothing ? filter(lbl -> _isbackendset(dfg, dfg.g[lbl,:label], backendset), neighbors) : neighbors

    # Variable sorting when using a factor (function order is important)
    if has_prop(dfg.g, dfg.g[label,:label], :factor)
		node = get_prop(dfg.g, dfg.g[label,:label], :factor)
		order = intersect(node._variableOrderSymbols, neighbors)
        return order
    end

	return neighbors

end

# Aliases
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::MetaGraphsDFG, node::T)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, node)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::MetaGraphsDFG, label::Symbol)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, label)
end

function _copyIntoGraph!(sourceDFG::MetaGraphsDFG, destDFG::MetaGraphsDFG, ns::Vector{Int}, includeOrphanFactors::Bool=false)::Nothing
	# Split into variables and factors
	subgraph = sourceDFG.g[ns]
	sourceVariableIds = collect(filter_vertices(subgraph, :variable))
	sourceFactorIds = collect(filter_vertices(subgraph, :factor))
	# or copy out of sourceDFG.
	# sourceFactorIds = intersect(ns, collect(filter_vertices(sourceDFG.g, :factor)))

	#get factor and variable nodes
	variables = map(vId->getVariable(subgraph, vId), sourceVariableIds)
	factors = map(fId->getFactor(subgraph, fId), sourceFactorIds)

	# Now we have to add all variables first,
	for v in variables
	    if !haskey(destDFG.g.metaindex[:label], v.label)
	        addVariable!(destDFG, deepcopy(v))
	    end
	end

    # And then all factors to the destDFG.
    for f in factors
        if !haskey(destDFG.g.metaindex[:label], f.label)
            # Get the original factor variables (we need them to create it)
            # variables = in_neighbors(factor, sourceDFG.g)
			# variables = getNeighbors(sourceDFG, f)
			varIds = LightGraphs.neighbors(sourceDFG.g, sourceDFG.g[f.label,:label])
			variables = map(vId->getVariable(sourceDFG.g, vId), varIds)

            # Find the labels and associated variables in our new subgraph
            factVariables = DFGVariable[]
            for v in variables
                if haskey(destDFG.g.metaindex[:label], v.label)
                    push!(factVariables, getVariable(destDFG, v.label))
                    #otherwise ignore
                end
            end

            # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
            if includeOrphanFactors || length(factVariables) == length(variables)
                addFactor!(destDFG, factVariables, deepcopy(f))
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
function getSubgraphAroundNode(dfg::MetaGraphsDFG{P}, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::MetaGraphsDFG=MetaGraphsDFG{P}())::MetaGraphsDFG where {P <: AbstractParams, T <: DFGNode}
    if !haskey(dfg.g.metaindex[:label], node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    # Get a list of all unique neighbors inside 'distance'
	ns = neighborhood(dfg.g, dfg.g[node.label,:label], distance)

	# Copy the section of graph we want
	# _copyIntoGraph!(dfg, addToDFG, map(n->get_prop(dfg.g, n, :label), ns), includeOrphanFactors)
	_copyIntoGraph!(dfg, addToDFG, ns, includeOrphanFactors)
    return addToDFG
end


function getSubgraphAroundNode(dfg::MetaGraphsDFG{<:AbstractParams}, node::DFGNode, distance::Int64, includeOrphanFactors::Bool, addToDFG::AbstractDFG)::AbstractDFG
    if !haskey(dfg.g.metaindex[:label], node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    # Get a list of all unique neighbors inside 'distance'
	ns = neighborhood(dfg.g, dfg.g[node.label,:label], distance)

	# Copy the section of graph we want
	_copyIntoGraph!(dfg, addToDFG, map(n->get_prop(dfg.g, n, :label), ns), includeOrphanFactors)
	# _copyIntoGraph!(dfg, addToDFG, ns, includeOrphanFactors)
    return addToDFG
end


"""
    $(SIGNATURES)
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::MetaGraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::MetaGraphsDFG=MetaGraphsDFG{AbstractParams}())::MetaGraphsDFG
    for label in variableFactorLabels
        if !haskey(dfg.g.metaindex[:label], label)
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
function getAdjacencyMatrix(dfg::MetaGraphsDFG)::Matrix{Union{Nothing, Symbol}}
    varLabels = map(v->v.label, getVariables(dfg))
    factLabels = map(f->f.label, getFactors(dfg))
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

function getAdjacencyMatrixSparse(dfg::MetaGraphsDFG)::Tuple{LightGraphs.SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}
    adj = LightGraphs.adjacency_matrix(dfg.g)
	v_labels = getVariableIds(dfg)
	f_labels = getFactorIds(dfg)
	v_index = [dfg.g[s,:label] for s in v_labels]
	f_index = [dfg.g[s,:label] for s in f_labels]
	adjvf = adj[f_index, v_index]
	return adjvf, v_labels, f_labels
end

#FIXME remove _ when issue #86 is resolved, for now force dispach to generic toDot
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function _toDot(dfg::MetaGraphsDFG)::String
	@error "toDot(dfg::MetaGraphsDFG) is not sopported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
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
function _toDotFile(dfg::MetaGraphsDFG, fileName::String="/tmp/dfg.dot")::Nothing
	@error "toDotFile(dfg::MetaGraphsDFG,filename) is not supported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
    open(fileName, "w") do fid
        MetaGraphs.savedot(fid, dfg.g)
    end
    return nothing
end
