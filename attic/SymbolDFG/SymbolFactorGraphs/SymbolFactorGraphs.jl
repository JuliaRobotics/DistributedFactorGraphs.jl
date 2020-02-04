module SymbolFactorGraphs

using LightGraphs

import LightGraphs: nv, ne, vertices, is_directed, has_edge, edges, inneighbors, outneighbors, rem_vertex!, neighbors, connected_components

import ...DistributedFactorGraphs: DFGNode

export
    SymbolFactorGraph,
    SymbolEdge
    # is_directed,
    # has_edge,
    # rem_vertex!,
    # addVariable!,
    # addFactor!

# import DistributedFactorGraphs: DFGNode
# const AbstractNodeType = DFGNode
import DistributedFactorGraphs: AbstractDFGVariable, AbstractDFGFactor
const AbstractVariableType = AbstractDFGVariable
const AbstractFactorType = AbstractDFGFactor

import Base: zero
const UnionNothingSymbol = Union{Nothing, Symbol}
zero(UnionNothingSymbol) = nothing


include("symboledge.jl")


"""
    SymbolFactorGraph{V, F}

A type representing an undirected bipartite factor graph based on `label::Symbol`.
"""
mutable struct SymbolFactorGraph{V <: AbstractVariableType, F <: AbstractFactorType} <: AbstractGraph{UnionNothingSymbol}
    ne::Int
    fadjdict::Dict{Symbol,Vector{Symbol}} # [variable src id]: (dst, dst, dst)
    variables::Dict{Symbol,V}
    factors::Dict{Symbol,F}
end

################################################################################
# overwrites from SimpleGraphs.jl

nv(g::SymbolFactorGraph) = length(g.fadjdict)
ne(g::SymbolFactorGraph) = g.ne

vertices(g::SymbolFactorGraph) = keys(g.fadjdict)

inneighbors(g::SymbolFactorGraph, v::Symbol) = (badj(g, v))

outneighbors(g::SymbolFactorGraph, v::Symbol) = (fadj(g, v))

neighbors(g::SymbolFactorGraph, v::Symbol) = (fadj(g, v))

"""
    is_directed(g)

Return `true` if `g` is a directed graph.
"""
is_directed(::Type{SymbolFactorGraph{V,F}}) where {V,F} = false

is_directed(::Type{SymbolFactorGraph}) = false

is_directed(g::SymbolFactorGraph) = false


##############################################################################


add_edge!(g::SymbolFactorGraph, x, y) = add_edge!(g, edgetype(g)(x, y))
eltype(x::SymbolFactorGraph) = Symbol

fadj(g::SymbolFactorGraph) = g.fadjdict
fadj(g::SymbolFactorGraph, v::Symbol) = g.fadjdict[v]

edgetype(::SymbolFactorGraph) = SymbolEdge

# eltype(x::SymbolFactorGraph{V,F}) where {T,V,F} = T

# Graph{UInt8}(6), Graph{Int16}(7), Graph{UInt8}()
"""
    SymbolFactorGraph{V,F}(nv=0, nf=0)

Construct an empty `SymbolFactorGraph{V,F}` with `nv,nf` varaibles `sizehint!`, factors and 0 edges.
If not specified, the element type `T` is the type of `nv,nf`.

## Examples
```jldoctest
# SymbolFactorGraph{AbstractVariableType,AbstractFactorType}()
```
"""
function SymbolFactorGraph{V, F}(nv::Int=100, nf::Int=100) where {V <: AbstractVariableType, F <: AbstractFactorType}
    fadjdict = Dict{Symbol,Vector{Symbol}}()
        sizehint!(fadjdict, nv + nf)
    variables = Dict{Symbol,V}()
        sizehint!(variables, nv)
    factors = Dict{Symbol,F}()
        sizehint!(factors, nf)
    return SymbolFactorGraph{V, F}(0, fadjdict, variables, factors)
end



# SymbolFactorGraph{V, F}() where {V<:AbstractVariableType,F<:AbstractFactorType}= SymbolFactorGraph{Int, V, F}()

# SimpleGraph(UInt8)
"""
    SymbolFactorGraph(::Type{T},::Type{V}, ::Type{F})

Construct an empty `SymbolFactorGraph{T}` with 0 vertices and 0 edges.

## Examples
```jldoctest
julia> SymbolFactorGraph(Int,AbstractVariableType, AbstractFactorType)
SymbolFactorGraph{Int64,AbstractVariableType,AbstractFactorType}(0, 0, Union{Nothing, FGNode{AbstractVariableType,Int64}}[], Union{Nothing, FGNode{AbstractFactorType,Int64}}[])
```
"""
# SymbolFactorGraph(::Type{T}, ::Type{V}, ::Type{F}) where {T <: Integer, V<:AbstractVariableType,F<:AbstractFactorType} = SymbolFactorGraph{T, V, F}(zero(T), zero(T))

# SymbolFactorGraph(Int,AbstractVariableType, AbstractFactorType)


#= #############################################################################
# SimpleGraph of a SimpleGraph
"""
    SimpleGraph{T}(g::SimpleGraph)

Construct a copy of g.
If the element type `T` is specified, the vertices of `g` are converted to this type.
Otherwise the element type is the same as for `g`.

## Examples
```jldoctest
julia> g = complete_graph(5)
julia> SimpleGraph{UInt8}(g)
{5, 10} undirected simple UInt8 graph
```
"""
SimpleGraph(g::SimpleGraph) = copy(g)
=#




"""
    badj(g::SymbolFactorGraph[, v::Symbol])

Return the backwards adjacency list of a graph. If `v` is specified,
return only the adjacency list for that vertex.

"""
badj(g::SymbolFactorGraph) = fadj(g)
badj(g::SymbolFactorGraph, v::Symbol) = fadj(g, v)


"""
    adj(g[, v])

Return the adjacency list of a graph. If `v` is specified, return only the
adjacency list for that vertex.

"""
adj(g::SymbolFactorGraph) = fadj(g)
adj(g::SymbolFactorGraph, v::Symbol) = fadj(g, v)

#TODO
#=
# copy(g::SymbolFactorGraph) =  SymbolFactorGraph(g.ne, deepcopy_adjlist(g.fadjlist))

==(g::SimpleGraph, h::SimpleGraph) =
vertices(g) == vertices(h) &&
ne(g) == ne(h) &&
fadj(g) == fadj(h)
=#




function has_edge(g::SymbolFactorGraph, s::Symbol, d::Symbol)
    verts = vertices(g)
    (s in verts && d in verts) || return false  # edge out of bounds
    @inbounds list_s = g.fadjdict[s]
    @inbounds list_d = g.fadjdict[d]
    if length(list_s) > length(list_d)
        d = s
        list_s = list_d
    end
    # return insorted(d, list_s)
    return in(d, list_s)
end

function has_edge(g::SymbolFactorGraph, e::SymbolEdge)
    s, d = Symbol.(Tuple(e))
    return has_edge(g, s, d)
end

"""
    add_edge!(g, e)

Add an edge `e` to graph `g`. Return `true` if edge was added successfully,
otherwise return `false`.

# Examples
```jldoctest
julia> using LightGraphs

julia> g = SimpleGraph(2);

julia> add_edge!(g, 1, 2)
true

julia> add_edge!(g, 2, 3)
false
```
"""
function add_edge!(g::SymbolFactorGraph, e::SymbolEdge)
    s, d = Tuple(e)
    s == d && error("Self loops not allowed")

    verts = vertices(g)
    (s in verts && d in verts) || return false  # edge out of bounds
    @inbounds list = g.fadjdict[s]
    index = searchsortedfirst(list, d)
    @inbounds (index <= length(list) && list[index] == d) && return false  # edge already in graph
    insert!(list, index, d)

    g.ne += 1

    @inbounds list = g.fadjdict[d]
    index = searchsortedfirst(list, s)
    insert!(list, index, s)
    return true  # edge successfully added
end

"""
    rem_edge!(g, e)

Remove an edge `e` from graph `g`. Return `true` if edge was removed successfully,
otherwise return `false`.

### Implementation Notes
If `rem_edge!` returns `false`, the graph may be in an indeterminate state, as
there are multiple points where the function can exit with `false`.

# Examples
```jldoctest
julia> using LightGraphs

julia> g = SimpleGraph(2);

julia> add_edge!(g, 1, 2);

julia> rem_edge!(g, 1, 2)
true

julia> rem_edge!(g, 1, 2)
false
```
"""
function rem_edge!(g::SymbolFactorGraph, e::SymbolEdge)
    s, d = Tuple(e)
    verts = vertices(g)
    (s in verts && d in verts) || return false  # edge out of bounds
    @inbounds list = g.fadjdict[s]
    index = searchsortedfirst(list, d)
    @inbounds (index <= length(list) && list[index] == d) || return false  # edge not in graph
    deleteat!(list, index)

    g.ne -= 1
    s == d && return true  # selfloop

    @inbounds list = g.fadjdict[d]
    index = searchsortedfirst(list, s)
    deleteat!(list, index)
    return true  # edge successfully removed
end


"""
    add_vertex!(g)

Add a new vertex to the graph `g`. Return `true` if addition was successful.

# Examples
```jldoctest
julia> using LightGraphs

julia> g = SimpleGraph(Int8(typemax(Int8) - 1))
{126, 0} undirected simple Int8 graph

julia> add_vertex!(g)
true

julia> add_vertex!(g)
false
```
"""
# function add_vertex!(g::SymbolFactorGraph, node::) where T
#     (nv(g) + one(T) <= nv(g)) && return false       # test for overflow
#     push!(g.fadjlist, Vector{T}())
#     return true
# end



function addVariable!(g::SymbolFactorGraph{V, F}, variable::V) where {V, F}
    (nv(g) + one(Int) <= nv(g)) && return false       # test for overflow
    # !isa(node,V) && (@warn "not a variable type"; return false)
    label = variable.label

    haskey(g.fadjdict, label) && (@error "Label already in fg"; return false) #TODO debug error or exception?
    # haskey(g.labelIndex, label) && error("Label already in fg")

    push!(g.fadjdict, label=>Symbol[])

    push!(g.variables, label=>variable)

    return true
end

function addFactor!(g::SymbolFactorGraph{V, F}, variableLabels::Vector{Symbol}, factor::F)::Bool where {V, F}

    haskey(g.fadjdict, factor.label) && (@error "Label $(factor.label) already in fg"; return false)

    for label in variableLabels
        !haskey(g.fadjdict, label) && (@error "Variable '$(label)' not found in graph when creating Factor '$(factor.label)'"; return false) #TODO debug error or exception?
    end

    (nv(g) + one(Int) <= nv(g)) && return false       # test for overflow
    # !isa(node,V) && (@warn "not a variable type"; return false)

    # factor._variableOrderSymbols = copy(variableLabels)

    push!(g.fadjdict, factor.label=>Symbol[])

    push!(g.factors, factor.label=>factor)

    # add the edges
    for label in variableLabels
        add_edge!(g, label, factor.label) || return false
    end

    return true
end


function edges(g::SymbolFactorGraph)

    fadjdict = fadj(g)
    n = nv(g)

    edges = SymbolEdge[]
    sizehint!(edges, n)

    for p = pairs(fadjdict)
        for l = p.second
            push!(edges,SymbolEdge(p.first=>l))
        end
    end

    edges


end


"""
    rem_vertex!(g, v)

Remove the vertex `v` from graph `g`. Return `false` if removal fails
(e.g., if vertex is not in the graph); `true` otherwise.

# Examples
```jldoctest
julia> using LightGraphs

julia> g = SimpleGraph(2);

julia> rem_vertex!(g, 2)
true

julia> rem_vertex!(g, 2)
false
```
"""
function rem_vertex!(g::SymbolFactorGraph, v::Symbol)
    v in vertices(g) || return false
    n = nv(g)

    # TODO behoort nie moontelik te wees nie...
    # self_loop_n = false  # true if n is self-looped (see #820)

    # remove the in_edges from v
    srcs = copy(inneighbors(g, v))
    @inbounds for s in srcs
        rem_edge!(g, edgetype(g)(s, v))
    end

    # # remove the in_edges from the last vertex
    # neigs = copy(inneighbors(g, n))
    # @inbounds for s in neigs
    #     rem_edge!(g, edgetype(g)(s, n))
    # end
    # if v != n
    #     # add the edges from n back to v
    #     @inbounds for s in neigs
    #         if s != n  # don't add an edge to the last vertex - see #820.
    #             add_edge!(g, edgetype(g)(s, v))
    #         else
    #             self_loop_n = true
    #         end
    #     end
    # end

    # if self_loop_n
    #     add_edge!(g, edgetype(g)(v, v))
    # end
    delete!(g.fadjdict, v)
    delete!(g.variables, v)
    delete!(g.factors, v)


    return true
end

function _connected_components!(label::Dict{Symbol, T}, g::SymbolFactorGraph) where T <: UnionNothingSymbol
    nvg = nv(g)

    for u in vertices(g)
        label[u] != nothing && continue
        label[u] = u
        Q = Vector{T}()
        push!(Q, u)
        while !isempty(Q)
            src = popfirst!(Q)
            for vertex in neighbors(g, src)
                if label[vertex] == zero(T)
                    push!(Q, vertex)
                    label[vertex] = u
                end
            end
        end
    end
    return label
end

function _components(labels::Dict{Symbol, UnionNothingSymbol})

    d = Dict{Symbol,Int}()
    c = Vector{Vector{Symbol}}()
    i = 1 #one(T)
    for (v, l) in enumerate(labels)
        index = get!(d, l.second, i)
        if length(c) >= index
            push!(c[index], l.first)
        else
            push!(c, [l.first])
            i += 1
        end
    end
    return c, d
end

function connected_components(g::SymbolFactorGraph)
    # label = zeros(T, nv(g))
    label = Dict{Symbol, UnionNothingSymbol}(l=>nothing for l in vertices(g))
    _connected_components!(label, g)
    c, d = _components(label)
    return c
end

end
