
## ================================================================================
## Deprecated in v0.24
##=================================================================================
@deprecate getBlobEntry(var::AbstractDFGVariable, key::AbstractString) getBlobEntryFirst(var, Regex(key))

@deprecate lsfWho(dfg::AbstractDFG, type::Symbol) lsf(dfg, getfield(Main, type))

## ================================================================================
## Deprecated in v0.23
##=================================================================================
#NOTE free up getNeighbors to return the variables or factors
@deprecate getNeighbors(args...; kwargs...) listNeighbors(args...; kwargs...)

## ================================================================================
## Deprecated in v0.22
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