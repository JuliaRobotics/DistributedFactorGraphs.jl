
## ================================================================================
## Remove in v0.24
##=================================================================================
#NOTE free up getNeighbors to return the variables or factors
@deprecate getNeighbors(args...; kwargs...) listNeighbors(args...; kwargs...)

## ================================================================================
## Remove in v0.23
##=================================================================================

@deprecate BlobEntry(
    id,
    blobId,
    originId::UUID,
    label::Symbol,
    blobstore::Symbol,
    hash::String,
    origin::String,
    description::String,
    mimeType::String,
    metadata::String,
    timestamp::ZonedDateTime,
    _type::String,
    _version::String,
) BlobEntry(
    id,
    blobId,
    originId,
    label,
    blobstore,
    hash,
    origin,
    -1,
    description,
    mimeType,
    metadata,
    timestamp,
    nothing,
    nothing,
    _type,
    _version,
)

## ================================================================================
## Remove in v0.22
##=================================================================================

@deprecate getBlobEntry(var::AbstractDFGVariable, key::Regex) getBlobEntryFirst(var, key)

## ================================================================================
## Remove in v0.21
##=================================================================================
@deprecate packFactor(dfg::AbstractDFG, f::DFGFactor) packFactor(f::DFGFactor)

# #TODO check this one
# function addData!(
#     ::Type{<:BlobEntry}, 
#     dfg::AbstractDFG, 
#     vLbl::Symbol, 
#     bLbl::Symbol, 
#     blob::AbstractVector{UInt8}, 
#     timestamp=now(localzone());
#     id::UUID = uuid4(), 
#     hashfunction::Function = sha256
# )
#     fde = BlobEntry(bLbl, id, timestamp, blob)
#     de = addBlobEntry!(dfg, vLbl, fde)
#     return de=>blob
# end

"""
$(TYPEDEF)
Abstract parent struct for big data entry.
"""
abstract type AbstractBlobEntry end

# should be deprecated by v0.21

@deprecate BlobStoreEntry(
    label::Symbol,
    id::UUID,
    blobstore::Symbol,
    hash::String,
    origin::String,
    description::String,
    mimeType::String,
    createdTimestamp::ZonedDateTime,
) BlobEntry(; originId = id, label, blobstore, hash, origin, description, mimeType)

@deprecate hasDataEntry(w...; kw...) hasBlobEntry(w...; kw...)
@deprecate getDataEntry(w...; kw...) getBlobEntry(w...; kw...)
@deprecate getDataEntries(w...; kw...) getBlobEntries(w...; kw...)
@deprecate addDataEntry!(w...; kw...) addBlobEntry!(w...; kw...)
@deprecate updateDataEntry!(w...; kw...) updateBlobEntry!(w...; kw...)
@deprecate deleteDataEntry!(w...; kw...) deleteBlobEntry!(w...; kw...)
@deprecate listDataEntrySequence(w...; kw...) listBlobEntrySequence(w...; kw...)

# @deprecate getData(w...;kw...) getBlob(w...;kw...)
@deprecate getDataBlob(w...; kw...) getBlob(w...; kw...)
@deprecate addDataBlob!(w...; kw...) addBlob!(w...; kw...)
@deprecate updateDataBlob!(w...; kw...) updateBlob!(w...; kw...)
@deprecate deleteDataBlob!(w...; kw...) deleteBlob!(w...; kw...)
@deprecate listDataBlobs(w...; kw...) listBlobs(w...; kw...)

# function updateBlob!(
#     dfg::AbstractDFG, 
#     label::Symbol, 
#     entry::BlobEntry
# )
#     # assertHash(entry, entry.data, hashfunction=hashfunction)
#     de = updateBlobEntry!(dfg, label, entry)
#     db = getBlob(dfg, entry)
#     return de=>db
# end

# function addBlob!(
#     dfg::AbstractDFG, 
#     label::Symbol, 
#     entry::BlobEntry; 
#     hashfunction = sha256
# )
#     # assertHash(entry, entry.data, hashfunction=hashfunction)
#     de = addBlobEntry!(dfg, label, entry)
#     db = getBlob(dfg, entry)
#     return de=>db
# end
