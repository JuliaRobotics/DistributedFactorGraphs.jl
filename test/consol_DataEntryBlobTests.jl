if false
    using Test
    using GraphPlot
    using DistributedFactorGraphs
    using Pkg
    using Dates
    using UUIDs
    using TimeZones
    using SHA

    include("testBlocks.jl")

    # import DistributedFactorGraphs: addData!, updateData!, getData, deleteData!

end

# Build a basic graph.

testDFGAPI = GraphsDFG

##==============================================================================
## DataEntry Blobs
##==============================================================================

dfg, verts, facs = connectivityTestGraph(testDFGAPI)

dataset1 = rand(UInt8, 1000)
dataset2 = rand(UInt8, 1000)

# ##==============================================================================
# ## InMemoryDataEntry
# ##==============================================================================
# ade,adb = addBlob!(InMemoryDataEntry, dfg, :x1, :random, dataset1)
# gde,gdb = getBlob(dfg, :x1, :random)
# dde,ddb = deleteBlob!(dfg, :x1, :random)

# @test ade == gde == dde
# @test adb == gdb == ddb

# # @test_throws ErrorException addBlob!(dfg, :x2, deepcopy(ade), dataset2)
# ade2,adb2 = addBlob!(dfg, :x2, deepcopy(ade))

# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade))

# @test ade == ade2 == ade3
# @test adb == adb2 == adb3

# @test :random in listBlobEntries(dfg, :x2)
# @test length(listBlobEntries(dfg, :x1)) === 0
# @test length(listBlobEntries(dfg, :x2)) === 1

# mergeBlobEntries!(dfg, :x1, dfg, :x2, :random)

# @test length(listBlobEntries(dfg, :x1)) === 1
# @test :random in listBlobEntries(dfg, :x1)
# @test length(listBlobEntries(dfg, :x2)) === 1

# deleteBlob!(dfg, :x1, :random)
# deleteBlob!(dfg, :x2, :random)

# @test length(listBlobEntries(dfg, :x1)) === 0
# @test length(listBlobEntries(dfg, :x2)) === 0

# ##==============================================================================
# ## FileDataEntry
# ##==============================================================================
# ade,adb = addBlob!(FileDataEntry, dfg, :x1, :random, "/tmp/dfgFileEntryBlob", dataset1)
# gde,gdb = getBlob(dfg, :x1, :random)
# dde,ddb = deleteBlob!(dfg, :x1, :random)

# @test ade == gde == dde
# @test adb == gdb == ddb

# @test_throws ErrorException addBlob!(dfg, :x2, deepcopy(ade), dataset2)

# ade2,adb2 = addBlob!(dfg, :x2, deepcopy(ade), dataset1)
# ade3,adb3  = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

# @test ade == ade2 == ade3
# @test adb == adb2 == adb3

# deleteBlob!(dfg, :x2, :random)

##==============================================================================
## FolderStore
##==============================================================================

# Create a data store and add it to DFG
mkdir("/tmp/dfgFolderStore")
ds = FolderStore{Vector{UInt8}}(:filestore, "/tmp/dfgFolderStore")
addBlobStore!(dfg, ds)

ade = addData!(dfg, :filestore, :x1, :random, dataset1)
_ = addData!(dfg, :filestore, :x1, :another_1, dataset1)
_, _ = getData(dfg, :x1, "random")
_, _ = getData(dfg, :x1, r"rando")
gde, gdb = getData(dfg, :x1, :random)

@test hasBlob(dfg, ade)

@show gde

@test incrDataLabelSuffix(dfg, :x1, :random) == :random_1
@test incrDataLabelSuffix(dfg, :x1, :another_1) == :another_2
# @test incrDataLabelSuffix(dfg,:x1,:another) == :another_2 # TODO exand support for Regex likely search on labels
# @test incrDataLabelSuffix(dfg,:x1,"random") == "random_1" # TODO expand support for label::String

dde, ddb = deleteData!(dfg, :x1, :random)
_, _ = deleteData!(dfg, :x1, :another_1)

@test ade == gde == dde
@test dataset1 == gdb == ddb

ade2 = addData!(dfg, :x2, deepcopy(ade), dataset1)
# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

@test ade == ade2# == ade3
# @test adb == adb2# == adb3

deleteData!(dfg, :x2, :random)

#test default folder store
dfs = FolderStore("/tmp/defaultfolderstore")
@test dfs.folder == "/tmp/defaultfolderstore"
@test dfs.key == :default_folder_store
@test dfs isa FolderStore{Vector{UInt8}}

##==============================================================================
## InMemoryBlobStore
##==============================================================================

# Create a data store and add it to DFG
ds = InMemoryBlobStore()
addBlobStore!(dfg, ds)

ade = addData!(dfg, :default_inmemory_store, :x1, :random, dataset1)
gde, gdb = getData(dfg, :x1, :random)
dde, ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test dataset1 == gdb == ddb

ade2 = addData!(dfg, :x2, deepcopy(ade), dataset1)
# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

@test hasBlob(dfg, ade2)
@test hasBlob(ds, ade2.blobId)

@test length(listBlobs(ds)) == 1

@test ade == ade2# == ade3
# @test adb == adb2# == adb3

deleteData!(dfg, :x2, :random)

##==============================================================================
## Unimplemented store
##==============================================================================
struct TestStore{T} <: DFG.AbstractBlobStore{T} end

store = TestStore{Int}()

@test_throws ErrorException getBlob(store, ade)
@test_throws ErrorException addBlob!(store, ade, 1)
@test_throws ErrorException updateBlob!(store, ade, 1)
@test_throws ErrorException deleteBlob!(store, ade)
@test_throws ErrorException listBlobs(store)
@test_throws ErrorException hasBlob(store, uuid4())
