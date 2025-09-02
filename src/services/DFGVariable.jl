##==============================================================================
## Accessors
##==============================================================================
##==============================================================================
## PointParametricEst
##==============================================================================
"$(SIGNATURES)"
getPPEMax(est::AbstractPointParametricEst) = est.max
function getPPEMax(fg::AbstractDFG, varlabel::Symbol, solveKey::Symbol = :default)
    return getPPE(fg, varlabel, solveKey) |> getPPEMax
end

"$(SIGNATURES)"
getPPEMean(est::AbstractPointParametricEst) = est.mean
function getPPEMean(fg::AbstractDFG, varlabel::Symbol, solveKey::Symbol = :default)
    return getPPE(fg, varlabel, solveKey) |> getPPEMean
end

"$(SIGNATURES)"
getPPESuggested(est::AbstractPointParametricEst) = est.suggested
function getPPESuggested(var::VariableCompute, solveKey::Symbol = :default)
    return getPPE(var, solveKey) |> getPPESuggested
end
function getPPESuggested(dfg::AbstractDFG, varlabel::Symbol, solveKey::Symbol = :default)
    return getPPE(getVariable(dfg, varlabel), solveKey) |> getPPESuggested
end

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
- API Quirk in that this function returns and instance of `::T` not a `::Type{<:StateType}`.

DevWork
- TODO, see IncrementalInference.jl 1228

Related

getVariableType
"""
getVariableType(::VariableCompute{T}) where {T} = T()

getVariableType(::State{T}) where {T} = T()

# TODO: Confirm that we can switch this out, instead of retrieving the complete variable.
# getVariableType(v::VariableCompute) = getVariableType(getState(v))

# Optimized in CGDFG
getVariableType(dfg::AbstractDFG, lbl::Symbol) = getVariableType(getVariable(dfg, lbl))

##------------------------------------------------------------------------------
## StateType
##------------------------------------------------------------------------------

# """
#     $SIGNATURES
# Interface function to return the `variableType` manifolds of an StateType, extend this function for all Types<:StateType.
# """
# function getManifolds end

# getManifolds(::Type{<:T}) where {T <: ManifoldsBase.AbstractManifold} = convert(Tuple, T)
# getManifolds(::T) where {T <: ManifoldsBase.AbstractManifold} = getManifolds(T)

"""
    @defStateType StructName manifold point_identity

A macro to create a new variable type with name `StructName` associated with a given manifold and identity point.

- `StructName` is the name of the new variable type, which will be defined as a subtype of `StateType`.
- `manifold` is an object that must be a subtype of `ManifoldsBase.AbstractManifold`.
- `point_identity` is the identity point on the manifold, used as a reference for operations.

This macro is useful for defining variable types that are not parameterized by dimension, and for associating them with a specific manifold and identity point.

See the [Manifolds.jl documentation on creating your own manifolds](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html) for more information.

Example:
```
DFG.@defVariable Pose2 SpecialEuclideanGroup(2) ArrayPartition([0;0.0],[1 0; 0 1.0])
```
"""
macro defStateType(structname, manifold, point_identity)
    return esc(
        quote
            Base.@__doc__ struct $structname <: StateType{Any} end

            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "@defVariable of " *
                                                     string($structname) *
                                                     " requires that the " *
                                                     string($manifold) *
                                                     " be a subtype of `ManifoldsBase.AbstractManifold`"

            DFG.getManifold(::Type{$structname}) = $manifold

            DFG.getPointType(::Type{$structname}) = typeof($point_identity)

            DFG.getPointIdentity(::Type{$structname}) = $point_identity
        end,
    )
end

macro defVariable(args...)
    return esc(:(DFG.@defStateType $(args...)))
end

"""
    @defStateTypeN StructName manifold point_identity

A macro to create a new variable type with name `StructName` that is parameterized by `N` and associated with a given manifold and identity point.

- `StructName` is the name of the new variable type, which will be defined as a subtype of `StateType{N}`.
- `manifold` is an object that must be a subtype of `ManifoldsBase.AbstractManifold`.
- `point_identity` is the identity point on the manifold, used as a reference for operations.

This macro is useful for defining variable types that are parameterized by dimension or other type parameters (e.g., `Pose{N}`), and for associating them with a specific manifold and identity point.

See the [Manifolds.jl documentation on creating your own manifolds](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html) for more information.

Example:
```
DFG.@defStateTypeN Pose{N} SpecialEuclideanGroup(N) ArrayPartition(zeros(SVector{N, Float64}), SMatrix{N, N, Float64}(I))
```
"""
macro defStateTypeN(structname, manifold, point_identity)
    return esc(
        quote
            Base.@__doc__ struct $structname <: StateType{N} end

            DFG.getManifold(::Type{$structname}) where {N} = $manifold

            DFG.getPointType(::Type{$structname}) where {N} = typeof($point_identity)

            DFG.getPointIdentity(::Type{$structname}) where {N} = $point_identity
        end,
    )
end

function Base.convert(
    ::Type{<:AbstractManifold},
    ::Union{<:T, Type{<:T}},
) where {T <: StateType}
    return getManifold(T)
end

"""
    $SIGNATURES
Interface function to return the `<:ManifoldsBase.AbstractManifold` object of `variableType<:StateType`.
"""
getManifold(::T) where {T <: StateType} = getManifold(T)
getManifold(vari::VariableCompute) = getVariableType(vari) |> getManifold
getManifold(state::State) = getVariableType(state) |> getManifold
# covers both <:StateType and <:AbstractObservation
getManifold(dfg::AbstractDFG, lbl::Symbol) = getManifold(dfg[lbl])

"""
    $SIGNATURES
Interface function to return the `variableType` dimension of an StateType, extend this function for all Types<:StateType.
"""
function getDimension end

getDimension(::Type{T}) where {T <: StateType} = manifold_dimension(getManifold(T))
getDimension(::T) where {T <: StateType} = manifold_dimension(getManifold(T))
getDimension(M::ManifoldsBase.AbstractManifold) = manifold_dimension(M)
getDimension(p::Distributions.Distribution) = length(p)
getDimension(var::VariableCompute) = getDimension(getVariableType(var))

"""
    $SIGNATURES
Interface function to return the manifold point type of an StateType, extend this function for all Types<:StateType.
"""
function getPointType end
getPointType(::T) where {T <: StateType} = getPointType(T)

"""
    $SIGNATURES
Interface function to return the user provided identity point for this StateType manifold, extend this function for all Types<:StateType.

Notes
- Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.
"""
function getPointIdentity end
getPointIdentity(::T) where {T <: StateType} = getPointIdentity(T)

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
function getPoint(
    ::Type{T},
    v::AbstractVector,
    basis = ManifoldsBase.DefaultOrthogonalBasis(),
) where {T <: StateType}
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.get_vector(M, p0, v, basis)
    return ManifoldsBase.exp(M, p0, X)
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
function getCoordinates(
    ::Type{T},
    p,
    basis = ManifoldsBase.DefaultOrthogonalBasis(),
) where {T <: StateType}
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.log(M, p0, p)
    return ManifoldsBase.get_coordinates(M, p0, X, basis)
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
getSolvedCount(v::State) = v.solvedCount
function getSolvedCount(v::VariableCompute, solveKey::Symbol = :default)
    return getState(v, solveKey) |> getSolvedCount
end
function getSolvedCount(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol = :default)
    return getSolvedCount(getVariable(dfg, sym), solveKey)
end

"""
    $SIGNATURES

Update/set the `solveCount` value.

Related

getSolved, isSolved
"""
setSolvedCount!(v::State, val::Int) = v.solvedCount = val
function setSolvedCount!(v::VariableCompute, val::Int, solveKey::Symbol = :default)
    return setSolvedCount!(getState(v, solveKey), val)
end
function setSolvedCount!(
    dfg::AbstractDFG,
    sym::Symbol,
    val::Int,
    solveKey::Symbol = :default,
)
    return setSolvedCount!(getVariable(dfg, sym), val, solveKey)
end

"""
    $SIGNATURES

Boolean on whether the variable has been solved.

Related

getSolved, setSolved!
"""
isSolved(v::State) = 0 < v.solvedCount
function isSolved(v::VariableCompute, solveKey::Symbol = :default)
    return getState(v, solveKey) |> isSolved
end
function isSolved(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol = :default)
    return isSolved(getVariable(dfg, sym), solveKey)
end

##------------------------------------------------------------------------------
## initialized
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Returns state of variable data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::VariableCompute, key::Symbol = :default)
    return getState(var, key).initialized
end

function isInitialized(dfg::AbstractDFG, label::Symbol, key::Symbol = :default)
    return isInitialized(getVariable(dfg, label), key)::Bool
end

"""
    $SIGNATURES

Return `::Bool` on whether this variable has been marginalized.

Notes:
- State default `solveKey=:default`
"""
function isMarginalized(vert::VariableCompute, solveKey::Symbol = :default)
    return getState(vert, solveKey).ismargin
end
function isMarginalized(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol = :default)
    return isMarginalized(DFG.getVariable(dfg, sym), solveKey)
end

"""
    $SIGNATURES

Mark a variable as marginalized `true` or `false`.
"""
function setMarginalized!(vnd::State, val::Bool)
    return vnd.ismargin = val
end
function setMarginalized!(vari::VariableCompute, val::Bool, solveKey::Symbol = :default)
    return setMarginalized!(getState(vari, solveKey), val)
end
function setMarginalized!(
    dfg::AbstractDFG,
    sym::Symbol,
    val::Bool,
    solveKey::Symbol = :default,
)
    return setMarginalized!(getVariable(dfg, sym), val, solveKey)
end

##==============================================================================
## Variables
##==============================================================================
#
# |                     | label | tags | timestamp | ppe | variableTypeName | solvable | solverData | smallData | dataEntries |
# |---------------------|:-----:|:----:|:---------:|:---:|:----------------:|:--------:|:----------:|:---------:|:-----------:|
# | VariableSkeleton |   X   |   X  |           |     |                  |          |            |           |             |
# | VariableSummary  |   X   |   X  |     X     |  X  |         X        |          |            |           |       X     |
# | VariableCompute         |   X   |   X  |     x     |  X  |                  |     X    |      X     |     X     |       X     |
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

Set the timestamp of a VariableCompute object returning a new VariableCompute.
Note:
Since the `timestamp` field is not mutable `setTimestamp` returns a new variable with the updated timestamp (note the absence of `!`).
Use [`mergeVariable!`](@ref) on the returened variable to update it in the factor graph if needed. Alternatively use [`setTimestamp!`](@ref).
See issue #315.
"""
function setTimestamp(v::VariableCompute, ts::ZonedDateTime; verbose::Bool = true)
    if verbose
        @warn "verbose=true: setTimestamp(::VariableCompute,...) creates a returns a new immutable VariableCompute object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return VariableCompute(
        v.id,
        v.label,
        ts,
        v.nstime,
        v.tags,
        v.ppeDict,
        v.solverDataDict,
        v.smallData,
        v.dataDict,
        Ref(v.solvable),
    )
end

function setTimestamp(
    v::AbstractGraphVariable,
    ts::DateTime,
    timezone = localzone();
    verbose::Bool = true,
)
    return setTimestamp(v, ZonedDateTime(ts, timezone); verbose)
end

function setTimestamp(v::VariableSummary, ts::ZonedDateTime; verbose::Bool = true)
    if verbose
        @warn "verbose=true: setTimestamp(::VariableSummary,...) creates and returns a new immutable VariableCompute object (and didn't change a distributed factor graph object), make sure you are using the right pointers: getVariable(...).  See setTimestamp!(...) and note suggested use is at addVariable!(..., [timestamp=...]).  See DFG #315 for explanation."
    end
    return VariableSummary(
        v.id,
        v.label,
        ts,
        v.tags,
        v.ppeDict,
        v.variableTypeName,
        v.dataDict,
    )
end

function setTimestamp(v::VariableDFG, timestamp::ZonedDateTime; verbose::Bool = true)
    return VariableDFG(;
        (key => getproperty(v, key) for key in fieldnames(VariableDFG))...,
        timestamp,
    )
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
getPPEDict(v::AbstractGraphVariable) = v.ppeDict

#TODO FIXME don't know if this should exist, should rather always update with fg object to simplify inmem vs cloud
"""
    $SIGNATURES

Get the parametric point estimate (PPE) for a variable in the factor graph.

Notes
- Defaults on keywords `solveKey` and `method`

Related

getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(vari::AbstractGraphVariable, solveKey::Symbol = :default)
    if haskey(getPPEDict(vari), solveKey)
        return getPPEDict(vari)[solveKey]
    else
        throw(LabelNotFoundError("PPE", solveKey, collect(keys(getPPEDict(vari)))))
    end
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
getVariablePPEDict(vari::AbstractGraphVariable) = getPPEDict(vari)

"""
    getVariablePPE(::VariableCompute)
    getVariablePPE(::State)

Get the Parametric Point Estimate of the given variable.
"""
getVariablePPE(args...) = getPPE(args...)

##------------------------------------------------------------------------------
## solverDataDict
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Get solver data dictionary for a variable.  Advised to use graph CRUD operations instead.
"""
getSolverDataDict(v::VariableCompute) = v.solverDataDict

##------------------------------------------------------------------------------
## Variable Metadata
##------------------------------------------------------------------------------

# Generic Metadata CRUD
# TODO optimize for difference in in-memory by extending in other drivers. 

"""
    $(SIGNATURES)
Get the Metadata entry at `key` for variable `label` in `dfg`
"""
function getMetadata(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getVariable(dfg, label).smallData[key]
end

"""
    $(SIGNATURES)
Add a Metadata pair `key=>value` for variable `label` in `dfg`
"""
function addMetadata!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:SmallDataTypes})
    v = getVariable(dfg, label)
    haskey(v.smallData, pair.first) && throw(LabelExistsError("Metadata", pair.first))
    push!(v.smallData, pair)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

"""
    $(SIGNATURES)
Update a Metadata pair `key=>value` for variable `label` in `dfg`
"""
function updateMetadata!(
    dfg::AbstractDFG,
    label::Symbol,
    pair::Pair{Symbol, <:SmallDataTypes};
    warn_if_absent::Bool = true,
)
    v = getVariable(dfg, label)
    warn_if_absent &&
        !haskey(v.smallData, pair.first) &&
        @warn("$(pair.first) does not exist, adding.")
    push!(v.smallData, pair)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

"""
    $(SIGNATURES)
Delete a Metadata entry at `key` for variable `label` in `dfg`
"""
function deleteMetadata!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    v = getVariable(dfg, label)
    pop!(v.smallData, key)
    mergeVariable!(dfg, v)
    return 1
end

"""
    $(SIGNATURES)
List all Metadata keys for a variable `label` in `dfg`
"""
function listMetadata(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    return collect(keys(v.smallData)) #or pair TODO
end

"""
    $(SIGNATURES)
Empty all Metadata from variable `label` in `dfg`
"""
function emptyMetadata!(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    empty!(v.smallData)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

##------------------------------------------------------------------------------
## Data Entries and Blobs
##------------------------------------------------------------------------------

## see DataEntryBlob Folder

##------------------------------------------------------------------------------
## variableTypeName
##------------------------------------------------------------------------------
## getter in VariableSummary only
## can be utility function for others
## TODO this should return the variableType object, or try to. it should be getVariableTypeName for the accessor
## TODO Consider parameter N in variableType for dims, and storing constructor in variableTypeName
## TODO or just not having this function at all
# getVariableType(v::VariableSummary) = v.softypename()
##------------------------------------------------------------------------------

"""
    $SIGNATURES
Retrieve the soft type name symbol for a VariableSummary. ie :Point2, Pose2, etc.
"""
getVariableTypeName(v::VariableSummary) = v.variableTypeName::Symbol

function getVariableType(v::VariableSummary)
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

function getState(v::VariableCompute, label::Symbol)
    !haskey(getSolverDataDict(v), label) && throw(LabelNotFoundError("State", label))
    return getSolverDataDict(v)[label]
end

function getState(v::VariableDFG, label::Symbol)
    stateidx = findfirst(==(label) ∘ getLabel, v.solverData)
    isnothing(stateidx) && throw(LabelNotFoundError("State", label))
    return unpackState(v.solverData[stateidx])
end

"""
    $(SIGNATURES)
Get the variable `State` for a given state label.
"""
function getState(dfg::AbstractDFG, variableLabel::Symbol, label::Symbol)
    v = getVariable(dfg, variableLabel)
    return getState(v, label)
end

function getStates(dfg::AbstractDFG, variableLabel::Symbol)
    v = getVariable(dfg, variableLabel)
    return collect(values(v.solverDataDict))
end

"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addState!(dfg::GraphsDFG, variableLabel::Symbol, state::State)
    var = getVariable(dfg, variableLabel)
    return addState!(var, state)
end

function addState!(v::VariableCompute, state::State)
    if haskey(v.solverDataDict, state.solveKey)
        throw(LabelExistsError("State", state.solveKey))
    end
    v.solverDataDict[state.solveKey] = state
    return state
end

"""
    $(SIGNATURES)
Add variable `State`s by calling `addState!`.
NOTE: If an error occurs while adding one of the states, previously added states will not be rolled back.
"""
function addStates!(dfg::AbstractDFG, variableLabel::Symbol, states::Vector{<:State})
    cnt = asyncmap(states) do state
        return addState!(dfg, variableLabel, state)
    end
    return sum(cnt)
end

function addStates!(dfg::AbstractDFG, varLabel_state_pairs::Vector{<:Pair{Symbol, <:State}})
    cnt = asyncmap(varLabel_state_pairs) do (varLabel, state)
        return addState!(dfg, varLabel, state)
    end
    return sum(cnt)
end

"""
    $(SIGNATURES)
Update the variable state if it exists, otherwise add it.

Related

mergeStates!
"""
function mergeState!(dfg::GraphsDFG, variableLabel::Symbol, vnd::State)
    return mergeState!(getVariable(dfg, variableLabel), vnd)
end

function mergeState!(v::VariableCompute, vnd::State)
    if !haskey(v.solverDataDict, vnd.solveKey)
        addState!(v, vnd)
    else
        v.solverDataDict[vnd.solveKey] = vnd
    end
    return 1
end

function mergeStates!(
    dfg::AbstractDFG,
    varLabel_state_pairs::Vector{<:Pair{Symbol, <:State}},
)
    cnt = asyncmap(varLabel_state_pairs) do (varLabel, state)
        return mergeState!(dfg, varLabel, state)
    end
    return sum(cnt)
end

function mergeStates!(dfg::AbstractDFG, variableLabel::Symbol, states::Vector{<:State})
    cnt = asyncmap(states) do state
        return mergeState!(dfg, variableLabel, state)
    end
    return sum(cnt)
end

function copytoState!(
    dfg::AbstractDFG,
    variableLabel::Symbol,
    stateLabel::Symbol,
    state::State,
)
    newstate = State(
        getVariableType(state);
        (k => deepcopy(getproperty(state, k)) for k in fieldnames(State))...,
        solveKey = stateLabel,
    )
    return mergeState!(dfg, variableLabel, newstate)
end

#

"""
    $(SIGNATURES)
Delete the variable `State` by label, returns the number of deleted elements.
"""
function deleteState!(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return deleteState!(getVariable(dfg, variableLabel), label)
end

function deleteState!(v::VariableCompute, label::Symbol)
    if !haskey(v.solverDataDict, label)
        throw(LabelNotFoundError("State", label))
    end
    delete!(v.solverDataDict, label)
    return 1
end

function deleteState!(dfg::AbstractDFG, sourceVariable::VariableCompute, label::Symbol)
    return deleteState!(dfg, sourceVariable.label, label)
end

"""
    $(SIGNATURES)
Delete the variable `State`s by label, returns the number of deleted elements.
"""
function deleteStates!(dfg::AbstractDFG, variableLabel::Symbol, labels::Vector{Symbol})
    cnt = asyncmap(labels) do label
        return deleteState!(dfg, variableLabel, label)
    end
    return sum(cnt)
end

function deleteStates!(
    dfg::AbstractDFG,
    varLabel_stateLabel_pairs::Vector{Pair{Symbol, Symbol}},
)
    cnt = asyncmap(varLabel_stateLabel_pairs) do (varLabel, stateLabel)
        return deleteState!(dfg, varLabel, stateLabel)
    end
    return sum(cnt)
end

##------------------------------------------------------------------------------
## SET: list, merge
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
List all the variable state labels.
"""
function listStates(v::VariableCompute; labelFilter::Union{Nothing, Function} = nothing)
    labels = collect(keys(v.solverDataDict))
    return filterDFG!(labels, labelFilter)
end

function listStates(
    dfg::AbstractDFG,
    lbl::Symbol;
    labelFilter::Union{Nothing, Function} = nothing,
)
    return listStates(getVariable(dfg, lbl); labelFilter)
end

function listStates(
    dfg::AbstractDFG;
    labelFilter::Union{Nothing, Function} = nothing,
    solvableFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    typeFilter::Union{Nothing, Function} = nothing,
    variableLabelFilter::Union{Nothing, Function} = nothing,
)
    labels = Set{Symbol}()
    vls = listVariables(
        dfg;
        solvableFilter,
        tagsFilter,
        typeFilter,
        labelFilter = variableLabelFilter,
    )
    for vl in vls
        union!(labels, listStates(dfg, vl; labelFilter))
    end
    return labels
end

#TODO deprecate PPEs
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
[`getPPEMean`](@ref), [`getPPEMax`](@ref), [`updatePPE!`](@ref), `mean(BeliefType)`
"""
function getPPE(v::VariableCompute, ppekey::Symbol = :default)
    !haskey(v.ppeDict, ppekey) && throw(LabelNotFoundError("PPE", ppekey))
    return v.ppeDict[ppekey]
end
function getPPE(dfg::AbstractDFG, variableLabel::Symbol, ppekey::Symbol = :default)
    return getPPE(getVariable(dfg, variableLabel), ppekey)
end
# Not the most efficient call but it at least reuses above (in memory it's probably ok)
function getPPE(
    dfg::AbstractDFG,
    sourceVariable::AbstractGraphVariable,
    ppekey::Symbol = :default,
)
    return getPPE(dfg, sourceVariable.label, ppekey)
end

"""
    $(SIGNATURES)
Add variable PPE, errors if it already exists.
"""
function addPPE!(
    dfg::AbstractDFG,
    variableLabel::Symbol,
    ppe::P,
) where {P <: AbstractPointParametricEst}
    var = getVariable(dfg, variableLabel)
    if haskey(var.ppeDict, ppe.solveKey)
        throw(LabelExistsError("PPE", ppe.solveKey))
    end
    var.ppeDict[ppe.solveKey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Add a new PPE entry from a deepcopy of the source variable PPE.
NOTE: Copies the PPE.
"""
function addPPE!(
    dfg::AbstractDFG,
    sourceVariable::VariableCompute,
    ppekey::Symbol = :default,
)
    return addPPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)))
end

function addPPEs!(
    dfg::AbstractDFG,
    sourceVariables::Vector{VariableCompute},
    ppekey::Symbol = :default,
)
    return addPPE!.(dfg, sourceVariables, ppekey)
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it -- one call per `key::Symbol=:default`.

Notes
- uses `ppe.solveKey` as solveKey.
"""
function updatePPE!(
    dfg::AbstractDFG,
    variableLabel::Symbol,
    ppe::AbstractPointParametricEst;
    warn_if_absent::Bool = true,
)
    var = getVariable(dfg, variableLabel)
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
function updatePPE!(
    dfg::AbstractDFG,
    sourceVariable::AbstractGraphVariable,
    ppekey::Symbol = :default;
    warn_if_absent::Bool = true,
)
    return updatePPE!(
        dfg,
        sourceVariable.label,
        deepcopy(getPPE(sourceVariable, ppekey));
        warn_if_absent = warn_if_absent,
    )
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(
    dfg::AbstractDFG,
    sourceVariables::Vector{<:AbstractGraphVariable},
    ppekey::Symbol = :default;
    warn_if_absent::Bool = true,
)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updatePPE!(
            dfg,
            var.label,
            getPPE(dfg, var, ppekey);
            warn_if_absent = warn_if_absent,
        )
    end
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
function deletePPE!(dfg::AbstractDFG, variableLabel::Symbol, ppekey::Symbol = :default)
    var = getVariable(dfg, variableLabel)

    if !haskey(var.ppeDict, ppekey)
        throw(LabelNotFoundError("PPE", ppekey))
    end
    pop!(var.ppeDict, ppekey)
    return 1
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
function deletePPE!(
    dfg::AbstractDFG,
    sourceVariable::VariableCompute,
    ppekey::Symbol = :default,
)
    return deletePPE!(dfg, sourceVariable.label, ppekey)
end

##------------------------------------------------------------------------------
## SET: list, merge
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
List all the PPE data keys in the variable.
"""
function listPPEs(dfg::AbstractDFG, variableLabel::Symbol)
    v = getVariable(dfg, variableLabel)
    return collect(keys(v.ppeDict))::Vector{Symbol}
end

#TODO API and only correct level
"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
function mergePPEs!(
    destVariable::AbstractGraphVariable,
    sourceVariable::AbstractGraphVariable,
)
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.ppeDict, deepcopy(sourceVariable.ppeDict))
    return destVariable
end
