

##==============================================================================
## Data CRUD interface
##==============================================================================
# NOTE this is the convenience wrappers for entry and blob.

"""
Get the data entry and blob for the specified blobstore or dfg retured as a tuple.
Related
[`getBlobEntry`](@ref)

$(METHODLIST)
"""
function getData end

"""
Add a data Entry and Blob to a distributed factor graph or BlobStore.
Related
[`addBlobEntry!`](@ref)

$(METHODLIST)
"""
function addData! end

"""
Update a data entry or blob to the blob store or dfg.
Related
[`updateBlobEntry!`](@ref)

$(METHODLIST)
"""
function updateData! end

"""
Delete a data entry and blob from the blob store or dfg.
Related
[`deleteBlobEntry!`](@ref)

$(METHODLIST)
"""
function deleteData! end


function getData(
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


#TODO from blobstores
function getData(
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


function addData!(
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

function addData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::BlobEntry, blob::Vector{UInt8}; hashfunction = sha256)
    assertHash(entry, blob; hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = addBlob!(blobstore, de, blob)
    return de=>db
end

#TODO check this one
function addData!(
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

addData!(
    dfg::AbstractDFG, 
    blobstorekey::Symbol, 
    label::Symbol, 
    key::Symbol, 
    blob::Vector{UInt8},
    timestamp=now(localzone()); 
    kwargs...
) = addData!(
        dfg,
        getBlobStore(dfg, blobstorekey),
        label,
        key,
        blob,
        timestamp;
        kwargs...
    )

function addData!(
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

    addData!(dfg, blobstore, label, entry, blob; hashfunction)
end


function updateData!(
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

function updateData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol,  entry::BlobEntry, blob::Vector{UInt8}; hashfunction = sha256)
    # Recalculate the hash - NOTE Assuming that this is going to be a BlobEntry. TBD.
    newEntry = BlobEntry(entry.id, entry.blobId, entry.originId, entry.label, blobstore.key, bytes2hex(hashfunction(blob)),
        buildSourceString(dfg, label),
        entry.description, entry.mimeType, entry.metadata, entry.timestamp, entry._type, string(_getDFGVersion()))

    de = updateBlobEntry!(dfg, label, newEntry)
    db = updateBlob!(blobstore, de, blob)
    return de=>db
end

function deleteData!(
    dfg::AbstractDFG, 
    label::Symbol, 
    key::Symbol
)
    de = deleteBlobEntry!(dfg, label, key)
    db = deleteBlob!(dfg, de)
    return de=>db
end


deleteData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, entry::BlobEntry) =
            deleteBlob!(dfg, blobstore, label, entry.label)

function deleteData!(dfg::AbstractDFG, blobstore::AbstractBlobStore, label::Symbol, key::Symbol)
    de = deleteBlobEntry!(dfg, label, key)
    db = deleteBlob!(blobstore, de)
    return de=>db
end
