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

Get the kind of the variable's state, eg. `Pose2`, `Point3`, etc. as an instance of `StateType`.
"""
getStateKind(::VariableDFG{T}) where {T} = T()

getStateKind(::State{T}) where {T} = T()

getStateKind(dfg::AbstractDFG, lbl::Symbol) = getStateKind(getVariable(dfg, lbl))

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

#TODO why this convert? rather enforce explicit use of getManifold
function Base.convert(
    ::Type{<:AbstractManifold},
    ::Union{<:T, Type{<:T}},
) where {T <: StateType}
    #TODO Deprecate v0.29
    Base.depwarn(
        "convert(AbstractManifold, StateType) is deprecated, use getManifold instead",
        :convert,
    )
    return getManifold(T)
end

"""
    $SIGNATURES
Interface function to return the `<:ManifoldsBase.AbstractManifold` object of `variableType<:StateType`.
"""
getManifold(::T) where {T <: StateType} = getManifold(T)
getManifold(vari::VariableDFG) = getStateKind(vari) |> getManifold
getManifold(state::State) = getStateKind(state) |> getManifold
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
getDimension(var::VariableDFG) = getDimension(getStateKind(var))

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
function getSolvedCount(v::VariableDFG, solveKey::Symbol = :default)
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
function setSolvedCount!(v::VariableDFG, val::Int, solveKey::Symbol = :default)
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
function isSolved(v::VariableDFG, solveKey::Symbol = :default)
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
function isInitialized(var::VariableDFG, key::Symbol = :default)
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
function isMarginalized(vert::VariableDFG, solveKey::Symbol = :default)
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
function setMarginalized!(vari::VariableDFG, val::Bool, solveKey::Symbol = :default)
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
# | VariableDFG  |   X   |   X  |     x     |                  |     X    |      X     |     X     |       X     |
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

##------------------------------------------------------------------------------
## Blobentries and Blobs
##------------------------------------------------------------------------------
## see DataEntryBlob Folder

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
hasState(v::VariableDFG, label::Symbol) = haskey(v.states, label)
function hasState(dfg::AbstractDFG, variableLabel::Symbol, label::Symbol)
    return hasState(getVariable(dfg, variableLabel), label)
end

function getState(v::VariableDFG, label::Symbol)
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

#TODO add filters
function getStates(dfg::AbstractDFG, variableLabel::Symbol)
    v = getVariable(dfg, variableLabel)
    return collect(values(refStates(v)))
end

"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addState!(dfg::GraphsDFG, variableLabel::Symbol, state::State)
    var = getVariable(dfg, variableLabel)
    return addState!(var, state)
end

function addState!(v::VariableDFG, state::State)
    if haskey(refStates(v), state.label)
        throw(LabelExistsError("State", state.label))
    end
    refStates(v)[state.label] = state
    return state
end

"""
    $(SIGNATURES)
Add variable `State`s by calling `addState!`.
NOTE: If an error occurs while adding one of the states, previously added states will not be rolled back.
"""
function addStates!(dfg::AbstractDFG, variableLabel::Symbol, states::Vector{<:State})
    cnt = asyncmap(states) do state
        addState!(dfg, variableLabel, state)
        return 1
    end
    return sum(cnt)
end

function addStates!(dfg::AbstractDFG, varLabel_state_pairs::Vector{<:Pair{Symbol, <:State}})
    cnt = asyncmap(varLabel_state_pairs) do (varLabel, state)
        addState!(dfg, varLabel, state)
        return 1
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

function mergeState!(v::VariableDFG, vnd::State)
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
    newstate = State(state; label = stateLabel)
    return mergeState!(dfg, variableLabel, newstate)
end

"""
    $(SIGNATURES)
Delete the variable `State` by label, returns the number of deleted elements.
"""
function deleteState!(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return deleteState!(getVariable(dfg, variableLabel), label)
end

function deleteState!(v::VariableDFG, label::Symbol)
    !haskey(v.states, label) && return 0
    delete!(v.states, label)
    return 1
end

function deleteState!(dfg::AbstractDFG, sourceVariable::VariableDFG, label::Symbol)
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
function listStates(v::VariableDFG; whereLabel::Union{Nothing, Function} = nothing)
    labels = collect(keys(v.states))
    return filterDFG!(labels, whereLabel)
end

function listStates(
    dfg::AbstractDFG,
    lbl::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
)
    return listStates(getVariable(dfg, lbl); whereLabel)
end

function listStates(
    dfg::AbstractDFG;
    whereLabel::Union{Nothing, Function} = nothing,
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereVariableLabel::Union{Nothing, Function} = nothing,
)
    labels = Set{Symbol}()
    vls = listVariables(
        dfg;
        whereSolvable,
        whereTags,
        whereType,
        whereLabel = whereVariableLabel,
    )
    for vl in vls
        union!(labels, listStates(dfg, vl; whereLabel))
    end
    return collect(labels)
end
