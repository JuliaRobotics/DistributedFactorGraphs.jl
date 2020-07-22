##==============================================================================
## InMemoryDataEntry Types
##==============================================================================
export InMemoryDataEntry
"""
    $(TYPEDEF)
Store data temporary in memory.
NOTE: Neigher Entry nor Blob will be persisted.
"""
struct InMemoryDataEntry{T} <: AbstractDataEntry
    label::Symbol
    id::UUID
    #hash::String #Is this needed?
    createdTimestamp::ZonedDateTime
    data::T
end

# getHash(::InMemoryDataEntry) = UInt8[]
assertHash(de::InMemoryDataEntry, db; hashfunction = sha256) = true


##==============================================================================
## InMemoryDataEntry Blob CRUD - dit lyk nie of dit gebruik moet word nie
##==============================================================================

getDataBlob(dfg::AbstractDFG, entry::InMemoryDataEntry) = entry.data

# addDataBlob!(dfg::AbstractDFG, entry::InMemoryDataEntry, blob) = error("Not suported")#entry.blob
# updateDataBlob!(dfg::AbstractDFG, entry::InMemoryDataEntry, blob) = error("Not suported")#entry.blob
deleteDataBlob!(dfg::AbstractDFG, entry::InMemoryDataEntry) = entry.data

function addData!(dfg::AbstractDFG, label::Symbol, entry::AbstractDataEntry; hashfunction = sha256)
    # assertHash(entry, entry.data, hashfunction=hashfunction)
    de = addDataEntry!(dfg, label, entry)
    db = getDataBlob(dfg, entry)
    return de=>db
end

function updateData!(dfg::AbstractDFG, label::Symbol,  entry::AbstractDataEntry)
    # assertHash(entry, entry.data, hashfunction=hashfunction)
    de = updateDataEntry!(dfg, label, entry)
    db = getDataBlob(dfg, entry)
    return de=>db
end
##==============================================================================
## InMemoryDataEntry CRUD Helpers
##==============================================================================

# function addData!(dfg::AbstractDFG, label::Symbol, key::Symbol, folder::String, blob::Vector{UInt8}, timestamp=now(localzone());
function addData!(::Type{InMemoryDataEntry}, dfg::AbstractDFG, label::Symbol, key::Symbol, blob, timestamp=now(localzone());
                  id::UUID = uuid4(), hashfunction = sha256)
    fde = InMemoryDataEntry(key, id, timestamp, blob)
    de = addDataEntry!(dfg, label, fde)
    return de=>blob
end
