"""
    DFGJSONStyle <: JSON.JSONStyle

Custom JSON serialization style used throughout DFG for `JSON.json` / `JSON.parse`.

This style adds handling for types that don't round-trip through plain JSON:
`Complex`, `SArray`, `ArrayPartition`, `RefValue{Int}`, `TimeDateZone`, etc.

# Polymorphic abstract types — `pack`/`unpack`

Abstract types like `AbstractBlobprovider` and `AbstractObservation` are serialized through the
[`Packed`](@ref) envelope.  Each concrete subtype can define a lightweight
"packed" companion struct and overload [`pack`](@ref) / [`unpack`](@ref).
The default `pack(x) = x` works for structs whose fields are all plain data.

When a type contains **non-serializable fields** (clients, connections, caches),
define a packed companion:

```julia
struct PackedMytype
    label::Symbol
end
DFG.pack(s::Mytype) = PackedMytype(s.label)
DFG.unpack(p::PackedMytype) = Mytype(reconnect_client(), p.label)
```

JSON emitted with `style = DFGJSONStyle()` embeds a `"type"` header
so the deserializer can locate the packed type and call `unpack`.

# Usage

```julia
json_str = JSON.json(value; style = DFGJSONStyle())
value    = JSON.parse(json_str, T; style = DFGJSONStyle())
```

See also: [`pack`](@ref), [`unpack`](@ref), [`Packed`](@ref), [`@packed`](@ref)
"""
struct DFGJSONStyle <: JSON.JSONStyle end

# Base.RefValue{Int} serialization
StructUtils.structlike(::DFGJSONStyle, ::Type{Base.RefValue{Int}}) = false
StructUtils.lower(::DFGJSONStyle, x::Base.RefValue{Int}) = x[]
function StructUtils.lift(::DFGJSONStyle, ::Type{Base.RefValue{Int}}, x::Integer)
    return Ref{Int}(x), nothing
end

# TimeDateZone serialization
StructUtils.structlike(::DFGJSONStyle, ::Type{TimeDateZone}) = false
StructUtils.lower(::DFGJSONStyle, x::TimeDateZone) = string(x)
function StructUtils.lift(::DFGJSONStyle, ::Type{TimeDateZone}, x::AbstractString)
    return TimeDateZone(x), nothing
end

#TODO StructUtils v2.7 adds support for StaticArrays, update, test, and remove these overloads if they work as expected
# SArray serialization overloads
StructUtils.lower(::DFGJSONStyle, x::SArray) = x

function StructUtils.makearray(
    style::DFGJSONStyle,
    ::Type{<:SArray{S, T}},
    source,
) where {S, T}
    v, st = StructUtils.makearray(style, Vector{T}, source)
    return SArray{S, T}(v), st
end

# ArrayPartition serialization overloads
StructUtils.arraylike(::DFGJSONStyle, ::Type{<:ArrayPartition}) = false
StructUtils.structlike(::DFGJSONStyle, ::Type{<:ArrayPartition}) = false

StructUtils.lower(::DFGJSONStyle, ap::ArrayPartition) = ap.x

function StructUtils.lift(
    ::DFGJSONStyle,
    ::Type{AP},
    source::Vector,
) where {T, S, AP <: ArrayPartition{T, S}}
    ptypes = fieldtypes(S)
    parts = ntuple(length(ptypes)) do i
        return ptypes[i](source[i])
    end
    return AP(parts), nothing
end

# Complex Serialization
StructUtils.structlike(::DFGJSONStyle, ::Type{<:Complex}) = false
StructUtils.lower(::DFGJSONStyle, x::Complex) = (real(x), imag(x))
function StructUtils.lift(::DFGJSONStyle, ::Type{T}, x::JSON.LazyValue) where {T <: Complex}
    return T(x[1][], x[2][]), nothing
end

# Above does not work for Array{ComplexF64, 0}
StructUtils.lower(::DFGJSONStyle, x::AbstractArray{<:Complex, 0}) = (real(x), imag(x))
function StructUtils.lift(
    ::DFGJSONStyle,
    ::Type{A},
    x::JSON.LazyValue,
) where {A <: AbstractArray{T, 0}} where {T <: Complex}
    m = A(undef)
    m[] = (T(x[1][], x[2][]))
    return m, nothing
end

# if serialized as an Struct
# function StructUtils.lift(::DFGJSONStyle, ::Type{T}, x::JSON.LazyValue) where T <: Complex 
#     return T(x.re[], x.im[]), nothing
# end
