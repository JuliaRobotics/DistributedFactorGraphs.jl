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
