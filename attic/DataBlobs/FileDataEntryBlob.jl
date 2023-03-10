

# @generated function ==(x::BlobEntry, y::BlobEntry)
#     mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
# end

#
# getHash(entry::AbstractBlobEntry) = hex2bytes(entry.hash)


##==============================================================================
## BlobEntry Common
##==============================================================================
blobfilename(entry::BlobEntry) = joinpath(entry.folder,"$(entry.id).dat")
entryfilename(entry::BlobEntry) = joinpath(entry.folder,"$(entry.id).json")


##==============================================================================
## BlobEntry Blob CRUD
##==============================================================================

function getBlob(dfg::AbstractDFG, entry::BlobEntry)
    if isfile(blobfilename(entry))
        open(blobfilename(entry)) do f
            return read(f)
        end
    else
        throw(KeyError("Could not find file '$(blobfilename(entry))'."))
        # return nothing
    end
end

function addBlob!(dfg::AbstractDFG, entry::BlobEntry, data::Vector{UInt8})
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
        return getBlob(dfg, entry)::Vector{UInt8}
    end
end

function updateBlob!(dfg::AbstractDFG, entry::BlobEntry, data::Vector{UInt8})
    if !isfile(blobfilename(entry))
        @warn "Entry '$(entry.id)' does not exist, adding."
        return addBlob!(dfg, entry, data)
    else
        # perhaps add an explicit force update flag and error otherwise
        @warn "Key '$(entry.id)' already exists, data will be overwritten."
        deleteBlob!(dfg, entry)
        return addBlob!(dfg, entry, data)
    end
end

function deleteBlob!(dfg::AbstractDFG, entry::BlobEntry)
    data = getBlob(dfg, entry)
    rm(blobfilename(entry))
    rm(entryfilename(entry))
    return data
end

##==============================================================================
## BlobEntry CRUD Helpers
##==============================================================================

function addData!(::Type{BlobEntry}, dfg::AbstractDFG, label::Symbol, key::Symbol, folder::String, blob::Vector{UInt8}, timestamp=now(localzone());
                  id::UUID = uuid4(), hashfunction = sha256)
    fde = BlobEntry(key, id, folder, bytes2hex(hashfunction(blob)), timestamp)
    de = addBlobEntry!(dfg, label, fde)
    db = addBlob!(dfg, fde, blob)
    return de=>db
end
