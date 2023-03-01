
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


