##==============================================================================
## Accessors
##==============================================================================
##==============================================================================
## PointParametricEst
##==============================================================================
"$(SIGNATURES)"
getPPEMax(est::AbstractPointParametricEst) = est.max
getPPEMax(fg::AbstractDFG, varlabel::Symbol, solveKey::Symbol=:default) =
                getPPE(fg, varlabel, solveKey) |> getPPEMax

"$(SIGNATURES)"
getPPEMean(est::AbstractPointParametricEst) = est.mean
getPPEMean(fg::AbstractDFG, varlabel::Symbol, solveKey::Symbol=:default) =
                getPPE(fg, varlabel, solveKey) |> getPPEMean
                
"$(SIGNATURES)"
getPPESuggested(est::AbstractPointParametricEst) = est.suggested
getPPESuggested(var::DFGVariable, solveKey::Symbol=:default) = getPPE(var, solveKey) |> getPPESuggested
getPPESuggested(dfg::AbstractDFG, varlabel::Symbol, solveKey::Symbol=:default) = getPPE(getVariable(dfg, varlabel), solveKey) |> getPPESuggested

"$(SIGNATURES)"
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = est.lastUpdatedTimestamp

##==============================================================================
## Variable Node Data
##==============================================================================

## COMMON
# getSolveInProgress
# isSolveInProgress

##------------------------------------------------------------------------------
## variableType
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)

Variable nodes `variableType` information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Notes
- API Quirk in that this function returns and instance of `::T` not a `::Type{<:InferenceVariable}`.

DevWork
- TODO, see IncrementalInference.jl 1228

Related

getVariableType
"""
getVariableType(::DFGVariable{T}) where T = T()

getVariableType(::VariableNodeData{T}) where T = T()



# TODO: Confirm that we can switch this out, instead of retrieving the complete variable.
# getVariableType(v::DFGVariable) = getVariableType(getSolverData(v))

# Optimized in CGDFG
getVariableType(dfg::AbstractDFG, lbl::Symbol) = getVariableType(getVariable(dfg,lbl))


##------------------------------------------------------------------------------
## InferenceVariable
##------------------------------------------------------------------------------

# """
#     $SIGNATURES
# Interface function to return the `variableType` manifolds of an InferenceVariable, extend this function for all Types<:InferenceVariable.
# """
# function getManifolds end

# getManifolds(::Type{<:T}) where {T <: ManifoldsBase.AbstractManifold} = convert(Tuple, T)
# getManifolds(::T) where {T <: ManifoldsBase.AbstractManifold} = getManifolds(T)


"""
    @defVariable StructName manifolds<:ManifoldsBase.AbstractManifold

A macro to create a new variable with name `StructName` and manifolds.  Note that 
the `manifolds` is an object and *must* be a subtype of `ManifoldsBase.AbstractManifold`.
See documentation in [Manifolds.jl on making your own](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html). 

Example:
```
DFG.@defVariable Pose2 SpecialEuclidean(2) ArrayPartition([0;0.0],[1 0; 0 1.0])
```
"""
macro defVariable(structname, manifold, point_identity)
    return esc(quote
        Base.@__doc__ struct $structname <: InferenceVariable end

        # user manifold must be a <:Manifold
        @assert ($manifold isa AbstractManifold) "@defVariable of "*string($structname)*" requires that the "*string($manifold)*" be a subtype of `ManifoldsBase.AbstractManifold`"

        DFG.getManifold(::Type{$structname}) = $manifold

        DFG.getPointType(::Type{$structname}) = typeof($point_identity)

        DFG.getPointIdentity(::Type{$structname}) = $point_identity

        DFG.getVariableType(::typeof($manifold)) = $structname

    end)
end

Base.convert(::Type{<:AbstractManifold}, ::Union{<:T, Type{<:T}}) where {T <: InferenceVariable} = getManifold(T)

"""
    $SIGNATURES
Interface function to return the `<:ManifoldsBase.AbstractManifold` object of `variableType<:InferenceVariable`.
"""
getManifold(::T) where {T <: InferenceVariable} = getManifold(T)
getManifold(vari::DFGVariable) = getVariableType(vari) |> getManifold
# covers both <:InferenceVariable and <:AbstractFactor
getManifold(dfg::AbstractDFG, lbl::Symbol) = getManifold(dfg[lbl])

"""
    $SIGNATURES
Interface function to return the `variableType` dimension of an InferenceVariable, extend this function for all Types<:InferenceVariable.
"""
function getDimension end

getDimension(::Type{T}) where {T <: InferenceVariable} = manifold_dimension(getManifold(T))
getDimension(::T) where {T <: InferenceVariable} = manifold_dimension(getManifold(T))
getDimension(M::ManifoldsBase.AbstractManifold) = manifold_dimension(M)
getDimension(p::Distributions.Distribution) = length(p)
getDimension(var::DFGVariable) = getDimension(getVariableType(var))

"""
    $SIGNATURES
Interface function to return the manifold point type of an InferenceVariable, extend this function for all Types<:InferenceVariable.
"""
function getPointType end
getPointType(::T) where {T <: InferenceVariable} = getPointType(T)

"""
    $SIGNATURES
Interface function to return the user provided identity point for this InferenceVariable manifold, extend this function for all Types<:InferenceVariable.

Notes
- Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.
"""
function getPointIdentity end
getPointIdentity(::T) where {T <: InferenceVariable} = getPointIdentity(T)


"""
    $SIGNATURES

Default escalzation from coordinates to a group representation point.  Override if defaults are not correct.
E.g. coords -> se(2) -> SE(2).

DevNotes
- TODO Likely remove as part of serialization updates, see #590
- Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.

Related

[`getCoordinates`](@ref)
"""
function getPoint(::Type{T}, v::AbstractVector, basis=ManifoldsBase.DefaultOrthogonalBasis()) where {T <: InferenceVariable}
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.get_vector(M, p0, v, basis)
    ManifoldsBase.exp(M, p0, X)
end

"""
    $SIGNATURES

Default reduction of a variable point value (a group element) into coordinates as `Vector`.  Override if defaults are not correct.

DevNotes
- TODO Likely remove as part of serialization updates, see #590
- Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.

Related

[`getPoint`](@ref)
"""
function getCoordinates(::Type{T}, p, basis=ManifoldsBase.DefaultOrthogonalBasis()) where {T <: InferenceVariable}
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.log(M, p0, p)
    ManifoldsBase.get_coordinates(M, p0, X, basis)
end


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

Returns state of variable data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::DFGVariable, key::Symbol=:default)
  data = getSolverData(var, key)
  if data === nothing
    #TODO we still have a mixture of 2 error behaviours
      # DF, not sure I follow the error here?
  return false
  else
    return data.initialized
  end
end

function isInitialized(dfg::AbstractDFG, label::Symbol, key::Symbol=:default)
  return isInitialized(getVariable(dfg, label), key)::Bool
end


"""
    $SIGNATURES

Return `::Bool` on whether this variable has been marginalized.

Notes:
- VariableNodeData default `solveKey=:default`
"""
isMarginalized(vert::DFGVariable, solveKey::Symbol=:default) = getSolverData(vert, solveKey).ismargin
isMarginalized(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = isMarginalized(DFG.getVariable(dfg, sym), solveKey)

"""
    $SIGNATURES

Mark a variable as marginalized `true` or `false`.
"""
function setMarginalized!(vnd::VariableNodeData, val::Bool)
  vnd.ismargin = val
end
setMarginalized!(vari::DFGVariable, val::Bool, solveKey::Symbol=:default) = setMarginalized!(getSolverData(vari, solveKey), val)
setMarginalized!(dfg::AbstractDFG, sym::Symbol, val::Bool, solveKey::Symbol=:default) = setMarginalized!(getVariable(dfg, sym), val, solveKey)


##==============================================================================
## Variables
##==============================================================================
#
# |                     | label | tags | timestamp | ppe | variableTypeName | solvable | solverData | smallData | dataEntries |
# |---------------------|:-----:|:----:|:---------:|:---:|:----------------:|:--------:|:----------:|:---------:|:-----------:|
# | SkeletonDFGVariable |   X   |   X  |           |     |                  |          |            |           |             |
# | DFGVariableSummary  |   X   |   X  |     X     |  X  |         X        |          |            |           |       X     |
# | DFGVariable         |   X   |   X  |     x     |  X  |                  |     X    |      X     |     X     |       X     |
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
    return DFGVariable(v.id, v.label, ts, v.nstime, v.tags, v.ppeDict, v.solverDataDict, v.smallData, v.dataDict, Ref(v.solvable))
end

setTimestamp(v::AbstractDFGVariable, ts::DateTime, timezone=localzone(); verbose::Bool=true) = setTimestamp(v, ZonedDateTime(ts,  timezone); verbose)

function setTimestamp(v::DFGVariableSummary, ts::ZonedDateTime; verbose::Bool=true)
    if verbose
        @warn "verbose=true: setTimestamp(::DFGVariableSummary,...) creates and returns a new immutable DFGVariable object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return DFGVariableSummary(v.id, v.label, ts, v.tags, v.ppeDict, v.variableTypeName, v.dataDict)
end

function setTimestamp(v::PackedVariable, timestamp::ZonedDateTime; verbose::Bool=true)
    return PackedVariable(;(key => getproperty(v, key) for key in fieldnames(PackedVariable))..., timestamp)
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

"""
    $SIGNATURES

Get all the parametric point estimate (PPE) for a variable in the factor graph.
"""
function getPPEs end

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
    vnd =  haskey(getSolverDataDict(v), key) ? getSolverDataDict(v)[key] : (@error "Variable $(getLabel(v)) does not have solver data $(key)"; nothing)
    return vnd
end

#TODO Repeated functionality? same as update
"""
    $SIGNATURES
Set solver data structure stored in a variable.
"""
function setSolverData!(v::DFGVariable, data::VariableNodeData, key::Symbol=:default)
    @assert key == data.solveKey "VariableNodeData.solveKey=:$(data.solveKey) does not match requested :$(key)"
    v.solverDataDict[key] = data
end

##------------------------------------------------------------------------------
## smallData
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
Get the small data for a variable.
Note: Rather use SmallData CRUD
"""
getSmallData(v::DFGVariable) = v.smallData

"""
    $(SIGNATURES)
Set the small data for a variable.
This will overwrite old smallData.
Note: Rather use SmallData CRUD
"""
function setSmallData!(v::DFGVariable, smallData::Dict{Symbol, SmallDataTypes})
    empty!(v.smallData)
    merge!(v.smallData, smallData)
end

# Generic SmallData CRUD
# TODO optimize for difference in in-memory by extending in other drivers. 

"""
    $(SIGNATURES)
Get the small data entry at `key` for variable `label` in `dfg`
"""
function getSmallData(dfg::AbstractDFG, label::Symbol, key::Symbol) 
    getVariable(dfg, label).smallData[key]
end

"""
    $(SIGNATURES)
Add a small data pair `key=>value` for variable `label` in `dfg`
"""
function addSmallData!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:SmallDataTypes})
    v = getVariable(dfg, label)
    haskey(v.smallData, pair.first) && error("$(pair.first) already exists.")
    push!(v.smallData, pair)
    updateVariable!(dfg, v)
    return v.smallData #or pair TODO
end

"""
    $(SIGNATURES)
Update a small data pair `key=>value` for variable `label` in `dfg`
"""
function updateSmallData!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:SmallDataTypes}; warn_if_absent::Bool=true)
    v = getVariable(dfg, label)
    warn_if_absent && !haskey(v.smallData, pair.first) && @warn("$(pair.first) does not exist, adding.")
    push!(v.smallData, pair)
    updateVariable!(dfg, v)
    return v.smallData #or pair TODO
end

"""
    $(SIGNATURES)
Delete a small data entry at `key` for variable `label` in `dfg`
"""
function deleteSmallData!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    v = getVariable(dfg, label)
    rval = pop!(v.smallData, key)
    updateVariable!(dfg, v)
    return rval
end

"""
    $(SIGNATURES)
List all small data keys for a variable `label` in `dfg`
"""
function listSmallData(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    return collect(keys(v.smallData)) #or pair TODO
end

"""
    $(SIGNATURES)
Empty all small data from variable `label` in `dfg`
"""
function emptySmallData!(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    empty!(v.smallData)
    updateVariable!(dfg, v)
    return v.smallData #or pair TODO
end


##------------------------------------------------------------------------------
## Data Entries and Blobs
##------------------------------------------------------------------------------

## see DataEntryBlob Folder

##------------------------------------------------------------------------------
## variableTypeName
##------------------------------------------------------------------------------
## getter in DFGVariableSummary only
## can be utility function for others
## TODO this should return the variableType object, or try to. it should be getVariableTypeName for the accessor
## TODO Consider parameter N in variableType for dims, and storing constructor in variableTypeName
## TODO or just not having this function at all
# getVariableType(v::DFGVariableSummary) = v.softypename()
##------------------------------------------------------------------------------

"""
    $SIGNATURES
Retrieve the soft type name symbol for a DFGVariableSummary. ie :Point2, Pose2, etc.
"""
getVariableTypeName(v::DFGVariableSummary) = v.variableTypeName::Symbol


function getVariableType(v::DFGVariableSummary)::InferenceVariable
    @warn "Looking for type in `Main`. Only use if `variableType` has only one implementation, ie. Pose2. Otherwise use the full variable."
    return getfield(Main, v.variableTypeName)()
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
function getVariableSolverData(dfg::AbstractDFG, variablekey::Symbol, solvekey::Symbol=:default)
    v = getVariable(dfg, variablekey)
    !haskey(v.solverDataDict, solvekey) && throw(KeyError("Solve key '$solvekey' not found in variable '$variablekey'"))
    return v.solverDataDict[solvekey]
end


"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData)
    var = getVariable(dfg, variablekey)
    if haskey(var.solverDataDict, vnd.solveKey)
        error("VariableNodeData '$(vnd.solveKey)' already exists")
    end
    var.solverDataDict[vnd.solveKey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Add a new solver data  entry from a deepcopy of the source variable solver data.
NOTE: Copies the solver data.
"""
addVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solveKey::Symbol=:default) =
    addVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solveKey)))


"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.

Notes:
- `useCopy=true` to copy solver data and keep separate memory.
- Use `fields` to updated only a few VND.fields while adhering to `useCopy`.

Related

mergeVariableSolverData!
"""
function updateVariableSolverData!(
    dfg::AbstractDFG,
    variablekey::Symbol,
    vnd::VariableNodeData,
    useCopy::Bool=false,
    fields::Vector{Symbol}=Symbol[]; 
    warn_if_absent::Bool=true
)
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    warn_if_absent && !haskey(var.solverDataDict, vnd.solveKey) && @warn "VariableNodeData '$(vnd.solveKey)' does not exist, adding"

    # for InMemoryDFGTypes do memory copy or repointing, for cloud this would be an different kind of update.
    usevnd = vnd # useCopy ? deepcopy(vnd) : vnd
    # should just one, or many pointers be updated?
    @show useExisting = haskey(var.solverDataDict, vnd.solveKey) && isa(var.solverDataDict[vnd.solveKey], VariableNodeData) && length(fields) != 0
    # @error useExisting vnd.solveKey
    if useExisting
        # change multiple pointers inside the VND var.solverDataDict[solvekey]
        for field in fields
            destField = getfield(var.solverDataDict[vnd.solveKey], field)
            srcField = getfield(usevnd, field)
            if isa(destField, Array) && size(destField) == size(srcField)
            # use broadcast (in-place operation)
            destField .= srcField
            else
            # change pointer of destination VND object member
            setfield!(var.solverDataDict[vnd.solveKey], field, srcField)
            end
        end
    else
        # change a single pointer in var.solverDataDict
        var.solverDataDict[vnd.solveKey] = usevnd
    end

    return var.solverDataDict[vnd.solveKey]
end

function updateVariableSolverData!(
    dfg::AbstractDFG,
    variablekey::Symbol,
    vnd::VariableNodeData,
    solveKey::Symbol,
    useCopy::Bool=false,
    fields::Vector{Symbol}=Symbol[];
    warn_if_absent::Bool=true
)
    # TODO not very clean
    if vnd.solveKey != solveKey
        @warn("updateVariableSolverData with solveKey parameter might change in the future, see DFG #565. Future warnings are suppressed", maxlog=1) 
        usevnd = useCopy ? deepcopy(vnd) : vnd
        usevnd.solveKey = solveKey
        return updateVariableSolverData!(dfg, variablekey, usevnd, useCopy, fields; warn_if_absent=warn_if_absent)
    else
        return updateVariableSolverData!(dfg, variablekey, vnd, useCopy, fields; warn_if_absent=warn_if_absent)
    end
end


function updateVariableSolverData!( 
    dfg::AbstractDFG,
    sourceVariable::DFGVariable,
    solveKey::Symbol=:default,
    useCopy::Bool=false,
    fields::Vector{Symbol}=Symbol[];
    warn_if_absent::Bool=true 
)
    #
    vnd = getSolverData(sourceVariable, solveKey)
    # toshow = listSolveKeys(sourceVariable) |> collect
    # @info "update DFGVar solveKey" solveKey vnd.solveKey 
    # @show toshow
    @assert solveKey == vnd.solveKey "VariableNodeData's solveKey=:$(vnd.solveKey) does not match requested :$solveKey"
    updateVariableSolverData!(dfg, sourceVariable.label, vnd, useCopy, fields; warn_if_absent=warn_if_absent)
end

function updateVariableSolverData!( 
    dfg::AbstractDFG,
    sourceVariables::Vector{<:DFGVariable},
    solveKey::Symbol=:default,
    useCopy::Bool=false,
    fields::Vector{Symbol}=Symbol[];
    warn_if_absent::Bool=true
)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solveKey), useCopy, fields; warn_if_absent=warn_if_absent)
    end
end

"""
    $SIGNATURES
Duplicate a `solveKey`` into a destination from a source.

Notes
- Can copy between graphs, or to different solveKeys within one graph.
"""
function cloneSolveKey!(
    dest_dfg::AbstractDFG,
    dest::Symbol,
    src_dfg::AbstractDFG,
    src::Symbol;
    solvable::Int=0,
    labels=intersect(ls(dest_dfg, solvable=solvable), ls(src_dfg, solvable=solvable)),
    verbose::Bool=false  
)
    #
    for x in labels
        sd = deepcopy(getSolverData(getVariable(src_dfg, x), src))
        sd.solveKey = dest
        updateVariableSolverData!(dest_dfg, x, sd, true, Symbol[]; warn_if_absent=verbose )
    end
    
    nothing
end

function cloneSolveKey!( 
    dfg::AbstractDFG,
    dest::Symbol,
    src::Symbol;
    kw...
)
    #
    @assert dest != src "Must copy to a different solveKey within the same graph, $dest."
    cloneSolveKey!(dfg, dest, dfg, src; kw...)
end

#

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
function deleteVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, solveKey::Symbol=:default)
    var = getVariable(dfg, variablekey)

    if !haskey(var.solverDataDict, solveKey)
        throw(KeyError("VariableNodeData '$(solveKey)' does not exist"))
    end
    vnd = pop!(var.solverDataDict, solveKey)
    return vnd
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
deleteVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solveKey::Symbol=:default) =
    deleteVariableSolverData!(dfg, sourceVariable.label, solveKey)

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
function mergeVariableSolverData!(destVariable::DFGVariable, sourceVariable::DFGVariable)
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
- Defaults on keywords `solveKey` and `method`

Related
[`getMeanPPE`](@ref), [`getMaxPPE`](@ref), [`updatePPE!`](@ref), getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(v::DFGVariable, ppekey::Symbol=:default)
    !haskey(v.ppeDict, ppekey) && throw(KeyError("PPE key '$ppekey' not found in variable '$(getLabel(v))'"))
    return v.ppeDict[ppekey]
end
getPPE(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default) = getPPE(getVariable(dfg, variablekey), ppekey)
# Not the most efficient call but it at least reuses above (in memory it's probably ok)
getPPE(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=:default) = getPPE(dfg, sourceVariable.label, ppekey)

"""
    $(SIGNATURES)
Add variable PPE, errors if it already exists.
"""
function addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P) where {P <: AbstractPointParametricEst}
    var = getVariable(dfg, variablekey)
    if haskey(var.ppeDict, ppe.solveKey)
        error("PPE '$(ppe.solveKey)' already exists")
    end
    var.ppeDict[ppe.solveKey] = ppe
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

Notes
- uses `ppe.solveKey` as solveKey.
"""
function updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::AbstractPointParametricEst; warn_if_absent::Bool=true)
    var = getVariable(dfg, variablekey)
    if warn_if_absent && !haskey(var.ppeDict, ppe.solveKey)
        @warn "PPE '$(ppe.solveKey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.ppeDict[ppe.solveKey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
NOTE: Copies the PPE data.
"""
updatePPE!(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=:default; warn_if_absent::Bool=true) =
    updatePPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)); warn_if_absent=warn_if_absent)

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, sourceVariables::Vector{<:VariableDataLevel1}, ppekey::Symbol=:default; warn_if_absent::Bool=true)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(dfg, var, ppekey); warn_if_absent=warn_if_absent)
    end
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
function deletePPE!(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default)
    var = getVariable(dfg, variablekey)

    if !haskey(var.ppeDict, ppekey)
        throw(KeyError("VariableNodeData '$(ppekey)' does not exist"))
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
function listPPEs(dfg::AbstractDFG, variablekey::Symbol)
    v = getVariable(dfg, variablekey)
    return collect(keys(v.ppeDict))::Vector{Symbol}
end

#TODO API and only correct level
"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
function mergePPEs!(destVariable::AbstractDFGVariable, sourceVariable::AbstractDFGVariable)
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.ppeDict, deepcopy(sourceVariable.ppeDict))
    return destVariable
end
