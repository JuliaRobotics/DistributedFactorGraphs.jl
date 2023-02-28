
##==============================================================================
## BlobEntry - Defined in src/entities/AbstractDFG.jl
##==============================================================================
# Fields to be implemented
# label
# id

getLabel(entry::BlobEntry) = entry.label
getId(entry::BlobEntry) = entry.id
getHash(entry::BlobEntry) = hex2bytes(entry.hash)
getTimestamp(entry::BlobEntry) = entry.timestamp



function assertHash(
    de::BlobEntry, 
    db::AbstractVector{UInt8}; 
    hashfunction::Function = sha256
)
    getHash(de) === nothing && @warn "Missing hash?" && return true
    if  hashfunction(db) == getHash(de)
        return true #or nothing?
    else
        error("Stored hash and data blob hash do not match")
    end
end


function Base.show(io::IO, entry::BlobEntry) 
    println(io, "_type=BlobEntry {")
    println(io, "  id:            ", entry.id) 
    println(io, "  blobId:        ", entry.blobId) 
    println(io, "  originId:      ", entry.originId) 
    println(io, "  label:         ", entry.label) 
    println(io, "  blobstore:     ", entry.blobstore) 
    println(io, "  hash:          ", entry.hash) 
    println(io, "  origin:        ", entry.origin) 
    println(io, "  description:   ", entry.description) 
    println(io, "  mimeType:      ", entry.mimeType)
    println(io, "  timestamp      ", entry.timestamp)
    println(io, "  _version:      ", entry._version) 
    println(io, "}") 
end 

Base.show(io::IO, ::MIME"text/plain", entry::BlobEntry) = show(io, entry)


##==============================================================================
## DFG BlobBlob CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get the data blob for the specified blobstore or dfg.
"""
function getBlob end

"""
    $(SIGNATURES)
Adds a blob to the blob store or dfg with the given entry.
"""
function addBlob! end

"""
    $(SIGNATURES)
Update a blob to the blob store or dfg with the given entry.
"""
function updateBlob! end

"""
    $(SIGNATURES)
Delete a blob to the blob store or dfg with the given entry.
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all ids in the blob store.
"""
function listBlobs end

##==============================================================================
## Blob CRUD interface
##==============================================================================

"""
Get the data entry and blob for the specified blobstore or dfg retured as a tuple.
Related
[`getBlobEntry`](@ref)

$(METHODLIST)
"""
function getBlob end

"""
Add a data Entry and Blob to a distributed factor graph or BlobStore.
Related
[`addBlobEntry!`](@ref)

$(METHODLIST)
"""
function addBlob! end

"""
Update a data entry or blob to the blob store or dfg.
Related
[`updateBlobEntry!`](@ref)

$(METHODLIST)

DevNotes
- TODO TBD update verb on data since data blobs and entries are restricted to immutable only.
"""
function updateBlob! end

"""
Delete a data entry and blob from the blob store or dfg.
Related
[`deleteBlobEntry!`](@ref)

$(METHODLIST)
"""
function deleteBlob! end

#
# addBlob!(dfg::AbstractDFG,  entry::BlobEntry, blob)
# updateBlob!(dfg::AbstractDFG,  entry::BlobEntry, blob)
# deleteBlob!(dfg::AbstractDFG,  entry::BlobEntry)



function getBlob(dfg::AbstractDFG, entry::BlobEntry)
    error("$(typeof(dfg)) doesn't override 'getBlob', with $(typeof(entry)).")
end

function addBlob!(dfg::AbstractDFG, entry::BlobEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'addBlob!'.")
end

function updateBlob!(dfg::AbstractDFG,  entry::BlobEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(dfg::AbstractDFG, entry::BlobEntry)
    error("$(typeof(dfg)) doesn't override 'deleteBlob!'.")
end

function listBlobs(dfg::AbstractDFG)
    error("$(typeof(dfg)) doesn't override 'listBlobs'.")
end

##==============================================================================
## DFG Blob CRUD
##==============================================================================

# function getBlob(
#     dfg::AbstractDFG,
#     entry::BlobEntry;
#     checkhash::Bool=true,
# )
  
# end

function getBlob(
    dfg::AbstractDFG, 
    vlabel::Symbol, 
    key::Union{Symbol,UUID, <:AbstractString, Regex}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    de_ = getBlobEntry(dfg, vlabel, key)
    _first(s) = s
    _first(s::AbstractVector) = s[1]
    de = _first(de_)
    db = getBlob(dfg, de)

    checkhash && assertHash(de, db, hashfunction=hashfunction)
    return de=>db
end

function addBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && assertHash(entry, blob, hashfunction=hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = addBlob!(dfg, de, blob)
    return de=>db
end

function addBlob!(
    ::Type{<:BlobEntry}, 
    dfg::AbstractDFG, 
    label::Symbol, 
    key::Symbol, 
    blob::AbstractVector{UInt8}, 
    timestamp=now(localzone());
    id::UUID = uuid4(), 
    hashfunction::Function = sha256
)
    fde = BlobEntry(key, id, timestamp, blob)
    de = addBlobEntry!(dfg, label, fde)
    return de=>blob
end

function updateBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::BlobEntry, 
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && assertHash(entry, blob, hashfunction=hashfunction)
    de = updateBlobEntry!(dfg, label, entry)
    db = updateBlob!(dfg, de, blob)
    return de=>db
end

function deleteBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    key::Symbol
)
    de = deleteBlobEntry!(dfg, label, key)
    db = deleteBlob!(dfg, de)
    return de=>db
end
