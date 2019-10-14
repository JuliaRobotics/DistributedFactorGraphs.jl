module FactorGraphs
using LightGraphs

import Base:
    eltype, show, ==, Pair,
    Tuple, copy, length, size,
    issubset, zero, getindex
# import Random:
#     randstring, seed!

import LightGraphs:
    AbstractGraph, src, dst, edgetype, nv,
    ne, vertices, edges, is_directed,
    add_vertex!, add_edge!, rem_vertex!, rem_edge!,
    has_vertex, has_edge, inneighbors, outneighbors,
    weights, indegree, outdegree, degree,
    induced_subgraph,
    loadgraph, savegraph, AbstractGraphFormat,
    reverse

import LightGraphs.SimpleGraphs:
    AbstractSimpleGraph, SimpleGraph, SimpleDiGraph,
    SimpleEdge, fadj, badj

export
    FactorGraph,
    # addVariable!,
    # addFactor!,
    LightBayesGraph,
    filter_edges,
    filter_vertices,
    reverse

# import DistributedFactorGraphs: DFGNode
# const AbstractNodeType = DFGNode
import DistributedFactorGraphs: AbstractDFGVariable, AbstractDFGFactor
const AbstractVariableType = AbstractDFGVariable
const AbstractFactorType = AbstractDFGFactor

include("BiMaps.jl")

struct FactorGraph{T <: Integer,V <: AbstractVariableType, F <: AbstractFactorType} <: AbstractGraph{T}
    graph::SimpleGraph{T}
    labels::BiDictMap{T}
    variables::Dict{Symbol,V}
    factors::Dict{Symbol,F}
end

function FactorGraph{T, V, F}(nv::Int=100, nf::Int=100) where {T <: Integer, V <: AbstractVariableType, F <: AbstractFactorType}
    fadjlist = Vector{Vector{T}}()
        sizehint!(fadjlist, nv + nf)
    g = SimpleGraph{T}(0, fadjlist)
    labels = BiDictMap{T}(sizehint=nv+nf)
    variables = Dict{Symbol,V}()
        sizehint!(variables, nv)
    factors = Dict{Symbol,F}()
        sizehint!(factors, nf)
    return FactorGraph{T, V, F}(g, labels, variables, factors)
end

# fg = FactorGraph{Int, AbstractVariableType, AbstractFactorType}()

FactorGraph() = FactorGraph{Int, AbstractVariableType, AbstractFactorType}()
FactorGraph{V,F}() where {V <: AbstractVariableType, F <: AbstractFactorType} = FactorGraph{Int, V, F}()


function show(io::IO, g::FactorGraph)
    dir = is_directed(g) ? "directed" : "undirected"
    print(io, "{$(nv(g)), $(ne(g))} $dir $(eltype(g)) $(typeof(g))")
end

@inline fadj(g::FactorGraph, x...) = fadj(g.graph, x...)
@inline badj(g::FactorGraph, x...) = badj(g.graph, x...)


eltype(g::FactorGraph) = eltype(g.graph)
edgetype(g::FactorGraph) = edgetype(g.graph)
nv(g::FactorGraph) = nv(g.graph)
vertices(g::FactorGraph) = vertices(g.graph)

ne(g::FactorGraph) = ne(g.graph)
edges(g::FactorGraph) = edges(g.graph)

has_vertex(g::FactorGraph, x...) = has_vertex(g.graph, x...)
@inline has_edge(g::FactorGraph, x...) = has_edge(g.graph, x...)

inneighbors(g::FactorGraph, v::Integer) = inneighbors(g.graph, v)
outneighbors(g::FactorGraph, v::Integer) = fadj(g.graph, v)

is_directed(::Type{FactorGraph}) = false
is_directed(::Type{FactorGraph{T,V,F}}) where {T,V,F} = false
is_directed(g::FactorGraph) = false

zero(g::FactorGraph{T,V,F}) where {T,V,F} = FactorGraph{T,V,F}(0,0)

# TODO issubset(g::T, h::T) where T <: FactorGraph = issubset(g.graph, h.graph)

"""
    add_edge!(g, u, v)
    Add an edge `(u, v)` to FactorGraph `g`.
    return true if the edge has been added, false otherwise
"""
@inline add_edge!(g::FactorGraph, x...) = add_edge!(g.graph, x...)

@inline rem_edge!(g::FactorGraph, x...) = rem_edge!(g.graph, x...)


function addVariable!(g::FactorGraph{T, V, F}, variable::V) where {T, V, F}

    label = variable.label

    haskey(g.labels, label) && (@error "Label already in fg"; return false) #TODO debug error or exception?

    add_vertex!(g.graph) || return false

    g.labels[nv(g.graph)] = label

    push!(g.variables, label=>variable)

    return true
end

function addFactor!(g::FactorGraph{T, V, F}, variableLabels::Vector{Symbol}, factor::F)::Bool where {T, V, F}

    haskey(g.labels, factor.label) && (@error "Label $(factor.label) already in fg"; return false)

    for vlabel in variableLabels
        !haskey(g.labels, vlabel) && (@error "Variable '$(vlabel)' not found in graph when creating Factor '$(factor.label)'"; return false) #TODO debug error or exception?
    end

    add_vertex!(g.graph) || return false

    g.labels[nv(g.graph)] = factor.label

    push!(g.factors, factor.label=>factor)

    # add the edges
    for vlabel in variableLabels
        add_edge!(g, g.labels[vlabel], nv(g.graph)) || return false
    end

    return true
end



function rem_vertex!(g::FactorGraph{T,V,F}, v::Integer) where {T,V,F}
    v in vertices(g) || return false
    lastv = nv(g)

    rem_vertex!(g.graph, v) || return false

    label = g.labels[v]
    delete!(g.variables, label)
    delete!(g.factors, label)

    if v != lastv
        g.labels[v] = g.labels[lastv] #lastSym
    else
        delete!(g.labels, v)
    end

    return true
end



end
