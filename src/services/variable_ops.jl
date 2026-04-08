"""
    $(SIGNATURES)
Add a VariableDFG to a DFG.
Implement `addVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)`
"""
function addVariable! end

"""
    $(SIGNATURES)
Add a Vector{VariableDFG} to a DFG.
Implement `addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})`
"""
function addVariables! end

"""
    $(SIGNATURES)
Get a VariableDFG from a DFG using its label.
Implement `getVariable(dfg::AbstractDFG, label::Symbol)`
"""
function getVariable end

"""
    $(SIGNATURES)
Get the variables in the DFG as a Vector, supporting various filters.

Keyword arguments
- `whereSolvable`: Optional function to filter on the `solvable` property, eg `>=(1)`.
- `whereLabel`: Optional function to filter on label e.g., `contains(r"x1")`.
- `whereTags`: Optional function to filter on tags, eg. `⊇([:POSE])`.
- `whereType`: Optional function to filter on the variable type.

Returns
- `Vector{<:AbstractGraphVariable}` matching the filters.

See also: [`listVariables`](@ref), [`ls`](@ref)
"""
function getVariables end

"""
    $(SIGNATURES)
Merge a variable into the DFG. If a variable with the same label exists, it will be overwritten; 
otherwise, the variable will be added to the graph.
Implement `mergeVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)`
"""
function mergeVariable! end

"""
    $(SIGNATURES)
Merge a vector of variables into the DFG. If a variable with the same label exists, it will be overwritten; otherwise, the variable will be added to the graph.
Implement `mergeVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})`
"""
function mergeVariables! end

"""
    $(SIGNATURES)
Delete a VariableDFG from the DFG.
Implement `deleteVariable!(dfg::AbstractDFG, label::Symbol)`
"""
function deleteVariable! end

"""
    $(SIGNATURES)
Get a list of labels of the DFGVariables in the graph.
Supports optional arguments to filter the variables returned.

Notes
- Returns `::Vector{Symbol}`

Example
```julia
listVariables(dfg)
```

See also: [`ls`](@ref)
"""
function listVariables end

"""
    $(SIGNATURES)
True if the variable exists in the graph.
Implement `hasVariable(dfg::AbstractDFG, label::Symbol)`
"""
function hasVariable end

# ==============================================================================
"""
    $(SIGNATURES)
Get a VariableSummary from a DFG.
"""
function getVariableSummary end

"""
    $(SIGNATURES)
Get the variables from a DFG as a Vector{VariableSummary}.
"""
function getVariablesSummary end

"""
    $(SIGNATURES)
Get a VariableSkeleton from a DFG.
"""
function getVariableSkeleton end

"""
    $(SIGNATURES)
Get the variables from a DFG as a Vector{VariableSkeleton}.
"""
function getVariablesSkeleton end

# =============================================================================

function getVariables(dfg::AbstractDFG, labels::Vector{Symbol})
    return map(label -> getVariable(dfg, label), labels)
end

function deleteVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)
    return deleteVariable!(dfg, variable.label)
end

function deleteVariables!(dfg::AbstractDFG, labels::Vector{Symbol})
    counts = asyncmap(labels) do l
        return deleteVariable!(dfg, l)
    end
    return sum(counts)
end

function deleteVariables!(dfg::AbstractDFG; kwargs...)
    labels = listVariables(dfg; kwargs...)
    return deleteVariables!(dfg, labels)
end

# =============================================================================
# TODO SORT OUT BELLOW
# =============================================================================

"""
    $(SIGNATURES)

Get the kind of the variable's state, eg. `Pose2`, `Point3`, etc. as an instance of `StateType`.
"""
getStateKind(::VariableDFG{T}) where {T} = T()

getStateKind(::State{T}) where {T} = T()

getStateKind(dfg::AbstractDFG, lbl::Symbol) = getStateKind(getVariable(dfg, lbl))

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
