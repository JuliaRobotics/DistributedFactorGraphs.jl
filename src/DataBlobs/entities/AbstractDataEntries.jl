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
