using Test
using GraphPlot # For plotting tests
using Neo4j
using DistributedFactorGraphs
using IncrementalInference

# Instantiate the APIs that you would like to test here
# Can do duplicates with different parameters.
apis = [
    GraphsDFG{NoSolverParams}(),
    LightDFG{NoSolverParams}(),
    # DistributedFactorGraphs.MetaGraphsDFG{NoSolverParams}(),
    # DistributedFactorGraphs.SymbolDFG{NoSolverParams}(),
    CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                                "testUser", "testRobot", "testSession",
                                nothing,
                                nothing,
                                IncrementalInference.decodePackedType,
                                IncrementalInference.rebuildFactorMetadata!,
                                solverParams=SolverParams())
]
for api in apis
    @testset "Testing Driver: $(typeof(api))" begin
        @info "Testing Driver: $(api)"
        global dfg = api
        include("iifInterfaceTests.jl")
    end
end

# Test each interface
# Still test LightDFG and MetaGraphsDFG for the moment until we remove in 0.4.2
apis = [
    GraphsDFG,
    DistributedFactorGraphs.MetaGraphsDFG,
    DistributedFactorGraphs.SymbolDFG,
    LightDFG]
for api in apis
    @testset "Testing Driver: $(api)" begin
        @info "Testing Driver: $(api)"
        global testDFGAPI = api
        include("interfaceTests.jl")
    end
end

# Test that we don't export LightDFG and MetaGraphsDFG
@testset "Deprecated Drivers Test" begin
    @test_throws UndefVarError SymbolDFG{NoSolverParams}()
    @test_throws UndefVarError MetaGraphsDFG{NoSolverParams}()
end

# Test special cases

@testset "Plotting Tests" begin
    include("plottingTest.jl")
end

@testset "SummaryDFG test" begin
    @info "Testing LightDFG Variable and Factor Subtypes"
    include("LightDFGSummaryTypes.jl")
end
