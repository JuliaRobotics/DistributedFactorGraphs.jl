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
    labelFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    solvableFilter::Union{Nothing, Function} = nothing,
    number::Int = 1,
)
    #
    # get the variable labels based on filters
    vls = listVariables(dfg; labelFilter, tagsFilter, solvableFilter)
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

[`findFactorsBetweenNaive`](@ref), `Graphs.dijkstra_shortest_paths`
"""
function findShortestPathDijkstra end

#TODO deprecate
"""
    $SIGNATURES

Relatively naive function counting linearly from-to

DevNotes
- Convert to using Graphs shortest path methods instead.
"""
function findFactorsBetweenNaive(
    dfg::AbstractDFG,
    from::Symbol,
    to::Symbol,
    assertSingles::Bool = false,
)
    #
    @info "findFactorsBetweenNaive is naive linear number method -- improvements welcome"
    SRT = getVariableLabelNumber(from)
    STP = getVariableLabelNumber(to)
    prefix = string(from)[1]
    @assert prefix == string(to)[1] "from-to prefixes must match, one is $prefix, other $(string(to)[1])"
    prev = from
    fctlist = Symbol[]
    for num = (SRT + 1):STP
        next = Symbol(prefix, num)
        fct = intersect(ls(dfg, prev), ls(dfg, next))
        if assertSingles
            @assert length(fct) == 1 "assertSingles=true, won't return multiple factors joining variables at this time"
        end
        union!(fctlist, fct)
        prev = next
    end

    return fctlist
end
