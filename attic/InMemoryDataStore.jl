"""
    $(TYPEDEF)
Simple in-memory data store with a specified data type and a specified key type.
"""
struct InMemoryDataStore{T, E <: AbstractDataEntry} <: AbstractDataStore{T}
    data::Dict{Symbol, T}
    entries::Dict{Symbol, E}
end

"""
    $(SIGNATURES)
Create an in-memory store using a specific data type.
"""
function InMemoryDataStore{T, E}() where {T, E <: AbstractDataEntry}
    return InMemoryDataStore{T, E}(Dict{Symbol, T}(), Dict{Symbol, E}())
end

"""
    $(SIGNATURES)
Create an in-memory store using binary data (UInt8) as a type.
"""
function InMemoryDataStore()
    return InMemoryDataStore{Vector{UInt8}, GeneralDataEntry}()
end


##==============================================================================
## InMemoryDataStore CRUD
##==============================================================================
function getDataBlob(store::InMemoryDataStore{T, E}, entry::E)::Union{T, Nothing} where {T, E <: AbstractDataEntry}
    !haskey(store.data, entry.storeKey) && return nothing
    return store.data[entry.storeKey]
end

function addDataBlob!(store::InMemoryDataStore{T, E}, entry::E, data::T)::T where {T, E <: AbstractDataEntry}
    haskey(store.entries, entry.storeKey) && @warn "Key '$(entry.storeKey)' already exists in the data store, overwriting!"
    store.entries[entry.storeKey] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.storeKey] = data
end

function updateDataBlob!(store::InMemoryDataStore{T, E}, entry::E, data::T)::Union{T, Nothing} where {T, E <: AbstractDataEntry}
    !haskey(store.entries, entry.storeKey) && (@error "Key '$(entry.storeKey)' doesn't exist in the data store!"; return nothing)
    store.entries[entry.storeKey] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.storeKey] = data
end

function deleteDataBlob!(store::InMemoryDataStore{T, E}, entry::E)::T where {T, E <: AbstractDataEntry}
    data = getDataBlob(store, entry)
    data == nothing && return nothing
    delete!(store.data, entry.storeKey)
    delete!(store.entries, entry.storeKey)
    return data
end

function listDataBlobs(store::InMemoryDataStore{T, E})::Vector{E} where {T, E <: AbstractDataEntry}
    return collect(values(store.entries))
end
