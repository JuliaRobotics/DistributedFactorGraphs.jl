##==============================================================================
## FileDataStore Common
##==============================================================================
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filename(store::FileDataStore, entry::AbstractDataEntry) = "$(store.folder)/$(entry.id).dat"

@deprecate readentry(args...) readfileblob(args...)
function readfileblob(store::FileDataStore, entry::AbstractDataEntry)
    open(filename(store, entry)) do f
        return read(f)
    end
end

@deprecate writeentry(args...) writefileblob(args...)
function writefileblob(store::FileDataStore, entry::AbstractDataEntry, data::Vector{UInt8})
    open(filename(store, entry), "w") do f
        write(f, data)
    end
end

##==============================================================================
## FileDataStore CRUD
##==============================================================================

function getDataBlob(store::FileDataStore{UInt8}, entry::AbstractDataEntry)
    length(searchdir(store.folder, string(entry.id)*".dat")) !=1 &&
        error("Could not find unique file for key '$(entry.id)'.")
    # perhaps its not needed to see if its unique? should filesystem not take care of that?
    # !isfile(string(entry.id)*".dat") &&
    #     error("Could not find file for key '$(entry.id)'.")
    return readentry(store, entry)
end

function addDataBlob!(store::FileDataStore{UInt8}, entry::AbstractDataEntry, data::Vector{UInt8})::Vector{UInt8}
    length(searchdir(store.folder, string(entry.id)*".dat")) !=0 && error("Key '$(entry.id)' already exists.")
    writeentry(store, entry, data)
    # Update timestamp
    entry.lastUpdatedTimestamp = now()
    return getDataBlob(store, entry)
end

function updateDataBlob!(store::FileDataStore{UInt8}, entry::AbstractDataEntry, data::Vector{UInt8})::Union{Vector{UInt8}, Nothing}
    n_entries = length(searchdir(store.folder, string(entry.id)*".dat"))
    if  n_entries > 1
        error("Could not find unique file for key '$(entry.id)'.")
        # return nothing
    elseif n_entries == 0
        @warn "Entry '$(entry.id)' does not exist, adding."
        return addDataBlob!(store, entry, data)
    else
        writeentry(store, entry, data)
        # Update timestamp
        entry.lastUpdatedTimestamp = now()
        return getDataBlob(store, entry)
    end
end

function deleteDataBlob!(store::FileDataStore{UInt8}, entry::AbstractDataEntry)::Vector{UInt8}
    data = getDataBlob(store, entry)
    data == nothing && return nothing
    rm(filename(store, entry))
    return data
end

# TODO json entry file for every data blob
function listDataBlobs(store::FileDataStore)
    return filter(s -> length(s) > 3 && s[end-3:end]==".dat", readdir(store.folder))
end
