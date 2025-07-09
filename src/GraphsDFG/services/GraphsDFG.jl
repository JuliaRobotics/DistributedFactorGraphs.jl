
function getDFGMetadata(fg::GraphsDFG)
    metafields = Set(fieldnames(GraphsDFG))
    setdiff!(metafields, [:g, :solverParams])
    metaprops = NamedTuple(k => getproperty(fg, k) for k in metafields)
    return metaprops
end

function hasVariable(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.variables, label)
end

function hasFactor(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.factors, label)
end

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
    if haskey(dfg.g.variables, variable.label)
        throw(LabelExistsError("Variable", variable.label))
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
        throw(LabelExistsError("Factor", factor.label))
    end
    # TODO
    # @assert FactorGraphs.addFactor!(dfg.g, getVariableOrder(factor), factor)
    variableLabels = Symbol[factor._variableOrderSymbols...]
    for vlabel in variableLabels
        !hasVariable(dfg, vlabel) && throw(LabelNotFoundError("Variable", vlabel))
    end
    @assert FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
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

function mergeVariable!(dfg::GraphsDFG, variable::AbstractDFGVariable)
    if !haskey(dfg.g.variables, variable.label)
        addVariable!(dfg, variable)
    else
        dfg.g.variables[variable.label] = variable
    end
    return 1
end

function mergeFactor!(dfg::GraphsDFG, factor::AbstractDFGFactor;)
    if !haskey(dfg.g.factors, factor.label)
        addFactor!(dfg, factor)
    elseif dfg.g.factors[factor.label]._variableOrderSymbols != factor._variableOrderSymbols
        #TODO should we allow merging the factor neighbors or error as before?
        error("Cannot update the factor, the neighbors are not the same.")
        # We need to delete the factor if we are updating the neighbors
        # deleteFactor!(dfg, factor.label)
        # addFactor!(dfg, factor)
    else
        dfg.g.factors[factor.label] = factor
    end

    return 1
end

function deleteVariable!(dfg::GraphsDFG, label::Symbol)#::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    if !haskey(dfg.g.variables, label)
        throw(LabelNotFoundError("Variable", label))
    end

    deleteNeighbors = true # reserved, orphaned factors are not supported at this time
    if deleteNeighbors
        del_facs = map(l -> deleteFactor!(dfg, l), listNeighbors(dfg, label))
    end
    rem_vertex!(dfg.g, dfg.g.labels[label])
    return sum(del_facs) + 1
end

function deleteFactor!(dfg::GraphsDFG, label::Symbol; suppressGetFactor::Bool = false)
    if !haskey(dfg.g.factors, label)
        throw(LabelNotFoundError("Factor", label))
    end
    rem_vertex!(dfg.g, dfg.g.labels[label])
    return 1
end

function getVariables(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
    solvableFilter::Union{Nothing, Base.Fix2} = nothing,
)

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa VariableCompute, vertices(dfg.g)))
    variables = collect(values(dfg.g.variables))

    !isnothing(regexFilter) &&
        filter!(v -> occursin(regexFilter, String(v.label)), variables)

    solvable != 0 && filter!(v -> _isSolvable(dfg, v.label, solvable), variables)

    !isempty(tags) && filter!(v -> !isempty(intersect(v.tags, tags)), variables)

    !isnothing(solvableFilter) && filter!(v -> solvableFilter(getSolvable(v)), variables)

    return variables
end

function listVariables(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
    solvableFilter::Union{Nothing, Base.Fix2} = nothing,
)

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa VariableCompute, vertices(dfg.g)))
    if length(tags) > 0
        return map(
            v -> v.label,
            getVariables(dfg, regexFilter; tags = tags, solvable = solvable),
        )::Vector{Symbol}
    else
        variables = copy(dfg.g.variables.keys)
        !isnothing(regexFilter) && filter!(v -> occursin(regexFilter, String(v)), variables)
        solvable != 0 && filter!(vId -> _isSolvable(dfg, vId, solvable), variables)
        !isnothing(solvableFilter) &&
            filter!(v -> solvableFilter(getSolvable(dfg, v)), variables)
        return variables::Vector{Symbol}
    end
end

function getFactors(
    dfg::GraphsDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
)
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa FactorCompute, vertices(dfg.g)))
    factors = collect(values(dfg.g.factors))
    if !isnothing(regexFilter)
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
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa FactorCompute, vertices(dfg.g)))
    if length(tags) > 0
        return map(
            v -> v.label,
            getFactors(dfg, regexFilter; tags = tags, solvable = solvable),
        )
    end
    factors = copy(dfg.g.factors.keys)
    if !isnothing(regexFilter)
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
    throw(LabelNotFoundError(label))
end

function listNeighbors(dfg::GraphsDFG, node::DFGNode; solvable::Int = 0)
    return listNeighbors(dfg, node.label; solvable)
end

function listNeighbors(dfg::GraphsDFG, label::Symbol; solvable::Int = 0)
    if !(hasVariable(dfg, label) || hasFactor(dfg, label))
        throw(LabelNotFoundError(label))
    end

    neighbors_il = FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label]._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order::Vector{Symbol}
    end

    return neighbors_ll::Vector{Symbol}
end

function listNeighborhood(
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
        agentLabel = getAgentLabel(dfg),
        graphLabel = getGraphLabel(dfg),
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

    if !(hasVariable(dfg_, from) || hasFactor(dfg_, from)) ||
       !(hasVariable(dfg_, to) || hasFactor(dfg_, to))
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
function getGraphBlobentry(fg::GraphsDFG, label::Symbol)
    if !haskey(fg.graphBlobEntries, label)
        throw(LabelNotFoundError("GraphBlobentry", label))
    end
    return fg.graphBlobEntries[label]
end

function getGraphBlobentries(
    fg::GraphsDFG,
    filt::Union{Nothing, String, Base.Fix2} = nothing,
)
    entries = collect(values(fg.graphBlobEntries))
    if !isnothing(filt) && isa(filt, String)
        @warn "String filter is deprecated, use startswith(filt_string) instead"
        filter!(e -> startswith(string(e.label), filt), entries)
    elseif !isnothing(filt)
        filter!(e -> filt(string(e.label)), entries)
    end
    return entries
end

function listGraphBlobentries(fg::GraphsDFG)
    return collect(keys(fg.graphBlobEntries))
end

function listAgentBlobentries(fg::GraphsDFG)
    return collect(keys(fg.agent.blobEntries))
end

function addGraphBlobentry!(fg::GraphsDFG, entry::Blobentry)
    if haskey(fg.graphBlobEntries, entry.label)
        throw(LabelExistsError("Blobentry", entry.label))
    end
    push!(fg.graphBlobEntries, entry.label => entry)
    return entry
end

function addGraphBlobentries!(fg::GraphsDFG, entries::Vector{Blobentry})
    return map(entries) do entry
        return addGraphBlobentry!(fg, entry)
    end
end
