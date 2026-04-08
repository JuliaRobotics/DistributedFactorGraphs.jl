# ==============================================================================
#  Blobentry
# ==============================================================================
"""
    $(TYPEDEF)

A `Blobentry` is a small about of structured data that holds reference information to find an actual blob. Many `Blobentry`s 
can exist on different graph nodes spanning Agents and Factor Graphs which can all reference the same `Blob`.

Notes:
- `blobid`s should be unique within a Blobstore and are immutable.
"""
StructUtils.@kwarg struct Blobentry
    """ Human friendly label of the `Blob` and also used as unique identifier per node on which a `Blobentry` is added.  E.g. do "LEFTCAM_1", "LEFTCAM_2", ... of you need to repeat a label on the same variable. """
    label::Symbol
    """ The label of the `Blobstore` in which the `Blob` is stored.  Default is `:primary`."""
    storelabel::Symbol = :primary
    """ Machine friendly and unique within a `Blobstore` identifier of the 'Blob'."""
    blobid::UUID = uuid4() # was blobId
    """ (Optional) crc32c hash value to ensure data consistency which must correspond to the stored hash upon retrieval."""
    crchash::Union{UInt32, Nothing} =
        nothing & (
            json = (
                lower = h -> isnothing(h) ? nothing : string(h; base = 16),
                lift = s -> isnothing(s) ? nothing : parse(UInt32, s; base = 16),
            )
        )
    """ (Optional) sha256 hash value to ensure data consistency which must correspond to the stored hash upon retrieval."""
    shahash::Union{Vector{UInt8}, Nothing} =
        nothing & (
            json = (
                lower = h -> isnothing(h) ? nothing : bytes2hex(h),
                lift = s -> isnothing(s) ? nothing : hex2bytes(s),
            )
        )
    """ Source system or application where the blob was created (e.g., webapp, sdk, robot)"""
    origin::String = ""
    """Number of bytes in blob serialized as a string"""
    size::Int64 = -1 & (json = (lower = string, lift = x -> parse(Int64, x)))
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
    storelabel = :primary;
    metadata::Union{JSONText, AbstractDict, NamedTuple} = JSONText("{}"),
    kwargs...,
)
    if !(metadata isa JSONText)
        metadata = JSONText(JSON.json(metadata))
    end
    return Blobentry(; label, storelabel, metadata, kwargs...)
end
# construction helper from existing Blobentry for user overriding via kwargs
function Blobentry(
    entry::Blobentry;
    blobid::UUID = entry.blobid,
    label::Symbol = entry.label,
    storelabel::Symbol = entry.storelabel,
    crchash = entry.crchash,
    shahash = entry.shahash,
    size::Int64 = entry.size,
    origin::String = entry.origin,
    description::String = entry.description,
    mimetype::MIME = entry.mimetype,
    metadata::JSONText = entry.metadata,
    timestamp::TimeDateZone = entry.timestamp,
    version = entry.version,
    blobstore = nothing, # TODO note deprecated in v0.29
)
    !isnothing(blobstore) && Base.depwarn(
        "The `blobstore` keyword argument has been renamed to `storelabel`",
        :Blobentry,
    )
    return Blobentry(;
        label,
        storelabel,
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

# ==============================================================================
# Blobentry - Generic node CRUD
# ==============================================================================

"""
    $(SIGNATURES)
"""
function getBlobentry(node, label::Symbol)
    !haskey(refBlobentries(node), label) && throw(LabelNotFoundError("Blobentry", label))
    return refBlobentries(node)[label]
end

function getBlobentries(
    node;
    whereLabel::Union{Nothing, Function} = nothing,
    whereBlobid::Union{Nothing, Function} = nothing,
)
    entries = collect(values(refBlobentries(node)))
    filterDFG!(entries, whereLabel, getLabel)
    filterDFG!(entries, whereBlobid, x -> string(x.blobid))
    return entries
end

"""
    $(SIGNATURES)
"""
function addBlobentry!(node, entry::Blobentry)
    label = getLabel(entry)
    haskey(refBlobentries(node), label) && throw(LabelExistsError("Blobentry", label))
    refBlobentries(node)[label] = entry
    return entry
end

function addBlobentries!(node, entries::Vector{Blobentry})
    addBlobentry!.(node, entries)
    return entries
end

"""
    $(SIGNATURES)
"""
function mergeBlobentry!(node, entry::Blobentry)
    label = getLabel(entry)
    refBlobentries(node)[label] = entry
    return 1
end

function mergeBlobentries!(node, entries::Vector{Blobentry})
    #TODO optimize with something like: merge!(refBlobentries(node), entries)
    mergeBlobentry!.(node, entries)
    return length(entries)
end

"""
    $(SIGNATURES)
"""
function deleteBlobentry!(node, label::Symbol)
    !haskey(refBlobentries(node), label) && return 0
    pop!(refBlobentries(node), label)
    return 1
end

deleteBlobentry!(node, entry) = deleteBlobentry!(node, getLabel(entry))

function deleteBlobentries!(node, labels::Vector{Symbol})
    return sum(deleteBlobentry!.(node, labels))
end

"""
    $(SIGNATURES)
List all Blobentry keys for a variable `label` in `dfg`
"""
function listBlobentries(node)
    return collect(keys(refBlobentries(node)))
end

"""
    $SIGNATURES

Does a blob entry exist with `label`.
"""
hasBlobentry(node, label::Symbol) = haskey(refBlobentries(node), label)

# ==============================================================================
# Blobentry - utils
# ==============================================================================

"""
    checkHash(entry::Blobentry, blob) -> Union{Bool,Nothing}

Checks the integrity of a blob against the hashes (crc32c, sha256) stored in the given `Blobentry`.

- Returns `true` if all present hashes (`crchash`, `shahash`) match the computed values from `blob`.
- Returns `false` if any present hash does not match.
- Returns `nothing` if no hashes are stored in the `Blobentry` to check against.
"""
function checkHash(entry::Blobentry, blob)
    if !isnothing(entry.crchash)
        crc32c(blob) != entry.crchash && return false
    end
    if entry.shahash != ""
        sha256(blob) != entry.shahash && return false
    end
    if isnothing(entry.crchash) && entry.shahash == ""
        return nothing
    end
    return true
end

function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
    println(io, "Blobentry {")
    println(io, "  blobid:        ", entry.blobid)
    println(io, "  label:         ", entry.label)
    println(io, "  storelabel:     ", entry.storelabel)
    println(io, "  origin:        ", entry.origin)
    println(io, "  description:   ", entry.description)
    println(io, "  mimetype:      ", entry.mimetype)
    println(io, "  timestamp      ", entry.timestamp)
    println(io, "  version:       ", entry.version)
    return println(io, "}")
end

# TODO Consider autogenerating all methods of the form:
# verbNoun(dfg::VariableCompute, label::Symbol, args...; kwargs...) = verbNoun(getVariable(dfg, label), args...; kwargs...)
# with something like:
# getvariablemethod = [
#     :getfirstBlobentry,
# ]
# for met in methodstooverload  
#     @eval DistributedFactorGraphs $met(dfg::AbstractDFG, label::Symbol, args...; kwargs...) = $met(getVariable(dfg, label), args...; kwargs...)
# end
