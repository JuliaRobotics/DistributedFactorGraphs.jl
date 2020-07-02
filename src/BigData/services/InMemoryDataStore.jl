##==============================================================================
## InMemoryDataStore CRUD
##==============================================================================
function getDataBlob(store::InMemoryDataStore{T, E}, entry::E)::Union{T, Nothing} where {T, E <: AbstractBigDataEntry}
    !haskey(store.data, entry.storeKey) && return nothing
    return store.data[entry.storeKey]
end

function addDataBlob!(store::InMemoryDataStore{T, E}, entry::E, data::T)::T where {T, E <: AbstractBigDataEntry}
    haskey(store.entries, entry.storeKey) && @warn "Key '$(entry.storeKey)' already exists in the data store, overwriting!"
    store.entries[entry.storeKey] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.storeKey] = data
end

function updateDataBlob!(store::InMemoryDataStore{T, E}, entry::E, data::T)::Union{T, Nothing} where {T, E <: AbstractBigDataEntry}
    !haskey(store.entries, entry.storeKey) && (@error "Key '$(entry.storeKey)' doesn't exist in the data store!"; return nothing)
    store.entries[entry.storeKey] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.storeKey] = data
end

function deleteDataBlob!(store::InMemoryDataStore{T, E}, entry::E)::T where {T, E <: AbstractBigDataEntry}
    data = getDataBlob(store, entry)
    data == nothing && return nothing
    delete!(store.data, entry.storeKey)
    delete!(store.entries, entry.storeKey)
    return data
end

function listDataBlobs(store::InMemoryDataStore{T, E})::Vector{E} where {T, E <: AbstractBigDataEntry}
    return collect(values(store.entries))
end
