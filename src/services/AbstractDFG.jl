
##==============================================================================
## Interface for an AbstractDFG
##==============================================================================

##------------------------------------------------------------------------------
## Getters
##------------------------------------------------------------------------------

## WIP line =======================================================================

"""
    $(SIGNATURES)
"""
function getId end

"""
    $(SIGNATURES)
"""
function getGraph end

"""
    $(SIGNATURES)
"""
getGraphLabel(dfg::AbstractDFG) = getLabel(getGraph(dfg))

"""
    $(SIGNATURES)

!!! warning "Deprecated"
    `getSolverParams(dfg)` is deprecated in DFG v0.29 Pass `SolverParams` directly
    to `solveTree!()` as a keyword argument instead.
"""
function getSolverParams(dfg::AbstractDFG)
    Base.depwarn(
        "getSolverParams(dfg) is deprecated. SolverParams will be removed from the DFG object. " *
        "Pass SolverParams directly to solveTree!() as a keyword argument instead.",
        :getSolverParams,
    )
    return dfg.solverParams
end

"""
    $(SIGNATURES)

Method must be overloaded by the user for Serialization to work.
"""
function rebuildFactorCache!(dfg::AbstractDFG, factor::AbstractGraphFactor, neighbors = [])
    @warn(
        "FactorCache not build, rebuildFactorCache! is not implemented for $(typeof(dfg)). `rebuildFactorCache!` is available in IncrementalInference.",
        maxlog = 1
    )
    return nothing
end

"""
    $(SIGNATURES)
Function to get the type of the variables in the DFG.
"""
getTypeDFGVariables(::AbstractDFG{V, F}) where {V, F} = V

"""
    $(SIGNATURES)
Function to get the type of the factors in the DFG.
"""
getTypeDFGFactors(::AbstractDFG{V, F}) where {V, F} = F

##------------------------------------------------------------------------------
## Setters
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
"""
#NOTE a MethodError will be thrown if solverParams type does not mach the one in dfg
# TODO Is it ok or do we want any abstract solver paramters
function setSolverParams!(dfg::AbstractDFG, solverParams::AbstractDFGParams)
    return dfg.solverParams = solverParams
end

##==============================================================================
## Graphs Structures (Abstract, overwrite for performance)
##==============================================================================

# TODO API name get seems wrong maybe just biadjacencyMatrix
"""
    $(SIGNATURES)
Get a matrix indicating adjacency between variables and factors. Returned as
a named tuple: B::SparseMatrixCSC{Int}, varLabels::Vector{Symbol)
facLabels::Vector{Symbol). Rows are the factors, columns are the variables,
with the corresponding labels in varLabels,facLabels.

Notes
-  Returns `::NamedTuple{(:B, :varLabels, :facLabels), Tuple{SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}}`
"""
function getBiadjacencyMatrix(dfg::AbstractDFG; solvable::Int = 0)
    whereSolvable = >=(solvable) #FIXME whereSolvable should be kwarg
    varLabels = map(v -> v.label, getVariables(dfg; whereSolvable))
    factLabels = map(f -> f.label, getFactors(dfg; whereSolvable))

    vDict = Dict(varLabels .=> [1:length(varLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = listNeighbors(dfg, getFactor(dfg, factLabel); whereSolvable)
        map(vLabel -> adjMat[fIndex, vDict[vLabel]] = 1, factVars)
    end
    return (B = adjMat, varLabels = varLabels, facLabels = factLabels)
end

##==============================================================================
## DOT Files, falls back to GraphsDFG dot functions
##==============================================================================
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.

Notes
- Returns `::String`
"""
function toDot(dfg::AbstractDFG)
    #convert to GraphsDFG
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg)) #fixme, this is probably copyto!/sync!
    return toDot(ldfg)
end

"""
    $(SIGNATURES)
Produces a dot file of the graph for visualization.
Download XDot to see the data

Note
- Default location "/tmp/dfg.dot" -- MIGHT BE REMOVED
- Can be viewed with the `xdot` system application.
- Based on graphviz.org
"""
function toDotFile(dfg::AbstractDFG, fileName::String = "/tmp/dfg.dot")

    #convert to GraphsDFG
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg))

    return toDotFile(ldfg, fileName)
end

##==============================================================================
## Summaries
##==============================================================================

"""
$(SIGNATURES)
Get a summary graph (first-class citizens of variables and factors) with the same structure as the original graph.

Notes
- this is a copy of the original.
- Returns `::GraphsDFG{NoSolverParams, VariableSummary, FactorSummary}`
"""
function getSummaryGraph(dfg::G) where {G <: AbstractDFG}
    #TODO fix deprecated constructor
    summaryDfg = GraphsDFG{NoSolverParams, VariableSummary, FactorSummary}(;
        graphDescription = "Summary of $(getDescription(dfg))",
        agents = deepcopy(dfg.agents),
        graphLabel = Symbol(getGraphLabel(dfg), "_summary_$(string(uuid4())[1:6])"),
    )
    deepcopyGraph!(summaryDfg, dfg)
    # for v in getVariables(dfg)
    #     newV = addVariable!(summaryDfg, VariableSummary(v))
    # end
    # for f in getFactors(dfg)
    #     addFactor!(summaryDfg, listNeighbors(dfg, f), FactorSummary(f))
    # end
    return summaryDfg
end

##
##==============================================================================
## Common Accessors
##==============================================================================

##------------------------------------------------------------------------------
## By value accessors
##------------------------------------------------------------------------------

# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.  Useful for ensuring atomic transactions.

Related:
- isSolveInProgress
"""
function getSolvable(node::Union{VariableDFG, VariableSummary, FactorDFG, FactorSummary})
    return node.solvable[]
end

"""
    $SIGNATURES

Get 'solvable' parameter for either a variable or factor.
"""
function getSolvable(dfg::AbstractDFG, sym::Symbol)
    if isVariable(dfg, sym)
        return getVariable(dfg, sym).solvable[]
    elseif isFactor(dfg, sym)
        return getFactor(dfg, sym).solvable[]
    end
end

"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(node::Union{VariableDFG, FactorDFG}, solvable::Int)
    node.solvable[] = solvable
    return solvable
end

#FIXME this is only for in memory DFGs
function setSolvable!(dfg::AbstractDFG, sym::Symbol, solvable::Int)
    if isVariable(dfg, sym)
        getVariable(dfg, sym).solvable[] = solvable
    elseif isFactor(dfg, sym)
        getFactor(dfg, sym).solvable[] = solvable
    end
    return solvable
end

"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.
returns true if `getSolvable` > 0
Related:
- `getSolvable`(@ref)
"""
isSolvable(node::Union{VariableDFG, FactorDFG}) = getSolvable(node) > 0

# =================================
# Additional Downstream dispatches
# =================================

"""
    $SIGNATURES

Default non-parametric graph solution.
"""
function solveGraph! end

"""
    $SIGNATURES

Standard parametric graph solution (Experimental).
"""
function solveGraphParametric! end

##==============================================================================
## Sorting
##==============================================================================
#Natural Sorting less than

# Adapted from https://rosettacode.org/wiki/Natural_sorting
# split at digit to not digit change
splitbynum(x::AbstractString) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
#parse to Int
function numstringtonum(arr::Vector{<:AbstractString})
    return [(n = tryparse(Int, e)) !== nothing ? n : e for e in arr]
end
#natural less than
function natural_lt(x::T, y::T) where {T <: AbstractString}
    xarr = numstringtonum(splitbynum(x))
    yarr = numstringtonum(splitbynum(y))
    for i = 1:min(length(xarr), length(yarr))
        if typeof(xarr[i]) != typeof(yarr[i])
            return isa(xarr[i], Int)
        elseif xarr[i] == yarr[i]
            continue
        else
            return xarr[i] < yarr[i]
        end
    end
    return length(xarr) < length(yarr)
end

natural_lt(x::Symbol, y::Symbol) = natural_lt(string(x), string(y))

"""
    $SIGNATURES

Convenience wrapper for `Base.sort`.
Sort variable (factor) lists in a meaningful way (by `timestamp`, `label`, etc), for example `[:april;:x1_3;:x1_6;]`
Defaults to sorting by timestamp for variables and factors and using `natural_lt` for Symbols.
See Base.sort for more detail.

Notes
- Not fool proof, but does better than native sort.

Example

`sortDFG(ls(dfg))`
`sortDFG(ls(dfg), by=getLabel, lt=natural_lt)`

Related

ls, lsf
"""
function sortDFG(vars::Vector{<:AbstractGraphNode}; by = getTimestamp, kwargs...)
    return sort(vars; by = by, kwargs...)
end
sortDFG(vars::Vector{Symbol}; lt = natural_lt, kwargs...) = sort(vars; lt = lt, kwargs...)

##==============================================================================
## Filtering
##==============================================================================

# std_numeric_predicates = [==, <, <=, >, >=, in]
# std_string_predicates = [==, in, contains, startswith, endswith]

# # full list
# tags_includes(tag::Symbol) = Base.Fix1(in, tag)
# solvable_eq(x::Int) = ==(x)
# solvable_in(x::Vector{Int}) = in(x)
# solvable_lt(x::Int) = <(x)
# solvable_lte(x::Int) = <=(x)
# solvable_gt(x::Int) = >(x)
# solvable_gte(x::Int) = >=(x)
# label_in(x::Vector{Symbol}) = in(x)
# label_contains(x::String) = contains(x)
# label_startswith(x::String) = startswith(x)
# label_endswith(x::String) = endswith(x)
# type_eq(x::AbstractStateType) = ==(x)
# type_in(x::Vector{<:AbstractStateType}) = in(x)
# type_contains(x::String) = contains(x)
# type_startswith(x::String) = startswith(x)
# type_endswith(x::String) = endswith(x)

# Set predicates
# collection_includes(item) = Base.Fix1(in, item) # collection includes item (item in collection)

# not supported helper
# collection_overlap(collection) = !isdisjoint(collection) # collection overlaps with another collection

"""
    $SIGNATURES
Filter nodes in a DFG based on a predicate function.
This function modifies the input `nodes` vector in place, removing nodes that do not satisfy the predicate.

- **For cross-backend compatibility:**  
  Use only the standard predicates (`==`, `<`, `<=`, `>`, `>=`, `in`, `contains`, `startswith`, `endswith`) 
  when you need your code to work with both in-memory and database-backed DFGs. 
  These are likely to be supported by database query languages and are defined in `std_numeric_predicates` and `std_string_predicates`.

- **For in-memory only operations:**  
  You can use any Julia predicate, since you have full access to the data and Julia's capabilities.
  This is more flexible but will not work if you later switch to a database backend or another programming language.

Standard predicates
- Numeric predicates: `==`, `<`, `<=`, `>`, `>=`, `in`
- String predicates: `==`, `contains`, `startswith`, `endswith`, `in`
"""
function filterDFG! end

filterDFG!(nodes, predicate::Nothing, by::Function = identity) = nodes
# function filterDFG!(nodes, predicate::Base.Fix2, by=identity)
function filterDFG!(nodes, predicate::Function, by::Function = identity)
    return filter!(predicate ∘ by, nodes)
end

# specialized for label::Symbol filtering
function filterDFG!(nodes, predicate::Function, by::typeof(getLabel))
    # TODO this is not as clean as it should be, revisit if any issues arise
    # Standard predicates that needs to be converted to string to work with Symbols
    # OR look for the type if predicate isa Base.Fix2 && (predicate.x isa AbstractString || predicate.x isa Regex)
    if predicate isa Base.Fix2 &&
       typeof(predicate.f) in [typeof(contains), typeof(startswith), typeof(endswith)]
        return filter!(predicate ∘ string ∘ by, nodes)
    else
        return filter!(predicate ∘ by, nodes)
    end
end
