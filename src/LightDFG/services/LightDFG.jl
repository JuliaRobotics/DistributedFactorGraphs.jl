

function exists(dfg::LightDFG{P,V,F}, node::V) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, node.label)
end

function exists(dfg::LightDFG{P,V,F}, node::F) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, node.label)
end

exists(dfg::LightDFG, nId::Symbol) = haskey(dfg.g.labels, nId)

exists(dfg::LightDFG, node::DFGNode) = exists(dfg, node.label)

function isVariable(dfg::LightDFG{P,V,F}, sym::Symbol) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, sym)
end

function isFactor(dfg::LightDFG{P,V,F}, sym::Symbol) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, sym)
end


function addVariable!(dfg::LightDFG{<:AbstractParams, V, <:AbstractDFGFactor}, variable::V)::V where V <: AbstractDFGVariable
    #TODO should this be an error
    if haskey(dfg.g.variables, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end

    FactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return variable
end

function addVariable!(dfg::LightDFG{<:AbstractParams, VD, <:AbstractDFGFactor},
                      variable::AbstractDFGVariable)::VD where VD <: AbstractDFGVariable
    return addVariable!(dfg, VD(variable))
end


#moved to abstract
# function addFactor!(dfg::LightDFG{<:AbstractParams, V, F}, variables::Vector{<:V}, factor::F)::F where {V <: AbstractDFGVariable, F <: AbstractDFGFactor}
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
# function addFactor!(dfg::LightDFG{<:AbstractParams, <:AbstractDFGVariable, F}, variableLabels::Vector{Symbol}, factor::F)::F where F <: AbstractDFGFactor
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


function addFactor!(dfg::LightDFG{<:AbstractParams, <:AbstractDFGVariable, F}, factor::F)::F where F <: AbstractDFGFactor
    if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    # TODO
    # @assert FactorGraphs.addFactor!(dfg.g, getVariableOrder(factor), factor)
    @assert FactorGraphs.addFactor!(dfg.g, factor._variableOrderSymbols, factor)
    return factor
end

function addFactor!(dfg::LightDFG{<:AbstractParams, <:AbstractDFGVariable, F},
                      factor::AbstractDFGFactor) where F <: AbstractDFGFactor
    return addFactor!(dfg, F(factor))
end

function getVariable(dfg::LightDFG, label::Symbol)
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end

    return dfg.g.variables[label]
end

function getFactor(dfg::LightDFG, label::Symbol)
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.factors[label]
end

function updateVariable!(dfg::LightDFG, variable::AbstractDFGVariable; warn_if_absent::Bool=true)
    if !haskey(dfg.g.variables, variable.label)
        warn_if_absent && @warn "Variable label '$(variable.label)' does not exist in the factor graph, adding"
        return addVariable!(dfg, variable)
    end
    dfg.g.variables[variable.label] = variable
    return variable
end

function updateFactor!(dfg::LightDFG, factor::AbstractDFGFactor; warn_if_absent::Bool=true)
    if !haskey(dfg.g.factors, factor.label)
        warn_if_absent && @warn "Factor label '$(factor.label)' does not exist in the factor graph, adding"
        return addFactor!(dfg, factor)
    end

    # Confirm that we're not updating the neighbors
    dfg.g.factors[factor.label]._variableOrderSymbols != factor._variableOrderSymbols && error("Cannot update the factor, the neighbors are not the same.")

    dfg.g.factors[factor.label] = factor
    return factor
end

function deleteVariable!(dfg::LightDFG, label::Symbol)#::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end

    deleteNeighbors = true # reserved, orphaned factors are not supported at this time
    if deleteNeighbors
        neigfacs = map(l->deleteFactor!(dfg, l), getNeighbors(dfg, label))
    end
    variable = dfg.g.variables[label]
    rem_vertex!(dfg.g, dfg.g.labels[label])

    return variable, neigfacs
end

function deleteFactor!(dfg::LightDFG, label::Symbol)::AbstractDFGFactor
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    factor = dfg.g.factors[label]
    variable = rem_vertex!(dfg.g,  dfg.g.labels[label])
    return factor
end

function getVariables(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGVariable}

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    variables = collect(values(dfg.g.variables))
    if regexFilter != nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
    if solvable != 0
        variables = filter(v -> _isSolvable(dfg, v.label, solvable), variables)
    end
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, variables )
        return variables[mask]
    end
    return variables
end

function listVariables(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol}

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    if length(tags) > 0
        return map(v -> v.label, getVariables(dfg, regexFilter, tags=tags, solvable=solvable))
    else
        variables = collect(keys(dfg.g.variables))
        regexFilter != nothing && (variables = filter(v -> occursin(regexFilter, String(v)), variables))
        solvable != 0 && (variables = filter(vId -> _isSolvable(dfg, vId, solvable), variables))
        return variables
    end
end

function getFactors(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGFactor}
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    factors = collect(values(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
    end
    if solvable != 0
        factors = filter(f -> _isSolvable(dfg, f.label, solvable), factors)
    end
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, factors )
        return factors[mask]
    end
    return factors
end

function listFactors(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol}
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    if length(tags) > 0
        return map(v -> v.label, getFactors(dfg, regexFilter, tags=tags, solvable=solvable))
    end
    factors = collect(keys(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f)), factors)
    end
    if solvable != 0
        factors = filter(fId -> _isSolvable(dfg, fId, solvable), factors)
    end
    return factors
end

function isConnected(dfg::LightDFG)::Bool
    return LightGraphs.is_connected(dfg.g)
    # return length(LightGraphs.connected_components(dfg.g)) == 1
end

function _isSolvable(dfg::LightDFG, label::Symbol, ready::Int)::Bool

    haskey(dfg.g.variables, label) && (return dfg.g.variables[label].solvable >= ready)
    haskey(dfg.g.factors, label) && (return dfg.g.factors[label].solvable >= ready)

    #TODO should this be a breaking error?
    @error "Node not in factor or variable"
    return false
end

function getNeighbors(dfg::LightDFG, node::DFGNode; solvable::Int=0)::Vector{Symbol}
    label = node.label
    if !exists(dfg, label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if typeof(node) <: AbstractDFGFactor
        order = intersect(node._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll
end


function getNeighbors(dfg::LightDFG, label::Symbol; solvable::Int=0)::Vector{Symbol}
    if !exists(dfg, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

    neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
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

function getNeighborhood(dfg::LightDFG, variableFactorLabels::Vector{Symbol}, distance::Int; solvable::Int=0)::Vector{Symbol}
    # find neighbors at distance to add
    nbhood = Int[]

    for l in variableFactorLabels
        union!(nbhood, neighborhood(dfg.g, dfg.g.labels[l], distance))
    end

    allvarfacs = [dfg.g.labels[id] for id in nbhood]

    solvable != 0 && filter!(nlbl -> (getSolvable(dfg, nlbl) >= solvable), allvarfacs)

    return allvarfacs

end

# TODO copy LightDFG to LightDFG overwrite
# function copyGraph!(destDFG::LightDFG,
#                     sourceDFG::LightDFG,
#                     variableFactorLabels::Vector{Symbol};
#                     copyGraphMetadata::Bool=false,
#                     overwriteDest::Bool=false,
#                     deepcopyNodes::Bool=false,
#                     verbose::Bool = true)


#  Biadjacency Matrix https://en.wikipedia.org/wiki/Adjacency_matrix#Of_a_bipartite_graph
function getBiadjacencyMatrix(dfg::LightDFG; solvable::Int=0)::NamedTuple{(:B, :varLabels, :facLabels),Tuple{LightGraphs.SparseMatrixCSC,Vector{Symbol}, Vector{Symbol}}}
    varLabels = listVariables(dfg, solvable=solvable)
    factLabels = listFactors(dfg, solvable=solvable)
    varIndex = [dfg.g.labels[s] for s in varLabels]
    factIndex = [dfg.g.labels[s] for s in factLabels]

    adj = adjacency_matrix(dfg.g)

    adjvf = adj[factIndex, varIndex]
    return (B=adjvf, varLabels=varLabels, facLabels=factLabels)
end

"""
    $(SIGNATURES)
Gets an empty and unique LightDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::LightDFG{P,V,F})::LightDFG where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    newDfg = LightDFG{P,V,F}(;
        userId=dfg.userId, robotId=dfg.robotId, sessionId=dfg.sessionId,
        solverParams=deepcopy(dfg.solverParams))
    newDfg.description ="(Copy of) $(dfg.description)"
    return newDfg
end


#TODO JT test.
"""
    $(SIGNATURES)
A replacement for to_dot that saves only hardcoded factor graph plotting attributes.
"""
function savedot_attributes(io::IO, dfg::LightDFG)
    write(io, "graph G {\n")

    for vl in listVariables(dfg)
        write(io, "$vl [color=red, shape=ellipse];\n")
    end
    for fl in listFactors(dfg)
        write(io, "$fl [color=blue, shape=box];\n")
    end

    for e in edges(dfg.g)
        write(io, "$(dfg.g.labels[src(e)]) -- $(dfg.g.labels[dst(e)])\n")
    end
    write(io, "}\n")
end

function toDotFile(dfg::LightDFG, fileName::String="/tmp/dfg.dot")::Nothing
    open(fileName, "w") do fid
        savedot_attributes(fid, dfg)
    end
    return nothing
end

function toDot(dfg::LightDFG)::String
    m = PipeBuffer()
    savedot_attributes(m, dfg)
    data = take!(m)
    close(m)
    return String(data)
end


"""
    $SIGNATURES

Speciallized function available to only LightDFG at this time.

Example
```julia
using IncrementalInference

# canonical example graph as example
fg = generateCanonicalFG_Kaess()

@show path = findShortestPathDijkstra(fg, :x1, :x3)
@show isVariable.(path)
@show isFactor.(path)
```

DevNotes
- # TODO expand to other AbstractDFG entities.

Related

[findFactorsBetweenNaive](@ref), `LightGraphs.dijkstra_shortest_paths`
"""
function findShortestPathDijkstra(  dfg::LightDFG, 
                                    from::Symbol,
                                    to::Symbol  )
  #
  # LightDFG internally uses Integers 
  frI = dfg.g.labels[from]
  toI = dfg.g.labels[to]
  
  path = LightGraphs.dijkstra_shortest_paths(dfg.g.graph, [toI;])
  
  # assemble into the list
  dijkpath = Symbol[]
  # test for connectivity
  if path.dists[frI] < Inf
    cursor = frI
    push!(dijkpath, dfg.g.labels[cursor])
    # walk the path
    while cursor != toI
      cursor = path.parents[cursor]
      push!(dijkpath, dfg.g.labels[cursor])
    end
  end

  # return the list of symbols
  return dijkpath
end