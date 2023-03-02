
## ================================================================================
## Remove in v0.21
##=================================================================================


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
    createdTimestamp::ZonedDateTime) BlobEntry(;
        originId=id,
        label,
        blobstore,
        hash,
        origin,
        description,
        mimeType,
    )


@deprecate hasDataEntry(w...;kw...) hasBlobEntry(w...;kw...)
@deprecate getDataEntry(w...;kw...) getBlobEntry(w...;kw...)
@deprecate getDataEntries(w...;kw...) getBlobEntries(w...;kw...)
@deprecate addDataEntry!(w...;kw...) addBlobEntry!(w...;kw...)
@deprecate updateDataEntry!(w...;kw...) updateBlobEntry!(w...;kw...)
@deprecate deleteDataEntry!(w...;kw...) deleteBlobEntry!(w...;kw...)
@deprecate listDataEntry(w...;kw...) listBlobEntry(w...;kw...)
@deprecate listDataEntrySequence(w...;kw...) listBlobEntrySequence(w...;kw...)
@deprecate mergeDataEntry!(w...;kw...) mergeBlobEntry!(w...;kw...)

# @deprecate getData(w...;kw...) getBlob(w...;kw...)
@deprecate getDataBlob(w...;kw...) getBlob(w...;kw...)
@deprecate addDataBlob!(w...;kw...) addBlob!(w...;kw...)
@deprecate updateDataBlob!(w...;kw...) updateBlob!(w...;kw...)
@deprecate deleteDataBlob!(w...;kw...) deleteBlob!(w...;kw...)
@deprecate listDataBlobs(w...;kw...) listBlobs(w...;kw...)

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

## ================================================================================
## Add @deprecate in v0.19, remove after v0.20
##=================================================================================

function Base.convert(::Type{String}, v::VersionNumber)
    @warn "Artificial conversion of VersionNumber to String will be deprected in future versions of DFG"
    string(v)
end

# TODO ADD DEPRECATION
@deprecate packVariable(::AbstractDFG, v::DFGVariable) packVariable(v) 

## ================================================================================
## Deprecate before v0.20
##=================================================================================

export DefaultDFG

const DefaultDFG = GraphsDFG

