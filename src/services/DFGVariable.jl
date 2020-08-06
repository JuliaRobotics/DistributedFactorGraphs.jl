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

# TODO: Confirm that we can switch this out, instead of retrieving the complete variable.
# getSofttype(v::DFGVariable{T}) where T <: InferenceVariable = T()
getSofttype(v::DFGVariable) = getSofttype(getSolverData(v))

# Optimized in CGDFG
getSofttype(dfg::AbstractDFG, lbl::Symbol) = getSofttype(getVariable(dfg,lbl))

"""
    getVariableType

Alias for [`getSofttype`](@ref).
"""
getVariableType(args...) = getSofttype(args...)

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
# |                     | label | tags | timestamp | ppe | softtypename | solvable | solverData | smallData | dataEntries |
# |---------------------|:-----:|:----:|:---------:|:---:|:------------:|:--------:|:----------:|:---------:|:-----------:|
# | SkeletonDFGVariable |   X   |   X  |           |     |              |          |            |           |             |
# | DFGVariableSummary  |   X   |   X  |     X     |  X  |       X      |          |            |           |       X     |
# | DFGVariable         |   X   |   X  |     x     |  X  |              |     X    |      X     |     X     |       X     |
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
function setTimestamp(v::DFGVariable, ts::ZonedDateTime; verbose::Bool=true)
    if verbose
        @warn "verbose=true: setTimestamp(::DFGVariable,...) creates a returns a new immutable DFGVariable object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return DFGVariable(v.label, ts, v.nstime, v.tags, v.ppeDict, v.solverDataDict, v.smallData, v.dataDict, Ref(v.solvable))
end

setTimestamp(v::AbstractDFGVariable, ts::DateTime, timezone=localzone(); verbose::Bool=true) = setTimestamp(v, ZonedDateTime(ts,  timezone); verbose=verbose)

function setTimestamp(v::DFGVariableSummary, ts::ZonedDateTime; verbose::Bool=true)
    if verbose
        @warn "verbose=true: setTimestamp(::DFGVariableSummary,...) creates and returns a new immutable DFGVariable object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return DFGVariableSummary(v.label, ts, v.tags, v.ppeDict, v.softtypename, v.dataDict)
end


##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

## COMMON: solvable
# getSolvable
# setSolvable!
# isSolvable

## COMMON:

##------------------------------------------------------------------------------
## ppeDict
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get the PPE dictionary for a variable.  Recommended to use CRUD operations instead, [`getPPE`](@ref), [`addPPE!`](@ref), [`updatePPE!`](@ref), [`deletePPE!`](@ref).
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

# afew more aliases on PPE, brought back from deprecated DF

"""
    $SIGNATURES

Return full dictionary of PPEs in a variable, recommended to rather use CRUD: [`getPPE`](@ref),
"""
getVariablePPEDict(vari::VariableDataLevel1) = getPPEDict(vari)

getVariablePPE(args...) = getPPE(args...)

##------------------------------------------------------------------------------
## solverDataDict
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get solver data dictionary for a variable.  Advised to use graph CRUD operations instead.
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
getSmallData(v::DFGVariable)::Dict{String, SmallDataType} = v.smallData

"""
    $(SIGNATURES)
Set the small data for a variable.
This will overwrite old smallData.
"""
function setSmallData!(v::DFGVariable, smallData::Dict{String, SmallDataType})
    empty!(v.smallData)
    merge!(v.smallData, smallData)
end

##------------------------------------------------------------------------------
## Data Entries and Blobs
##------------------------------------------------------------------------------

## see DataEntryBlob Folder

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
function addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData)::VariableNodeData
    var = getVariable(dfg, variablekey)
    if haskey(var.solverDataDict, vnd.solverKey)
        error("VariableNodeData '$(vnd.solverKey)' already exists")
    end
    var.solverDataDict[vnd.solverKey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Add a new solver data  entry from a deepcopy of the source variable solver data.
NOTE: Copies the solver data.
"""
addVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solverKey::Symbol=:default) =
    addVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solverKey)))


"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.

Notes:
- `useCopy=true` to copy solver data and keep separate memory.
- Use `fields` to updated only a few VND.fields while adhering to `useCopy`.

Related

mergeVariableSolverData!
"""
function updateVariableSolverData!(dfg::AbstractDFG,
                                   variablekey::Symbol,
                                   vnd::VariableNodeData,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[],
                                   verbose::Bool=true  )
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    if verbose && !haskey(var.solverDataDict, vnd.solverKey)
        @warn "VariableNodeData '$(vnd.solverKey)' does not exist, adding"
    end

    # for InMemoryDFGTypes do memory copy or repointing, for cloud this would be an different kind of update.
    usevnd = useCopy ? deepcopy(vnd) : vnd
    # should just one, or many pointers be updated?
    if haskey(var.solverDataDict, vnd.solverKey) && isa(var.solverDataDict[vnd.solverKey], VariableNodeData) && length(fields) != 0
      # change multiple pointers inside the VND var.solverDataDict[solvekey]
      for field in fields
        destField = getfield(var.solverDataDict[vnd.solverKey], field)
        srcField = getfield(usevnd, field)
        if isa(destField, Array) && size(destField) == size(srcField)
          # use broadcast (in-place operation)
          destField .= srcField
        else
          # change pointer of destination VND object member
          setfield!(var.solverDataDict[vnd.solverKey], field, srcField)
        end
      end
    else
      # change a single pointer in var.solverDataDict
      var.solverDataDict[vnd.solverKey] = usevnd
    end

    return var.solverDataDict[vnd.solverKey]
end


function updateVariableSolverData!(dfg::AbstractDFG,
                                   variablekey::Symbol,
                                   vnd::VariableNodeData,
                                   solverKey::Symbol,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[],
                                   verbose::Bool=true)

    # TODO not very clean
    if vnd.solverKey != solverKey
        @warn "TODO It looks like solverKey as parameter is deprecated, set it in vnd, or keep this function?"
        usevnd = useCopy ? deepcopy(vnd) : vnd
        usevnd.solverKey = solverKey
        return updateVariableSolverData!(dfg, variablekey, usevnd, useCopy, fields, verbose)
    else
        return updateVariableSolverData!(dfg, variablekey, vnd, useCopy, fields, verbose)
    end
end


updateVariableSolverData!(dfg::AbstractDFG,
                          sourceVariable::DFGVariable,
                          solverKey::Symbol=:default,
                          useCopy::Bool=true,
                          fields::Vector{Symbol}=Symbol[] ) =
    updateVariableSolverData!(dfg, sourceVariable.label, getSolverData(sourceVariable, solverKey), useCopy, fields)

function updateVariableSolverData!(dfg::AbstractDFG,
                                   sourceVariables::Vector{<:DFGVariable},
                                   solverKey::Symbol=:default,
                                   useCopy::Bool=true,
                                   fields::Vector{Symbol}=Symbol[]  )
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solverKey), useCopy, fields)
    end
end

"""
    $SIGNATURES
Duplicate a supersolve (solverKey).
"""
function deepcopySolvekeys!(dfg::AbstractDFG,
                            dest::Symbol,
                            src::Symbol;
                            solvable::Int=0,
                            labels=ls(dfg, solvable=solvable),
                            verbose::Bool=false  )
  #
  for x in labels
      sd = deepcopy(getSolverData(getVariable(dfg,x), src))
      sd.solverKey = dest
      updateVariableSolverData!(dfg, x, sd, true, Symbol[], verbose )
  end
end
const deepcopySupersolve! = deepcopySolvekeys!

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
function deleteVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, solverKey::Symbol=:default)::VariableNodeData
    var = getVariable(dfg, variablekey)

    if !haskey(var.solverDataDict, solverKey)
        error("VariableNodeData '$(solverKey)' does not exist")
    end
    vnd = pop!(var.solverDataDict, solverKey)
    return vnd
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
deleteVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solverKey::Symbol=:default) =
    deleteVariableSolverData!(dfg, sourceVariable.label, solverKey)

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

mergeVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable) =     mergeVariableSolverData!(getVariable(dfg,getLabel(sourceVariable)), sourceVariable)


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
- Defaults on keywords `solverKey` and `method`

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
function addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P)::AbstractPointParametricEst where {P <: AbstractPointParametricEst}
    var = getVariable(dfg, variablekey)
    if haskey(var.ppeDict, ppe.solverKey)
        error("PPE '$(ppe.solverKey)' already exists")
    end
    var.ppeDict[ppe.solverKey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Add a new PPE entry from a deepcopy of the source variable PPE.
NOTE: Copies the PPE.
"""
addPPE!(dfg::AbstractDFG, sourceVariable::DFGVariable, ppekey::Symbol=:default) =
    addPPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)))


"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it -- one call per `key::Symbol=:default`.
"""
function updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P)::P where {P <: AbstractPointParametricEst}
    var = getVariable(dfg, variablekey)
    if !haskey(var.ppeDict, ppe.solverKey)
        @warn "PPE '$(ppe.solverKey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.ppeDict[ppe.solverKey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
NOTE: Copies the PPE data.
"""
updatePPE!(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=:default) =
    updatePPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)))

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, sourceVariables::Vector{<:VariableDataLevel1}, ppekey::Symbol=:default)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(dfg, var, ppekey))
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
function listPPEs(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
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
