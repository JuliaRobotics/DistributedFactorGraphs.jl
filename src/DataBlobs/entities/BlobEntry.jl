##==============================================================================
## Blobentry
##==============================================================================
"""
    $(TYPEDEF)

A `Blobentry` is a small about of structured data that holds reference information to find an actual blob. Many `Blobentry`s 
can exist on different graph nodes spanning Agents and Factor Graphs which can all reference the same `Blob`.

Notes:
- `blobid`s should be unique within a blobstore and are immutable.
"""
StructUtils.@kwarg struct Blobentry
    """ Human friendly label of the `Blob` and also used as unique identifier per node on which a `Blobentry` is added.  E.g. do "LEFTCAM_1", "LEFTCAM_2", ... of you need to repeat a label on the same variable. """
    label::Symbol
    """ The label of the `Blobstore` in which the `Blob` is stored.  Default is `:default`."""
    blobstore::Symbol = :default
    """ Machine friendly and unique within a `Blobstore` identifier of the 'Blob'."""
    blobid::UUID = uuid4() # was blobId
    """ (Optional) crc32c hash value to ensure data consistency which must correspond to the stored hash upon retrieval."""
    crchash::Union{UInt32, Nothing} =
        nothing & (
            json=(
                lower = h->isnothing(h) ? nothing : string(h, base = 16),
                lift = s->isnothing(s) ? nothing : parse(UInt32, s; base = 16),
            )
        )
    """ (Optional) sha256 hash value to ensure data consistency which must correspond to the stored hash upon retrieval."""
    shahash::Union{Vector{UInt8}, Nothing} =
        nothing & (
            json=(
                lower = h->isnothing(h) ? nothing : bytes2hex(h),
                lift = s->isnothing(s) ? nothing : hex2bytes(s),
            )
        )
    """ Source system or application where the blob was created (e.g., webapp, sdk, robot)"""
    origin::String = ""
    """Number of bytes in blob serialized as a string"""
    size::Int64 = -1 & (json=(lower = string, lift = x->parse(Int64, x)))
    """ Additional information that can help a different user of the Blob. """
    description::String = ""
    """ MIME description describing the format of binary data in the `Blob`, e.g. 'image/png' or 'application/json'. """
    mimetype::MIME = MIME("application/octet-stream")
    """ Storage for a couple of bytes directly in the graph. Use with caution and keep it small and simple."""
    metadata::JSONText = JSONText("{}")
    """ When the Blob itself was first created. Serialized as an ISO 8601 string."""
    timestamp::TimeDateZone = now_tdz()
    """ Type version of this Blobentry."""
    version::VersionNumber = DFG.version(Blobentry)
end
version(::Type{Blobentry}) = v"0.1.0"

function Blobentry(
    label::Symbol,
    blobstore = :default;
    metadata::Union{JSONText, AbstractDict, NamedTuple} = JSONText("{}"),
    kwargs...,
)
    if !(metadata isa JSONText)
        metadata = JSONText(JSON.json(metadata))
    end
    return Blobentry(; label, blobstore, metadata, kwargs...)
end
# construction helper from existing Blobentry for user overriding via kwargs
function Blobentry(
    entry::Blobentry;
    blobid::UUID = entry.blobid,
    label::Symbol = entry.label,
    blobstore::Symbol = entry.blobstore,
    crchash = entry.crchash,
    shahash = entry.shahash,
    size::Int64 = entry.size,
    origin::String = entry.origin,
    description::String = entry.description,
    mimetype::String = entry.mimetype,
    metadata::JSONText = entry.metadata,
    timestamp::ZonedDateTime = entry.timestamp,
    version = entry.version,
)
    return Blobentry(;
        label,
        blobstore,
        blobid,
        crchash,
        shahash,
        origin,
        size,
        description,
        mimetype,
        metadata,
        timestamp,
        version,
    )
end

#TODO deprecated in v0.29
function Base.getproperty(x::Blobentry, f::Symbol)
    if f in [:id, :createdTimestamp, :lastUpdatedTimestamp]
        error("Blobentry field $f has been deprecated")
    elseif f == :hash
        error("Blobentry field :hash has been deprecated; use :crchash or :shahash instead")
    elseif f == :blobId
        @warn "Blobentry field :blobId has been renamed to :blobid"
        return getfield(x, :blobid)
    elseif f == :mimeType
        @warn "Blobentry field :mimeType has been renamed to :mimetype"
        return getfield(x, :mimetype)
    elseif f == :_version
        @warn "Blobentry field :_version has been renamed to :version"
        return getfield(x, :version)
    else
        getfield(x, f)
    end
end

const Blobentries = OrderedDict{Symbol, Blobentry}

function StructUtils.lower(entries::Blobentries)
    return map(collect(values(entries))) do (entry)
        return StructUtils.lower(entry)
    end
end

function StructUtils.makedict(s::StructUtils.StructStyle, T::Type{Blobentries}, json_vector)
    entries = T()
    foreach(json_vector) do obj
        entry, _ = StructUtils.make(s, Blobentry, obj)
        return push!(entries, Symbol(obj.label[]) => entry)
    end
    return entries, nothing
end
