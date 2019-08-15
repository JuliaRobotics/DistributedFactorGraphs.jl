import ...DistributedFactorGraphs: DFGVariable, DFGFactor

# Accessors
getLabelDict(dfg::SymbolDFG) = dfg.labelDict
getDescription(dfg::SymbolDFG) = dfg.description
setDescription(dfg::SymbolDFG, description::String) = dfg.description = description
getInnerGraph(dfg::SymbolDFG) = dfg.g
getAddHistory(dfg::SymbolDFG) = dfg.addHistory
getSolverParams(dfg::SymbolDFG) = dfg.solverParams

# setSolverParams(dfg::SymbolDFG, solverParams) = dfg.solverParams = solverParams
function setSolverParams(dfg::SymbolDFG, solverParams::P) where P <: AbstractParams
  dfg.solverParams = solverParams
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::SymbolDFG{P,V,F}, node::N) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode, N <: DFGNode}
    # TODO just checking for key, maybe check equallity?
    if N == V
        return haskey(dfg.g.variables, node.label)
    elseif N == F
        return haskey(dfg.g.variables, node.label)
    else
        @error "Node $(N) not a variable or a factor of type $(V),$(F)"
        return false
    end

end
exists(dfg::SymbolDFG, nId::Symbol) = haskey(dfg.g.fadjdict, nId)



"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::SymbolDFG, variable::DFGVariable)::Bool
	#TODO should this be an error
	if haskey(dfg.g.variables, variable.label)
		error("Variable '$(variable.label)' already exists in the factor graph")
	end

	#NOTE Internal ID always set to zero as it is not needed?
    variable._internalId = 0

	SymbolFactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return true
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::SymbolDFG, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool
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


    return SymbolFactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::SymbolDFG, variableLabels::Vector{Symbol}, factor::DFGFactor)::Bool
	#TODO should this be an error
	if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
	factor._internalId = 0

    factor._variableOrderSymbols = variableLabels

    return SymbolFactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end


"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::SymbolDFG, label::Symbol)::DFGVariable
    return dfg.g.variables[label]
end

getVariable(dfg::SymbolDFG, label::String) = getVariable(dfg, Symbol(label))

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::SymbolDFG, label::Symbol)::DFGFactor
    return dfg.g.factors[label]
end

getFactor(dfg::SymbolDFG, label::String) = getFactor(dfg, Symbol(label))


"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::SymbolDFG, variable::DFGVariable)::DFGVariable
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
function updateFactor!(dfg::SymbolDFG, factor::DFGFactor)::DFGFactor
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
function deleteVariable!(dfg::SymbolDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
	variable = dfg.g.variables[label]
	rem_vertex!(dfg.g, label)

    return variable
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
deleteVariable!(dfg::SymbolDFG, variable::DFGVariable)::DFGVariable = deleteVariable!(dfg, variable.label)

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::SymbolDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
	factor = dfg.g.factors[label]
	variable = rem_vertex!(dfg.g, label)
    return factor
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
deleteFactor!(dfg::SymbolDFG, factor::DFGFactor)::DFGFactor = deleteFactor!(dfg, factor.label)

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable}

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
getVariableIds(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} = map(v -> v.label, getVariables(dfg, regexFilter, tags=tags))

# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
ls(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} = getVariableIds(dfg, regexFilter, tags=tags)

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
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
getFactorIds(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = map(f -> f.label, getFactors(dfg, regexFilter))

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
# Alias
lsf(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} = getFactorIds(dfg, regexFilter)

"""
	$(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::SymbolDFG, label::Symbol)::Vector{Symbol}
  return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::SymbolDFG)::Bool
    return length(connected_components(dfg.g)) == 1
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
hasOrphans(dfg::SymbolDFG)::Bool = !isFullyConnected(dfg)

function _isready(dfg::SymbolDFG, label::Symbol, ready::Int)::Bool

	haskey(dfg.g.variables, label) && (return dfg.g.variables[label].ready == ready)
	haskey(dfg.g.factors, label) && (return dfg.g.factors[label].ready == ready)

	#TODO should this be a breaking error?
	@error "Node not in factor or variable"
	return false
end

function _isbackendset(dfg::SymbolDFG, label::Symbol, backendset::Int)::Bool
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
function getNeighbors(dfg::SymbolDFG, node::DFGNode; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}
	label = node.label
    if !haskey(dfg.g.fadjdict, label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

	neighbors_ll =  outneighbors(dfg.g, label)
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
function getNeighbors(dfg::SymbolDFG, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where T <: DFGNode
	if !haskey(dfg.g.fadjdict, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

	neighbors_ll =  outneighbors(dfg.g, label)
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
function ls(dfg::SymbolDFG, node::T)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, node)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::SymbolDFG, label::Symbol)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, label)
end

#=
function _copyIntoGraph!(sourceDFG::SymbolDFG, destDFG::SymbolDFG, ns::Vector{Int}, includeOrphanFactors::Bool=false)::Nothing
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
function getSubgraphAroundNode(dfg::SymbolDFG{P}, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::SymbolDFG=SymbolDFG{P}())::SymbolDFG where {P <: AbstractParams, T <: DFGNode}
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


function getSubgraphAroundNode(dfg::SymbolDFG{<:AbstractParams}, node::DFGNode, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::AbstractDFG=SymbolDFG{AbstractParams}())::AbstractDFG
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
function getSubgraph(dfg::SymbolDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::SymbolDFG=SymbolDFG{AbstractParams}())::SymbolDFG
    for label in variableFactorLabels
        if !haskey(dfg.g.metaindex[:label], label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end
=#
"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}.
Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
The first row and first column are factor and variable headings respectively.
"""
function getAdjacencyMatrix(dfg::SymbolDFG)::Matrix{Union{Nothing, Symbol}}
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

#=
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::SymbolDFG)::String
	@error "toDot(dfg::SymbolDFG) is not sopported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
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
function toDotFile(dfg::SymbolDFG, fileName::String="/tmp/dfg.dot")::Nothing
	@error "toDotFile(dfg::SymbolDFG,filename) is not sopported yet, see https://github.com/JuliaGraphs/MetaGraphs.jl/issues/86"
    open(fileName, "w") do fid
        MetaGraphs.savedot(fid, dfg.g)
    end
    return nothing
end
=#
