include("entities/AbstractDataStore.jl")
include("entities/AbstractBigDataEntries.jl")
include("entities/InMemoryDataStore.jl")
include("entities/FileDataStore.jl")

include("services/AbstractDataStore.jl")
include("services/AbstractBigDataEntries.jl")
include("services/InMemoryDataStore.jl")
include("services/FileDataStore.jl")

export AbstractDataStore

export AbstractBigDataEntry, GeneralBigDataEntry, MongodbBigDataEntry, FileBigDataEntry
export InMemoryDataStore, FileDataStore

export getBigData, addBigData!, updateBigData!, deleteBigData!, listStoreEntries
export copyStore
