if false
    using Test
    using GraphMakie
    using DistributedFactorGraphs
    using Pkg
    using Dates
    using UUIDs
    using TimeZones
    using SHA

    include("testBlocks.jl")
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

# @test :random in listBlobentries(dfg, :x2)
# @test length(listBlobentries(dfg, :x1)) === 0
# @test length(listBlobentries(dfg, :x2)) === 1

# mergeBlobentries!(dfg, :x1, dfg, :x2, :random)

# @test length(listBlobentries(dfg, :x1)) === 1
# @test :random in listBlobentries(dfg, :x1)
# @test length(listBlobentries(dfg, :x2)) === 1

# deleteBlob!(dfg, :x1, :random)
# deleteBlob!(dfg, :x2, :random)

# @test length(listBlobentries(dfg, :x1)) === 0
# @test length(listBlobentries(dfg, :x2)) === 0

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
ds = FolderStore("/tmp/dfgFolderStore"; label = :filestore)
addBlobstore!(dfg, ds)

ade = DFG.saveBlob_Variable!(dfg, :x1, dataset1, :random, :filestore)
_ = DFG.saveBlob_Variable!(dfg, :x1, dataset1, :another_1, :filestore)
gde, gdb = DFG.loadBlob_Variable(dfg, :x1, :random)

@test hasBlob(dfg, ade)

@test incrDataLabelSuffix(dfg, :x1, :random) == :random_1
@test incrDataLabelSuffix(dfg, :x1, :another_1) == :another_2
@test incrDataLabelSuffix(dfg, :x1, :another) == :another_2
@test incrDataLabelSuffix(dfg, :x1, "random") == :random_1

@test DFG.deleteBlob_Variable!(dfg, :x1, :random) == 2
@test DFG.deleteBlob_Variable!(dfg, :x1, :another_1) == 2

@test ade == gde
@test dataset1 == gdb

ade2 = DFG.saveBlob_Variable!(dfg, :x2, dataset1, :random, :filestore)
# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

DFG.deleteBlob_Variable!(dfg, :x2, :random)

#test default folder store
dfs = FolderStore("/tmp/defaultfolderstore")
@test dfs.folder == "/tmp/defaultfolderstore"
@test getLabel(dfs) == :default
@test dfs isa FolderStore{Vector{UInt8}}

##==============================================================================
## InMemoryBlobstore
##==============================================================================

# Create a data store and add it to DFG
ds = InMemoryBlobstore()
addBlobstore!(dfg, ds)

ade = DFG.saveBlob_Variable!(dfg, :x1, dataset1, :random, :default_inmemory_store)
gde, gdb = DFG.loadBlob_Variable(dfg, :x1, :random)
@test DFG.deleteBlob_Variable!(dfg, :x1, :random) == 2

@test ade == gde
@test dataset1 == gdb

ade2 = DFG.saveBlob_Variable!(dfg, :x2, dataset1, :random, :default_inmemory_store)
# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

@test hasBlob(dfg, ade2)
@test hasBlob(ds, ade2.blobId)

@test length(listBlobs(ds)) == 1

@test DFG.deleteBlob_Variable!(dfg, :x2, :random) == 2

##==============================================================================
## Unimplemented store
##==============================================================================
struct TestStore{T} <: DFG.AbstractBlobstore{T} end

store = TestStore{Int}()

@test_throws MethodError getBlob(store, ade)
@test_throws MethodError addBlob!(store, ade, 1)
@test_throws MethodError deleteBlob!(store, ade)
@test_throws MethodError listBlobs(store)
@test_throws MethodError hasBlob(store, uuid4())
