
function assertHash(de::AbstractDataEntry, db; hashfunction = sha256)
    if  hashfunction(db) == getHash(de)
        return true #or nothing?
    else
        error("Stored hash and data blob hash do not match")
    end
end

##==============================================================================
## DFG DataBlob CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get the data blob for the specified blobstore or dfg.
"""
function getDataBlob end

"""
    $(SIGNATURES)
Adds a blob to the blob store or dfg with the given entry.
"""
function addDataBlob! end

"""
    $(SIGNATURES)
Update a blob to the blob store or dfg with the given entry.
"""
function updateDataBlob! end

"""
    $(SIGNATURES)
Delete a blob to the blob store or dfg with the given entry.
"""
function deleteDataBlob! end

"""
    $(SIGNATURES)
List all ids in the blob store.
"""
function listDataBlobs end

##==============================================================================
## Data CRUD interface
##==============================================================================

"""
Get the data entry and blob for the specified blobstore or dfg retured as a tuple.
Related
[`getDataEntry`](@ref)

$(METHODLIST)
"""
function getData end

"""
Add a data Entry and Blob to a distributed factor graph or BlobStore.
Related
[`addDataEntry!`](@ref)

$(METHODLIST)
"""
function addData! end

"""
Update a data entry or blob to the blob store or dfg.
Related
[`updateDataEntry!`](@ref)

$(METHODLIST)
"""
function updateData! end

"""
Delete a data entry and blob from the blob store or dfg.
Related
[`deleteDataEntry!`](@ref)

$(METHODLIST)
"""
function deleteData! end

#
# addDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry, blob)
# updateDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry, blob)
# deleteDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry)


function getDataBlob(dfg::AbstractDFG, entry::AbstractDataEntry)
    error("$(typeof(dfg)) doesn't override 'getDataBlob'.")
end

function addDataBlob!(dfg::AbstractDFG, entry::AbstractDataEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'addDataBlob!'.")
end

function updateDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry, data::T) where T
    error("$(typeof(dfg)) doesn't override 'updateDataBlob!'.")
end

function deleteDataBlob!(dfg::AbstractDFG, entry::AbstractDataEntry)
    error("$(typeof(dfg)) doesn't override 'deleteDataBlob!'.")
end

function listDataBlobs(dfg::AbstractDFG)
    error("$(typeof(dfg)) doesn't override 'listDataBlobs'.")
end

##==============================================================================
## DFG Data CRUD
##==============================================================================

function getData(
    dfg::AbstractDFG, 
    vlabel::Symbol, 
    key::Union{Symbol,UUID}; 
    hashfunction = sha256
)
    de = getDataEntry(dfg, vlabel, key)
    db = getDataBlob(dfg, de)

    assertHash(de, db, hashfunction=hashfunction)
    return de=>db
end

function addData!(dfg::AbstractDFG, label::Symbol, entry::AbstractDataEntry, blob::Vector{UInt8}; hashfunction = sha256)
    assertHash(entry, blob, hashfunction=hashfunction)
    de = addDataEntry!(dfg, label, entry)
    db = addDataBlob!(dfg, de, blob)
    return de=>db
end

function updateData!(dfg::AbstractDFG, label::Symbol,  entry::AbstractDataEntry,  blob::Vector{UInt8}; hashfunction = sha256)
    assertHash(entry, blob, hashfunction=hashfunction)
    de = updateDataEntry!(dfg, label, entry)
    db = updateDataBlob!(dfg, de, blob)
    return de=>db
end

function deleteData!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    de = deleteDataEntry!(dfg, label, key)
    db = deleteDataBlob!(dfg, de)
    return de=>db
end
