# using DataFrames
# using CSV
using JSON
using SHA

include("entities/AbstractDataStore.jl")
include("entities/AbstractDataEntries.jl")
include("entities/InMemoryDataStore.jl")
include("entities/FileDataStore.jl")

include("services/AbstractDataStore.jl")
include("services/AbstractDataEntries.jl")
include("services/InMemoryDataStore.jl")
include("services/FileDataStore.jl")

include("services/FileDataEntryBlob.jl")

export AbstractDataStore

export AbstractDataEntry, GeneralDataEntry, MongodbDataEntry, FileDataEntry
export InMemoryDataStore, FileDataStore

export getData, addData!, updateData!, deleteData!, listStoreEntries
export getDataBlob, addDataBlob!, updateDataBlob!, deleteDataBlob!, listDataBlobs
export copyStore
