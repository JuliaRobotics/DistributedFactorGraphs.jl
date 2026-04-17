# ==============================================================================
#  Blobprovider Operations
# ==============================================================================

"""
    $(SIGNATURES)
Return the internal blobprovider dictionary reference for `dfg`.
"""
function refBlobproviders end

"""
    $(SIGNATURES)
Add a blobprovider to the DFG.
"""
function addBlobprovider! end

"""
    $(SIGNATURES)
Get a blobprovider by label.
"""
function getBlobprovider end

"""
    $(SIGNATURES)
Get all blobproviders in the DFG.
"""
function getBlobproviders end

"""
    $(SIGNATURES)
Merge a single blobprovider link into the DFG (idempotent if identical).
"""
function mergeBlobprovider! end

"""
    $(SIGNATURES)
Merge a vector of blobprovider links into the DFG.
"""
function mergeBlobproviders! end

"""
    $(SIGNATURES)
Delete the link to a blobprovider by label. Returns 0 if not found.
"""
function deleteBlobprovider! end

"""
    $(SIGNATURES)
List all blobprovider labels in the DFG.
"""
function listBlobproviders end

"""
    $(SIGNATURES)
Check whether a blobprovider with the given label exists.
"""
function hasBlobprovider end

# ==============================================================================
#  Blob Operations (Layer 1 verbs)
# ==============================================================================
"""
Fetch a blob from a Blobprovider.  Returns `nothing` when the multihash is
not present (never throws for a missing key).

Related
[`getBlobentry`](@ref)
Implement 
`fetchBlob(provider::AbstractBlobprovider, m::Multihash) -> Union{Vector{UInt8}, Nothing}`

$(METHODLIST)
"""
function fetchBlob end

"""
Put a blob into the Blobprovider (idempotent CAS write).

The convenience method hashes once and delegates to the core storage method:

    putBlob!(provider, blob::Vector{UInt8}; hash_func) -> Multihash   # hashes, delegates
    putBlob!(provider, m::Multihash, blob)             -> Multihash   # core — implement this

Related
[`addBlobentry!`](@ref)
$(METHODLIST)
"""
function putBlob! end

"""
Purge (physically remove) a blob from the provider.

Related
[`deleteBlobentry!`](@ref)
Implement
`purgeBlob!(provider::AbstractBlobprovider, m::Multihash)`
$(METHODLIST)
"""
function purgeBlob! end

"""
    $(SIGNATURES)
List all multihashes in the blob provider.
Implement
`listBlobs(provider::AbstractBlobprovider)`
"""
function listBlobs end

"""
    $(SIGNATURES)
Check if the blob provider has a blob with the given multihash.
"""
function hasBlob end

# ==============================================================================
# AbstractBlobprovider derived CRUD for Blob 
# ==============================================================================

function getBlob(dfg::AbstractDFG, entry::Blobentry)
    providers = refBlobproviders(dfg)

    if isempty(providers)
        @warn(
            "No Blobproviders mounted on DFG. Add one with `addBlobprovider!(dfg, FolderBlobprovider(path))` before storing blobs. Cannot retrieve multihash: $(entry.multihash)",
        )
        throw(LabelNotFoundError("Blobprovider", entry.provider, collect(keys(providers))))
    end

    # 1. Build the search order: Hinted provider first, followed by the rest
    search_order = Symbol[]
    if haskey(providers, entry.provider)
        push!(search_order, entry.provider)
    end
    for label in keys(providers)
        label != entry.provider && push!(search_order, label)
    end

    # 2. Iterate — single call per provider (fetchBlob returns nothing on miss)
    for label in search_order
        blob = fetchBlob(providers[label], entry.multihash)
        if !isnothing(blob)
            return blob
        end
    end

    # 3. Exhausted all options
    throw(
        IdNotFoundError(
            "Blob content not found across any mounted provider for multihash",
            entry.multihash,
        ),
    )
end

function fetchBlob(provider::AbstractBlobprovider, entry::Blobentry)
    return fetchBlob(provider, entry.multihash)
end

#put — generic hashing layer (computes hash once, delegates to core)
function putBlob!(
    provider::AbstractBlobprovider,
    blob::Vector{UInt8};
    hash_func::Function = sha2_256,
)
    m = Multihash(hash_func, blob)
    return putBlob!(provider, m, blob)
end

#has
function hasBlob(provider::AbstractBlobprovider, entry::Blobentry)
    return hasBlob(provider, entry.multihash)
end
function hasBlob(dfg::AbstractDFG, entry::Blobentry)
    # CAS: check all providers — the blob may have been stored via a different route
    #TODO check entry.provider first
    for (_, provider) in refBlobproviders(dfg)
        hasBlob(provider, entry.multihash) && return true
    end
    return false
end

# NOTE: purgeBlob! only exists at Layer 1 (provider, multihash).
# Users should call deleteVariableBlobentry! etc. to remove metadata pointers.
# Physical blob GC is handled asynchronously — we never delete blobs from the
# node API to avoid breaking CAS deduplication.
