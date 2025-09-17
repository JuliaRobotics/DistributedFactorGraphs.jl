
##==============================================================================
## Blobentry
##==============================================================================
#TODO think origin and buildSourceString should be deprecated, description can be used instead
#TODO hash - maybe use both crc32c for fast error check and sha256 for strong integrity check
#            stored seperately as crc and sha or as a tuple `hash::Tuple{Symbol, String}` where Symbol is :crc32c or :sha256
#            or an enum with suppored hash types
"""
    $(TYPEDEF)

A `Blobentry` is a small about of structured data that holds reference information to find an actual blob. Many `Blobentry`s 
can exist on different graph nodes spanning Agents and Factor Graphs which can all reference the same `Blob`.

Notes:
- `blobId`s should be unique within a blobstore and are immutable.
"""
Base.@kwdef struct Blobentry
    """ Remotely assigned and globally unique identifier for the `Blobentry` itself (not the `.blobId`). """
    id::Union{UUID, Nothing} = nothing
    """ Machine friendly and globally unique identifier of the 'Blob', usually assigned from a common point in the system.  This can be used to guarantee unique retrieval of the large data blob. """
    blobId::UUID = uuid4()
    """ Human friendly label of the `Blob` and also used as unique identifier per node on which a `Blobentry` is added.  E.g. do "LEFTCAM_1", "LEFTCAM_2", ... of you need to repeat a label on the same variable. """
    label::Symbol
    """ A hint about where the `Blob` itself might be stored.  Remember that a Blob may be duplicated over multiple blobstores. """
    blobstore::Symbol = :default
    """ A hash value to ensure data consistency which must correspond to the stored hash upon retrieval.  Use `bytes2hex(sha256(blob))`. [Legacy: some usage functions allow the check to be skipped if needed.] """
    hash::String = ""# Probably https://docs.julialang.org/en/v1/stdlib/SHA
    """ Context from which a Blobentry=>Blob was first created. E.g. agent|graph|varlabel. """
    origin::String = ""
    """ number of bytes in blob as a string"""
    size::String = "-1"
    """ Additional information that can help a different user of the Blob. """
    description::String = ""
    """ MIME description describing the format of binary data in the `Blob`, e.g. 'image/png' or 'application/json; _type=CameraModel'. """
    mimeType::String = "application/octet-stream"
    """ Additional storage for functional metadata used in some scenarios, e.g. to support advanced features such as `parsejson(base64decode(entry.metadata))['time_sync']`. """
    metadata::String = "e30="
    """ When the Blob itself was first created. """
    timestamp::ZonedDateTime = now(localzone())
    """ When the Blobentry was created. """
    createdTimestamp::Union{ZonedDateTime, Nothing} = nothing
    """ Use carefully, but necessary to support advanced usage such as time synchronization over Blob data. """
    lastUpdatedTimestamp::Union{ZonedDateTime, Nothing} = nothing
    """ Type version of this Blobentry."""
    _version::VersionNumber = _getDFGVersion()
end

StructTypes.StructType(::Type{Blobentry}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{Blobentry}) = :id
StructTypes.omitempties(::Type{Blobentry}) = (:id,)

function Blobentry(label::Symbol, blobstore = :default; kwargs...)
    return Blobentry(; label, blobstore, kwargs...)
end
# construction helper from existing Blobentry for user overriding via kwargs
function Blobentry(
    entry::Blobentry;
    id::Union{UUID, Nothing} = entry.id,
    blobId::UUID = entry.blobId,
    label::Symbol = entry.label,
    blobstore::Symbol = entry.blobstore,
    hash::String = entry.hash,
    size::Union{String, Int, Nothing} = entry.size,
    origin::String = entry.origin,
    description::String = entry.description,
    mimeType::String = entry.mimeType,
    metadata::String = entry.metadata,
    timestamp::ZonedDateTime = entry.timestamp,
    createdTimestamp = entry.createdTimestamp,
    lastUpdatedTimestamp = entry.lastUpdatedTimestamp,
    _version = entry._version,
)
    return Blobentry(;
        id,
        blobId,
        label,
        blobstore,
        hash,
        origin,
        size = string(size),
        description,
        mimeType,
        metadata,
        timestamp,
        createdTimestamp,
        lastUpdatedTimestamp,
        _version,
    )
end
