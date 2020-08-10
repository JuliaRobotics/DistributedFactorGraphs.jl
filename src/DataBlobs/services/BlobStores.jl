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


#TODO
# """
#     $(SIGNATURES)
# Copies all the entries from the source into the destination.
# Can specify which entries to copy with the `sourceEntries` parameter.
# Returns the list of copied entries.
# """
# function copyBlobStore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: AbstractDataEntry}
#     # Quick check
#     destEntries = listDataBlobs(destStore)
#     typeof(sourceEntries) != typeof(destEntries) && error("Can't copy stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
#     # Same source/destination check
#     sourceStore == destStore && error("Can't specify same store for source and destination.")
#     # Otherwise, continue
#     for sourceEntry in sourceEntries
#         addDataBlob!(destStore, deepcopy(sourceEntry), getDataBlob(sourceStore, sourceEntry))
#     end
#     return sourceEntries
# end

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

function updateData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol,  entry::AbstractDataEntry, blob::Vector{UInt8}; hashfunction = sha256)
    # Recalculate the hash - NOTE Assuming that this is going to be a BlobStoreEntry. TBD.
    newEntry = BlobStoreEntry(entry.label, entry.id, blobstore.key, bytes2hex(hashfunction(blob)),
        "$(dfg.userId)|$(dfg.robotId)|$(dfg.sessionId)|$(label)",
        entry.description, entry.mimeType, entry.createdTimestamp)

    de = updateDataEntry!(dfg, label, newEntry)
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

blobfilename(store::FolderStore, entry::BlobStoreEntry) = joinpath(store.folder,"$(entry.id).dat")
entryfilename(store::FolderStore, entry::BlobStoreEntry) = joinpath(store.folder,"$(entry.id).json")

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

function updateDataBlob!(store::FolderStore{T},  entry::BlobStoreEntry, data::T) where T
    blobfilename = joinpath(store.folder,"$(entry.id).dat")
    entryfilename = joinpath(store.folder,"$(entry.id).json")
    if !isfile(blobfilename)
        error("Key '$(id)' doesn't exist.")
    elseif !isfile(entryfilename)
        error("Key '$(id)' doesn't exist.")
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
