# struct FileDataEntry <: AbstractDataEntry
#     label::Symbol
#     id::UUID
#     folder::String
#     hash::String #using bytes2hex or perhaps Vector{Uint8}?
#     timestamp::DateTime
#
#     function FileDataEntry(label, id, folder, hash, timestamp)
#         if !isdir(folder)
#             @warn "Folder '$folder' doesn't exist - creating."
#             # create new folder
#             mkpath(folder)
#         end
#         return new(label, id, folder, hash, timestamp)
#       end
# end
#
# getHash(entry::AbstractDataEntry) = hex2bytes(entry.hash)


##==============================================================================
## FileDataEntryBlob Common
##==============================================================================
blobfilename(entry::FileDataEntry) = "$(entry.folder)/$(entry.id).dat"
entryfilename(entry::FileDataEntry) = "$(entry.folder)/$(entry.id).json"


##==============================================================================
## FileDataEntryBlob CRUD
##==============================================================================

function getDataBlob(entry::FileDataEntry)
    if isfile(blobfilename(entry))
        open(blobfilename(entry)) do f
            return read(f)
        end
    else
        error("Could not find file '$(blobfilename(entry))'.")
        # return nothing
    end
end

function addDataBlob!(entry::FileDataEntry, data::Vector{UInt8})
    if isfile(blobfilename(entry))
        error("Key '$(entry.id)' blob already exists.")
    elseif isfile(entryfilename(entry))
        error("Key '$(entry.id)' entry already exists, but no blob.")
    else
        open(blobfilename(entry), "w") do f
            write(f, data)
        end
        open(entryfilename(entry), "w") do f
            JSON.print(f, entry)
        end
        return getDataBlob(entry)::Vector{UInt8}
    end
end

function updateDataBlob!(entry::FileDataEntry, data::Vector{UInt8})
    if !isfile(blobfilename(entry))
        @warn "Entry '$(entry.id)' does not exist, adding."
        return addDataBlob!(entry, data)
    else
        # perhaps add an explicit force update flag and error otherwise
        @warn "Key '$(entry.id)' already exists, data will be overwritten."
        deleteDataBlob!(entry::AbstractDataEntry)
        return addDataBlob!(entry, data)
    end
end

function deleteDataBlob!(entry::FileDataEntry)
    data = getDataBlob(entry)
    rm(blobfilename(entry))
    rm(entryfilename(entry))
    return data
end

##==============================================================================
## FileData CRUD
##==============================================================================

#TODO needs some design to work out. can propably be common to all.

function getData(dfg::AbstractDFG, label::Symbol, key::Symbol; hashfunction = sha256)
    de = getDataEntry(dfg, label, key)
    db = getDataBlob(de)

    hashfunction(db) != getHash(de) && error("Stored hash and data blob hash do not match")
    return de=>db
end

function addData!(dfg::AbstractDFG, label::Symbol, bde::FileDataEntry, blob::Vector{UInt8}; hashfunction = sha256)
    hashfunction(blob) != getHash(bde)  && error("Stored hash and data blob hash do not match")
    de = addDataEntry!(dfg, label, bde)
    db = addDataBlob!(bde, blob)
    return de=>db
end

function updateData!(dfg::AbstractDFG, label::Symbol,  bde::FileDataEntry,  blob::Vector{UInt8})
    de = updateDataEntry!(dfg, label, bde)
    db = updateDataBlob!(de, blob)
    return de=>db
end

function deleteData!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    de = deleteDataEntry!(dfg, label, key)
    db = deleteDataBlob!(de)
    return de=>db
end

##==============================================================================
## Store and Blob CRUD
##==============================================================================

function addData!(dfg::AbstractDFG, label::Symbol, key::Symbol, folder::String, blob::Vector{UInt8}, timestamp=now(UTC);
                  id::UUID = uuid4(), hashfunction = sha256)
    bde = FileDataEntry(key, id, folder, bytes2hex(hashfunction(blob)), timestamp)
    de = addDataEntry!(dfg, label, bde)
    db = addDataBlob!(bde, blob)
    return de=>db
end
