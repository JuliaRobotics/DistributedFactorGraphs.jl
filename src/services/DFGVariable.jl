##==============================================================================
## Accessors
##==============================================================================

##==============================================================================
## Variable Node Data
##==============================================================================

##------------------------------------------------------------------------------
## variableType
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)

Get the type of the variable's state, eg. `Pose2`, `Point3`, etc. as an instance of `StateType`.
"""
getStateType(::VariableCompute{T}) where {T} = T()

getStateType(::State{T}) where {T} = T()

getStateType(dfg::AbstractDFG, lbl::Symbol) = getStateType(getVariable(dfg, lbl))

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
DFG.@defStateType Pose2 SpecialEuclideanGroup(2) ArrayPartition([0;0.0],[1 0; 0 1.0])
```
"""
macro defStateType(structname, manifold, point_identity)
    return esc(
        quote
            Base.@__doc__ struct $structname <: StateType{Any} end

            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "defStateType of " *
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
getManifold(vari::VariableCompute) = getStateType(vari) |> getManifold
getManifold(state::State) = getStateType(state) |> getManifold
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
getSolvedCount(v::State) = v.solves
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
setSolvedCount!(v::State, val::Int) = v.solves = val
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
isSolved(v::State) = 0 < v.solves
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
    return getState(vert, solveKey).marginalized
end
function isMarginalized(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol = :default)
    return isMarginalized(DFG.getVariable(dfg, sym), solveKey)
end

"""
    $SIGNATURES

Mark a variable as marginalized `true` or `false`.
"""
function setMarginalized!(vnd::State, val::Bool)
    return vnd.marginalized = val
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
# |                     | label | tags | timestamp | variableTypeName | solvable | solverData | smallData | dataEntries |
# |---------------------|:-----:|:----:|:---------:|:----------------:|:--------:|:----------:|:---------:|:-----------:|
# | VariableSkeleton |   X   |   X  |           |                  |          |            |           |             |
# | VariableSummary  |   X   |   X  |     X     |         X        |          |            |           |       X     |
# | VariableCompute  |   X   |   X  |     x     |                  |     X    |      X     |     X     |       X     |
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

##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

## COMMON: solvable
# getSolvable
# setSolvable!
# isSolvable

## COMMON:

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
function addMetadata!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:MetadataTypes})
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
    pair::Pair{Symbol, <:MetadataTypes};
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
hasState(v::VariableCompute, label::Symbol) = haskey(v.states, label)

function getState(v::VariableCompute, label::Symbol)
    !haskey(refStates(v), label) && throw(LabelNotFoundError("State", label))
    return refStates(v)[label]
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
    return collect(values(v.states))
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
    if haskey(v.states, state.label)
        throw(LabelExistsError("State", state.label))
    end
    v.states[state.label] = state
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
    if !haskey(v.states, vnd.label)
        addState!(v, vnd)
    else
        v.states[vnd.label] = vnd
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
    if !haskey(v.states, label)
        throw(LabelNotFoundError("State", label))
    end
    delete!(v.states, label)
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
    labels = collect(keys(v.states))
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

