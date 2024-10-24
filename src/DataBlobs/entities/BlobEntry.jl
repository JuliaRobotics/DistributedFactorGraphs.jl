
##==============================================================================
## BlobEntry
##==============================================================================

"""
    $(TYPEDEF)

A `BlobEntry` is a small about of structured data that holds reference information to find an actual blob. Many `BlobEntry`s 
can exist on different graph nodes spanning Agents and Factor Graphs which can all reference the same `Blob`.

Notes:
- `blobId`s should be unique within a blobstore and are immutable.
"""
Base.@kwdef struct BlobEntry
    """ Remotely assigned and globally unique identifier for the `BlobEntry` itself (not the `.blobId`). """
    id::Union{UUID, Nothing} = nothing
    """ Machine friendly and globally unique identifier of the 'Blob', usually assigned from a common point in the system.  This can be used to guarantee unique retrieval of the large data blob. """
    blobId::Union{UUID, Nothing} = uuid4() #Deprecated in v0.25 TODO  remove union, blobId is mandatory
    """ Machine friendly and locally assigned identifier of the 'Blob'.  `.originId`s are mandatory upon first creation at the origin regardless of network access.  Separate from `.blobId` since some architectures do not allow edge processes to assign a uuid4 to data store elements. """
    originId::Union{UUID, Nothing} = blobId #Deprecated in v0.25 TODO remove union or remove originId completely
    """ Human friendly label of the `Blob` and also used as unique identifier per node on which a `BlobEntry` is added.  E.g. do "LEFTCAM_1", "LEFTCAM_2", ... of you need to repeat a label on the same variable. """
    label::Symbol
    """ A hint about where the `Blob` itself might be stored.  Remember that a Blob may be duplicated over multiple blobstores. """
    blobstore::Symbol = :default
    """ A hash value to ensure data consistency which must correspond to the stored hash upon retrieval.  Use `bytes2hex(sha256(blob))`. [Legacy: some usage functions allow the check to be skipped if needed.] """
    hash::String = ""# Probably https://docs.julialang.org/en/v1/stdlib/SHA
    """ Context from which a BlobEntry=>Blob was first created. E.g. agent|graph|varlabel. """
    origin::String = ""
    """ number of bytes in blob as a string"""
    size::Union{String, Nothing} = "" #TODO remove union, use "" as nothing
    """ Additional information that can help a different user of the Blob. """
    description::String = ""
    """ MIME description describing the format of binary data in the `Blob`, e.g. 'image/png' or 'application/json; _type=CameraModel'. """
    mimeType::String = "application/octet-stream"
    """ Additional storage for functional metadata used in some scenarios, e.g. to support advanced features such as `parsejson(base64decode(entry.metadata))['time_sync']`. """
    metadata::String = "e30="
    """ When the Blob itself was first created. """
    timestamp::ZonedDateTime = now(localzone())
    """ When the BlobEntry was created. """
    createdTimestamp::Union{ZonedDateTime, Nothing} = nothing
    """ Use carefully, but necessary to support advanced usage such as time synchronization over Blob data. """
    lastUpdatedTimestamp::Union{ZonedDateTime, Nothing} = nothing
    """ Type version of this BlobEntry. TBD.jl consider upgrading to `::VersionNumber`. """
    _version::String = string(_getDFGVersion())
end

StructTypes.StructType(::Type{BlobEntry}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{BlobEntry}) = :id
StructTypes.omitempties(::Type{BlobEntry}) = (:id,)

_fixtimezone(cts::NamedTuple) = ZonedDateTime(cts.utc_datetime * "+00")
