##==============================================================================
## FileDataStore Common
##==============================================================================
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filename(store::FileDataStore, entry::E) where E <: AbstractDataEntry = "$(store.folder)/$(entry.storeKey).dat"

function readentry(store::FileDataStore, entry::AbstractDataEntry)
    open(filename(store, entry)) do f
        return read(f)
    end
end

function writeentry(store::FileDataStore, entry::AbstractDataEntry, data::Vector{UInt8})
    open(filename(store, entry), "w") do f
        write(f, data)
    end
end

##==============================================================================
## FileDataStore CRUD
##==============================================================================

function getDataBlob(store::FileDataStore, entry::AbstractDataEntry)::Union{Vector{UInt8}, Nothing}
    length(searchdir(store.folder, String(entry.storeKey)*".dat")) !=1 && (@warn "Could not find unique file for key '$(entry.storeKey)'."; return nothing)
    return readentry(store, entry)
end

function addDataBlob!(store::FileDataStore, entry::AbstractDataEntry, data::Vector{UInt8})::Vector{UInt8}
    length(searchdir(store.folder, String(entry.storeKey)*".dat")) !=0 && error("Key '$(entry.storeKey)' already exists.")
    writeentry(store, entry, data)
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return getDataBlob(store, entry)
end

function updateDataBlob!(store::FileDataStore, entry::AbstractDataEntry, data::Vector{UInt8})::Union{Vector{UInt8}, Nothing}
    n_entries = length(searchdir(store.folder, String(entry.storeKey)*".dat"))
    if  n_entries > 1
        error("Could not find unique file for key '$(entry.storeKey)'.")
        # return nothing
    elseif n_entries == 0
        @warn "Entry '$(entry.storeKey)' does not exist, adding."
        return addDataBlob!(store, entry, data)
    else
        writeentry(store, entry, data)
        # Update timestamp
        entry.lastUpdatedTimestamp = now()
        return getDataBlob(store, entry)
    end
end

function deleteDataBlob!(store::FileDataStore, entry::AbstractDataEntry)::Vector{UInt8}
    data = getDataBlob(store, entry)
    data == nothing && return nothing
    rm(filename(store, entry))
    return data
end

# TODO: Manifest file
#
# function listDataBlobs(store::FileDataStore)::Vector{E} where {E <: AbstractDataEntry}
#     return collect(values(store.entries))
# end
