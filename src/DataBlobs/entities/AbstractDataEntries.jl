##==============================================================================
## AbstractDataEntry - Defined in src/entities/AbstractDFG.jl
##==============================================================================
# Fields to be implemented
# label
# id

getLabel(entry::AbstractDataEntry) = entry.label
getId(entry::AbstractDataEntry) = entry.id
getHash(entry::AbstractDataEntry) = hex2bytes(entry.hash)
getCreatedTimestamp(entry::AbstractDataEntry) = entry.createdTimestamp


##==============================================================================
## BlobStoreEntry
##==============================================================================
export BlobStoreEntry

"""
    $(TYPEDEF)
Genaral Data Store Entry.
"""
struct BlobStoreEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    blobstore::Symbol
    hash::String # Probably https://docs.julialang.org/en/v1/stdlib/SHA
    origin::String # E.g. user|robot|session|varlabel
    description::String
    mimeType::String
    createdTimestamp::ZonedDateTime # of when the entry was created
end

# TODO
"""
    $(TYPEDEF)
Data Entry in MongoDB.
"""
struct MongodbDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    oid::NTuple{12, UInt8} #mongodb object id - TODO Not needed with id::UUID unique, but perhaps usefull
    hash::String
    createdTimestamp::ZonedDateTime
    # mongodb
    # mongoConfig::MongoConfig
    #maybe other fields such as:
    #flags::Bool ready, valid, locked, permissions
    #MIMEType::String
end


##==============================================================================
## FileDataEntryBlob Types
##==============================================================================
export FileDataEntry
"""
    $(TYPEDEF)
Data Entry in a file.
"""
struct FileDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    folder::String
    hash::String #using bytes2hex or perhaps Vector{Uint8}?
    createdTimestamp::ZonedDateTime

    function FileDataEntry(label, id, folder, hash, timestamp)
        if !isdir(folder)
            @info "Folder '$folder' doesn't exist - creating."
            # create new folder
            mkpath(folder)
        end
        return new(label, id, folder, hash, timestamp)
    end
end


##==============================================================================
## InMemoryDataEntry Types
##==============================================================================
export InMemoryDataEntry
"""
    $(TYPEDEF)
Store data temporary in memory.
NOTE: Neither Entry nor Blob will be persisted.
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
