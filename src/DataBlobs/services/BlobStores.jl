
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

function getBlob(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    label::Symbol, 
    key::Union{Symbol,UUID, <:AbstractString, Regex}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    de = getBlobEntry(dfg, label, key)
    db = getBlob(blobstore, de)
    checkhash && assertHash(de, db; hashfunction)
    return de=>db
end

function addBlob!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::BlobEntry, blob::Vector{UInt8}; hashfunction = sha256)
    assertHash(entry, blob; hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = addBlob!(blobstore, de, blob)
    return de=>db
end

function updateBlob!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol,  entry::BlobEntry, blob::Vector{UInt8}; hashfunction = sha256)
    # Recalculate the hash - NOTE Assuming that this is going to be a BlobEntry. TBD.
    newEntry = BlobEntry(entry.id, entry.blobId, entry.originId, entry.label, blobstore.key, bytes2hex(hashfunction(blob)),
        buildSourceString(dfg, label),
        entry.description, entry.mimeType, entry.metadata, entry.timestamp, entry._type, string(_getDFGVersion()))

    de = updateBlobEntry!(dfg, label, newEntry)
    db = updateBlob!(blobstore, de, blob)
    return de=>db
end

deleteBlob!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::BlobEntry) =
            deleteBlob!(dfg, blobstore, label, entry.label)

function deleteBlob!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, key::Symbol)
    de = deleteBlobEntry!(dfg, label, key)
    db = deleteBlob!(blobstore, de)
    return de=>db
end

##==============================================================================
## Blob CRUD helper functions
##==============================================================================

addBlob!(
    dfg::AbstractDFG, 
    blobstorekey::Symbol, 
    label::Symbol, 
    key::Symbol, 
    blob::Vector{UInt8},
    timestamp=now(localzone()); 
    kwargs...) = addBlob!(
        dfg,
        getBlobStore(dfg, blobstorekey),
        label,
        key,
        blob,
        timestamp;
        kwargs...
    )

function addBlob!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    label::Symbol, 
    key::Symbol,
    blob::Vector{UInt8}, 
    timestamp=now(localzone()); 
    description="", mimeType = "application/octet-stream", 
    id::UUID = uuid4(), 
    hashfunction = sha256
)
    #
    @warn "ID's and origin IDs should be reconciled here."
    entry = BlobEntry(
        id = id, 
        originId = id,
        label = key, 
        blobstore = blobstore.key, 
        hash = bytes2hex(hashfunction(blob)),
        origin = buildSourceString(dfg, label),
        description = description, 
        mimeType = mimeType, 
        metadata = "", 
        timestamp = timestamp)

    addBlob!(dfg, blobstore, label, entry, blob; hashfunction)
end

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
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")
    if isfile(blobfilename)
        error("Key '$(entry.id)' blob already exists.")
    elseif isfile(entryfilename)
        error("Key '$(entry.id)' entry already exists, but no blob.")
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

function updateBlob!(store::FolderStore{T},  entry::BlobEntry, data::T) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")
    if !isfile(blobfilename)
        @warn "Key '$(entry.id)' doesn't exist."
    elseif !isfile(entryfilename)
        @warn "Key '$(entry.id)' doesn't exist."
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
    if haskey(store.blobs, entry.id)
        error("Key '$(entry.id)' blob already exists.")
    end
    return store.blobs[entry.id] = data
end

function updateBlob!(store::InMemoryBlobStore{T},  entry::BlobEntry, data::T) where T
    if haskey(store.blobs, entry.id)
        @warn "Key '$(entry.id)' doesn't exist."
    end
    return store.blobs[entry.id] = data
end

function deleteBlob!(store::InMemoryBlobStore{T}, entry::BlobEntry) where T
    return pop!(store.blobs, entry.id)
end
