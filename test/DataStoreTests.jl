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
end
# Build a basic graph.

testDFGAPI = LightDFG
dfg = testDFGAPI{NoSolverParams}()
#add types for softtypes
# struct TestInferenceVariable1 <: InferenceVariable end
# v1 = DFGVariable(:a, TestInferenceVariable1())
# v2 = DFGVariable(:b, TestInferenceVariable1())
# f1 = DFGFactor{TestFunctorInferenceType1}(:f1, [:a,:b]);
# #add tags for filters
# union!(v1.tags, [:VARIABLE, :POSE])
# union!(v2.tags, [:VARIABLE, :LANDMARK])
# union!(f1.tags, [:FACTOR])
# # @testset "Creating Graphs" begin

var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
fac0, fac1, fac2 = DFGFactorSCA()

addVariable!(dfg, var1)
addVariable!(dfg, var2)
addFactor!(dfg, fac1)

# Stores to test
testStores = [InMemoryDataStore(), FileDataStore("/tmp/dfgFilestore")]

if false
testStore = testStores[1]
testStore = testStores[2]
end

for testStore in testStores
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
# gde_td1 = DFG.addData!(dfg, :a, ds, :td1, "text/plain", rand(UInt8,10))
# DFG.getDataEntryBlob(dfg, :a, ds, :td1)
#
#
#
# @test getDataBlob(ds, entry1) == dataset2

#TODO
    #listStoreEntries(ds)
end

1320*4

3600+2200
