
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
"""
function updateVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable)::DFGVariable
    if !exists(dfg, sourceVariable)
        error("Source variable '$(sourceVariable.label)' doesn't exist in the graph.")
    end
    var = getVariable(dfg, sourceVariable.label)
    merge!(var.estimateDict, sourceVariable.estimateDict)
    merge!(var.solverDataDict, sourceVariable.solverDataDict)
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

## Utility functions for getting type names and modules (from IncrementalInference)
function _getmodule(t::T) where T
  T.name.module
end
function _getname(t::T) where T
  T.name.name
end

## Interfaces
"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a tuple: adjmat::SparseMatrixCSC{Int}, var_labels::Vector{Symbol) fac_labels::Vector{Symbol).
Rows are the factors, columns are the variables, with the corresponding labels in fac_labels,var_labels.
"""
getAdjacencyMatrixSparse(dfg::AbstractDFG) =  error("getAdjacencyMatrixSparse not implemented for $(typeof(dfg))")


"""
    $SIGNATURES

Return boolean whether a factor `label` is present in `<:AbstractDFG`.
"""
function hasFactor(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
  return haskey(dfg.labelDict, label)
end

"""
    $(SIGNATURES)

Return `::Bool` on whether `dfg` contains the variable `lbl::Symbol`.
"""
function hasVariable(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
  return haskey(dfg.labelDict, label) # haskey(vertices(dfg.g), label)
end


"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
TODO: Refactor
"""
function isInitialized(var::DFGVariable; key::Symbol=:default)::Bool
  return var.solverDataDict[key].initialized
end
function isInitialized(fct::DFGFactor; key::Symbol=:default)::Bool
  return fct.solverDataDict[key].initialized
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
