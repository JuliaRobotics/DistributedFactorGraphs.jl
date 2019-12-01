include("entities/AbstractDataStore.jl")
include("entities/DataEntries.jl")
include("entities/InMemoryDataStore.jl")
include("entities/FileDataStore.jl")

include("services/AbstractDataStore.jl")
include("services/InMemoryDataStore.jl")
include("services/FileDataStore.jl")

export AbstractDataStore

export GeneralBigDataEntry, MongodbBigDataEntry, FileBigDataEntry
export InMemoryDataStore, FileDataStore

export getBigData, addBigData!, updateBigData!, deleteBigData!, listStoreEntries
export copyStore
