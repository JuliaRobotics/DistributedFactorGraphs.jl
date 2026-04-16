"""
    AbstractBlobprovider

Abstract supertype for all blob storage implementations in the Virtual Blob System (VBS).

Every concrete subtype represents a physical storage backend and must carry a `label::Symbol`
field (defaulting to `:default`) that the VBS uses as its routing key. The label also doubles
as the `provider` hint stored in every `Blobentry` created through this provider.

# Required Interface (Layer 1 — Storage Physics)

Subtypes must implement the following Content-Addressable Storage (CAS) primitives, which
operate exclusively on raw bytes and Multihashes — no graph logic:

- `putBlob!(provider, m::Multihash, blob::Vector{UInt8}) -> Multihash` — Idempotently store blob at key `m`. (A convenience `putBlob!(provider, blob; hash_func)` that hashes and delegates is provided.)
- `fetchBlob(provider, multihash) -> Union{Vector{UInt8}, Nothing}` — Fetch raw bytes by Multihash, or `nothing` if absent.
- `hasBlob(provider, multihash) -> Bool` — Fast existence / deduplication check.
- `purgeBlob!(provider, multihash)` — Physical removal.

# Routing & Labelling

Every concrete implementation should accept an optional `label` keyword in its constructor:

```julia
FolderBlobprovider(path::String; label::Symbol = :default)
NavAbilityBlobprovider(;          label::Symbol = :default)
CachedBlobprovider(local, remote; label::Symbol = :default)
```

Mount providers onto a graph with:

```julia
addBlobprovider!(dfg, provider)               # mounts under provider.label
getBlobprovider(dfg, label::Symbol)           # retrieves by label
listBlobproviders(dfg)                        # lists all mounted labels
```

# CAS Design Principles

- Blobs are **immutable** and identified by the cryptographic Multihash of their content,
  not by random UUIDs. This guarantees global deduplication across all providers.
- `putBlob!` is idempotent: uploading the same bytes twice is a no-op.
- Physical blobs are **never deleted** through the graph metadata API. Only the `Blobentry`
  pointer is removed (`deleteVariableBlobentry!` etc.); garbage collection handles physical
  cleanup asynchronously.
- All providers sharing the same content hash hold identical, interchangeable bytes.

# Core Implementations

- `FolderBlobprovider` — Local disk I/O; acts as a fast ephemeral LRU cache.
- `MemoryBlobprovider` — In-memory storage for testing and transient data.
- `CachedBlobprovider` — Write-through wrapper composing a local and a remote provider.

"""
abstract type AbstractBlobprovider end
const Blobprovider = AbstractBlobprovider

function StructUtils.lower(::StructUtils.StructStyle, store::AbstractBlobprovider)
    return StructUtils.lower(Packed(store))
end
@choosetype AbstractBlobprovider resolvePackedType
