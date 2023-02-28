# using BlobFrames
# using CSV
using JSON
using SHA

include("entities/AbstractBlobEntries.jl")
include("entities/BlobStores.jl")

include("services/AbstractBlobEntries.jl")
include("services/BlobEntry.jl")
include("services/BlobStores.jl")

include("services/InMemoryStore.jl")


export BlobEntry

export getBlob, addBlob!, updateBlob!, deleteBlob!, listBlobEntries
export getBlobBlob, addBlob!, updateBlob!, deleteBlob!, listBlobs
export copyStore

export getId, getHash, getTimestamp
