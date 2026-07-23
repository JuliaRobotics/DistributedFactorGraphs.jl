# ==============================================================================
#  Blobentry
# ==============================================================================
"""
    $(TYPEDEF)

A `Blobentry` is a small about of structured data that holds reference information to find an actual blob. Many `Blobentry`s 
can exist on different graph nodes spanning Agents and Factor Graphs which can all reference the same `Blob`.
"""
StructUtils.@kwarg struct Blobentry
    """ Human friendly label of the `Blob` and also used as unique identifier per node on which a `Blobentry` is added.  E.g. do "LEFTCAM_1", "LEFTCAM_2", ... of you need to repeat a label on the same variable. """
    label::Symbol
    """ Self-describing content hash (Multihash standard)."""
    multihash::Multihash
    """ CRC-32C checksum for fast integrity verification on retrieval."""
    crc32csum::UInt32 &
    (json = (lower = h -> string(h; base = 16), lift = s -> parse(UInt32, s; base = 16)))
    """Number of bytes in blob serialized as a string"""
    size::Int64 & (json = (lower = string, lift = x -> parse(Int64, x)))
    """ The label of the `Blobprovider` as a routing hint of where to look for the blob first.  Default is `:default`."""
    provider::Symbol = :default
    """ Source system or application where the blob was created (e.g., webapp, sdk, robot)"""
    origin::String = ""
    """ Additional information that can help a different user of the Blob. """
    description::String = ""
    #TODO Look into multicodec in addition to (or instead of) mimetype to encode the type of the blob content.
    """ MIME description describing the format of binary data in the `Blob`, e.g. 'image/png' or 'application/json'. """
    mimetype::MIME = MIME("application/octet-stream")
    """ Storage for a couple of bytes directly in the graph. Use with caution and keep it small and simple."""
    metadata::JSONText = JSONText("{}")
    """ When the Blob itself was first created. Serialized as an ISO 8601 string."""
    timestamp::TimeDateZone = now_tdz()
    """ DFG types serialization format version."""
    version::VersionNumber = DFG.DFG_TYPES_VERSION
end

# construction helper from existing Blobentry for user overriding via kwargs
function Blobentry(entry::Blobentry; kwargs...)
    old_kwargs = (; (f => getfield(entry, f) for f in fieldnames(Blobentry))...)
    return Blobentry(; merge(old_kwargs, values(kwargs))...)
end

function Blobentry(
    label::Symbol,
    blob::Vector{UInt8};
    hash_func::Function = sha2_256,
    multihash::Multihash = Multihash(hash_func, blob),
    crc32csum = crc32c(blob),
    size = length(blob),
    mimetype::MIME = getMimetype(IOBuffer(blob)),
    metadata::Union{JSONText, AbstractDict, NamedTuple} = JSONText("{}"),
    kwargs...,
)
    if !(metadata isa JSONText)
        metadata = JSONText(JSON.json(metadata))
    end
    return Blobentry(; label, multihash, crc32csum, size, mimetype, metadata, kwargs...)
end

#TODO deprecated in v0.29
function Base.getproperty(x::Blobentry, f::Symbol)
    if f in [:id, :createdTimestamp, :lastUpdatedTimestamp]
        error("Blobentry field $f has been deprecated")
    elseif f == :hash
        error("Blobentry field :hash has been deprecated; use :multihash instead")
    elseif f == :blobId || f == :blobid
        error("Blobentry field :blobId is obsolete; use :multihash instead")
    elseif f == :mimeType
        @warn "Blobentry field :mimeType has been renamed to :mimetype"
        return getfield(x, :mimetype)
    elseif f == :_version
        @warn "Blobentry field :_version has been renamed to :version"
        return getfield(x, :version)
    elseif f == :blobstore
        @warn "Blobentry field :blobstore has been renamed to :provider"
        return getfield(x, :provider)
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
    whereMultihash::Union{Nothing, Function} = nothing,
)
    entries = collect(values(refBlobentries(node)))
    filterDFG!(entries, whereLabel, getLabel)
    filterDFG!(entries, whereMultihash, x -> string(x.multihash))
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
    return sum(deleteBlobentry!.(node, labels); init = 0)
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
    verifyBlob(entry::Blobentry, blob) -> Union{Bool,Nothing}

Checks the integrity of a blob against the hashes stored in the given `Blobentry`.

- Verifies the `multihash` by decoding its algorithm code, recomputing the digest
  from `blob`, and comparing it to the stored digest.
- Additionally verifies the `crc32csum` checksum.
- Returns `true` if all present hashes match.
- Returns `false` if any hash does not match.
- Returns `nothing` if  the multihash algorithm is unregistered.
"""
function verifyBlob(entry::Blobentry, blob)
    code, stored_digest = decode(entry.multihash)
    func = get(MULTIHASH_CODES, code, nothing)
    if isnothing(func)
        @warn "verifyBlob: unregistered multihash algorithm code $(repr(code)), skipping multihash check"
        return nothing
    else
        func(blob) != stored_digest && return false
    end

    crc32c(blob) != entry.crc32csum && return false

    return true
end

function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
    println(io, "Blobentry {")
    println(io, "  label:      ", entry.label)
    println(io, "  multihash:  ", string(entry.multihash))
    println(io, "  crc32csum:  ", string(entry.crc32csum; base = 16))
    println(io, "  provider:   ", entry.provider)
    println(io, "  mimetype:   ", entry.mimetype)
    println(io, "  size:       ", Base.format_bytes(entry.size))
    println(io, "  timestamp:  ", entry.timestamp)
    !isempty(entry.origin) && println(io, "  origin:        ", entry.origin)
    !isempty(entry.description) && println(io, "  description:   ", entry.description)
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
