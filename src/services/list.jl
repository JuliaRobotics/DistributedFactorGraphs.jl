##==============================================================================
## Listing and listing aliases
##==============================================================================

##------------------------------------------------------------------------------
## Overwrite in driver for performance
##------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## Aliases and Other filtered lists
##------------------------------------------------------------------------------

## ls Shorthands
##--------
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

Notes:
- Returns `Vector{Symbol}`
"""
function ls(
    dfg::AbstractDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    return listVariables(dfg; whereSolvable, whereTags, whereType, whereLabel)
end

#TODO tags kwarg
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.

Notes
- Return `Vector{Symbol}`
"""
function lsf(
    dfg::AbstractDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    return listFactors(dfg; whereSolvable, whereTags, whereType, whereLabel)
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(
    dfg::AbstractDFG,
    node::AbstractGraphNode;
    solvable::Union{Nothing, Int} = nothing,
)
    return listNeighbors(dfg, node; solvable = solvable)
end
function ls(dfg::AbstractDFG, label::Symbol; solvable::Union{Nothing, Int} = nothing)
    return listNeighbors(dfg, label; solvable = solvable)
end

function lsf(dfg::AbstractDFG, label::Symbol; solvable::Union{Nothing, Int} = nothing)
    return listNeighbors(dfg, label; solvable = solvable)
end

## list by types
##--------------

function ls(dfg::AbstractDFG, ::Type{T}) where {T <: StateType}
    return listVariables(dfg; whereType = ==(T()))
end

"""
    $(SIGNATURES)
Lists the factors of a specific type in the factor graph. 
Example, list all the Point2Point2 factors in the factor graph `dfg`:
    lsf(dfg, Point2Point2)

Notes
- Return `Vector{Symbol}`
"""
function lsf(dfg::AbstractDFG, ::Type{T}) where {T <: AbstractObservation}
    whereType = isconcretetype(T) ? x -> x == T : x -> x <: T
    return listFactors(dfg; whereType)
end

function ls(dfg::AbstractDFG, ::Type{T}) where {T <: AbstractObservation}
    return lsf(dfg, T)
end

# TODO listNeighborsSecondary or listNeighborsOfNeighbors
"""
    $(SIGNATURES)
List the second order neighbors of a given node.
"""
function listNeighborsSecondary(dfg::AbstractDFG, label::Symbol)
    varls2, facls2 = listNeighborhood(dfg, label, 2)
    varls1, facls1 = listNeighborhood(dfg, label, 1)
    l1 = union(varls1, facls1)
    l2 = union(varls2, facls2)
    return setdiff(l2, l1)
end
function listNeighborsSecondary(dfg::AbstractDFG, v::AbstractGraphNode)
    return listNeighborsSecondary(dfg, getLabel(v))
end

ls2(args...) = listNeighborsSecondary(args...)

"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.

Notes:
- Returns `Vector{Symbol}`
"""
function lsfPriors(dfg::AbstractDFG)
    return listFactors(dfg; whereType = isPrior)
end

## Listing DataTypes in a DFG

"""
    $SIGNATURES

Return `Vector{DataType}` of all unique variable types in factor graph.
"""
function lsTypes(dfg::AbstractDFG)
    vars = getVariables(dfg)
    alltypes = Set{DataType}()
    for v in vars
        varType = typeof(getStateKind(v))
        push!(alltypes, varType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{DataType, Vector{Symbol}}` of all unique variable types with labels in a factor graph.
"""
function lsTypesDict(dfg::AbstractDFG)
    vars = getVariables(dfg)
    alltypes = Dict{DataType, Vector{Symbol}}()
    for v in vars
        varType = typeof(getStateKind(v))
        d = get!(alltypes, varType, Symbol[])
        push!(d, v.label)
    end
    return alltypes
end

"""
    $SIGNATURES

Return `Vector{Symbol}` of all unique factor types in factor graph.
"""
function lsfTypes(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Set{DataType}()
    for f in facs
        facType = typeof(getObservation(f))
        push!(alltypes, facType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{DataType, Vector{Symbol}}` of all unique factors types with labels in a factor graph.
"""
function lsfTypesDict(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Dict{DataType, Vector{Symbol}}()
    for f in facs
        facType = typeof(getObservation(f))
        d = get!(alltypes, facType, Symbol[])
        push!(d, f.label)
    end
    return alltypes
end
