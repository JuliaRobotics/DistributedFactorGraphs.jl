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

dfg, verts, facs = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)

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
## FolderBlobprovider
##==============================================================================

# Create a data store and add it to DFG
ds = DFG.FolderBlobprovider("/tmp/dfgFolderStore"; label = :filestore)
addBlobprovider!(dfg, ds)

ade = DFG.saveVariableBlob!(dfg, :x1, dataset1, :random, :filestore)
_ = DFG.saveVariableBlob!(dfg, :x1, dataset1, :another_1, :filestore)
gde, gdb = DFG.loadVariableBlob(dfg, :x1, :random)

@test hasBlob(dfg, ade)

@test incrDataLabelSuffix(dfg, :x1, :random) == :random_1
@test incrDataLabelSuffix(dfg, :x1, :another_1) == :another_2
@test incrDataLabelSuffix(dfg, :x1, :another) == :another_2
@test incrDataLabelSuffix(dfg, :x1, "random") == :random_1

deleteVariableBlobentry!(dfg, :x1, :random)
deleteVariableBlobentry!(dfg, :x1, :another_1)

@test ade == gde
@test dataset1 == gdb

ade2 = DFG.saveVariableBlob!(dfg, :x2, dataset1, :random, :filestore)
# ade3,adb3 = updateBlob!(dfg, :x2, deepcopy(ade), dataset1)

deleteVariableBlobentry!(dfg, :x2, :random)

#test default folder store
dfs = DFG.FolderBlobprovider("/tmp/defaultfolderstore")
@test dfs.folder == "/tmp/defaultfolderstore"
@test getLabel(dfs) == :default
@test dfs isa FolderBlobprovider

##==============================================================================
## MemoryBlobprovider
##==============================================================================

# Create a data store and add it to DFG
ds = DFG.MemoryBlobprovider()
addBlobprovider!(dfg, ds)

ade = DFG.saveVariableBlob!(dfg, :x1, dataset1, :random, :default)
gde, gdb = DFG.loadVariableBlob(dfg, :x1, :random)
deleteVariableBlobentry!(dfg, :x1, :random)

@test ade == gde
@test dataset1 == gdb

ade2 = DFG.saveVariableBlob!(dfg, :x2, dataset1, :random, :default)

@test hasBlob(dfg, ade2)
@test hasBlob(ds, ade2.multihash)

@test length(listBlobs(ds)) == 1

deleteVariableBlobentry!(dfg, :x2, :random)

##==============================================================================
## Unimplemented store
##==============================================================================
struct TestStore{T} <: DFG.AbstractBlobprovider end

store = TestStore{Int}()

test_mh = DFG.Multihash(sha2_256, rand(UInt8, 32))
@test_throws MethodError fetchBlob(store, test_mh)
@test_throws MethodError putBlob!(store, rand(UInt8, 10))
@test_throws MethodError purgeBlob!(store, test_mh)
@test_throws MethodError listBlobs(store)
@test_throws MethodError hasBlob(store, test_mh)
