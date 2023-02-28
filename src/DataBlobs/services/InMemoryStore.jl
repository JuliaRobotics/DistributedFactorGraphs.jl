

##==============================================================================
## BlobEntry Blob CRUD - dit lyk nie of dit gebruik moet word nie
##==============================================================================

getBlob(dfg::AbstractDFG, entry::BlobEntry) = (@error("Inmemory blobstore is not working"); return nothing) ## entry.data

# addBlob!(dfg::AbstractDFG, entry::BlobEntry, blob) = error("Not suported")#entry.blob
# updateBlob!(dfg::AbstractDFG, entry::BlobEntry, blob) = error("Not suported")#entry.blob
deleteBlob!(dfg::AbstractDFG, entry::BlobEntry) = (@error("Inmemory blobstore is not working"); return nothing) ## entry.data

function addBlob!(dfg::AbstractDFG, label::Symbol, entry::BlobEntry; hashfunction = sha256)
    # assertHash(entry, entry.data, hashfunction=hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = getBlob(dfg, entry)
    return de=>db
end

function updateBlob!(dfg::AbstractDFG, label::Symbol, entry::BlobEntry)
    # assertHash(entry, entry.data, hashfunction=hashfunction)
    de = updateBlobEntry!(dfg, label, entry)
    db = getBlob(dfg, entry)
    return de=>db
end
##==============================================================================
## BlobEntry CRUD Helpers
##==============================================================================

# function addBlob!(dfg::AbstractDFG, label::Symbol, key::Symbol, folder::String, blob::Vector{UInt8}, timestamp=now(localzone());
function addBlob!(::Type{BlobEntry}, dfg::AbstractDFG, label::Symbol, key::Symbol, blob, timestamp=now(localzone());
                  id::UUID = uuid4(), hashfunction = sha256)
    fde = BlobEntry(key, id, timestamp, blob)
    de = addBlobEntry!(dfg, label, fde)
    return de=>blob
end
