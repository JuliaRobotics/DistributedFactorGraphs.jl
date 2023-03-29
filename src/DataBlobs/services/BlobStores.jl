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

function getBlob(store::AbstractBlobStore, ::UUID)
    error("$(typeof(store)) doesn't override 'getBlob'.")
end

function addBlob!(store::AbstractBlobStore{T}, ::UUID, ::T) where {T}
    error("$(typeof(store)) doesn't override 'addBlob!'.")
end

function updateBlob!(store::AbstractBlobStore{T}, ::UUID, ::T) where {T}
    error("$(typeof(store)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(store::AbstractBlobStore, ::UUID)
    error("$(typeof(store)) doesn't override 'deleteBlob!'.")
end

function listBlobs(store::AbstractBlobStore)
    error("$(typeof(store)) doesn't override 'listBlobs'.")
end

function hasBlob(store::AbstractBlobStore, ::UUID)
    error("$(typeof(store)) doesn't override 'hasBlob'.")
end

##==============================================================================
## AbstractBlobStore derived CRUD for Blob 
##==============================================================================

function getBlob(dfg::AbstractDFG, entry::BlobEntry)
    # cannot use entry.blobstore because the blob can be in any one of the blobstores
    stores = getBlobStores(dfg)
    for (k, store) in stores
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
            "could not find $(entry.label), uuid $blobId) in any of the listed blobstores:\n $([s->getKey(s) for (s,v) in stores]))"
        )
    )
end

getBlob(store::AbstractBlobStore, entry::BlobEntry) =
    getBlob(store, entry.originId)

#add 
addBlob!(dfg::AbstractDFG, entry::BlobEntry, data) =
    addBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

addBlob!(store::AbstractBlobStore, entry::BlobEntry, data) =
    addBlob!(store, entry.originId, data)
    
addBlob!(store::AbstractBlobStore, data) =
    addBlob!(store, uuid4(), data)

#fallback as not all blobStores use filename
addBlob!(store::AbstractBlobStore, blobId::UUID, data, ::String) = 
    addBlob!(store, blobId, data)

#update
updateBlob!(dfg::AbstractDFG, entry::BlobEntry, data::T) where {T} =
    updateBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

updateBlob!(store::AbstractBlobStore, entry::BlobEntry, data) =
    updateBlob!(store, entry.originId, data)

#delete
deleteBlob!(dfg::AbstractDFG, entry::BlobEntry) =
    deleteBlob!(getBlobStore(dfg, entry.blobstore), entry)

deleteBlob!(store::AbstractBlobStore, entry::BlobEntry) =
    deleteBlob!(store, entry.originId)


#has
hasBlob(dfg::AbstractDFG, entry::BlobEntry) = hasBlob(getBlobStore(dfg, entry.blobstore), entry.originId)

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
    function FolderStore{T}(key, folder) where {T}
        if !isdir(folder)
            @info "Folder '$folder' doesn't exist - creating."
            # create new folder
            mkpath(folder)
        end
        return new(key, folder)
    end
end

FolderStore(foldername::String) = FolderStore{Vector{UInt8}}(:default_folder_store, foldername)

blobfilename(store::FolderStore, blobId::UUID) = joinpath(store.folder, "$blobId.dat")

function getBlob(store::FolderStore{T}, blobId::UUID) where {T}
    blobfilename = joinpath(store.folder, "$blobId.dat")
    if isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        throw(KeyError("Could not find file '$(blobfilename)'."))
    end
end

function addBlob!(store::FolderStore{T}, blobId::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, "$blobId.dat")
    if isfile(blobfilename)
        throw(KeyError("Key '$blobId' blob already exists."))
    else
        open(blobfilename, "w") do f
            write(f, data)
        end
        # return data
        return blobId
    end
end

function updateBlob!(store::FolderStore{T}, blobId::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, "$blobId.dat")
    if !isfile(blobfilename)
        @warn "Key '$blobId' doesn't exist."
    else
        open(blobfilename, "w") do f
            write(f, data)
        end
        return data
    end
end


function deleteBlob!(store::FolderStore{T}, blobId::UUID) where {T}
    blobfilename = joinpath(store.folder, "$blobId.dat")

    data = getBlob(store, entry)
    rm(blobfilename)
    return data
end

#hasBlob or existsBlob?
function hasBlob(store::FolderStore, blobId::UUID)
    blobfilename = joinpath(store.folder, "$blobId.dat")
    isfile(blobfilename)
end

hasBlob(store::FolderStore, entry::BlobEntry) = hasBlob(store, entry.originId)


##==============================================================================
## InMemoryBlobStore
##==============================================================================

struct InMemoryBlobStore{T} <: AbstractBlobStore{T}
    key::Symbol
    blobs::Dict{UUID,T}
end

InMemoryBlobStore{T}(storeKey::Symbol) where {T} = InMemoryBlobStore{Vector{UInt8}}(storeKey, Dict{UUID,T}())
InMemoryBlobStore(storeKey::Symbol=:default_inmemory_store) = InMemoryBlobStore{Vector{UInt8}}(storeKey)

function getBlob(store::InMemoryBlobStore, blobId::UUID)
    return store.blobs[blobId]
end

function addBlob!(store::InMemoryBlobStore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, entry.originId)
        error("Key '$blobId' blob already exists.")
    end
    store.blobs[blobId] = data
    return UUIDblobId
end

function updateBlob!(store::InMemoryBlobStore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = data
end

function deleteBlob!(store::InMemoryBlobStore, blobId::UUID)
    return pop!(store.blobs, blobId)
end

hasBlob(store::InMemoryBlobStore, blobId::UUID) = haskey(store.blobs, blobId)
