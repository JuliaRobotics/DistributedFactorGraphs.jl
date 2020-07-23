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

testDFGAPI = CloudGraphsDFG
testDFGAPI = LightDFG
end
# Build a basic graph.

testDFGAPI = LightDFG

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

##==============================================================================
## FileDataEntry
##==============================================================================
ade,adb = addData!(FileDataEntry, dfg, :x1, :random, "/tmp/dfgFilestore", dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb

##==============================================================================
## FolderStore
##==============================================================================

# Create a data store and add it to DFG
ds = FolderStore{Vector{UInt8}}(:filestore, "/tmp/dfgFilestore")
addBlobStore!(dfg, ds)

ade,adb = addData!(dfg, :filestore, :x1, :random, dataset1)
gde,gdb = getData(dfg, :x1, :random)
dde,ddb = deleteData!(dfg, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb

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
