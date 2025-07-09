"""
    AbstractBlobstore{T}

Abstract supertype for all blobstore implementations.

# Usage

Subtypes of `AbstractBlobstore{T}` must implement the required interface for blob storage and retrieval, such as:

- `add!(store, blobId, blob)`: Add a new blob to the store.
- `get(store, blobId)`: Retrieve a blob by its ID.
- `list(store)`: List all blob IDs in the store.

The parameter `T` represents the type of blobs stored (e.g., `Vector{UInt8}` or a custom `Blob` type).

See concrete implementations for details.

Design Notes
- `blobId` is not considered unique across blobstores with different labels only within a single blobstore.
- We cannot guarantee that `blobId` is unique across different blobstores with the same label and this is up to the end user.
- Within a single blobstore `addBlob!` will fail if there is a UUID collision.
- TODO: We should consider using uuid7 for `blobId`s (requires jl v1.12).
- `Blobstrores`are identified by a `label::Symbol`, which allows for multiple blobstores to coexist in the same system.

TODO: If we want to make the `blobId`=>Blob pair immutable:
- We can use the tombstone pattern to mark a blob as deleted. See FolderStore in PR#TODO.

Design goal: all `Blobstore`s with the same `label` can contain the same `blobId`=>`Blob` pair and the blobs should be identical since they are immutable.

"""
abstract type AbstractBlobstore{T} end
