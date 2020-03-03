##==============================================================================
## Accessors
##==============================================================================
##==============================================================================
## PointParametricEst
##==============================================================================
"$(SIGNATURES)"
getMaxPPE(est::AbstractPointParametricEst) = est.max
"$(SIGNATURES)"
getMeanPPE(est::AbstractPointParametricEst) = est.mean
"$(SIGNATURES)"
getSuggestedPPE(est::AbstractPointParametricEst) = est.suggested
"$(SIGNATURES)"
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = est.lastUpdatedTimestamp

##==============================================================================
## Variable Node Data
##==============================================================================

## COMMON
# getSolveInProgress
# isSolveInProgress

##------------------------------------------------------------------------------
## softtype
##------------------------------------------------------------------------------
"""
   $(SIGNATURES)

Variable nodes softtype information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Related

getVariableType
"""
function getSofttype(vnd::VariableNodeData)
  return vnd.softtype
end

getSofttype(v::DFGVariable, solvekey::Symbol=:default) = getSofttype(getSolverData(v, solvekey))

getSofttype(dfg::AbstractDFG, lbl::Symbol, solvekey::Symbol=:default) = getSofttype(getVariable(dfg,lbl), solvekey)

"""
    getVariableType

Alias for [`getSofttype`](@ref).
"""
getVariableType(params...) = getSofttype(params...)

##------------------------------------------------------------------------------
## solvedCount
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get the number of times a variable has been inferred -- i.e. `solvedCount`.

Related

isSolved, setSolvedCount!
"""
getSolvedCount(v::VariableNodeData) = v.solvedCount
getSolvedCount(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> getSolvedCount
getSolvedCount(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = getSolvedCount(getVariable(dfg, sym), solveKey)


"""
    $SIGNATURES

Update/set the `solveCount` value.

Related

getSolved, isSolved
"""
setSolvedCount!(v::VariableNodeData, val::Int) = v.solvedCount = val
setSolvedCount!(v::VariableDataLevel2, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getSolverData(v, solveKey), val)
setSolvedCount!(dfg::AbstractDFG, sym::Symbol, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getVariable(dfg, sym), val, solveKey)


"""
    $SIGNATURES

Boolean on whether the variable has been solved.

Related

getSolved, setSolved!
"""
isSolved(v::VariableNodeData) = 0 < v.solvedCount
isSolved(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> isSolved
isSolved(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = isSolved(getVariable(dfg, sym), solveKey)

##------------------------------------------------------------------------------
## initialized
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::DFGVariable, key::Symbol=:default)::Bool
      data = getSolverData(var, key)
      if data == nothing
          #TODO we still have a mixture of 2 error behaviours
        return false
      else
          return data.initialized
    end
end

function isInitialized(dfg::AbstractDFG, label::Symbol, key::Symbol=:default)::Bool
  return isInitialized(getVariable(dfg, label), key)
end


##==============================================================================
## Variables
##==============================================================================
#
# |                     | label | tags | timestamp | ppe | softtypename | solvable | solverData | smallData | bigData |
# |---------------------|:-----:|:----:|:---------:|:---:|:------------:|:--------:|:----------:|:---------:|:-------:|
# | SkeletonDFGVariable |   X   |   X  |           |     |              |          |            |           |         |
# | DFGVariableSummary  |   X   |   X  |     X     |  X  |       X      |          |            |           |    X    |
# | DFGVariable         |   X   |   X  |     x     |  X  |              |     X    |      X     |     X     |    X    |
#
##------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## label
##------------------------------------------------------------------------------

## COMMON
# getLabel

##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------

## COMMON
# getTags
# setTags!

##------------------------------------------------------------------------------
## timestamp
##------------------------------------------------------------------------------

## COMMON
# getTimestamp

"""
    $SIGNATURES

Set the timestamp of a DFGVariable object returning a new DFGVariable.
Note:
Since the `timestamp` field is not mutable `setTimestamp` returns a new variable with the updated timestamp (note the absence of `!`).
Use [`updateVariable!`](@ref) on the returened variable to update it in the factor graph if needed. Alternatively use [`setTimestamp!`](@ref).
See issue #315.
"""
function setTimestamp(v::DFGVariable, ts::DateTime; verbose::Bool=true)
    if verbose
        @warn "verbose=true: setTimestamp(::DFGVariable,...) creates a returns a new immutable DFGVariable object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return DFGVariable(v.label, ts, v.tags, v.ppeDict, v.solverDataDict, v.smallData, v.bigData, v._dfgNodeParams)
end

function setTimestamp(v::DFGVariableSummary, ts::DateTime; verbose::Bool=true)
    if verbose
        @warn "verbose=true: setTimestamp(::DFGVariableSummary,...) creates a returns a new immutable DFGVariable object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return DFGVariableSummary(v.label, ts, v.tags, v.ppeDict, v.softtypename, v.bigData, v._internalId)
end


##------------------------------------------------------------------------------
## _dfgNodeParams [_internalId, solvable]
##------------------------------------------------------------------------------

## COMMON: solvable
# getSolvable
# setSolvable!
# isSolvable

## COMMON: _internalId
# getInternalId

##------------------------------------------------------------------------------
## ppeDict
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get the PPE dictionary for a variable. Its direct use is not recomended.
"""
getPPEDict(v::VariableDataLevel1) = v.ppeDict


#TODO FIXME don't know if this should exist, should rather always update with fg object to simplify inmem vs cloud
"""
    $SIGNATURES

Get the parametric point estimate (PPE) for a variable in the factor graph.

Notes
- Defaults on keywords `solveKey` and `method`

Related

getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(vari::VariableDataLevel1, solveKey::Symbol=:default)
    return  getPPEDict(vari)[solveKey]
    # return haskey(ppeDict, solveKey) ? ppeDict[solveKey] : nothing
end

##------------------------------------------------------------------------------
## solverDataDict
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get solver data dictionary for a variable.
"""
getSolverDataDict(v::DFGVariable) = v.solverDataDict


# TODO move to crud, don't know if this should exist, should rather always update with fg object to simplify inmem vs cloud
"""
    $SIGNATURES

Retrieve solver data structure stored in a variable.
"""
function getSolverData(v::DFGVariable, key::Symbol=:default)
    #TODO this does not fit in with some of the other error behaviour. but its used so added @error
    vnd =  haskey(v.solverDataDict, key) ? v.solverDataDict[key] : (@error "Variable does not have solver data $(key)"; nothing)
    return vnd
end

#TODO Repeated functionality? same as update
"""
    $SIGNATURES
Set solver data structure stored in a variable.
"""
setSolverData!(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) = v.solverDataDict[key] = data

##------------------------------------------------------------------------------
## smallData
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
Get the small data for a variable.
"""
getSmallData(v::DFGVariable)::Dict{String, String} = v.smallData

"""
    $(SIGNATURES)
Set the small data for a variable.
This will overwrite old smallData.
"""
function setSmallData!(v::DFGVariable, smallData::Dict{String, String})::Dict{String, String}
    empty!(v.smallData)
    merge!(v.smallData, smallData)
end

##------------------------------------------------------------------------------
## bigData
##------------------------------------------------------------------------------

## see Bigdata Folder

##------------------------------------------------------------------------------
## softtypename
##------------------------------------------------------------------------------
## getter in DFGVariableSummary only
## can be utility function for others
## TODO this should return the softtype object, or try to. it should be getSofttypename for the accessor
## TODO Consider parameter N in softtype for dims, and storing constructor in softtypename
## TODO or just not having this function at all
# getSofttype(v::DFGVariableSummary) = v.softypename()
##------------------------------------------------------------------------------

"""
    $SIGNATURES
Retrieve the soft type name symbol for a DFGVariableSummary. ie :Point2, Pose2, etc.
"""
getSofttypename(v::DFGVariableSummary)::Symbol = v.softtypename


function getSofttype(v::DFGVariableSummary)::InferenceVariable
    @warn "Looking for type in `Main`. Only use if softtype has only one implementation,ie. Pose2. Otherwise use the full variable."
    return getfield(Main, v.softtypename)()
end

##==============================================================================
## Layer 2 CRUD and SET
##==============================================================================

##==============================================================================
## TAGS - See CommonAccessors
##==============================================================================

##==============================================================================
## Variable Node Data
##==============================================================================
##------------------------------------------------------------------------------
## CRUD: get, add, update, delete
##------------------------------------------------------------------------------

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
## SET: list, merge
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
Merges and updates solver and estimate data for a variable (variable can be from another graph).
If the same key is present in another collection, the value for that key will be the value it has in the last collection listed (updated).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
function mergeVariableSolverData!(destVariable::DFGVariable, sourceVariable::DFGVariable)::DFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.solverDataDict, deepcopy(sourceVariable.solverDataDict))
    return destVariable
end

##==============================================================================
## Point Parametric Estimates
##==============================================================================

##------------------------------------------------------------------------------
## CRUD: get, add, update, delete
##------------------------------------------------------------------------------

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
## SET: list, merge
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
List all the PPE data keys in the variable.
"""
function listPPE(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
    v = getVariable(dfg, variablekey)
    return collect(keys(v.ppeDict))
end

#TODO API and only correct level
"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
function mergePPEs!(destVariable::AbstractDFGVariable, sourceVariable::AbstractDFGVariable)::AbstractDFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.ppeDict, deepcopy(sourceVariable.ppeDict))
    return destVariable
end
