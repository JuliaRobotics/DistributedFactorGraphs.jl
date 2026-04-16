
# ==============================================================================
# Shared CAS folder utilities (used by FolderBlobprovider & LinkBlobprovider)
# ==============================================================================

"""
    blobfilename(folder, m::Multihash) -> String

Generates the physical file path for a blob using a Git/IPFS style sharding
strategy to prevent OS directory-size limits.
"""
function blobfilename(folder::String, m::Multihash)
    hex_str = bytes2hex(m.bytes)
    folder_shard1 = hex_str[1:6]
    folder_shard2 = hex_str[7:8]
    return expanduser(joinpath(folder, folder_shard1, folder_shard2, hex_str))
end

function fetchBlob_folder(folder::String, m::Multihash)
    path = blobfilename(folder, m)
    isfile(path) || return nothing
    return read(path)
end

function purgeBlob_folder!(folder::String, m::Multihash)
    path = blobfilename(folder, m)
    if isfile(path)
        rm(path)
        parent = dirname(path)
        if isempty(readdir(parent))
            rm(parent)
        end
        return 1
    end
    return 0
end

function listBlobs_folder(folder::String)
    root_folder = expanduser(folder)
    !isdir(root_folder) && return Multihash[]

    hashes = Multihash[]
    for (root, _, files) in walkdir(root_folder)
        for filename in files
            m = tryparse(Multihash, filename)
            if !isnothing(m)
                push!(hashes, m)
            end
        end
    end
    return hashes
end

# ==============================================================================
# FolderBlobprovider
# ==============================================================================
struct FolderBlobprovider <: AbstractBlobprovider
    label::Symbol
    folder::String
end

function FolderBlobprovider(
    foldername::String;
    label::Symbol = :default,
    createfolder = true,
)
    storepath = expanduser(joinpath(foldername))
    if createfolder && !isdir(storepath)
        @info "Folder '$storepath' doesn't exist - creating."
        mkpath(storepath)
    end
    return FolderBlobprovider(label, foldername)
end

blobfilename(provider::FolderBlobprovider, m::Multihash) = blobfilename(provider.folder, m)

function fetchBlob(provider::FolderBlobprovider, m::Multihash)
    return fetchBlob_folder(provider.folder, m)
end

function putBlob!(provider::FolderBlobprovider, m::Multihash, blob::Vector{UInt8})
    filename = blobfilename(provider, m)
    if !isfile(filename)
        mkpath(dirname(filename))
        open(filename, "w") do f
            return write(f, blob)
        end
    end
    return m
end

function purgeBlob!(provider::FolderBlobprovider, m::Multihash)
    return purgeBlob_folder!(provider.folder, m)
end

function hasBlob(provider::FolderBlobprovider, m::Multihash)
    return isfile(blobfilename(provider, m))
end

function listBlobs(provider::FolderBlobprovider)
    return listBlobs_folder(provider.folder)
end

# ==============================================================================
# MemoryBlobprovider
# ==============================================================================
struct MemoryBlobprovider <: AbstractBlobprovider
    label::Symbol
    blobs::Dict{Multihash, Vector{UInt8}}
end

function MemoryBlobprovider(; label::Symbol = :default)
    return MemoryBlobprovider(label, Dict{Multihash, Vector{UInt8}}())
end

function fetchBlob(store::MemoryBlobprovider, m::Multihash)
    return get(store.blobs, m, nothing)
end

function putBlob!(store::MemoryBlobprovider, m::Multihash, blob::Vector{UInt8})
    if !haskey(store.blobs, m)
        store.blobs[m] = copy(blob)
    end
    return m
end

function purgeBlob!(store::MemoryBlobprovider, m::Multihash)
    !haskey(store.blobs, m) && return 0
    pop!(store.blobs, m)
    return 1
end

hasBlob(store::MemoryBlobprovider, m::Multihash) = haskey(store.blobs, m)

listBlobs(store::MemoryBlobprovider) = collect(keys(store.blobs))

# ==============================================================================
# CachedBlobprovider — Write-through cache wrapping a local and remote provider
# ==============================================================================

"""
    CachedBlobprovider(local, remote; label = :default)

A write-through CAS cache that composes two `AbstractBlobprovider`s.

- **`putBlob!`**: Writes to both `remote` and `local` (remote first).
- **`fetchBlob`**: Reads from `local` first; on miss, fetches from `remote` and caches locally.
- **`purgeBlob!`**: Purges from both stores.
- **`hasBlob`**: Checks local, falls back to remote.
- **`listBlobs`**: Delegates to remote (the authoritative provider).
"""
struct CachedBlobprovider <: AbstractBlobprovider
    label::Symbol
    local_provider::AbstractBlobprovider
    remote_provider::AbstractBlobprovider
end

function CachedBlobprovider(
    local_provider::AbstractBlobprovider,
    remote_provider::AbstractBlobprovider;
    label::Symbol = :default,
)
    return CachedBlobprovider(label, local_provider, remote_provider)
end

function fetchBlob(store::CachedBlobprovider, m::Multihash)
    blob = fetchBlob(store.local_provider, m)
    !isnothing(blob) && return blob
    blob = fetchBlob(store.remote_provider, m)
    if !isnothing(blob)
        putBlob!(store.local_provider, blob)
    end
    return blob
end

function putBlob!(store::CachedBlobprovider, m::Multihash, blob::Vector{UInt8})
    putBlob!(store.remote_provider, m, blob)
    putBlob!(store.local_provider, m, blob)
    return m
end

function purgeBlob!(store::CachedBlobprovider, m::Multihash)
    rem_num = purgeBlob!(store.remote_provider, m)
    rem_num += purgeBlob!(store.local_provider, m)
    return rem_num
end

function hasBlob(store::CachedBlobprovider, m::Multihash)
    return hasBlob(store.local_provider, m) || hasBlob(store.remote_provider, m)
end

listBlobs(store::CachedBlobprovider) = listBlobs(store.remote_provider)

# ==============================================================================
# LinkBlobprovider — Hardlink existing files into the CAS folder layout
# ==============================================================================

"""
    LinkBlobprovider(folder; label = :default)

A CAS provider that hardlinks existing files into the standard sharded folder
layout (same as `FolderBlobprovider`). This avoids copying large files while
still making them addressable by Multihash.

The specialised `putBlob!(provider, filepath::String)` streams the file to
compute its hash (no full load into RAM), then creates a hardlink at the CAS
path.  All other Layer 1 verbs (`fetchBlob`, `hasBlob`, `purgeBlob!`,
`listBlobs`) behave identically to `FolderBlobprovider`.
"""
struct LinkBlobprovider <: AbstractBlobprovider
    label::Symbol
    folder::String
end

function LinkBlobprovider(foldername::String; label::Symbol = :default, createfolder = true)
    storepath = expanduser(foldername)
    if createfolder && !isdir(storepath)
        @info "Folder '$storepath' doesn't exist - creating."
        mkpath(storepath)
    end
    return LinkBlobprovider(label, foldername)
end

# Shared CAS folder layout — identical to FolderBlobprovider
blobfilename(provider::LinkBlobprovider, m::Multihash) = blobfilename(provider.folder, m)

fetchBlob(provider::LinkBlobprovider, m::Multihash) = fetchBlob_folder(provider.folder, m)

hasBlob(provider::LinkBlobprovider, m::Multihash) = isfile(blobfilename(provider, m))

listBlobs(provider::LinkBlobprovider) = listBlobs_folder(provider.folder)

function purgeBlob!(provider::LinkBlobprovider, m::Multihash)
    return purgeBlob_folder!(provider.folder, m)
end

# Streams the file to compute its Multihash, then hardlinks the file into the
# CAS sharded folder.
function putBlob!(
    provider::LinkBlobprovider,
    filepath::String;
    hash_func::Function = sha2_256,
)
    m = open(filepath, "r") do io
        return Multihash(hash_func, io)
    end
    return putBlob!(provider, m, filepath)
end

function putBlob!(provider::LinkBlobprovider, m::Multihash, filepath::String)
    target_path = blobfilename(provider, m)
    if !isfile(target_path)
        mkpath(dirname(target_path))
        hardlink(filepath, target_path)
    end
    return m
end
