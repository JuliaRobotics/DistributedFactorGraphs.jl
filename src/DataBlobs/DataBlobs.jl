
using SHA

include("entities/AbstractBlobEntries.jl")
include("entities/BlobStores.jl")

include("services/AbstractBlobEntries.jl")
include("services/BlobEntry.jl")
include("services/BlobStores.jl")
include("services/Blob.jl")

# include("services/InMemoryStore.jl")

export InMemoryBlobStore
export FolderStore

export BlobEntry

export getBlob, addBlob!, updateBlob!, deleteBlob!, listBlobEntries
export listBlobs
export BlobEntry
# export copyStore

export getId, getHash, getTimestamp
