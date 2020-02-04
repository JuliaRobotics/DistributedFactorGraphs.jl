
# Accessors
getLabelDict(dfg::SymbolDFG) = copy(dfg.g.fadjdict)
getDescription(dfg::SymbolDFG) = dfg.description
setDescription(dfg::SymbolDFG, description::String) = dfg.description = description
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
function exists(dfg::SymbolDFG{P,V,F}, node::V) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode, N <: DFGNode}
    return haskey(dfg.g.variables, node.label)
end

function exists(dfg::SymbolDFG{P,V,F}, node::F) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode, N <: DFGNode}
    return haskey(dfg.g.factors, node.label)
end

exists(dfg::SymbolDFG, nId::Symbol) = haskey(dfg.g.fadjdict, nId)

exists(dfg::SymbolDFG, node::DFGNode) = exists(dfg, node.label)

function isVariable(dfg::SymbolDFG{P,V,F}, sym::Symbol) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode}
	return haskey(dfg.g.variables, sym)
end

function isFactor(dfg::SymbolDFG{P,V,F}, sym::Symbol) where {P <:AbstractParams, V <: DFGNode, F <: DFGNode}
	return haskey(dfg.g.factors, sym)
end

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
    # variable._internalId = 0

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
function getVariables(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{DFGVariable}

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    variables = collect(values(dfg.g.variables))
    if regexFilter != nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
    if solvable != 0
        variables = filter(v -> _isSolvable(dfg, v.label, solvable), variables)
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
getVariableIds(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} = map(v -> v.label, getVariables(dfg, regexFilter, tags=tags, solvable=solvable))

# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
"""
ls(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} = getVariableIds(dfg, regexFilter, tags=tags, solvable=solvable)

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{DFGFactor}
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    factors = collect(values(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
    end
    if solvable != 0
        factors = filter(f -> _isSolvable(dfg, f.label, solvable), factors)
    end
    return factors
end

"""
    $(SIGNATURES)
Get a list of the IDs of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
getFactorIds(dfg::SymbolDFG, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{Symbol} = map(f -> f.label, getFactors(dfg, regexFilter, solvable=solvable))

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::SymbolDFG)::Bool
    return length(LightGraphs.connected_components(dfg.g)) == 1
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
hasOrphans(dfg::SymbolDFG)::Bool = !isFullyConnected(dfg)

function _isSolvable(dfg::SymbolDFG, label::Symbol, solvable::Int)::Bool

    haskey(dfg.g.variables, label) && (return dfg.g.variables[label].solvable >= solvable)
    haskey(dfg.g.factors, label) && (return dfg.g.factors[label].solvable >= solvable)

    #TODO should this be a breaking error?
    @error "Node not in factor or variable"
    return false
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::SymbolDFG, node::DFGNode; solvable::Int=0)::Vector{Symbol}
    label = node.label
    if !haskey(dfg.g.fadjdict, label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    neighbors_ll =  copy(outneighbors(dfg.g, label))
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

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
function getNeighbors(dfg::SymbolDFG, label::Symbol; solvable::Int=0)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.g.fadjdict, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

    neighbors_ll =  copy(outneighbors(dfg.g, label))
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label]._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll

end

# function _copyIntoGraph!(sourceDFG{AbstractParam,DFGVariable,DFGFactor}::SymbolDFG, destDFG{AbstractParam,DFGVariable,DFGFactor}::SymbolDFG, labels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing
function _copyIntoGraph!(sourceDFG::SymbolDFG, destDFG::SymbolDFG, labels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing

    # Add all variables first,
    for v in values(sourceDFG.g.variables)
        if v.label in labels
            exists(destDFG, v) ? (@warn "_copyIntoGraph $(v.label) exists, ignoring") : addVariable!(destDFG, deepcopy(v))
        end
    end

    # And then all factors to the destDFG.
    for f in values(sourceDFG.g.factors)
        if f.label in labels
            # Get the original factor variables (we need them to create it)
            neigh_labels = outneighbors(sourceDFG.g, f.label)

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

# moved to abstract 
# """
#     $(SIGNATURES)
# Retrieve a deep subgraph copy around a given variable or factor.
# Optionally provide a distance to specify the number of edges should be followed.
# Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
# Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
# """
# function getSubgraphAroundNode(dfg::SymbolDFG, node::DFGNode, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::SymbolDFG=SymbolDFG{AbstractParams}(); solvable::Int=0)::SymbolDFG
#     if !exists(dfg,node.label)
#         error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
#     end
#
#     nodelabel = node.label
#     # Build a list of all unique neighbors inside 'distance'
#     neighborList = Symbol[nodelabel]
#
#     curList = Symbol[nodelabel]
#
#     for dist in 1:distance
#         newNeighbors = Symbol[]
#         for cl in curList
#             neighbors = outneighbors(dfg.g, cl)
#             for neighbor in neighbors
#                 if !(neighbor in neighborList) && _isSolvable(dfg, neighbor, solvable)
#                     push!(neighborList, neighbor)
#                     push!(newNeighbors, neighbor)
#                 end
#             end
#         end
#         curList = newNeighbors
#     end
#
#
#     # _copyIntoGraph!(dfg, addToDFG, map(n->get_prop(dfg.g, n, :label), ns), includeOrphanFactors)
#     _copyIntoGraph!(dfg, addToDFG, neighborList, includeOrphanFactors)
#     return addToDFG
# end


"""
    $(SIGNATURES)
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::SymbolDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::SymbolDFG=SymbolDFG{AbstractParams}())::SymbolDFG
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
function getIncidenceMatrix(dfg::SymbolDFG; solvable::Int=0)::Matrix{Union{Nothing, Symbol}}
    varLabels = map(v->v.label, getVariables(dfg, solvable=solvable))
    factLabels = map(f->f.label, getFactors(dfg, solvable=solvable))
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


function getIncidenceMatrixSparse(dfg::SymbolDFG; solvable::Int=0)::Tuple{LightGraphs.SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}
    varLabels = getVariableIds(dfg, solvable=solvable)
    factLabels = getFactorIds(dfg, solvable=solvable)

    vDict = Dict(varLabels .=> [1:length(varLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = outneighbors(dfg.g, factLabel)
        map(vLabel -> adjMat[fIndex,vDict[vLabel]] = 1, factVars)
    end
    return adjMat, varLabels, factLabels
end

"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::SymbolDFG{T,V,F})::SymbolDFG where {T <: AbstractParams, V <: DFGNode, F <:DFGNode}
    newDfg = SymbolDFG{T, V, F}(;
        userId=dfg.userId, robotId=dfg.robotId, sessionId=dfg.sessionId,
        params=deepcopy(dfg.solverParams))
    newDfg.description ="(Copy of) $(dfg.description)"
    return newDfg
end
