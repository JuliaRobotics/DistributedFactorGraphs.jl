# can you have more than one small data entry?
# its aim is to reduce maintance by consolidating small data and data entries.
# should only support a dictionary of primitive types and N tuples of primitive types



struct SmallDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    folder::String
    hash::String #using bytes2hex or perhaps Vector{Uint8}?
    timestamp::DateTime

    smallData::Dict{Symbol, Any}#not any see NOTE

end

# NOTE small data types
# Integer
# AbstractFloat
# AbstractString
# NTuple(N, <:Integer)
# NTuple(N, <:AbstractFloat)
# NTuple(N, <:AbstractString)
