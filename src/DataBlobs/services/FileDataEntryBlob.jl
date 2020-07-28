##==============================================================================
## FileDataEntryBlob Types
##==============================================================================
export FileDataEntry
"""
    $(TYPEDEF)
Data Entry in a file.
"""
struct FileDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    folder::String
    hash::String #using bytes2hex or perhaps Vector{Uint8}?
    createdTimestamp::ZonedDateTime

    function FileDataEntry(label, id, folder, hash, timestamp)
        if !isdir(folder)
            @warn "Folder '$folder' doesn't exist - creating."
            # create new folder
            mkpath(folder)
        end
        return new(label, id, folder, hash, timestamp)
      end
end

# @generated function ==(x::FileDataEntry, y::FileDataEntry)
#     mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
# end

#
# getHash(entry::AbstractDataEntry) = hex2bytes(entry.hash)


##==============================================================================
## FileDataEntry Common
##==============================================================================
blobfilename(entry::FileDataEntry) = joinpath(entry.folder,"$(entry.id).dat")
entryfilename(entry::FileDataEntry) = joinpath(entry.folder,"$(entry.id).json")


##==============================================================================
## FileDataEntry Blob CRUD
##==============================================================================

function getDataBlob(dfg::AbstractDFG, entry::FileDataEntry)
    if isfile(blobfilename(entry))
        open(blobfilename(entry)) do f
            return read(f)
        end
    else
        error("Could not find file '$(blobfilename(entry))'.")
        # return nothing
    end
end

function addDataBlob!(dfg::AbstractDFG, entry::FileDataEntry, data::Vector{UInt8})
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
        return getDataBlob(dfg, entry)::Vector{UInt8}
    end
end

function updateDataBlob!(dfg::AbstractDFG, entry::FileDataEntry, data::Vector{UInt8})
    if !isfile(blobfilename(entry))
        @warn "Entry '$(entry.id)' does not exist, adding."
        return addDataBlob!(dfg, entry, data)
    else
        # perhaps add an explicit force update flag and error otherwise
        @warn "Key '$(entry.id)' already exists, data will be overwritten."
        deleteDataBlob!(dfg, entry)
        return addDataBlob!(dfg, entry, data)
    end
end

function deleteDataBlob!(dfg::AbstractDFG, entry::FileDataEntry)
    data = getDataBlob(dfg, entry)
    rm(blobfilename(entry))
    rm(entryfilename(entry))
    return data
end

##==============================================================================
## FileDataEntry CRUD Helpers
##==============================================================================

function addData!(::Type{FileDataEntry}, dfg::AbstractDFG, label::Symbol, key::Symbol, folder::String, blob::Vector{UInt8}, timestamp=now(localzone());
                  id::UUID = uuid4(), hashfunction = sha256)
    fde = FileDataEntry(key, id, folder, bytes2hex(hashfunction(blob)), timestamp)
    de = addDataEntry!(dfg, label, fde)
    db = addDataBlob!(dfg, fde, blob)
    return de=>db
end
