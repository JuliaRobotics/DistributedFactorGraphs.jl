import Base: ==, convert

##==============================================================================
## accessors
##==============================================================================

##==============================================================================
## TAGS as a set, list, merge, remove, empty
##==============================================================================
"""
$SIGNATURES

Return the tags for a variable or factor.
"""
function listTags(dfg::AbstractDFG, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  getTags(getFnc(dfg, sym))
end
#alias for completeness
listTags(f::DataLevel0) = getTags(f)

"""
    $SIGNATURES

Merge add tags to a variable or factor (union)
"""
function mergeTags!(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  union!(getTags(getFnc(dfg, sym)), tags)
end
mergeTags!(f::DataLevel0, tags::Vector{Symbol}) = union!(f.tags, tags)


"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
function removeTags!(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  setdiff!(getTags(getFnc(dfg, sym)), tags)
end
removeTags!(f::DataLevel0, tags::Vector{Symbol}) = setdiff!(f.tags, tags)

"""
$SIGNATURES

Empty all tags from the node (empty)
"""
function emptyTags!(dfg::AbstractDFG, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  empty!(getTags(getFnc(dfg, sym)))
end
emptyTags!(f::DataLevel0) = empty!(f.tags)


##==============================================================================
## Variable Node Data
##==============================================================================
##------------------------------------------------------------------------------
## CRUD
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
List all the solver data keys in the variable.
"""
function listVariableSolverData(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
    v = getVariable(dfg, variablekey)
    return collect(keys(v.solverDataDict))
end

"""
    $(SIGNATURES)
Get variable solverdata for a given solve key.
"""
function getVariableSolverData(dfg::AbstractDFG, variablekey::Symbol, solvekey::Symbol=:default)::VariableNodeData
    v = getVariable(dfg, variablekey)
    !haskey(v.solverDataDict, solvekey) && error("Solve key '$solvekey' not found in variable '$variablekey'")
    return v.solverDataDict[solvekey]
end


"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solvekey::Symbol=:default)::VariableNodeData
    var = getVariable(dfg, variablekey)
    if haskey(var.solverDataDict, solvekey)
        error("VariableNodeData '$(solvekey)' already exists")
    end
    var.solverDataDict[solvekey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Add a new solver data  entry from a deepcopy of the source variable solver data.
NOTE: Copies the solver data.
"""
addVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    addVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solvekey)), solvekey)


"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
"""
function updateVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solvekey::Symbol=:default)::VariableNodeData
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    if !haskey(var.solverDataDict, solvekey)
        @warn "VariableNodeData '$(solvekey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.solverDataDict[solvekey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
NOTE: Copies the solver data.
"""
updateVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    updateVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solvekey)), solvekey)

"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
"""
function updateVariableSolverData!(dfg::AbstractDFG, sourceVariables::Vector{<:DFGVariable}, solvekey::Symbol=:default)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solvekey), solvekey)
    end
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
function deleteVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, solvekey::Symbol=:default)::VariableNodeData
    var = getVariable(dfg, variablekey)

    if !haskey(var.solverDataDict, solvekey)
        error("VariableNodeData '$(solvekey)' does not exist")
    end
    vnd = pop!(var.solverDataDict, solvekey)
    return vnd
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
deleteVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    deleteVariableSolverData!(dfg, sourceVariable.label, solvekey)

##------------------------------------------------------------------------------
## SETs
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
If the same key is present in another collection, the value for that key will be the value it has in the last collection listed (updated).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
#TODO API
function mergeVariableSolverData!(destVariable::DFGVariable, sourceVariable::DFGVariable)::DFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.solverDataDict, deepcopy(sourceVariable.solverDataDict))
    return destVariable
end

##==============================================================================
## Point Parametric Estimates
##==============================================================================

##------------------------------------------------------------------------------
## CRUD
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
List all the PPE data keys in the variable.
"""
function listPPE(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
    v = getVariable(dfg, variablekey)
    return collect(keys(v.ppeDict))
end

"""
    $(SIGNATURES)
Get the parametric point estimate (PPE) for a variable in the factor graph for a given solve key.

Notes
- Defaults on keywords `solveKey` and `method`

Related
getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default)::AbstractPointParametricEst
    v = getVariable(dfg, variablekey)
    !haskey(v.ppeDict, ppekey) && error("PPE key '$ppekey' not found in variable '$variablekey'")
    return v.ppeDict[ppekey]
end

# Not the most efficient call but it at least reuses above (in memory it's probably ok)
getPPE(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=default)::AbstractPointParametricEst = getPPE(dfg, sourceVariable.label, ppekey)

"""
    $(SIGNATURES)
Add variable PPE, errors if it already exists.
"""
function addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default)::AbstractPointParametricEst where P <: AbstractPointParametricEst
    var = getVariable(dfg, variablekey)
    if haskey(var.ppeDict, ppekey)
        error("PPE '$(ppekey)' already exists")
    end
    var.ppeDict[ppekey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Add a new PPE entry from a deepcopy of the source variable PPE.
NOTE: Copies the solver data.
"""
addPPE!(dfg::AbstractDFG, sourceVariable::DFGVariable, ppekey::Symbol=:default) =
    addPPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)), ppekey)


"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default)::P where P <: AbstractPointParametricEst

    var = getVariable(dfg, variablekey)
    if !haskey(var.ppeDict, ppekey)
        @warn "PPE '$(ppekey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.ppeDict[ppekey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
NOTE: Copies the PPE data.
"""
updatePPE!(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=:default) =
    updatePPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)), ppekey)

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, sourceVariables::Vector{<:VariableDataLevel1}, ppekey::Symbol=:default)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(dfg, var, ppekey), ppekey)
    end
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
function deletePPE!(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default)::AbstractPointParametricEst
    var = getVariable(dfg, variablekey)

    if !haskey(var.ppeDict, ppekey)
        error("VariableNodeData '$(ppekey)' does not exist")
    end
    vnd = pop!(var.ppeDict, ppekey)
    return vnd
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
deletePPE!(dfg::AbstractDFG, sourceVariable::DFGVariable, ppekey::Symbol=:default) =
    deletePPE!(dfg, sourceVariable.label, ppekey)

##------------------------------------------------------------------------------
## Sets
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
#TODO API and only correct level
function mergePPEs!(destVariable::AbstractDFGVariable, sourceVariable::AbstractDFGVariable)::AbstractDFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.ppeDict, deepcopy(sourceVariable.ppeDict))
    return destVariable
end
