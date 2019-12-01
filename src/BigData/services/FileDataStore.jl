searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filename(store::FileDataStore, entry::E) where E <: AbstractBigDataEntry = "$(store.folder)/$(entry.key).dat"
function readentry(store::FileDataStore, entry::E) where E <: AbstractBigDataEntry
    open(filename(store, entry)) do f
        return read(f)
    end
end
function writeentry(store::FileDataStore, entry::E, data::Vector{UInt8}) where E <: AbstractBigDataEntry
    open(filename(store, entry), "w") do f
        write(f, data)
    end
end

function getBigData(store::FileDataStore, entry::E)::Union{Vector{UInt8}, Nothing} where {E <: AbstractBigDataEntry}
    length(searchdir(store.folder, String(entry.key))) !=1 && (@warn "Could not find unique file for key '$(entry.key)'."; return nothing)
    return readentry(store, entry)
end

function addBigData!(store::FileDataStore, entry::E, data::Vector{UInt8})::Vector{UInt8} where {E <: AbstractBigDataEntry}
    length(searchdir(store.folder, String(entry.key))) !=0 && @warn "Key '$(entry.key)' already exists, overwriting!."
    writeentry(store, entry, data)
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return getBigData(store, entry)
end

function updateBigData!(store::FileDataStore, entry::E, data::Vector{UInt8})::Union{Vector{UInt8}, Nothing} where {E <: AbstractBigDataEntry}
    length(searchdir(store.folder, String(entry.key))) !=1 && (@warn "Could not find unique file for key '$(entry.key)'."; return nothing)
    writeentry(store, entry, data)
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return getBigData(store, entry)
end

function deleteBigData!(store::FileDataStore, entry::E)::Vector{UInt8} where {E <: AbstractBigDataEntry}
    data = getData(store, v, entry.key)
    data == nothing && return nothing
    rm(filename(store, entry))
    return data
end
#
# function listStoreEntries(store::FileDataStore)::Vector{E} where {E <: AbstractBigDataEntry}
#     return collect(values(store.entries))
# end
