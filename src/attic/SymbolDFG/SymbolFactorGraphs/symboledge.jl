import Base: Pair, Tuple, show, ==
import LightGraphs: AbstractEdge, src, dst, reverse

# abstract type AbstractSymbolEdge{Symbol} <: AbstractEdge{Symbol} end

struct SymbolEdge{Symbol} <: AbstractEdge{Symbol}
    src::Symbol
    dst::Symbol
end

SymbolEdge(t::Tuple) = SymbolEdge(t[1], t[2])
SymbolEdge(p::Pair) = SymbolEdge(p.first, p.second)

e = SymbolEdge(:x1,:x2)
e = SymbolEdge((:x1,:x2))

eltype(e::SymbolEdge) = Symbol

# Accessors
src(e::SymbolEdge) = e.src
dst(e::SymbolEdge) = e.dst

# I/O
show(io::IO, e::SymbolEdge) = print(io, "Edge $(e.src) => $(e.dst)")

# Conversions
Pair(e::SymbolEdge) = Pair(src(e), dst(e))
Tuple(e::SymbolEdge) = (src(e), dst(e))

SymbolEdge(e::SymbolEdge) = SimpleEdge(e.src, e.dst)

# Convenience functions
reverse(e::SymbolEdge) = SymbolEdge(dst(e), src(e))
==(e1::SymbolEdge, e2::SymbolEdge) = (src(e1) == src(e2) && dst(e1) == dst(e2))
