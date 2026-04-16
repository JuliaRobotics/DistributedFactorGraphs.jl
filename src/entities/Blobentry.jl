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
    """ The label of the `Blobprovider` as a routing hint of where to look for the blob first.  Default is `:default`."""
    provider::Symbol = :default
    """ (Optional) crc32c hash value to ensure data consistency which must correspond to the stored hash upon retrieval."""
    crchash::Union{UInt32, Nothing} =
        nothing & (
            json = (
                lower = h -> isnothing(h) ? nothing : string(h; base = 16),
                lift = s -> isnothing(s) ? nothing : parse(UInt32, s; base = 16),
            )
        )
    """ Source system or application where the blob was created (e.g., webapp, sdk, robot)"""
    origin::String = ""
    """Number of bytes in blob serialized as a string"""
    size::Int64 = -1 & (json = (lower = string, lift = x -> parse(Int64, x)))
    """ Additional information that can help a different user of the Blob. """
    description::String = ""
    #TODO Look into multicodec in addition to (or instead of) mimetype to encode the type of the blob content.
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
    multihash::Multihash,
    provider::Symbol = :default;
    metadata::Union{JSONText, AbstractDict, NamedTuple} = JSONText("{}"),
    kwargs...,
)
    if !(metadata isa JSONText)
        metadata = JSONText(JSON.json(metadata))
    end
    return Blobentry(; label, multihash, provider, metadata, kwargs...)
end
# construction helper from existing Blobentry for user overriding via kwargs
function Blobentry(
    entry::Blobentry;
    label::Symbol = entry.label,
    multihash = entry.multihash,
    provider::Symbol = entry.provider,
    crchash = entry.crchash,
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
        "The `blobstore` keyword argument has been renamed to `provider`",
        :Blobentry,
    )
    return Blobentry(;
        label,
        multihash,
        provider,
        crchash,
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
        error(
            "Blobentry field :hash has been deprecated; use :crchash or :multihash instead",
        )
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

Checks the integrity of a blob against the hashes stored in the given `Blobentry`.

- Verifies the `multihash` by decoding its algorithm code, recomputing the digest
  from `blob`, and comparing it to the stored digest.
- Additionally verifies the `crchash` (crc32c) if present.
- Returns `true` if all present hashes match.
- Returns `false` if any hash does not match.
- Returns `nothing` if only the multihash is present but the algorithm is unregistered.
"""
function checkHash(entry::Blobentry, blob)
    # Reverse lookup: multicodec code -> hash function
    code_to_func = Dict{UInt64, Function}(v => k for (k, v) in MULTIHASH_FUNCTIONS)

    code, stored_digest = decode(entry.multihash)
    func = get(code_to_func, code, nothing)
    if isnothing(func)
        @warn "checkHash: unregistered multihash algorithm code $(repr(code)), skipping multihash check"
    else
        func(blob) != stored_digest && return false
    end

    if !isnothing(entry.crchash)
        crc32c(blob) != entry.crchash && return false
    end

    return true
end

function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
    println(io, "Blobentry {")
    println(io, "  label:         ", entry.label)
    println(io, "  multihash:     ", entry.multihash)
    println(io, "  provider:      ", entry.provider)
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
