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
function addVariable!(dfg::G, variable::DFGVariable)::Bool where G <: AbstractDFG
	error("addVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::G, variables::Vector{DFGVariable}, factor::DFGFactor)::Bool where G <: AbstractDFG
	error("addFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGFactor to a DFG.
"""
function addFactor!(dfg::G, variableIds::Vector{Symbol}, factor::DFGFactor)::Bool where G <: AbstractDFG
	error("addFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its underlying integer ID.
"""
function getVariable(dfg::G, variableId::Int64)::DFGVariable where G <: AbstractDFG
	error("getVariable not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::G, label::Union{Symbol, String})::DFGVariable where G <: AbstractDFG
	error("getVariable not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its underlying integer ID.
"""
function getFactor(dfg::G, factorId::Int64)::DFGFactor where G <: AbstractDFG
	error("getFactor not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::G, label::Union{Symbol, String})::DFGFactor where G <: AbstractDFG
	error("getFactor not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::G, variable::DFGVariable)::DFGVariable where G <: AbstractDFG
	error("updateVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::G, factor::DFGFactor)::DFGFactor where G <: AbstractDFG
	error("updateFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::G, label::Symbol)::DFGVariable where G <: AbstractDFG
	error("deleteVariable! not implemented for $(typeof(dfg))")
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
function deleteVariable!(dfg::G, variable::DFGVariable)::DFGVariable where G <: AbstractDFG
	return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::G, label::Symbol)::DFGFactor where G <: AbstractDFG
	error("deleteFactors not implemented for $(typeof(dfg))")
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
function deleteFactor!(dfg::G, factor::DFGFactor)::DFGFactor where G <: AbstractDFG
	return deleteFactor!(dfg, factor.label)
end

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
function getVariables(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[])::Vector{DFGVariable} where G <: AbstractDFG
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
function getFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor} where G <: AbstractDFG
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
Get an adjacency matrix for the DFG, returned as a Matrix{Union{Nothing, Symbol}}.
Rows are all factors, columns are all variables, and each cell contains either nothing or the symbol of the relating factor.
The first row and first column are factor and variable headings respectively.
"""
function getAdjacencyMatrix(dfg::G)::Matrix{Union{Nothing, Symbol}} where G <: AbstractDFG
	error("getAdjacencyMatrix not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::G)::String where G <: AbstractDFG
	error("toDot not implemented for $(typeof(dfg))")
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
function toDotFile(dfg::G, fileName::String="/tmp/dfg.dot")::Nothing where G <: AbstractDFG
	error("toDotFile not implemented for $(typeof(dfg))")
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
Get an adjacency matrix for the DFG, returned as a tuple: adjmat::SparseMatrixCSC{Int}, var_labels::Vector{Symbol) fac_labels::Vector{Symbol).
Rows are the factors, columns are the variables, with the corresponding labels in fac_labels,var_labels.
"""
function getAdjacencyMatrixSparse(dfg::G) where G <: AbstractDFG
    error("getAdjacencyMatrixSparse not implemented for $(typeof(dfg))")
end
