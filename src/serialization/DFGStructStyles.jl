struct DFGJSONStyle <: JSON.JSONStyle end

StructUtils.structlike(::DFGJSONStyle, ::Type{Base.RefValue{Int}}) = false
StructUtils.lower(::DFGJSONStyle, x::Base.RefValue{Int}) = x[]
StructUtils.lift(::DFGJSONStyle, ::Type{Base.RefValue{Int}}, x) = Ref(x), nothing

StructUtils.structlike(::DFGJSONStyle, ::Type{TimeDateZone}) = false
StructUtils.lower(::DFGJSONStyle, x::TimeDateZone) = string(x)
StructUtils.lift(::DFGJSONStyle, ::Type{TimeDateZone}, x) = TimeDateZone(x), nothing
