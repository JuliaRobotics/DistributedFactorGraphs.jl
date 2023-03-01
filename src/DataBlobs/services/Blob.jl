

##==============================================================================
## DFG Blob CRUD
##==============================================================================

# function getBlob(
#     dfg::AbstractDFG,
#     entry::BlobEntry;
#     checkhash::Bool=true,
# )
  
# end

function getBlob(
    dfg::AbstractDFG, 
    vlabel::Symbol, 
    key::Union{Symbol,UUID, <:AbstractString, Regex}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    de_ = getBlobEntry(dfg, vlabel, key)
    _first(s) = s
    _first(s::AbstractVector) = s[1]
    de = _first(de_)
    db = getBlob(dfg, de)

    checkhash && assertHash(de, db, hashfunction=hashfunction)
    return de=>db
end

function addBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && assertHash(entry, blob, hashfunction=hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = addBlob!(dfg, de, blob)
    return de=>db
end

function addBlob!(
    ::Type{<:BlobEntry}, 
    dfg::AbstractDFG, 
    label::Symbol, 
    key::Symbol, 
    blob::AbstractVector{UInt8}, 
    timestamp=now(localzone());
    id::UUID = uuid4(), 
    hashfunction::Function = sha256
)
    fde = BlobEntry(key, id, timestamp, blob)
    de = addBlobEntry!(dfg, label, fde)
    return de=>blob
end

function updateBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && assertHash(entry, blob, hashfunction=hashfunction)
    de = updateBlobEntry!(dfg, label, entry)
    db = updateBlob!(dfg, de, blob)
    return de=>db
end

function deleteBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    key::Symbol
)
    de = deleteBlobEntry!(dfg, label, key)
    db = deleteBlob!(dfg, de)
    return de=>db
end
