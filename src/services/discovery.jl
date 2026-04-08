"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
Implement `isConnected(dfg::AbstractDFG)`
"""
function isConnected end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
Implement `listNeighbors(dfg::AbstractDFG, label::Symbol; whereSolvable, whereTags)`
"""
function listNeighbors end

"""
    findPaths(dfg, from::Symbol, to::Symbol, k::Int; variableLabels, factorLabels, kwargs...)

Return the `k` shortest paths between `from` and `to` in the factor graph.
Each result is a `(path = Vector{Symbol}, dist)` named tuple.

Optional keyword arguments restrict which variables and/or factors may appear on
the path.  When neither is given the full graph is used.  When only one is
provided the other defaults to all labels of that kind in `dfg`.

Typical usage with filters:
```julia
vars = listVariables(dfg; whereSolvable = >=(1))
facs = listFactors(dfg; whereSolvable = >=(1))
findPaths(dfg, :x1, :x5, 3; variableLabels = vars, factorLabels = facs)
```

See also: [`findPath`](@ref), [`listVariables`](@ref), [`listFactors`](@ref)
"""
function findPaths end

"""
    findPath(dfg, from::Symbol, to::Symbol; variableLabels, factorLabels, kwargs...)

Return the single shortest path between `from` and `to`.
Errors if no path exists (use `findPaths` for graphs that may be disconnected).

Accepts the same restriction keywords as [`findPaths`](@ref).
"""
function findPath end

#TODO Move findPaths and findPath to AbstractDFG services as default implementations.
function findPaths(
    dfg::AbstractDFG,
    from::Symbol,
    to::Symbol,
    k::Int;
    variableLabels::Union{Nothing, Vector{Symbol}} = nothing,
    factorLabels::Union{Nothing, Vector{Symbol}} = nothing,
    kwargs...,
)
    # If the user provided restricted lists, build the subgraph automatically
    active_dfg =
        if isa(dfg, GraphsDFG) && isnothing(variableLabels) && isnothing(factorLabels)
            dfg
        else
            vlabels = something(variableLabels, listVariables(dfg))
            flabels = something(factorLabels, listFactors(dfg))
            labels = vcat(vlabels, flabels)
            DFG.getSubgraph(
                GraphsDFG{NoSolverParams, VariableSkeleton, FactorSkeleton},
                dfg,
                labels,
            )
        end
    !hasVariable(active_dfg, from) &&
        !hasFactor(active_dfg, from) &&
        throw(DFG.LabelNotFoundError(from))
    !hasVariable(active_dfg, to) &&
        !hasFactor(active_dfg, to) &&
        throw(DFG.LabelNotFoundError(to))

    # optimization for k=1 since A* is more efficient than Yen's for single shortest path
    if k == 1
        return findPaths(GraphsDFGs.a_star, active_dfg, from, to; kwargs...)
    else
        return findPaths(
            GraphsDFGs.yen_k_shortest_paths,
            active_dfg,
            from,
            to,
            k;
            kwargs...,
        )
    end
end

function findPath(
    dfg::AbstractDFG,
    from::Symbol,
    to::Symbol;
    variableLabels::Union{Nothing, Vector{Symbol}} = nothing,
    factorLabels::Union{Nothing, Vector{Symbol}} = nothing,
    kwargs...,
)
    paths = findPaths(dfg, from, to, 1; variableLabels, factorLabels, kwargs...)

    if isempty(paths)
        return nothing
    else
        return first(paths)
    end
end

function listNeighbors(dfg::AbstractDFG, node::AbstractGraphNode; kwargs...)
    return listNeighbors(dfg, getLabel(node); kwargs...)
end

##==============================================================================
## Subgraphs and Neighborhoods
##==============================================================================

#TODO add pruning filters that is applied during traversal.
"""
    $(SIGNATURES)
Build a list of all unique neighbors inside 'distance'. Neighbors can be filtered by using keyword arguments, eg. [`whereTags`] and [`whereSolvable`].
Filters are applied to final neighborhood result.

Notes
- Returns a tuple `(variableLabels, factorLabels)`, where each element is a `Vector{Symbol}`.

Related:
- [`getSubgraph`](@ref)
- [`mergeGraph!`](@ref)
"""
function listNeighborhood(dfg::AbstractDFG, label::Symbol, distance::Int; filters...)
    neighborList = Set{Symbol}([label])
    curList = Set{Symbol}([label])

    for dist = 1:distance
        newNeighbors = Set{Symbol}()
        for node in curList
            neighbors = listNeighbors(dfg, node)
            union!(neighborList, neighbors)
            union!(newNeighbors, neighbors)
        end
        curList = newNeighbors
    end

    variableLabels = intersect(listVariables(dfg; filters...), neighborList)
    factorLabels = intersect(listFactors(dfg; filters...), neighborList)

    return variableLabels, factorLabels
end

function listNeighborhood(
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int;
    filters...,
)
    if distance > 0
        variableLabels = Symbol[]
        factorLabels = Symbol[]
        for l in variableFactorLabels
            varls, facls = listNeighborhood(dfg, l, distance; filters...)
            union!(variableLabels, varls)
            union!(factorLabels, facls)
        end
    else
        variableLabels = intersect(listVariables(dfg; filters...), variableFactorLabels)
        factorLabels = intersect(listFactors(dfg; filters...), variableFactorLabels)
    end

    return variableLabels, factorLabels
end

##==============================================================================
## Finding
##==============================================================================
# function findClosestTimestamp(setA::Vector{Tuple{DateTime,T}},
# setB::Vector{Tuple{DateTime,S}}) where {S,T}
"""
    $SIGNATURES

Find and return the closest timestamp from two sets of Tuples.  Also return the minimum delta-time (`::Nanosecond`) and how many elements match from the two sets are separated by the minimum delta-time.
"""
function findClosestTimestamp(
    setA::Vector{Tuple{TimeDateZone, T}},
    setB::Vector{Tuple{TimeDateZone, S}},
) where {S, T}
    #
    # build matrix of delta times, ranges on rows x vars on columns
    DT = map(Iterators.product(setA, setB)) do (a, b)
        return abs(DFG.calcDeltatime_ns(a[1], b[1]))
    end

    # absolute time differences
    # DTi = (x->x.value).(DT) .|> abs

    # find the smallest element
    mdt = minimum(DT)
    corrs = findall(x -> x == mdt, DT)

    # return the closest timestamp, deltaT, number of correspondences
    return corrs[1].I, mdt, length(corrs)
end

"""
    $SIGNATURES

Find and return nearest variable labels per delta time.  Function will filter on `regexFilter`, `tags`, and `solvable`.

Notes
- Returns `Vector{Tuple{Vector{Symbol}, Nanosecond}}`

DevNotes:
- TODO `number` should allow returning more than one for k-nearest matches.
- Future versions likely will require some optimization around the internal `getVariable` call.
  - Perhaps a dedicated/efficient `getVariableTimestamp` for all DFG flavors.

Related

ls, listVariables, findClosestTimestamp
"""
function findVariablesNearTimestamp(
    dfg::AbstractDFG,
    query_timestamp::TimeDateZone;
    whereLabel::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereSolvable::Union{Nothing, Function} = nothing,
    number::Int = 1,
)
    #
    # get the variable labels based on filters
    vls = listVariables(dfg; whereLabel, whereTags, whereSolvable)
    # compile timestamps with label
    # vars = map( x->getVariable(dfg, x), vls )
    timeset = map(x -> (getTimestamp(getVariable(dfg, x)), x), vls)
    mask = BitArray{1}(undef, length(vls))
    fill!(mask, true)

    RET = Vector{Tuple{Vector{Symbol}, Nanosecond}}()
    SYMS = Symbol[]
    CORRS = 1
    NUMBER = number
    while 0 < CORRS + NUMBER
        # get closest
        link, mdt, corrs = findClosestTimestamp([(query_timestamp, 0)], timeset[mask])
        newsym = vls[link[2]]
        union!(SYMS, !isa(newsym, Vector) ? [newsym] : newsym)
        mask[link[2]] = false
        CORRS = corrs - 1
        # last match, done with this delta time
        if corrs == 1
            NUMBER -= 1
            push!(RET, (deepcopy(SYMS), mdt))
            SYMS = Symbol[]
        end
    end

    return RET
end

function findVariablesNearTimestamp(
    dfg::AbstractDFG,
    query_timestamp::DateTime;
    timezone = tz"UTC",
    kwargs...,
)
    return findVariablesNearTimestamp(
        dfg,
        TimeDateZone(query_timestamp, timezone);
        kwargs...,
    )
end

##==============================================================================
## Automated Graph Searching
##==============================================================================
"""
    $SIGNATURES

Speciallized function available to only GraphsDFG at this time.

Notes
- Has option for various types of filters (increases memory usage)

Example
```julia
using IncrementalInference

# canonical example graph as example
fg = generateGraph_Kaess()

@show path = findShortestPathDijkstra(fg, :x1, :x3)
@show isVariable.(fg, path)
@show isFactor.(fg, path)
```

DevNotes
- TODO expand to other AbstractDFG entities.
- TODO use of filter resource consumption can be improved.

Related

`Graphs.dijkstra_shortest_paths`
"""
function findShortestPathDijkstra end
