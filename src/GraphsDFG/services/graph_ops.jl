
function DFG.isVariable(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    return haskey(dfg.g.variables, sym)
end

function DFG.isFactor(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    return haskey(dfg.g.factors, sym)
end

function DFG.isConnected(dfg::GraphsDFG)
    return Graphs.is_connected(dfg.g)
    # return length(Graphs.connected_components(dfg.g)) == 1
end

function DFG.listNeighbors(
    dfg::GraphsDFG,
    label::Symbol;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    solvable::Union{Nothing, Int} = nothing, #TODO deprecated for whereSolvable v0.29
)
    if !isnothing(solvable)
        Base.depwarn(
            "solvable kwarg is deprecated, use kwarg `whereSolvable = >=(solvable)` instead", #v0.29
            :listNeighbors,
        )
        !isnothing(whereSolvable) &&
            error("Cannot use both solvable and whereSolvable kwargs.")
        whereSolvable = >=(solvable)
    end

    if !(hasVariable(dfg, label) || hasFactor(dfg, label))
        throw(LabelNotFoundError(label))
    end

    neighbors_il = FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]

    # Additional filtering
    # solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)
    filterDFG!(neighbors_ll, whereSolvable, l -> getSolvable(dfg, l))
    filterDFG!(neighbors_ll, whereTags, l -> listTags(dfg, l))

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label].variableorder, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order::Vector{Symbol}
    end

    return neighbors_ll::Vector{Symbol}
end

function DFG.listNeighborhood(
    dfg::GraphsDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    solvable::Union{Nothing, Int} = nothing, #TODO deprecated for whereSolvable v0.29
)
    if !isnothing(solvable)
        Base.depwarn(
            "solvable kwarg is deprecated, use kwarg `whereSolvable = >=(solvable)` instead", #v0.29
            :listNeighborhood,
        )
        !isnothing(whereSolvable) &&
            error("Cannot use both solvable and whereSolvable kwargs.")
        whereSolvable = >=(solvable)
    end

    # find neighbors at distance to add
    nbhood = Int[]

    for l in variableFactorLabels
        union!(nbhood, neighborhood(dfg.g, dfg.g.labels[l], distance))
    end

    allvarfacs = [dfg.g.labels[id] for id in nbhood]

    filterDFG!(allvarfacs, whereSolvable, l -> getSolvable(dfg, l))
    filterDFG!(allvarfacs, whereTags, l -> listTags(dfg, l))

    variableLabels = intersect(listVariables(dfg), allvarfacs)
    factorLabels = intersect(listFactors(dfg), allvarfacs)

    # if filterOrphans
    #     filter!(factorLabels) do lbl
    #         issubset(getVariableOrder(fg, lbl), variableLabels)
    #     end
    # end

    return variableLabels, factorLabels
end

# TODO copy GraphsDFG to GraphsDFG overwrite
# function copyGraph!(destDFG::GraphsDFG,
#                     sourceDFG::GraphsDFG,
#                     variableFactorLabels::Vector{Symbol};
#                     copyGraphMetadata::Bool=false,
#                     overwriteDest::Bool=false,
#                     deepcopyNodes::Bool=false,
#                     verbose::Bool = true)

#  Biadjacency Matrix https://en.wikipedia.org/wiki/Adjacency_matrix#Of_a_bipartite_graph
function DFG.getBiadjacencyMatrix(
    dfg::GraphsDFG;
    solvable::Union{Nothing, Int} = nothing, #TODO deprecated for whereSolvable v0.29
    whereSolvable = isnothing(solvable) ? nothing : >=(solvable),
    varLabels = listVariables(dfg; whereSolvable),
    factLabels = listFactors(dfg; whereSolvable),
)
    varIndex = [dfg.g.labels[s] for s in varLabels]
    factIndex = [dfg.g.labels[s] for s in factLabels]

    adj = adjacency_matrix(dfg.g)

    adjvf = adj[factIndex, varIndex]
    return (B = adjvf, varLabels = varLabels, facLabels = factLabels)
end

#TODO JT test.
"""
    $(SIGNATURES)
A replacement for to_dot that saves only hardcoded factor graph plotting attributes.
"""
function savedot_attributes(io::IO, dfg::GraphsDFG)
    write(io, "graph G {\n")

    for vl in listVariables(dfg)
        write(io, "$vl [color=red, shape=ellipse];\n")
    end
    for fl in listFactors(dfg)
        write(
            io,
            "$fl [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\n",
        )
    end

    for e in edges(dfg.g)
        write(io, "$(dfg.g.labels[src(e)]) -- $(dfg.g.labels[dst(e)])\n")
    end
    return write(io, "}\n")
end

function DFG.toDotFile(dfg::GraphsDFG, fileName::String = "/tmp/dfg.dot")
    open(fileName, "w") do fid
        return savedot_attributes(fid, dfg)
    end
    return nothing
end

function DFG.toDot(dfg::GraphsDFG)
    m = PipeBuffer()
    savedot_attributes(m, dfg)
    data = take!(m)
    close(m)
    return String(data)
end

#API design NOTE:
# Do not create new Verbs or Nouns for metric vs. topological pathfinding. findPaths is the universal router... findPaths(..., metric)
# for now we only look at topological paths.

function DFG.findPaths(::typeof(all_simple_paths), dfg, from::Symbol, to::Symbol; kwargs...)
    gpaths = Graphs.all_simple_paths(dfg.g, dfg.g.labels[from], dfg.g.labels[to]; kwargs...)
    return map(p -> (path = map(i -> dfg.g.labels[i], p), dist = length(p) - 1), gpaths)
end

function DFG.findPaths(
    ::typeof(yen_k_shortest_paths),
    dfg::GraphsDFG,
    from::Symbol,
    to::Symbol,
    k::Int;
    distmx = weights(dfg.g),
    kwargs...,
)
    (; paths, dists) = Graphs.yen_k_shortest_paths(
        dfg.g,
        dfg.g.labels[from],
        dfg.g.labels[to],
        distmx,
        k;
        kwargs...,
    )
    return map(zip(paths, dists)) do (path, dist)
        return (path = map(i -> dfg.g.labels[i], path), dist = dist)
    end
end

# note with default heuristic this is just dijkstra's algorithm
function DFG.findPaths(
    ::typeof(a_star),
    dfg::GraphsDFG,
    from::Symbol,
    to::Symbol;
    distmx::AbstractMatrix{T} = weights(dfg.g),
    heuristic = nothing,
) where {T}
    #TODO make it easier to use label in the heuristic 
    heuristic = something(heuristic, (n) -> zero(T))
    edgepath = Graphs.a_star(dfg.g, dfg.g.labels[from], dfg.g.labels[to], distmx, heuristic)

    if isempty(edgepath)
        return @NamedTuple{path::Vector{Symbol}, dist::T}[]
    end

    path = [dfg.g.labels[edgepath[1].src]]
    dist = zero(T)
    for (; dst, src) in edgepath
        push!(path, dfg.g.labels[dst])
        dist += distmx[src, dst]
    end

    return [(path = path, dist = dist)]
end

export bfs_tree
export dfs_tree
export traverseGraphTopologicalSort

function Graphs.bfs_tree(fg::GraphsDFG, s::Symbol)
    return bfs_tree(fg.g, fg.g.labels[s])
end

function Graphs.dfs_tree(fg::GraphsDFG, s::Symbol)
    return dfs_tree(fg.g, fg.g.labels[s])
end

"""
    $SIGNATURES

Return a topological sort of a factor graph as a vector of vertex labels in topological order.
Starting from s::Symbol  
"""
function traverseGraphTopologicalSort(fg::GraphsDFG, s::Symbol, fs_tree = bfs_tree)
    tree = fs_tree(fg, s)
    list = topological_sort_by_dfs(tree)
    symlist = map(s -> fg.g.labels[s], list)
    return symlist
end
