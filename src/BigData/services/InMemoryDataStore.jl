function getBigData(store::InMemoryDataStore{T, E}, entry::E)::Union{T, Nothing} where {T, E <: AbstractBigDataEntry}
    !haskey(store.data, entry.key) && return nothing
    return store.data[entry.key]
end

function addBigData!(store::InMemoryDataStore{T, E}, entry::E, data::T)::T where {T, E <: AbstractBigDataEntry}
    haskey(store.entries, entry.key) && @warn "Key '$(entry.key)' already exists in the data store, overwriting!"
    store.entries[entry.key] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.key] = data
end

function updateBigData!(store::InMemoryDataStore{T, E}, entry::E, data::T)::Union{T, Nothing} where {T, E <: AbstractBigDataEntry}
    !haskey(store.entries, entry.key) && (@error "Key '$(entry.key)' doesn't exist in the data store!"; return nothing)
    store.entries[entry.key] = entry
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return store.data[entry.key] = data
end

function deleteBigData!(store::InMemoryDataStore{T, E}, entry::E)::T where {T, E <: AbstractBigDataEntry}
    data = getBigData(store, entry)
    data == nothing && return nothing
    delete!(store.data, entry.key)
    delete!(store.entries, entry.key)
    return data
end

function listStoreEntries(store::InMemoryDataStore{T, E})::Vector{E} where {T, E <: AbstractBigDataEntry}
    return collect(values(store.entries))
end
