##==============================================================================
## Blob CRUD interface
##==============================================================================


"""
Get the data blob for the specified blobstore or dfg.

Related
[`getBlobEntry`](@ref)

$(METHODLIST)
"""
function getBlob end

"""
Adds a blob to the blob store or dfg with the given entry.

Related
[`addBlobEntry!`](@ref)

$(METHODLIST)
"""
function addBlob! end

"""
Update a blob to the blob store or dfg with the given entry.
Related
[`updateBlobEntry!`](@ref)

$(METHODLIST)

DevNotes
- TODO TBD update verb on data since data blobs and entries are restricted to immutable only.
"""
function updateBlob! end

"""
Delete a blob from the blob store or dfg with the given entry.

Related
[`deleteBlobEntry!`](@ref)

$(METHODLIST)
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all ids in the blob store.
"""
function listBlobs end

##==============================================================================
## AbstractBlobStore CRUD Interface
##==============================================================================

function getBlob(store::AbstractBlobStore, entry::BlobEntry)
    error("$(typeof(store)) doesn't override 'getBlob'.")
end

function addBlob!(store::AbstractBlobStore{T}, entry::BlobEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'addBlob!'.")
end

function updateBlob!(store::AbstractBlobStore{T},  entry::BlobEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(store::AbstractBlobStore, entry::BlobEntry)
    error("$(typeof(store)) doesn't override 'deleteBlob!'.")
end

function listBlobs(store::AbstractBlobStore)
    error("$(typeof(store)) doesn't override 'listBlobs'.")
end

##==============================================================================
## AbstractBlobStore derived CRUD for Blob 
##==============================================================================

function getBlob(dfg::AbstractDFG, entry::BlobEntry)
    # cannot use entry.blobstore because the blob can be in any one of the blobstores
    stores = getBlobStores(dfg)
    for (k,store) in stores
        try
            blob = getBlob(store, entry)
            return blob
        catch err
            if !(err isa KeyError)
                throw(err)
            end
        end
    end
    throw(
        KeyError(
            "could not find $(entry.label), uuid $(entry.id)) in any of the listed blobstores:\n $([s->getKey(s) for (s,v) in stores]))"
        )
    )
end

addBlob!(dfg::AbstractDFG, entry::BlobEntry, data::T) where T =
        addBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

updateBlob!(dfg::AbstractDFG, entry::BlobEntry, data::T) where T =
        updateBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

deleteBlob!(dfg::AbstractDFG, entry::BlobEntry) =
        deleteBlob!(getBlobStore(dfg, entry.blobstore), entry)


#TODO
# """
#     $(SIGNATURES)
# Copies all the entries from the source into the destination.
# Can specify which entries to copy with the `sourceEntries` parameter.
# Returns the list of copied entries.
# """
# function copyBlobStore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: BlobEntry}
#     # Quick check
#     destEntries = listBlobs(destStore)
#     typeof(sourceEntries) != typeof(destEntries) && error("Can't copy stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
#     # Same source/destination check
#     sourceStore == destStore && error("Can't specify same store for source and destination.")
#     # Otherwise, continue
#     for sourceEntry in sourceEntries
#         addBlob!(destStore, deepcopy(sourceEntry), getBlob(sourceStore, sourceEntry))
#     end
#     return sourceEntries
# end


##==============================================================================
## FolderStore
##==============================================================================
struct FolderStore{T} <: AbstractBlobStore{T}
    key::Symbol
    folder::String
    function FolderStore{T}(key, folder) where T
        if !isdir(folder)
            @info "Folder '$folder' doesn't exist - creating."
            # create new folder
            mkpath(folder)
        end
        return new(key, folder)
    end
end

FolderStore(foldername::String) = FolderStore{Vector{UInt8}}(:default_folder_store, foldername)

blobfilename(store::FolderStore, entry::BlobEntry) = joinpath(store.folder,"$(entry.id).dat")
entryfilename(store::FolderStore, entry::BlobEntry) = joinpath(store.folder,"$(entry.id).json")

function getBlob(store::FolderStore{T}, entry::BlobEntry) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    # entryfilename = "$(store.folder)/$(entry.id).json"
    if isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        throw(KeyError("Could not find file '$(blobfilename)'."))
        # return nothing
    end
end

function addBlob!(store::FolderStore{T}, entry::BlobEntry, data::T) where T
    blobfilename = joinpath(store.folder,"$(entry.originId).dat")
    entryfilename = joinpath(store.folder,"$(entry.originId).json")
    if isfile(blobfilename)
        error("Key '$(entry.originId)' blob already exists.")
    elseif isfile(entryfilename)
        error("Key '$(entry.originId)' entry already exists, but no blob.")
    else
        open(blobfilename, "w") do f
            write(f, data)
        end
        open(entryfilename, "w") do f
            JSON3.write(f, entry)
        end
        # return data
        # FIXME update for entry.blobId vs. entry.originId
        return UUID(entry.originId)
    end
end

function updateBlob!(store::FolderStore{T},  entry::BlobEntry, data::T) where T
    blobfilename = joinpath(store.folder,"$(entry.originId).dat")
    entryfilename = joinpath(store.folder,"$(entry.originId).json")
    if !isfile(blobfilename)
        @warn "Key '$(entry.originId)' doesn't exist."
    elseif !isfile(entryfilename)
        @warn "Key '$(entry.originId)' doesn't exist."
    else
        open(blobfilename, "w") do f
            write(f, data)
        end
        open(entryfilename, "w") do f
            JSON3.write(f, entry)
        end
        return data
    end
end


function deleteBlob!(store::FolderStore{T}, entry::BlobEntry) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")
    
    data = getBlob(store, entry)
    rm(blobfilename)
    rm(entryfilename)
    return data
end

##==============================================================================
## InMemoryBlobStore
##==============================================================================

struct InMemoryBlobStore{T} <: AbstractBlobStore{T}
    key::Symbol
    blobs::Dict{UUID, T}
end

InMemoryBlobStore{T}(storeKey::Symbol) where T = InMemoryBlobStore{Vector{UInt8}}(storeKey, Dict{UUID, T}())
InMemoryBlobStore(storeKey::Symbol=:default_inmemory_store) = InMemoryBlobStore{Vector{UInt8}}(storeKey)

function getBlob(store::InMemoryBlobStore{T}, entry::BlobEntry) where T
    return store.blobs[entry.id]
end

function addBlob!(store::InMemoryBlobStore{T}, entry::BlobEntry, data::T) where T
    if haskey(store.blobs, entry.originId)
        error("Key '$(entry.originId)' blob already exists.")
    end
    # FIXME update for entry.originId vs .blobId
    store.blobs[entry.originId] = data
    return UUID(entry.originId)
end

function updateBlob!(store::InMemoryBlobStore{T},  entry::BlobEntry, data::T) where T
    if haskey(store.blobs, entry.originId)
        @warn "Key '$(entry.originId)' doesn't exist."
    end
    return store.blobs[entry.originId] = data
end

function deleteBlob!(store::InMemoryBlobStore{T}, entry::BlobEntry) where T
    return pop!(store.blobs, entry.originId)
end
