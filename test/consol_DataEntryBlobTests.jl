if false
using Test
using GraphPlot
using Neo4j
using DistributedFactorGraphs
using Pkg
using Dates
using UUIDs
using TimeZones
using SHA

include("testBlocks.jl")

testDFGAPI = Neo4jDFG
testDFGAPI = GraphsDFG
end
# Build a basic graph.

testDFGAPI = GraphsDFG

##==============================================================================
## DataEntry Blobs
##==============================================================================

dfg, verts, facs = connectivityTestGraph(testDFGAPI)

dataset1 = rand(UInt8, 1000)
dataset2 = rand(UInt8, 1000)

##==============================================================================
## InMemoryDataEntry
##==============================================================================
ade,adb = addData!(InMemoryDataEntry, dfg, :x1, :random, dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb

# @test_throws ErrorException addData!(dfg, :x2, deepcopy(ade), dataset2)
ade2,adb2 = addData!(dfg, :x2, deepcopy(ade))

ade3,adb3 = updateData!(dfg, :x2, deepcopy(ade))

@test ade == ade2 == ade3
@test adb == adb2 == adb3

deleteData!(dfg, :x2, :random)

##==============================================================================
## FileDataEntry
##==============================================================================
ade,adb = addData!(FileDataEntry, dfg, :x1, :random, "/tmp/dfgFileEntryBlob", dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb


@test_throws ErrorException addData!(dfg, :x2, deepcopy(ade), dataset2)

ade2,adb2 = addData!(dfg, :x2, deepcopy(ade), dataset1)
ade3,adb3  = updateData!(dfg, :x2, deepcopy(ade), dataset1)

@test ade == ade2 == ade3
@test adb == adb2 == adb3

deleteData!(dfg, :x2, :random)

##==============================================================================
## FolderStore
##==============================================================================

# Create a data store and add it to DFG
ds = FolderStore{Vector{UInt8}}(:filestore, "/tmp/dfgFolderStore")
addBlobStore!(dfg, ds)

ade,adb = addData!(dfg, :filestore, :x1, :random, dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb

ade2,adb2 = addData!(dfg, :x2, deepcopy(ade), dataset1)
# ade3,adb3 = updateData!(dfg, :x2, deepcopy(ade), dataset1)

@test ade == ade2# == ade3
@test adb == adb2# == adb3

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

ade,adb = addData!(dfg, :default_inmemory_store, :x1, :random, dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb

ade2,adb2 = addData!(dfg, :x2, deepcopy(ade), dataset1)
# ade3,adb3 = updateData!(dfg, :x2, deepcopy(ade), dataset1)

@test ade == ade2# == ade3
@test adb == adb2# == adb3

deleteData!(dfg, :x2, :random)

##==============================================================================
## Unimplemented store
##==============================================================================
struct TestStore{T} <: DFG.AbstractBlobStore{T} end

store = TestStore{Int}()

@test_throws ErrorException getDataBlob(store, ade)
@test_throws ErrorException addDataBlob!(store, ade, 1)
@test_throws ErrorException updateDataBlob!(store,  ade, 1)
@test_throws ErrorException deleteDataBlob!(store, ade)
@test_throws ErrorException listDataBlobs(store)


##==============================================================================
## Unimplemented Entry Blob Crud
##==============================================================================
struct NotImplementedDE <: AbstractDataEntry end

nde = NotImplementedDE()

@test_throws ErrorException getDataBlob(dfg, nde)
@test_throws ErrorException addDataBlob!(dfg, nde, 1)
@test_throws ErrorException updateDataBlob!(dfg,  nde, 1)
@test_throws ErrorException deleteDataBlob!(dfg, nde)
@test_throws ErrorException listDataBlobs(dfg)
