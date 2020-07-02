"""
    $(TYPEDEF)
Simple in-memory data store with a specified data type and a specified key type.
"""
struct InMemoryDataStore{T, E <: AbstractBigDataEntry} <: AbstractDataStore{T}
    data::Dict{Symbol, T}
    entries::Dict{Symbol, E}
end

"""
    $(SIGNATURES)
Create an in-memory store using a specific data type.
"""
function InMemoryDataStore{T, E}() where {T, E <: AbstractBigDataEntry}
    return InMemoryDataStore{T, E}(Dict{Symbol, T}(), Dict{Symbol, E}())
end

"""
    $(SIGNATURES)
Create an in-memory store using binary data (UInt8) as a type.
"""
function InMemoryDataStore()
    return InMemoryDataStore{Vector{UInt8}, GeneralDataEntry}()
end
