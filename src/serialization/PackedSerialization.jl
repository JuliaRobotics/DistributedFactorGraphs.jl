function pack end
function unpack end

version(::Type{T}) where {T} = pkgversion(parentmodule(T))
# version(node) = node.version

# Type for storing packed type information
struct TypeMetadata
    pkg::Symbol #TODO use PkgId, maybe best to use flat structure with optional uuid, something like pkg[_name], pkg_uuid::Union{Nothing, UUID}
    name::Symbol
    version::Union{Nothing, VersionNumber}
end

function TypeMetadata(::Type{T}) where {T}
    return TypeMetadata(fullname(parentmodule(T))[1], nameof(T), version(T))
end

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

function pack_lower(x)
    px = Packed(x)
    d = StructUtils.make(OrderedDict{Symbol, Any}, px.packed)
    push!(d, :type => px.type)
    return d
end

unpack(x) = x
unpack(p::Packed) = unpack(p.packed)
pack(x) = x

#TODO add overwriteable layer
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

function resolveType(obj::DFG.JSON.Object)
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
    @packed

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

See also: [`Packed`](@ref), [`pack`](@ref), [`unpack`](@ref), [`resolvePackedType`](@ref)
"""
macro packed()
    return esc(:(lower = DFG.Packed, choosetype = DFG.resolvePackedType))
end
