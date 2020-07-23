export BlobStoreEntry

"""
    $(TYPEDEF)
Genaral Data Store Entry.
"""
struct BlobStoreEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    blobstore::Symbol
    hash::String # Probably https://docs.julialang.org/en/v1/stdlib/SHA
    origin::String # E.g. user|robot|session|varlabel
    description::String
    mimeType::String
    createdTimestamp::ZonedDateTime # of when the entry was created
end


##==============================================================================
## AbstractBlobStore CRUD Interface
##==============================================================================

getDataBlob(dfg::AbstractDFG, entry::BlobStoreEntry) =
        getDataBlob(getBlobStore(dfg, entry.blobstore), entry)

function getDataBlob(store::AbstractBlobStore, entry::BlobStoreEntry)
    error("$(typeof(store)) doesn't override 'getDataBlob'.")
end

addDataBlob!(dfg::AbstractDFG, entry::BlobStoreEntry, data::T) where T =
        addDataBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

function addDataBlob!(store::AbstractBlobStore{T}, entry::BlobStoreEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'addDataBlob!'.")
end

updateDataBlob!(dfg::AbstractDFG, entry::BlobStoreEntry, data::T) where T =
        updateDataBlob!(getBlobStore(dfg, entry.blobstore), entry, data)

function updateDataBlob!(store::AbstractBlobStore{T},  entry::BlobStoreEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'updateDataBlob!'.")
end

deleteDataBlob!(dfg::AbstractDFG, entry::BlobStoreEntry) =
        deleteDataBlob!(getBlobStore(dfg, entry.blobstore), entry)

function deleteDataBlob!(store::AbstractBlobStore, entry::BlobStoreEntry)
    error("$(typeof(store)) doesn't override 'deleteDataBlob!'.")
end

function listDataBlobs(store::AbstractBlobStore)
    error("$(typeof(store)) doesn't override 'listDataBlobs'.")
end

##==============================================================================
## Store and Entry Data CRUD
##==============================================================================

function getData(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, key::Symbol; hashfunction = sha256)
    de = getDataEntry(dfg, label, key)
    db = getDataBlob(blobstore, de)
    assertHash(de, db, hashfunction=hashfunction)
    return de=>db
end

function addData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::AbstractDataEntry, blob::Vector{UInt8}; hashfunction = sha256)
    assertHash(entry, blob, hashfunction=hashfunction)
    de = addDataEntry!(dfg, label, entry)
    db = addDataBlob!(blobstore, de, blob)
    return de=>db
end

function updateData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol,  entry::AbstractDataEntry, blob::Vector{UInt8})
    assertHash(entry, blob, hashfunction=hashfunction)
    de = updateDataEntry!(dfg, label, entry)
    db = updateDataBlob!(blobstore, de, blob)
    return de=>db
end

deleteData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::AbstractDataEntry) =
            deleteData!(dfg, blobstore, label, entry.label)

function deleteData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, key::Symbol)
    de = deleteDataEntry!(dfg, label, key)
    db = deleteDataBlob!(blobstore, de)
    return de=>db
end

##==============================================================================

addData!(dfg::AbstractDFG, blobstorekey::Symbol, label::Symbol, key::Symbol, blob::Vector{UInt8},
         timestamp=now(localzone()); kwargs...) = addData!(dfg,
                                                           getBlobStore(dfg, blobstorekey),
                                                           label,
                                                           key,
                                                           blob,
                                                           timestamp;
                                                           kwargs...)

function addData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, key::Symbol,
                  blob::Vector{UInt8}, timestamp=now(localzone()); description="", mimeType = "", id::UUID = uuid4(), hashfunction = sha256)


    entry = BlobStoreEntry(key, id, blobstore.key, bytes2hex(hashfunction(blob)),
                           "$(dfg.userId)|$(dfg.robotId)|$(dfg.sessionId)|$(label)",
                           description, mimeType, timestamp)

    addData!(dfg, blobstore, label, entry, blob; hashfunction = hashfunction)
end


##==============================================================================
## FolderStore
##==============================================================================
export FolderStore

struct FolderStore{T} <: AbstractBlobStore{T}
    key::Symbol
    folder::String
end

blobfilename(store::FolderStore, entry::FileDataEntry) = joinpath(store.folder,"$(entry.id).dat")
entryfilename(store::FolderStore, entry::FileDataEntry) = joinpath(store.folder,"$(entry.id).json")

function getDataBlob(store::FolderStore{T}, entry::BlobStoreEntry) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    # entryfilename = "$(store.folder)/$(entry.id).json"
    if isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        error("Could not find file '$(blobfilename)'.")
        # return nothing
    end
end

function addDataBlob!(store::FolderStore{T}, entry::BlobStoreEntry, data::T) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")
    if isfile(blobfilename)
        error("Key '$(id)' blob already exists.")
    elseif isfile(entryfilename)
        error("Key '$(id)' entry already exists, but no blob.")
    else
        open(blobfilename, "w") do f
            write(f, data)
        end
        open(entryfilename, "w") do f
            JSON.print(f, entry)
        end
        return data
    end
end

function deleteDataBlob!(store::FolderStore{T}, entry::BlobStoreEntry) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")

    data = getDataBlob(store, entry)
    rm(blobfilename)
    rm(entryfilename)
    return data
end
