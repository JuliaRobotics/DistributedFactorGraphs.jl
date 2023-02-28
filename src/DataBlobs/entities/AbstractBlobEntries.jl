
##==============================================================================
## BlobStoreEntry
##==============================================================================

"""
    $(TYPEDEF)
General Data Store Entry.
"""
@Base.kwdef struct BlobEntry
    """ This is created by server-side GraphQL """
    id::Union{UUID, Nothing}=nothing 
    """ This is the forced server generated blobId, or the filesystem blobId. """
    blobId::Union{UUID, Nothing}=nothing 
    """ This is the ID at creation at the edge, do whatever you want with this, but make sure you populate it. """
    originId::UUID
    label::Symbol
    blobstore::Symbol
    hash::String # Probably https://docs.julialang.org/en/v1/stdlib/SHA
    origin::String # E.g. user|robot|session|varlabel
    description::String
    mimeType::String
    metadata::String = ""
    timestamp::ZonedDateTime = now(localzone())
    _type::String = "BlobEntry"
    _version::String = string(_getDFGVersion()) # TBD consider upgrading to ::VersionNumber
end


_fixtimezone(cts::NamedTuple) = ZonedDateTime(cts.utc_datetime*"+00")
