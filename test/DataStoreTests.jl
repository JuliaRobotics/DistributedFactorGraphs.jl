using DistributedFactorGraphs
using Test

# Build a basic graph.

dfg = LightDFG{NoSolverParams}()
#add types for softtypes
struct TestInferenceVariable1 <: InferenceVariable end
v1 = DFGVariable(:a, TestInferenceVariable1())
v2 = DFGVariable(:b, TestInferenceVariable1())
f1 = DFGFactor{TestFunctorInferenceType1, Symbol}(:f1)
#add tags for filters
union!(v1.tags, [:VARIABLE, :POSE])
union!(v2.tags, [:VARIABLE, :LANDMARK])
union!(f1.tags, [:FACTOR])
# @testset "Creating Graphs" begin
addVariable!(dfg, v1)
addVariable!(dfg, v2)
addFactor!(dfg, [v1, v2], f1)

# Stores to test
testStores = [InMemoryDataStore(), FileDataStore("/tmp/dfgFilestore")]

for testStore in testStores
    # Create a data store and a dataset
    ds = testStore
    # ds = FileDataStore("/tmp/filestore")
    dataset = rand(UInt8, 1000)
    dataset2 = rand(UInt8, 1000)

    entry1 = GeneralBigDataEntry(dfg, v1, :test1)
    # Set it in the store
    @test addBigData!(ds, entry1, dataset) == dataset
    @test getBigData(ds, entry1) == dataset
    # Now add it to the variable
    @test addBigDataEntry!(v1, entry1) == entry1
    @test entry1 in getBigDataEntries(v1)
    # Update test
    copyEntry = deepcopy(entry1)
    sleep(0.1)
    @test updateBigData!(ds, entry1, dataset2) == dataset2
    # Data updated?
    @test getBigData(ds, entry1) == dataset2
    # Timestamp updated?
    @test entry1.lastUpdatedTimestamp > copyEntry.lastUpdatedTimestamp
    # Delete data
    @test deleteBigData!(ds, entry1) == dataset2
    # Delete entry
    @test deleteBigDataEntry!(v1, entry1) == v1
    #TODO
    #listStoreEntries(ds)
end
