## ===== Interface for an AbstractDFG =====

"""
    $(SIGNATURES)

De-serialization of IncrementalInference objects require discovery of foreign types.

Example:

Template to tunnel types from a user module:
```julia
# or more generic solution -- will always try Main if available
IIF.setSerializationNamespace!(Main)

# or a specific package such as RoME if you import all variable and factor types into a specific module.
using RoME
IIF.setSerializationNamespace!(RoME)
```
"""
function setSerializationModule!(dfg::G, mod::Module)::Nothing where G <: AbstractDFG
    @warn "Setting serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is being ignored."
end

function getSerializationModule(dfg::G)::Module where G <: AbstractDFG
    @warn "Retrieving serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is returning Main"
    return Main
end

# Accessors
function getLabelDict(dfg::G) where G <: AbstractDFG
	error("getLabelDict not implemented for $(typeof(dfg))")
end
function getDescription(dfg::G) where G <: AbstractDFG
	error("getDescription not implemented for $(typeof(dfg))")
end
function setDescription(dfg::G, description::String) where G <: AbstractDFG
	error("setDescription not implemented for $(typeof(dfg))")
end
function getInnerGraph(dfg::G) where G <: AbstractDFG
	error("getInnerGraph not implemented for $(typeof(dfg))")
end
function getAddHistory(dfg::G) where G <: AbstractDFG
	error("getAddHistory not implemented for $(typeof(dfg))")
end
function getSolverParams(dfg::G) where G <: AbstractDFG
	error("getSolverParams not implemented for $(typeof(dfg))")
end
function setSolverParams(dfg::G, solverParams::T) where {G <: AbstractDFG, T <: AbstractParams}
	error("setSolverParams not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
True if the variable or factor exists in the graph.
"""
function exists(dfg::G, node::N) where {G <: AbstractDFG, N <: DFGNode}
	error("exists not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::G, variable::V)::Bool where {G <: AbstractDFG, V <: AbstractDFGVariable}
	error("addVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::G, variables::Vector{V}, factor::F)::Bool where {G <: AbstractDFG, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
	error("addFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::G, variableIds::Vector{Symbol}, factor::F)::Bool where {G <: AbstractDFG, F <: AbstractDFGFactor}
	error("addFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its underlying integer ID.
"""
function getVariable(dfg::G, variableId::Int64)::AbstractDFGVariable where G <: AbstractDFG
	error("getVariable not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::G, label::Union{Symbol, String})::AbstractDFGVariable where G <: AbstractDFG
	return getVariable(dfg, Symbol(label))
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its underlying integer ID.
"""
function getFactor(dfg::G, factorId::Int64)::AbstractDFGFactor where G <: AbstractDFG
	error("getFactor not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::G, label::Union{Symbol, String})::AbstractDFGFactor where G <: AbstractDFG
	return getFactor(dfg, Symbol(label))
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::G, variable::V)::AbstractDFGVariable where {G <: AbstractDFG, V <: AbstractDFGVariable}
	error("updateVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::G, factor::F)::AbstractDFGFactor where {G <: AbstractDFG, F <: AbstractDFGFactor}
	error("updateFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::G, label::Symbol)::AbstractDFGVariable where G <: AbstractDFG
	error("deleteVariable! not implemented for $(typeof(dfg))")
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
function deleteVariable!(dfg::G, variable::V)::AbstractDFGVariable where {G <: AbstractDFG, V <: AbstractDFGVariable}
	return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::G, label::Symbol)::AbstractDFGFactor where G <: AbstractDFG
	error("deleteFactors not implemented for $(typeof(dfg))")
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
function deleteFactor!(dfg::G, factor::F)::AbstractDFGFactor where {G <: AbstractDFG, F <: AbstractDFGFactor}
	return deleteFactor!(dfg, factor.label)
end

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{AbstractDFGVariable} where G <: AbstractDFG
	error("getVariables not implemented for $(typeof(dfg))")
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
function getVariableIds(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} where G <: AbstractDFG
  vars = getVariables(dfg, regexFilter, tags=tags)
  # mask = map(v -> length(intersect(v.tags, tags)) > 0, vars )
  return map(v -> v.label, vars)
end

# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function ls(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{Symbol} where G <: AbstractDFG
	return getVariableIds(dfg, regexFilter, tags=tags)
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing)::Vector{AbstractDFGFactor} where G <: AbstractDFG
	error("getFactors not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a list of the IDs of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactorIds(dfg::G, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} where G <: AbstractDFG
	return map(f -> f.label, getFactors(dfg, regexFilter))
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
# Alias
function lsf(dfg::G, regexFilter::Union{Nothing, Regex}=nothing)::Vector{Symbol} where G <: AbstractDFG
	return getFactorIds(dfg, regexFilter)
end

"""
	$(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::G, label::Symbol)::Vector{Symbol} where G <: AbstractDFG
  return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::G)::Bool where G <: AbstractDFG
	error("isFullyConnected not implemented for $(typeof(dfg))")
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
function hasOrphans(dfg::G)::Bool where G <: AbstractDFG
	return !isFullyConnected(dfg)
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::G, node::T; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol}  where {G <: AbstractDFG, T <: DFGNode}
	error("getNeighbors not implemented for $(typeof(dfg))")
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::G, label::Symbol; ready::Union{Nothing, Int}=nothing, backendset::Union{Nothing, Int}=nothing)::Vector{Symbol} where G <: AbstractDFG
	error("getNeighbors not implemented for $(typeof(dfg))")
end

# Aliases
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::G, node::T)::Vector{Symbol} where {G <: AbstractDFG, T <: DFGNode}
    return getNeighbors(dfg, node)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::G, label::Symbol)::Vector{Symbol} where G <: AbstractDFG
    return getNeighbors(dfg, label)
end

"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::G)::G where G <: AbstractDFG
	error("_getDuplicatedEmptyDFG not implemented for $(typeof(dfg))")
end

# TODO: NEED TO FIGURE OUT SIGNATURE FOR DEFAULT ARGS

"""
    $(SIGNATURES)
Retrieve a deep subgraph copy around a given variable or factor.
Optionally provide a distance to specify the number of edges should be followed.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraphAroundNode(dfg::G, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::H=_getDuplicatedEmptyDFG(dfg))::G where {G <: AbstractDFG, H <: AbstractDFG, P <: AbstractParams, T <: DFGNode}
	error("getSubgraphAroundNode not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::G,
					 variableFactorLabels::Vector{Symbol},
					 includeOrphanFactors::Bool=false,
					 addToDFG::H=_getDuplicatedEmptyDFG(dfg))::H where {G <: AbstractDFG, H <: AbstractDFG}
    for label in variableFactorLabels
        if !exists(dfg, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
"""
function _copyIntoGraph!(sourceDFG::G, destDFG::H, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Split into variables and factors
    sourceVariables = map(vId->getVariable(sourceDFG, vId), intersect(getVariableIds(sourceDFG), variableFactorLabels))
    sourceFactors = map(fId->getFactor(sourceDFG, fId), intersect(getFactorIds(sourceDFG), variableFactorLabels))
    if length(sourceVariables) + length(sourceFactors) != length(variableFactorLabels)
        rem = symdiff(map(v->v.label, sourceVariables), variableFactorLabels)
        rem = symdiff(map(f->f.label, sourceFactors), variableFactorLabels)
        error("Cannot copy because cannot find the following nodes in the source graph: $rem")
    end

    # Now we have to add all variables first,
    for variable in sourceVariables
        if !exists(destDFG, variable)
            addVariable!(destDFG, deepcopy(variable))
        end
    end
    # And then all factors to the destDFG.
    for factor in sourceFactors
        # Get the original factor variables (we need them to create it)
        sourceFactorVariableIds = getNeighbors(sourceDFG, factor)
        # Find the labels and associated variables in our new subgraph
        factVariableIds = Symbol[]
        for variable in sourceFactorVariableIds
            if exists(destDFG, variable)
                push!(factVariableIds, variable)
            end
        end
        # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
        if includeOrphanFactors || length(factVariableIds) == length(sourceFactorVariableIds)
            if !exists(destDFG, factor)
                addFactor!(destDFG, factVariableIds, deepcopy(factor))
            end
        end
    end
    return nothing
end

"""
    $(SIGNATURES)
Update solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling
between graphs.
"""
function updateVariableSolverData!(dfg::AbstractDFG, sourceVariable::AbstractDFGVariable)::AbstractDFGVariable
    if !exists(dfg, sourceVariable)
        error("Source variable '$(sourceVariable.label)' doesn't exist in the graph.")
    end
    var = getVariable(dfg, sourceVariable.label)
    # We don't know which graph this came from, must be copied!
    merge!(var.estimateDict, deepcopy(sourceVariable.estimateDict))
	# If this variable has solverDataDict (summaries do not)
	:solverDataDict in fieldnames(typeof(var)) && merge!(var.solverDataDict, deepcopy(sourceVariable.solverDataDict))
    return sourceVariable
end

"""
    $(SIGNATURES)
Common function to update all solver data and estimates from one graph to another.
This should be used to push local solve data back into a cloud graph, for example.
"""
function updateGraphSolverData!(sourceDFG::G, destDFG::H, varSyms::Vector{Symbol})::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Update all variables in the destination
    # (For now... we may change this soon)
    for variableId in varSyms
        updateVariableSolverData!(destDFG, getVariable(sourceDFG, variableId))
    end
end

"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}.
Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
The first row and first column are factor and variable headings respectively.
"""
function getAdjacencyMatrix(dfg::G)::Matrix{Union{Nothing, Symbol}} where G <: AbstractDFG
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
Get an adjacency matrix for the DFG, returned as a tuple: adjmat::SparseMatrixCSC{Int}, var_labels::Vector{Symbol) fac_labels::Vector{Symbol).
Rows are the factors, columns are the variables, with the corresponding labels in fac_labels,var_labels.
"""
function getAdjacencyMatrixSparse(dfg::G)::Tuple{LightGraphs.SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}} where G <: AbstractDFG
	varLabels = map(v->v.label, getVariables(dfg))
	factLabels = map(f->f.label, getFactors(dfg))

	vDict = Dict(varLabels .=> [1:length(varLabels)...])

	adjMat = spzeros(Int, length(factLabels), length(varLabels))

	for (fIndex, factLabel) in enumerate(factLabels)
		factVars = getNeighbors(dfg, getFactor(dfg, factLabel))
	    map(vLabel -> adjMat[fIndex,vDict[vLabel]] = 1, factVars)
	end
	return adjMat, varLabels, factLabels
end

"""
    $SIGNATURES

Return boolean whether a factor `label` is present in `<:AbstractDFG`.
"""
function hasFactor(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
	@warn "hasFactor() deprecated, please use exists()"
	return haskey(dfg.labelDict, label)
end

"""
    $(SIGNATURES)

Return `::Bool` on whether `dfg` contains the variable `lbl::Symbol`.
"""
function hasVariable(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
	@warn "hasVariable() deprecated, please use exists()"
	return haskey(dfg.labelDict, label) # haskey(vertices(dfg.g), label)
end


"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::DFGVariable; key::Symbol=:default)::Bool
  solverData(var, key) != nothing && return solverData(var, key).initialized
  return false
end
function isInitialized(fct::DFGFactor; key::Symbol=:default)::Bool
  solverData(var, key) != nothing && return solverData(fct, key).initialized
  return false
end
function isInitialized(dfg::G, label::Symbol; key::Symbol=:default)::Bool where G <: AbstractDFG
  return isInitialized(getVariable(dfg, label), key=key)
end


"""
    $SIGNATURES

Return whether `sym::Symbol` represents a variable vertex in the graph.
"""
isVariable(dfg::G, sym::Symbol) where G <: AbstractDFG = hasVariable(dfg, sym)

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a factor vertex in the graph.
"""
isFactor(dfg::G, sym::Symbol) where G <: AbstractDFG = hasFactor(dfg, sym)

"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fcd::GenericFunctionNodeData) = fcd.fnc.usrfnc!
getFactorFunction(fc::DFGFactor) = getFactorFunction(getData(fc))
function getFactorFunction(dfg::G, fsym::Symbol) where G <: AbstractDFG
  getFactorFunction(getFactor(dfg, fsym))
end


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
showFactor(fgl::G, fsym::Symbol) where G <: AbstractDFG = @show getFactor(fgl,fsym)


"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::AbstractDFG)::String
    @warn "Falling Back to convert to GraphsDFG"
    #TODO implement convert
    graphsdfg = GraphsDFG{AbstractParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, graphsdfg, union(getVariableIds(dfg), getFactorIds(dfg)), true)

	# Calls down to GraphsDFG.toDot
    return toDot(graphsdfg)
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
function toDotFile(dfg::AbstractDFG, fileName::String="/tmp/dfg.dot")::Nothing
    @warn "Falling Back to convert to GraphsDFG"
    #TODO implement convert
    graphsdfg = GraphsDFG{AbstractParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, graphsdfg, union(getVariableIds(dfg), getFactorIds(dfg)), true)

    open(fileName, "w") do fid
        write(fid,Graphs.to_dot(graphsdfg.g))
    end
    return nothing
end

"""
    $(SIGNATURES)
Get a summary of the graph (first-class citizens of variables and factors).
Returns a AbstractDFGSummary.
"""
function getSummary(dfg::G)::AbstractDFGSummary where {G <: AbstractDFG}
	vars = map(v -> convert(DFGVariableSummary, v), getVariables(dfg))
	facts = map(f -> convert(DFGFactorSummary, f), getFactors(dfg))
	return AbstractDFGSummary(
		Dict(map(v->v.label, vars) .=> vars),
		Dict(map(f->f.label, facts) .=> facts),
		dfg.userId,
		dfg.robotId,
		dfg.sessionId)
end

"""
$(SIGNATURES)
Get a summary graph (first-class citizens of variables and factors) with the same structure as the original graph.
Note this is a copy of the original.
Returns a LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}.
"""
function getSummaryGraph(dfg::G)::LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary} where {G <: AbstractDFG}
	summaryDfg = LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}(
		description="Summary of $(dfg.description)",
		userId=dfg.userId,
		robotId=dfg.robotId,
		sessionId=dfg.sessionId)
	for v in getVariables(dfg)
		newV = addVariable!(summaryDfg, convert(DFGVariableSummary, v))
	end
	for f in getFactors(dfg)
		addFactor!(summaryDfg, getNeighbors(dfg, f), convert(DFGFactorSummary, f))
	end
	return summaryDfg
end
