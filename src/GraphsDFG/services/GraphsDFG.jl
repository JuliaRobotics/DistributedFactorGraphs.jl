
function getDFGMetadata(fg::GraphsDFG)
    metafields = Set(fieldnames(GraphsDFG))
    setdiff!(metafields, [:g, :solverParams])
    metaprops = NamedTuple(k => getproperty(fg, k) for k in metafields)
    return metaprops
end

function exists(
    dfg::GraphsDFG{P, V, F},
    node::V,
) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, node.label)
end

function exists(
    dfg::GraphsDFG{P, V, F},
    node::F,
) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, node.label)
end

exists(dfg::GraphsDFG, nId::Symbol) = haskey(dfg.g.labels, nId)

exists(dfg::GraphsDFG, node::DFGNode) = exists(dfg, node.label)

function isVariable(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, sym)
end

function isFactor(
    dfg::GraphsDFG{P, V, F},
    sym::Symbol,
) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, sym)
end

function addVariable!(
    dfg::GraphsDFG{<:AbstractParams, V, <:AbstractDFGFactor},
    variable::V,
) where {V <: AbstractDFGVariable}
    #TODO should this be an error
    if haskey(dfg.g.variables, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end

    FactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return variable
end

function addVariable!(
    dfg::GraphsDFG{<:AbstractParams, VD, <:AbstractDFGFactor},
    variable::AbstractDFGVariable,
) where {VD <: AbstractDFGVariable}
    return addVariable!(dfg, VD(variable))
end

#moved to abstract
# function addFactor!(dfg::GraphsDFG{<:AbstractParams, V, F}, variables::Vector{<:V}, factor::F)::F where {V <: AbstractDFGVariable, F <: AbstractDFGFactor}
#
#     #TODO should this be an error
#     if haskey(dfg.g.factors, factor.label)
#         error("Factor '$(factor.label)' already exists in the factor graph")
#     end
#     # for v in variables
#     #     if !(v.label in keys(dfg.g.metaindex[:label]))
#     #         error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
#     #     end
#     # end
#
#     variableLabels = map(v->v.label, variables)
#
#     resize!(factor._variableOrderSymbols, length(variableLabels))
#     factor._variableOrderSymbols .= variableLabels
#     # factor._variableOrderSymbols = copy(variableLabels)
#
#     @assert FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
#     return factor
# end
#
# function addFactor!(dfg::GraphsDFG{<:AbstractParams, <:AbstractDFGVariable, F}, variableLabels::Vector{Symbol}, factor::F)::F where F <: AbstractDFGFactor
#     #TODO should this be an error
#     if haskey(dfg.g.factors, factor.label)
#         error("Factor '$(factor.label)' already exists in the factor graph")
#     end
#
#     resize!(factor._variableOrderSymbols, length(variableLabels))
#     factor._variableOrderSymbols .= variableLabels
#
#     @assert FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
#
#     return factor
# end

function addFactor!(
    dfg::GraphsDFG{<:AbstractParams, <:AbstractDFGVariable, F},
    factor::F,
) where {F <: AbstractDFGFactor}
    if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    # TODO
    # @assert FactorGraphs.addFactor!(dfg.g, getVariableOrder(factor), factor)
    @assert FactorGraphs.addFactor!(dfg.g, Symbol[factor._variableOrderSymbols...], factor)
    return factor
end

function addFactor!(
    dfg::GraphsDFG{<:AbstractParams, <:AbstractDFGVariable, F},
    factor::AbstractDFGFactor,
) where {F <: AbstractDFGFactor}
    return addFactor!(dfg, F(factor))
end

function getVariable(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end

    return dfg.g.variables[label]
end

function getFactor(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.factors[label]
end

function updateVariable!(
    dfg::GraphsDFG,
    variable::AbstractDFGVariable;
    warn_if_absent::Bool = true,
)
    if !haskey(dfg.g.variables, variable.label)
        warn_if_absent &&
            @warn "Variable label '$(variable.label)' does not exist in the factor graph, adding"
        return addVariable!(dfg, variable)
    end
    dfg.g.variables[variable.label] = variable
    return variable
end

function updateFactor!(
    dfg::GraphsDFG,
    factor::AbstractDFGFactor;
    warn_if_absent::Bool = true,
)
    if !haskey(dfg.g.factors, factor.label)
        warn_if_absent &&
            @warn "Factor label '$(factor.label)' does not exist in the factor graph, adding"
        return addFactor!(dfg, factor)
    end

    # Confirm that we're not updating the neighbors
    dfg.g.factors[factor.label]._variableOrderSymbols != factor._variableOrderSymbols &&
        error("Cannot update the factor, the neighbors are not the same.")

    dfg.g.factors[factor.label] = factor
    return factor
end

function deleteVariable!(dfg::GraphsDFG, label::Symbol)#::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end

    deleteNeighbors = true # reserved, orphaned factors are not supported at this time
    if deleteNeighbors
        neigfacs = map(l -> deleteFactor!(dfg, l), listNeighbors(dfg, label))
    end
    variable = dfg.g.variables[label]
    rem_vertex!(dfg.g, dfg.g.labels[label])

    return variable, neigfacs
end

function deleteFactor!(
    dfg::GraphsDFG,
    label::Symbol;
    suppressGetFactor::Bool = false,
)
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    factor = dfg.g.factors[label]
    rem_vertex!(dfg.g, dfg.g.labels[label])
    return factor
end

function getVariables(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
    detail = nothing,
)

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    variables = collect(values(dfg.g.variables))
    if regexFilter !== nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
    if solvable != 0
        variables = filter(v -> _isSolvable(dfg, v.label, solvable), variables)
    end
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, variables)
        return variables[mask]
    end
    return variables
end

function listVariables(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
)

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    if length(tags) > 0
        return map(
            v -> v.label,
            getVariables(dfg, regexFilter; tags = tags, solvable = solvable),
        )
    else
        variables = copy(dfg.g.variables.keys)
        regexFilter !== nothing &&
            (variables = filter(v -> occursin(regexFilter, String(v)), variables))
        solvable != 0 &&
            (variables = filter(vId -> _isSolvable(dfg, vId, solvable), variables))
        return variables::Vector{Symbol}
    end
end

function getFactors(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
)
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    factors = collect(values(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
    end
    if solvable != 0
        factors = filter(f -> _isSolvable(dfg, f.label, solvable), factors)
    end
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, factors)
        return factors[mask]
    end
    return factors
end

function listFactors(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
)
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    if length(tags) > 0
        return map(
            v -> v.label,
            getFactors(dfg, regexFilter; tags = tags, solvable = solvable),
        )
    end
    factors = copy(dfg.g.factors.keys)
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f)), factors)
    end
    if solvable != 0
        factors = filter(fId -> _isSolvable(dfg, fId, solvable), factors)
    end
    return factors::Vector{Symbol}
end

function isConnected(dfg::GraphsDFG)
    return Graphs.is_connected(dfg.g)
    # return length(Graphs.connected_components(dfg.g)) == 1
end

function _isSolvable(dfg::GraphsDFG, label::Symbol, ready::Int)
    haskey(dfg.g.variables, label) && (return dfg.g.variables[label].solvable >= ready)
    haskey(dfg.g.factors, label) && (return dfg.g.factors[label].solvable >= ready)

    #TODO should this be a breaking error?
    @error "Node not in factor or variable"
    return false
end

function listNeighbors(dfg::GraphsDFG, node::DFGNode; solvable::Int = 0)
    label = node.label
    if !exists(dfg, label)
        error(
            "Variable/factor with label '$(node.label)' does not exist in the factor graph",
        )
    end

    neighbors_il = FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if typeof(node) <: AbstractDFGFactor
        order = intersect(node._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll::Vector{Symbol}
end

function listNeighbors(dfg::GraphsDFG, label::Symbol; solvable::Int = 0)
    if !exists(dfg, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

    neighbors_il = FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label]._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll
end

function getNeighborhood(
    dfg::GraphsDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int;
    solvable::Int = 0,
)
    # find neighbors at distance to add
    nbhood = Int[]

    for l in variableFactorLabels
        union!(nbhood, neighborhood(dfg.g, dfg.g.labels[l], distance))
    end

    allvarfacs = [dfg.g.labels[id] for id in nbhood]

    solvable != 0 && filter!(nlbl -> (getSolvable(dfg, nlbl) >= solvable), allvarfacs)

    return allvarfacs
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
    solvable::Int = 0,
    varLabels = listVariables(dfg; solvable = solvable),
    factLabels = listFactors(dfg; solvable = solvable),
)
    varIndex = [dfg.g.labels[s] for s in varLabels]
    factIndex = [dfg.g.labels[s] for s in factLabels]

    adj = adjacency_matrix(dfg.g)

    adjvf = adj[factIndex, varIndex]
    return (B = adjvf, varLabels = varLabels, facLabels = factLabels)
end

"""
    $(SIGNATURES)
Gets an empty and unique GraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(
    dfg::GraphsDFG{P, V, F},
) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    newDfg = GraphsDFG{P, V, F}(;
        userLabel = getUserLabel(dfg),
        robotLabel = getRobotLabel(dfg),
        sessionLabel = getSessionLabel(dfg),
        solverParams = deepcopy(dfg.solverParams),
    )
    newDfg.description = "(Copy of) $(dfg.description)"
    return newDfg
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
function findShortestPathDijkstra(
    dfg::GraphsDFG,
    from::Symbol,
    to::Symbol;
    regexVariables::Union{Nothing, Regex} = nothing,
    regexFactors::Union{Nothing, Regex} = nothing,
    tagsVariables::Vector{Symbol} = Symbol[],
    tagsFactors::Vector{Symbol} = Symbol[],
    typeVariables::Union{Nothing, <:AbstractVector} = nothing,
    typeFactors::Union{Nothing, <:AbstractVector} = nothing,
    solvable::Int = 0,
    initialized::Union{Nothing, Bool} = nothing,
)
    #
    # helper function to filter on vector of types
    function _filterTypeList(thelist::Vector{Symbol}, typeList, listfnc = x -> ls(dfg, x))
        thelist_ = Symbol[]
        for type_ in typeList
            union!(thelist_, listfnc(type_))
        end
        return intersect(thelist, thelist_)
    end

    #
    duplicate =
        regexVariables !== nothing ||
        regexFactors !== nothing ||
        0 < length(tagsVariables) ||
        0 < length(tagsFactors) ||
        typeVariables !== nothing ||
        typeFactors !== nothing ||
        initialized !== nothing ||
        solvable != 0
    #
    dfg_ = if duplicate
        # use copy if filter is being applied
        varList = ls(dfg, regexVariables; tags = tagsVariables, solvable = solvable)
        fctList = lsf(dfg, regexFactors; tags = tagsFactors, solvable = solvable)
        varList = if typeVariables !== nothing
            _filterTypeList(varList, typeVariables)
        else
            varList
        end
        fctList = if typeFactors !== nothing
            _filterTypeList(fctList, typeFactors, x -> lsf(dfg, x))
        else
            fctList
        end
        varList = if initialized !== nothing
            initmask = isInitialized.(dfg, varList) .== initialized
            varList[initmask]
        else
            varList
        end
        deepcopyGraph(typeof(dfg), dfg, varList, fctList)
    else
        # no filter can be used directly
        dfg
    end

    if !exists(dfg_, from) || !exists(dfg_, to)
        # assume filters excluded either `to` or `from` and hence no shortest path
        return Symbol[]
    end
    # GraphsDFG internally uses Integers 
    frI = dfg_.g.labels[from]
    toI = dfg_.g.labels[to]

    # get shortest path from graph provider
    path_state = Graphs.dijkstra_shortest_paths(dfg_.g.graph, [frI;])
    path = Graphs.enumerate_paths(path_state, toI)
    dijkpath = map(x -> dfg_.g.labels[x], path)

    # return the list of symbols
    return dijkpath
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
# session blob entries

function getSessionBlobEntry(fg::GraphsDFG, label::Symbol)
    return fg.sessionBlobEntries[label]
end

function getSessionBlobEntries(fg::GraphsDFG, startwith::Union{Nothing, String} = nothing)
    entries = collect(values(fg.sessionBlobEntries))
    !isnothing(startwith) && filter!(e -> startswith(string(e.label), startwith), entries)
    return entries
end

function listSessionBlobEntries(fg::GraphsDFG)
    return collect(keys(fg.sessionBlobEntries))
end

function listRobotBlobEntries(fg::GraphsDFG)
    return collect(keys(fg.robotBlobEntries))
end

function listUserBlobEntries(fg::GraphsDFG)
    return collect(keys(fg.userBlobEntries))
end

function addSessionBlobEntry!(fg::GraphsDFG, entry::BlobEntry)
    if haskey(fg.sessionBlobEntries, entry.label)
        error(
            "BlobEntry '$(entry.label)' already exists in the factor graph's session blob entries.",
        )
    end
    push!(fg.sessionBlobEntries, entry.label => entry)
    return entry
end

function addSessionBlobEntries!(fg::GraphsDFG, entries::Vector{BlobEntry})
    return map(entries) do entry
        return addSessionBlobEntry!(fg, entry)
    end
end

# function getSessionBlobEntry(fg::GraphsDFG, label::Symbol)
#     return JSON3.read(fg.sessionData[label], BlobEntry)
# end

# function getSessionBlobEntries(fg::GraphsDFG, startwith::Union{Nothing,String}=nothing)
#     entries = map(values(fg.sessionData)) do entry
#         JSON3.read(entry, BlobEntry)
#     end
#     !isnothing(startwith) && filter!(e->startswith(string(e.label), startwith), entries)
#     return entries
# end

# function addSessionBlobEntries!(fg::GraphsDFG, entries::Vector{BlobEntry})
#     return map(entries) do entry
#         push!(fg.sessionData, entry.label=>JSON3.write(entry))
#     end
# end
