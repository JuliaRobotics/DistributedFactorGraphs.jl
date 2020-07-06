include("entities/AbstractDataStore.jl")
#TODO Rename to AbstractDataEntries
include("entities/AbstractBigDataEntries.jl")
include("entities/InMemoryDataStore.jl")
include("entities/FileDataStore.jl")

include("services/AbstractDataStore.jl")
#TODO Rename to AbstractDataEntries
include("services/AbstractBigDataEntries.jl")
include("services/InMemoryDataStore.jl")
include("services/FileDataStore.jl")

export AbstractDataStore

export AbstractDataEntry, GeneralDataEntry, MongodbDataEntry, FileDataEntry
export InMemoryDataStore, FileDataStore

export getData, addData!, updateData!, deleteData!, listStoreEntries
export getDataBlob, addDataBlob!, updateDataBlob!, deleteDataBlob!, listDataBlobs
export copyStore
