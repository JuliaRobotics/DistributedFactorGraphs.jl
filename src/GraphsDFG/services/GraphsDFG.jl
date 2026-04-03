function hasVariable(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.variables, label)
end

function hasFactor(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.factors, label)
end

function isVariable(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    return haskey(dfg.g.variables, sym)
end

function isFactor(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    return haskey(dfg.g.factors, sym)
end

function addVariable!(
    dfg::GraphsDFG{<:AbstractDFGParams, V, <:AbstractGraphFactor},
    variable::V,
) where {V <: AbstractGraphVariable}
    if haskey(dfg.g.variables, variable.label)
        throw(LabelExistsError("Variable", variable.label))
    end

    FactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    # push!(dfg.addHistory, variable.label)

    return variable
end

function addVariable!(
    dfg::GraphsDFG{<:AbstractDFGParams, VD, <:AbstractGraphFactor},
    variable::AbstractGraphVariable,
) where {VD <: AbstractGraphVariable}
    return addVariable!(dfg, VD(variable))
end

function addFactor!(
    dfg::GraphsDFG{<:AbstractDFGParams, <:AbstractGraphVariable, F},
    factor::F,
) where {F <: AbstractGraphFactor}
    if haskey(dfg.g.factors, factor.label)
        throw(LabelExistsError("Factor", factor.label))
    end
    # TODO
    # @assert FactorGraphs.addFactor!(dfg.g, getVariableOrder(factor), factor)
    variableLabels = Symbol[factor.variableorder...]
    for vlabel in variableLabels
        !hasVariable(dfg, vlabel) && throw(LabelNotFoundError("Variable", vlabel))
    end
    @assert FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
    return factor
end

function addFactor!(
    dfg::GraphsDFG{<:AbstractDFGParams, <:AbstractGraphVariable, F},
    factor::AbstractGraphFactor,
) where {F <: AbstractGraphFactor}
    return addFactor!(dfg, F(factor))
end

function getVariable(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.variables, label)
        throw(LabelNotFoundError("Variable", label))
    end

    return dfg.g.variables[label]
end

function getFactor(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.factors, label)
        throw(LabelNotFoundError("Factor", label))
    end
    return dfg.g.factors[label]
end

function mergeVariable!(dfg::GraphsDFG, variable::AbstractGraphVariable)
    if !haskey(dfg.g.variables, variable.label)
        addVariable!(dfg, variable)
    else
        patch!(dfg.g.variables[variable.label], variable)
    end
    # metrics = (;
    #     tags = length(variable.tags),
    #     states = length(variable.states),
    #     bloblets = length(variable.bloblets),
    #     blobentries = length(variable.blobentries),
    # )
    #TODO return metrics or 1 to keep it simple?
    # if 1, the merge result does not include the children.
    # if metrics, the merge result includes the children counts
    return 1
end

function mergeFactor!(dfg::GraphsDFG, factor::AbstractGraphFactor)
    label = getLabel(factor)
    if !haskey(dfg.g.factors, label)
        addFactor!(dfg, factor)
    else
        patch!(dfg.g.factors[label], factor)
    end
    #TODO also same metrics consideration as mergeVariable!
    return 1
end

function deleteVariable!(dfg::GraphsDFG, label::Symbol)#::Tuple{AbstractGraphVariable, Vector{<:AbstractGraphFactor}}
    !haskey(dfg.g.variables, label) && return 0

    # orphaned factors are not supported.
    del_facs = map(l -> deleteFactor!(dfg, l), listNeighbors(dfg, label))

    rem_vertex!(dfg.g, dfg.g.labels[label])
    return sum(del_facs; init = 0) + 1
end

function deleteFactor!(dfg::GraphsDFG, label::Symbol)
    !haskey(dfg.g.factors, label) && return 0
    rem_vertex!(dfg.g, dfg.g.labels[label])
    return 1
end

# """
# whereTags = ⊇([:x1])
# whereTags([:x1, :x2])
# true
# whereTags = Base.Fix1(in, :x1)
# whereTags([:x1, :x2])
# true
# """

function getVariables(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
)
    variables = collect(values(dfg.g.variables))

    filterDFG!(variables, whereLabel, getLabel)
    filterDFG!(variables, whereSolvable, getSolvable)
    filterDFG!(variables, whereTags, refTags)
    filterDFG!(variables, whereType, getStateKind)

    return variables
end

function listVariables(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    if !isnothing(whereSolvable) || !isnothing(whereTags) || !isnothing(whereType)
        return map(
            getLabel,
            getVariables(dfg; whereSolvable, whereTags, whereType, whereLabel),
        )::Vector{Symbol}
    else
        # Is it ok to continue using the internal keys property? collect(keys(dfg.g.variables)) allowcates a lot.
        labels = copy(dfg.g.variables.keys)
        filterDFG!(labels, whereLabel, string)
        return labels
    end
end

function getFactors(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    factors = collect(values(dfg.g.factors))
    filterDFG!(factors, whereLabel, getLabel)
    filterDFG!(factors, whereSolvable, getSolvable)
    filterDFG!(factors, whereTags, refTags)
    filterDFG!(factors, whereType, typeof ∘ DFG.getObservation)
    return factors
end

function listFactors(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    if !isnothing(whereSolvable) || !isnothing(whereTags) || !isnothing(whereType)
        return map(
            getLabel,
            getFactors(dfg; whereSolvable, whereTags, whereType, whereLabel),
        )::Vector{Symbol}
    else
        # Is it ok to continue using the internal keys property? collect(keys(dfg.g.factors)) allowcates a lot.
        labels = copy(dfg.g.factors.keys)
        filterDFG!(labels, whereLabel, string)
        return labels
    end
end

function isConnected(dfg::GraphsDFG)
    return Graphs.is_connected(dfg.g)
    # return length(Graphs.connected_components(dfg.g)) == 1
end

function listNeighbors(
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

function listNeighborhood(
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
function getBiadjacencyMatrix(
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

function toDotFile(dfg::GraphsDFG, fileName::String = "/tmp/dfg.dot")
    open(fileName, "w") do fid
        return savedot_attributes(fid, dfg)
    end
    return nothing
end

function toDot(dfg::GraphsDFG)
    m = PipeBuffer()
    savedot_attributes(m, dfg)
    data = take!(m)
    close(m)
    return String(data)
end

#API design NOTE:
# Do not create new Verbs or Nouns for metric vs. topological pathfinding. findPaths is the universal router... findPaths(..., metric)
# for now we only look at topological paths.

function findPaths(::typeof(all_simple_paths), dfg, from::Symbol, to::Symbol; kwargs...)
    gpaths = Graphs.all_simple_paths(dfg.g, dfg.g.labels[from], dfg.g.labels[to]; kwargs...)
    return map(p -> (path = map(i -> dfg.g.labels[i], p), dist = length(p) - 1), gpaths)
end

function findPaths(
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
function findPaths(
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
        return findPaths(a_star, active_dfg, from, to; kwargs...)
    else
        return findPaths(yen_k_shortest_paths, active_dfg, from, to, k; kwargs...)
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

# FG blob entries 
function getGraphBlobentry(fg::GraphsDFG, label::Symbol)
    if !haskey(fg.graph.blobentries, label)
        throw(LabelNotFoundError("GraphBlobentry", label))
    end
    return fg.graph.blobentries[label]
end

function getGraphBlobentries(fg::GraphsDFG; whereLabel::Union{Nothing, Function} = nothing)
    entries = collect(values(fg.graph.blobentries))
    filterDFG!(entries, whereLabel, getLabel)
    return entries
end

function listGraphBlobentries(fg::GraphsDFG; whereLabel::Union{Nothing, Function} = nothing)
    labels = collect(keys(fg.graph.blobentries))
    filterDFG!(labels, whereLabel, string)
    return labels
end

function listAgentBlobentries(fg::GraphsDFG, agentlabel::Symbol)
    return collect(keys(fg.agents[agentlabel].blobentries))
end

function addGraphBlobentry!(fg::GraphsDFG, entry::Blobentry)
    if haskey(fg.graph.blobentries, entry.label)
        throw(LabelExistsError("Blobentry", entry.label))
    end
    push!(fg.graph.blobentries, entry.label => entry)
    return entry
end

function addGraphBlobentries!(fg::GraphsDFG, entries::Vector{Blobentry})
    return map(entries) do entry
        return addGraphBlobentry!(fg, entry)
    end
end

function DFG.addAgentBlobentry!(fg::GraphsDFG, agentlabel::Symbol, entry::Blobentry)
    if haskey(fg.agents[agentlabel].blobentries, entry.label)
        throw(LabelExistsError("Blobentry", entry.label))
    end
    push!(fg.agents[agentlabel].blobentries, entry.label => entry)
    return entry
end

function DFG.addAgentBlobentries!(
    fg::GraphsDFG,
    agentlabel::Symbol,
    entries::Vector{Blobentry},
)
    return map(entries) do entry
        return addAgentBlobentry!(fg, agentlabel, entry)
    end
end

function DFG.getAgentBlobentry(fg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    if !haskey(fg.agents[agentlabel].blobentries, label)
        throw(LabelNotFoundError("Blobentry", label))
    end
    return fg.agents[agentlabel].blobentries[label]
end

function DFG.getAgentBlobentries(
    fg::GraphsDFG,
    agentlabel::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
)
    entries = collect(values(fg.agents[agentlabel].blobentries))
    filterDFG!(entries, whereLabel, getLabel)
    return entries
end

function DFG.mergeGraphBlobentry!(dfg::GraphsDFG, entry::Blobentry)
    DFG.refBlobentries(dfg.graph)[getLabel(entry)] = entry
    return 1
end

function DFG.mergeAgentBlobentry!(dfg::GraphsDFG, agentlabel::Symbol, entry::Blobentry)
    DFG.refBlobentries(dfg.agents[agentlabel])[getLabel(entry)] = entry
    return 1
end

function DFG.mergeGraphBlobentries!(dfg::GraphsDFG, entries::Vector{Blobentry})
    cnts = map(entries) do entry
        return mergeGraphBlobentry!(dfg, entry)
    end
    return sum(cnts)
end

function DFG.mergeAgentBlobentries!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    entries::Vector{Blobentry},
)
    cnts = map(entries) do entry
        return mergeAgentBlobentry!(dfg, agentlabel, entry)
    end
    return sum(cnts)
end

##=============================================================================
## Variable Blobentries
##=============================================================================

function DFG.addVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    variable = getVariable(dfg, label)
    addBlobentry!(variable, entry)
    return entry
end

function DFG.mergeVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    return mergeBlobentry!(getVariable(dfg, label), entry)
end

function DFG.deleteVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entryLabel::Symbol)
    return deleteBlobentry!(getVariable(dfg, label), entryLabel)
end

##=============================================================================
## Factor Blobentries
##=============================================================================

function DFG.addFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    factor = getFactor(dfg, label)
    addBlobentry!(factor, entry)
    return entry
end

function DFG.mergeFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    return mergeBlobentry!(getFactor(dfg, label), entry)
end

function DFG.deleteFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entryLabel::Symbol)
    return deleteBlobentry!(getFactor(dfg, label), entryLabel)
end

function DFG.deleteGraphBlobentry!(dfg::GraphsDFG, label::Symbol)
    !haskey(dfg.graph.blobentries, label) && return 0
    delete!(dfg.graph.blobentries, label)
    return 1
end

function DFG.deleteAgentBlobentry!(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    !haskey(dfg.agents[agentlabel].blobentries, label) && return 0
    delete!(dfg.agents[agentlabel].blobentries, label)
    return 1
end

function DFG.hasGraphBlobentry(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.graph.blobentries, label)
end

function DFG.hasAgentBlobentry(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return haskey(dfg.agents[agentlabel].blobentries, label)
end
