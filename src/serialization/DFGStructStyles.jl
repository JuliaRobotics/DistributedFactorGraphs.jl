struct DFGJSONStyle <: JSON.JSONStyle end

StructUtils.structlike(::DFGJSONStyle, ::Type{Base.RefValue{Int}}) = false
StructUtils.lower(::DFGJSONStyle, x::Base.RefValue{Int}) = x[]
function StructUtils.lift(::DFGJSONStyle, ::Type{Base.RefValue{Int}}, x::Integer)
    return Ref{Int}(x), nothing
end

StructUtils.structlike(::DFGJSONStyle, ::Type{TimeDateZone}) = false
StructUtils.lower(::DFGJSONStyle, x::TimeDateZone) = string(x)
function StructUtils.lift(::DFGJSONStyle, ::Type{TimeDateZone}, x::AbstractString)
    return TimeDateZone(x), nothing
end
