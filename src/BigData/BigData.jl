include("entities/AbstractDataStore.jl")
include("entities/AbstractBigDataEntries.jl")
include("entities/InMemoryDataStore.jl")
include("entities/FileDataStore.jl")

include("services/AbstractDataStore.jl")
include("services/AbstractBigDataEntries.jl")
include("services/InMemoryDataStore.jl")
include("services/FileDataStore.jl")

export AbstractDataStore

export AbstractBigDataEntry, GeneralDataEntry, MongodbDataEntry, FileDataEntry
export InMemoryDataStore, FileDataStore

export getData, addData!, updateData!, deleteData!, listStoreEntries
export getDataBlob, addDataBlob!, updateDataBlob!, deleteDataBlob!, listDataBlobs
export copyStore
