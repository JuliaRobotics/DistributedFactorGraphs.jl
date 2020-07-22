
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

#
# addDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry, blob)
# updateDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry, blob)
# deleteDataBlob!(dfg::AbstractDFG,  entry::AbstractDataEntry)

function getDataBlob(dfg::AbstractDFG, entry::AbstractDataEntry)
    error("$(typeof(store)) doesn't override 'getDataBlob'.")
end

function addDataBlob!(dfg::AbstractDFG, entry::BlobStoreEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'addDataBlob!'.")
end

function updateDataBlob!(dfg::AbstractDFG,  entry::BlobStoreEntry, data::T) where T
    error("$(typeof(store)) doesn't override 'updateDataBlob!'.")
end

function deleteDataBlob!(dfg::AbstractDFG, entry::BlobStoreEntry)
    error("$(typeof(store)) doesn't override 'deleteDataBlob!'.")
end

function listDataBlobs(dfg::AbstractDFG)
    error("$(typeof(store)) doesn't override 'listDataBlobs'.")
end

##==============================================================================
## DFG Data CRUD
##==============================================================================

function getData(dfg::AbstractDFG, label::Symbol, key::Symbol; hashfunction = sha256)
    de = getDataEntry(dfg, label, key)
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

function updateData!(dfg::AbstractDFG, label::Symbol,  entry::AbstractDataEntry,  blob::Vector{UInt8})
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
