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

# Create a data store and a dataset
ds = FolderStore{Vector{UInt8}}(:filestore, "/tmp/dfgFilestore")

entry1 = BlobStoreEntry(:random, uuid4(), :filestore, bytes2hex(sha256(dataset1)), "","","", now(localzone()))

ade,adb = addData!(dfg, ds, :x1, entry1, dataset1)
gde,gdb = getData(dfg, ds, :x1, :random)
dde,ddb = deleteData!(dfg, ds, :x1, :random)

@test ade == gde == dde
@test adb == gdb == ddb
