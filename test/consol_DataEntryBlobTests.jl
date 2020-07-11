if false
using Test
using GraphPlot
using Neo4j
using DistributedFactorGraphs
using Pkg
using Dates
using UUIDs

include("testBlocks.jl")

testDFGAPI = CloudGraphsDFG
testDFGAPI = LightDFG
end
# Build a basic graph.

testDFGAPI = LightDFG

# Stores to test
testStores = [InMemoryDataStore(), FileDataStore("/tmp/dfgFilestore")]

if false
testStore = testStores[1]
testStore = testStores[2]
end

for testStore in testStores

dfg = testDFGAPI{NoSolverParams}()
var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
fac0, fac1, fac2 = DFGFactorSCA()

addVariable!(dfg, var1)
addVariable!(dfg, var2)
addFactor!(dfg, fac1)
    # Create a data store and a dataset
ds = testStore
# ds = FileDataStore("/tmp/filestore")
dataset = rand(UInt8, 1000)
dataset2 = rand(UInt8, 1000)

entry1 = GeneralDataEntry(dfg, var1, :test1)
# Set it in the store
@test addDataBlob!(ds, entry1, dataset) == dataset
@test getDataBlob(ds, entry1) == dataset
# Now add it to the variable
@test addDataEntry!(var1, entry1) == entry1
@test entry1 in getDataEntries(var1)

@test getDataEntryBlob(dfg, :a, ds, :test1) == (entry1, dataset)

# Update test
copyEntry = deepcopy(entry1)
sleep(0.1)
@test updateDataBlob!(ds, entry1, dataset2) == dataset2
# Data updated?
@test getDataBlob(ds, entry1) == dataset2
# Timestamp updated?
@test entry1.lastUpdatedTimestamp > copyEntry.lastUpdatedTimestamp
# Delete data
@test deleteDataBlob!(ds, entry1) == dataset2
# Delete entry
@test deleteDataEntry!(var1, entry1) == var1

# @test addData!()
gde_td1 = addData!(dfg, :a, ds, :td1, "text/plain", rand(UInt8,10))

td1_entry = getDataEntry(dfg, :a, :td1)
td1_blob = getDataBlob(ds, td1_entry)
@test getDataEntryBlob(dfg, :a, ds, :td1) == (td1_entry, td1_blob)

if testStore == testStores[1]
    liststore = listDataBlobs(ds)
    @test length(liststore) == 1
    @test liststore[1] == td1_entry
end
end


fg = testDFGAPI{NoSolverParams}()
var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
fac0, fac1, fac2 = DFGFactorSCA()

addVariable!(fg, var1)
addVariable!(fg, var2)
addFactor!(fg, fac1)

oid = zeros(UInt8,12); oid[12] = 0x01
de1 = MongodbDataEntry(:key1, NTuple{12,UInt8}(oid))

oid = zeros(UInt8,12); oid[12] = 0x02
de2 = MongodbDataEntry(:key2, NTuple{12,UInt8}(oid))

oid = zeros(UInt8,12); oid[12] = 0x03
de2_update = MongodbDataEntry(:key2, NTuple{12,UInt8}(oid))

#add
v1 = getVariable(fg, :a)
@test addDataEntry!(v1, de1) == de1
@test addDataEntry!(fg, :a, de2) == de2
@test_throws ErrorException addDataEntry!(v1, de1)
@test de2 in getDataEntries(v1)

#get
@test deepcopy(de1) == getDataEntry(v1, :key1)
@test deepcopy(de2) == getDataEntry(fg, :a, :key2)
@test_throws ErrorException getDataEntry(v2, :key1)
@test_throws ErrorException getDataEntry(fg, :b, :key1)

#update
@test updateDataEntry!(fg, :a, de2_update) == de2_update
@test deepcopy(de2_update) == getDataEntry(fg, :a, :key2)
@test @test_logs (:warn, r"does not exist") updateDataEntry!(fg, :b, de2_update) == de2_update

#list
entries = getDataEntries(fg, :a)
@test length(entries) == 2
@test issetequal(map(e->e.key, entries), [:key1, :key2])
@test length(getDataEntries(fg, :b)) == 1

@test issetequal(listDataEntries(fg, :a), [:key1, :key2])
@test listDataEntries(fg, :b) == Symbol[:key2]

#delete
@test deleteDataEntry!(v1, :key1) == v1
@test listDataEntries(v1) == Symbol[:key2]
#delete from dfg
@test deleteDataEntry!(fg, :a, :key2) == v1
@test listDataEntries(v1) == Symbol[]





##

fg = testDFGAPI{NoSolverParams}()
var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
fac0, fac1, fac2 = DFGFactorSCA()

addVariable!(fg, var1)
addVariable!(fg, var2)
addFactor!(fg, fac1)


addData!(fg, :a, :fd1, "/tmp/dfgFilestore/test", rand(UInt8, 100))

de,db = getData(fg, :a, :fd1)


de, db = deleteData!(fg, :a, :fd1)


updateData!(fg, :a, de, rand(UInt8, 100))
