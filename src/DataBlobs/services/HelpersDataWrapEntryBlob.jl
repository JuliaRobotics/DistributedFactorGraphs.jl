

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
Add both a BlobEntry and Blob to a distributed factor graph or BlobStore.
Related
[`addBlobEntry!`](@ref)

$(METHODLIST)
"""
function addData! end

"""
Update a blob entry or blob to the blob store or dfg.
Related
[`updateBlobEntry!`](@ref)

$(METHODLIST)
"""
function updateData! end

"""
Delete a blob entry and blob from the blob store or dfg.
Related
[`deleteBlobEntry!`](@ref)

$(METHODLIST)
"""
function deleteData! end


# cosntruction helper from existing BlobEntry for user overriding via kwargs
BlobEntry(
    entry::BlobEntry;
    id::Union{UUID,Nothing} = entry.id, 
    blobId::Union{UUID,Nothing} = entry.blobId, 
    originId::UUID = entry.originId, 
    label::Symbol = entry.label, 
    blobstore::Symbol = entry.blobstore, 
    hash::String = entry.hash,
    origin::String = entry.origin,
    description::String = entry.description, 
    mimeType::String = entry.mimeType, 
    metadata::String = entry.metadata, 
    timestamp::ZonedDateTime = entry.timestamp, 
    _type::String = entry._type, 
    _version::String = entry._version,
) = BlobEntry(;
    id,
    blobId,
    originId,
    label,
    blobstore,
    hash,
    origin,
    description,
    mimeType,
    metadata,
    timestamp,
    _type,
    _version
)

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
    checkhash::Bool=false
)
    checkhash && assertHash(entry, blob, hashfunction=hashfunction)
    blobId = addBlob!(dfg, entry, blob) |> UUID
    newEntry = BlobEntry(entry; id=blobId, blobId) #, size=length(blob))
    addBlobEntry!(dfg, label, newEntry; blobSize=length(blob))
end

function addData!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8}; 
    hashfunction = sha256,
    checkhash::Bool=false,
)
    checkhash && assertHash(entry, blob; hashfunction)
    blobId = addBlob!(blobstore, entry, blob) |> UUID
    newEntry = BlobEntry(entry; id=blobId, blobId) #, size=length(blob))
    addBlobEntry!(dfg, label, newEntry; blobSize=length(blob))
end


addData!(
    dfg::AbstractDFG, 
    blobstorekey::Symbol, 
    vLbl::Symbol, 
    bLbl::Symbol, 
    blob::Vector{UInt8},
    timestamp=now(localzone()); 
    kwargs...
) = addData!(
    dfg,
    getBlobStore(dfg, blobstorekey),
    vLbl,
    bLbl,
    blob,
    timestamp;
    kwargs...
)

function addData!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    vLbl::Symbol, 
    bLbl::Symbol,
    blob::Vector{UInt8}, 
    timestamp=now(localzone()); 
    description="",
    metadata = "",
    mimeType::String = "application/octet-stream", 
    id::Union{UUID,Nothing} = nothing, #only assign if blobstore issued you an id
    originId::UUID = uuid4(),
    hashfunction = sha256
)
    #
    @warn "ID's and origin IDs should be reconciled here in DFG.addData!." maxlog=50
    entry = BlobEntry(;
        id, 
        originId,
        label = bLbl, 
        blobstore = blobstore.key, 
        hash = string(bytes2hex(hashfunction(blob))),
        origin = buildSourceString(dfg, vLbl),
        description = description, 
        mimeType, 
        metadata, 
        timestamp)

    addData!(dfg, blobstore, vLbl, entry, blob; hashfunction)
end


function updateData!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && assertHash(entry, blob; hashfunction)
    # order of ops with unknown new blobId not tested
    de = updateBlobEntry!(dfg, label, entry)
    db = updateBlob!(dfg, de, blob)
    return de=>db
end


function updateData!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8}; 
    hashfunction = sha256
)
    # Recalculate the hash - NOTE Assuming that this is going to be a BlobEntry. TBD.
    # order of operations with unknown new blobId not tested
    newEntry = BlobEntry(
        entry; # and kwargs to override new values
        blobstore = blobstore.key, 
        hash = string(bytes2hex(hashfunction(blob))),
        origin = buildSourceString(dfg, label),
        _version = string(_getDFGVersion()),
    )

    de = updateBlobEntry!(dfg, label, newEntry)
    db = updateBlob!(blobstore, de, blob)
    return de=>db
end

function deleteData!(
    dfg::AbstractDFG, 
    vLbl::Symbol, 
    bLbl::Symbol
)
    de = deleteBlobEntry!(dfg, vLbl, bLbl)
    db = deleteBlob!(dfg, de)
    return de=>db
end


deleteData!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    label::Symbol, 
    entry::BlobEntry
) = deleteBlob!(
    dfg, 
    blobstore, 
    label, 
    entry.label
)

function deleteData!(
    dfg::AbstractDFG, 
    blobstore::AbstractBlobStore, 
    vLbl::Symbol, 
    bLbl::Symbol
)
    de = deleteBlobEntry!(dfg, vLbl, bLbl)
    db = deleteBlob!(blobstore, de)
    return de=>db
end
