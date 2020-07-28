# using DataFrames
# using CSV
using JSON
using SHA

include("entities/AbstractDataEntries.jl")
# include("entities/BlobStores.jl")

include("services/AbstractDataEntries.jl")
include("services/DataEntryBlob.jl")
include("services/BlobStores.jl")

include("services/FileDataEntryBlob.jl")
include("services/InMemoryDataEntryBlob.jl")


export AbstractDataEntry, GeneralDataEntry, MongodbDataEntry, FileDataEntry
export InMemoryDataStore, FileDataStore

export getData, addData!, updateData!, deleteData!, listStoreEntries
export getDataBlob, addDataBlob!, updateDataBlob!, deleteDataBlob!, listDataBlobs
export copyStore

export getId, getHash, getCreatedTimestamp
