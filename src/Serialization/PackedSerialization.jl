"""
    pack(x) -> packed_x

Convert `x` into a serialization-friendly "packed" form.

The default method is the identity (`pack(x) = x`), meaning types whose fields
are all plain data (numbers, strings, arrays, nested structs of the same) need
no special treatment — they serialize as-is through `StructUtils.jl`.

Overload `pack` when a type contains **non-serializable fields** such as network
connections, open file handles, live caches, or opaque foreign objects.
The pattern is:

1. Define a "packed" companion struct holding only the serializable subset.
2. Overload `pack` to project the live type onto the packed struct.
3. Overload [`unpack`](@ref) to reconstruct the live type from the packed struct.

The `Packed` wrapper calls `pack` automatically during serialization, embedding a
`TypeMetadata` header so the deserializer can locate the packed type.

# Example

```julia
# Live type — `client` is an HTTP connection, not serializable
struct MyRemoteStore <: DFG.AbstractBlobprovider
    client::HTTPClient
    label::Symbol
end

# Packed form — only the serializable fields
struct PackedMyRemoteStore
    label::Symbol
end

DFG.pack(s::MyRemoteStore) = PackedMyRemoteStore(s.label)
DFG.unpack(p::PackedMyRemoteStore) = MyRemoteStore(find_active_client(), p.label)
```

The JSON output will contain `"type": {"pkg": "MyPkg", "name": "PackedMyRemoteStore", ...}`
so the deserializer resolves the packed type, calls `StructUtils.make(PackedMyRemoteStore, json)`,
and then calls `unpack(::PackedMyRemoteStore)` to produce the live `MyRemoteStore`.

See also: [`unpack`](@ref), [`Packed`](@ref), [`TypeMetadata`](@ref), [`DFGJSONStyle`](@ref)
"""
function pack end

"""
    unpack(packed_x) -> x

Reconstruct a live object from its packed (serialization-safe) form.

The default method is the identity (`unpack(x) = x`).  Overload it for each
packed companion type created alongside a [`pack`](@ref) overload.

During deserialization the pipeline is:

    JSON bytes  →  StructUtils.make(PackedT, data)  →  unpack(::PackedT)  →  live T

`unpack` is the place to reconnect non-serializable resources (clients,
file handles, caches) that were stripped by `pack`.

# Example

```julia
DFG.unpack(p::PackedMyRemoteStore) = MyRemoteStore(find_active_client(), p.label)
```

See also: [`pack`](@ref), [`Packed`](@ref)
"""
function unpack end

version(::Type{T}) where {T} = pkgversion(parentmodule(T))
# version(node) = node.version

"""
    TypeMetadata(pkg, name, version)
    TypeMetadata(::Type{T})

Metadata header embedded in every [`Packed`](@ref) envelope.

Stores the top-level package name, the struct name, and the package version so
the deserializer can resolve the correct concrete type at load time via
[`resolvePackedType`](@ref).

Generally you never construct this manually — `Packed(x)` does it for you.
"""
struct TypeMetadata
    pkg::Symbol #TODO use PkgId, maybe best to use flat structure with optional uuid, something like pkg[_name], pkg_uuid::Union{Nothing, UUID}
    name::Symbol
    version::Union{Nothing, VersionNumber}
end

function TypeMetadata(::Type{T}) where {T}
    return TypeMetadata(fullname(parentmodule(T))[1], nameof(T), version(T))
end

"""
    Packed{T}(type::TypeMetadata, packed::T)
    Packed(x)

Serialization envelope that pairs a value with its [`TypeMetadata`](@ref).

Calling `Packed(x)` runs the full pipeline:

1. `packed_x = pack(x)` — convert `x` to its serialization-safe form.
2. `TypeMetadata(typeof(packed_x))` — snapshot the packed type's identity.
3. Bundle both into `Packed{typeof(packed_x)}(metadata, packed_x)`.

During **serialization** (`lower`): the packed struct's fields are flattened
into an `OrderedDict` alongside a `:type` key holding the metadata.

During **deserialization** (`lift`): `resolvePackedType` reads the `:type` key
to identify the packed type, `StructUtils.make` builds it, and [`unpack`](@ref)
reconstructs the original live type.

See also: [`pack`](@ref), [`unpack`](@ref), [`TypeMetadata`](@ref), [`resolvePackedType`](@ref)
"""
StructUtils.@nonstruct struct Packed{T}
    type::TypeMetadata
    packed::T
end

function Packed(x)
    packedx = pack(x)
    return Packed(TypeMetadata(typeof(packedx)), packedx)
end

function StructUtils.lower(x::Packed)
    d = StructUtils.make(OrderedDict{Symbol, Any}, x.packed)
    push!(d, :type => x.type)
    return d
end

function StructUtils.lift(::Type{<:Packed{T}}, x) where {T}
    r = unpack(StructUtils.make(T, x))
    return r
end

"""
    pack_lower(x)

Convenience: `pack` then `lower` in one call.  Equivalent to `StructUtils.lower(Packed(x))`.
"""
function pack_lower(x)
    px = Packed(x)
    d = StructUtils.make(OrderedDict{Symbol, Any}, px.packed)
    push!(d, :type => px.type)
    return d
end

unpack(x) = x
unpack(p::Packed) = unpack(p.packed)
pack(x) = x

#TODO add overwriteable layer to resolvePackedType
"""
    resolvePackedType(json_obj) -> Type{Packed{T}}

Read the `type` metadata from a JSON object and resolve the corresponding
`Packed{T}` type.  Called automatically by the `@choosetype` machinery during
deserialization of abstract types (e.g. `AbstractBlobprovider`, `Packed`).

The resolver requires the owning module to be loaded in `Main`.
"""
function resolvePackedType(lazyobj::JSON.LazyValue)
    type = JSON.parse(lazyobj.type)
    # TODO we can use Base.PkgId to not require modules to be available in Main
    pkg = Base.require(Main, Symbol(type.pkg))
    if !isdefined(Main, Symbol(type.pkg))
        throw(SerializationError("Module $(pkg) is available, but not loaded in `Main`."))
    end
    return Packed{getfield(pkg, Symbol(type.name))}
end

function resolvePackedType(obj::JSON.Object)
    type = obj.type
    pkg = Base.require(Main, Symbol(type.pkg))
    if !isdefined(Main, Symbol(type.pkg))
        throw(SerializationError("Module $(pkg) is available, but not loaded in `Main`."))
    end
    return Packed{getfield(pkg, Symbol(type.name))}
end

function resolveType(obj::JSON.Object)
    type = obj.type
    pkg = Base.require(Main, Symbol(type.pkg))
    if !isdefined(Main, Symbol(type.pkg))
        throw(SerializationError("Module $(pkg) is available, but not loaded in `Main`."))
    end
    return getfield(pkg, Symbol(type.name))
end

@choosetype Packed resolvePackedType

# Stash optional TypeMetadata expansion function.
# function expandTypeMetadata(;kwargs...)
#     md = StructUtils.make(OrderedDict{Symbol, Any}, TypeMetadata(FactorDFG))
#     push!(md, kwargs...)
#     return md
# end 

"""
    DFG.@packed

Macro annotation for DFG serialization metadata on struct fields.
Expands to `(lower = DFG.Packed, choosetype = DFG.resolvePackedType)` for use with 
StructTypes.jl field annotations.

Used to mark belief fields in factor types for serialization through 
the DFG packing system. The `lower` function converts the field to a `Packed` wrapper 
during serialization, and `choosetype` resolves the correct type during deserialization.

# Usage
Use with the `&` operator in `@kwarg` or `@tags` struct definitions:

```julia
@kwarg struct Pose2Point2Range{T} <: AbstractRelativeObservation
    Z::T & DFG.@packed
    partial::Tuple{Int, Int} = (1, 2)
end
```

This is equivalent to writing:
```julia
@kwarg struct Pose2Point2Range{T} <: AbstractRelativeObservation
    Z::T & (lower = DFG.Packed, choosetype = DFG.resolvePackedType)
    partial::Tuple{Int, Int} = (1, 2)
end
```

See also: `Packed`, `pack`, `unpack`, `resolvePackedType`
"""
macro packed()
    return esc(:(lower = DFG.Packed, choosetype = DFG.resolvePackedType))
end
