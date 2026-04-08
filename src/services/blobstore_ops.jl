# ==============================================================================
#  Blobstore Operations
# ==============================================================================

"""
    $(SIGNATURES)
Return the internal blobstore dictionary reference for `dfg`.
    """
function refBlobstores end

"""
    $(SIGNATURES)
Add a blobstore to the DFG.
"""
function addBlobstore! end

"""
    $(SIGNATURES)
Get a blobstore by label.
"""
function getBlobstore end

"""
    $(SIGNATURES)
Get all blobstores in the DFG.
"""
function getBlobstores end

"""
    $(SIGNATURES)
Merge a single blobstore link into the DFG (idempotent if identical).
"""
function mergeStorelink! end

"""
    $(SIGNATURES)
Merge a vector of blobstore links into the DFG.
"""
function mergeStorelinks! end

"""
    $(SIGNATURES)
Delete a blobstore by label. Returns 0 if not found.
"""
function deleteBlobstore! end

"""
    $(SIGNATURES)
List all blobstore labels in the DFG.
"""
function listBlobstores end

"""
    $(SIGNATURES)
Check whether a blobstore with the given label exists.
"""
function hasBlobstore end

# ==============================================================================
#  Blob Operations
# ==============================================================================
"""
Get the data blob for the specified Blobstore or DFG.

Related
[`getBlobentry`](@ref)
Implement 
`getBlob(store::AbstractBlobstore, blobid::UUID)`

$(METHODLIST)
"""
function getBlob end

"""
Adds a blob to the Blobstore with the blobid.

Related
[`addBlobentry!`](@ref)
Implement
`addBlob!(store::AbstractBlobstore, blobid::UUID, data)`
$(METHODLIST)
"""
function addBlob! end

"""
Delete a blob from the blob store or dfg with the given entry.

Related
[`deleteBlobentry!`](@ref)
Implement
`deleteBlob!(store::AbstractBlobstore, blobid::UUID)`
$(METHODLIST)
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all `blobid`s in the blob store.
Implement
`listBlobs(store::AbstractBlobstore)`
"""
function listBlobs end

"""
    $(SIGNATURES)
Check if the blob store has a blob with the given `blobid`.
"""
function hasBlob end

# ==============================================================================
# AbstractBlobstore derived CRUD for Blob 
# ==============================================================================
#TODO maybe we should generalize and move the cached Blobstore to DFG.
function getBlob(dfg::AbstractDFG, entry::Blobentry)
    storeLabel = entry.storelabel
    store = getBlobstore(dfg, storeLabel)
    return getBlob(store, entry.blobid)
end

function getBlob(store::AbstractBlobstore, entry::Blobentry)
    return getBlob(store, entry.blobid)
end

#add 
function addBlob!(dfg::AbstractDFG, entry::Blobentry, blob)
    return addBlob!(getBlobstore(dfg, entry.storelabel), entry, blob)
end

function addBlob!(store::AbstractBlobstore{T}, entry::Blobentry, blob::T) where {T}
    return addBlob!(store, entry.blobid, blob)
end

# also creates an blobid as uuid4
addBlob!(store::AbstractBlobstore, blob) = addBlob!(store, uuid4(), blob)

#delete
function deleteBlob!(dfg::AbstractDFG, entry::Blobentry)
    return deleteBlob!(getBlobstore(dfg, entry.storelabel), entry)
end

function deleteBlob!(store::AbstractBlobstore, entry::Blobentry)
    return deleteBlob!(store, entry.blobid)
end

#has
function hasBlob(store::AbstractBlobstore, entry::Blobentry)
    return hasBlob(store, entry.blobid)
end
function hasBlob(dfg::AbstractDFG, entry::Blobentry)
    return hasBlob(getBlobstore(dfg, entry.storelabel), entry.blobid)
end

#TODO Copy is wrong verb here, merge works better, blobs are immutable so id should be enough, but we can maybe check blob and error with merge conflict.
# """
#     $(SIGNATURES)
# Merges all the entries from the source into the destination.
# Can specify which entries to merge with the `sourceEntries` parameter.
# Returns the list of merged entries.
# """
# function mergeBlobstore!(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: Blobentry}
#     # Quick check
#     destEntries = listBlobs(destStore)
#     typeof(sourceEntries) != typeof(destEntries) && error("Can't merge stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
#     # Same source/destination check
#     sourceStore == destStore && error("Can't specify same store for source and destination.")
#     # Otherwise, continue
#     for sourceEntry in sourceEntries
#         addBlob!(destStore, deepcopy(sourceEntry), getBlob(sourceStore, sourceEntry))
#     end
#     return sourceEntries
# end
