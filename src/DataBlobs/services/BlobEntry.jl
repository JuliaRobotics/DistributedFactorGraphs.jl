
function assertHash(de::AbstractBlobEntry, db; hashfunction = sha256)
    getHash(de) === nothing && @warn "Hey friends, how about some hashing?" && return true
    if  hashfunction(db) == getHash(de)
        return true #or nothing?
    else
        error("Stored hash and data blob hash do not match")
    end
end

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
# addBlob!(dfg::AbstractDFG,  entry::AbstractBlobEntry, blob)
# updateBlob!(dfg::AbstractDFG,  entry::AbstractBlobEntry, blob)
# deleteBlob!(dfg::AbstractDFG,  entry::AbstractBlobEntry)


function getBlob(dfg::AbstractDFG, entry::AbstractBlobEntry)
    error("$(typeof(dfg)) doesn't override 'getBlob'.")
end

function addBlob!(dfg::AbstractDFG, entry::AbstractBlobEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'addBlob!'.")
end

function updateBlob!(dfg::AbstractDFG,  entry::AbstractBlobEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(dfg::AbstractDFG, entry::AbstractBlobEntry)
    error("$(typeof(dfg)) doesn't override 'deleteBlob!'.")
end

function listBlobs(dfg::AbstractDFG)
    error("$(typeof(dfg)) doesn't override 'listBlobs'.")
end

##==============================================================================
## DFG Blob CRUD
##==============================================================================

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

    checkhash && de.hash !== nothing && assertHash(de, db, hashfunction=hashfunction)
    return de=>db
end

function addBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::AbstractBlobEntry, 
    blob::Vector{UInt8}; 
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && de.hash !== nothing && assertHash(entry, blob, hashfunction=hashfunction)
    de = addBlobEntry!(dfg, label, entry)
    db = addBlob!(dfg, de, blob)
    return de=>db
end

function updateBlob!(
    dfg::AbstractDFG, 
    label::Symbol, 
    entry::AbstractBlobEntry, 
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool=true
)
    checkhash && de.hash !== nothing && assertHash(entry, blob, hashfunction=hashfunction)
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
