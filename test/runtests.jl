using Test
using GraphPlot # For plotting tests
using Neo4j
using DistributedFactorGraphs
using Pkg

# Instantiate the APIs that you would like to test here
# Can do duplicates with different parameters.
apis = [
    GraphsDFG{NoSolverParams}(),
    LightDFG{NoSolverParams}(),
    DistributedFactorGraphs.MetaGraphsDFG{NoSolverParams}(),
    DistributedFactorGraphs.SymbolDFG{NoSolverParams}(),
    # CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
    #                             "testUser", "testRobot", "testSession",
    #                             nothing,
    #                             nothing,
    #                             IncrementalInference.decodePackedType,
    #                             IncrementalInference.rebuildFactorMetadata!,
    #                             solverParams=SolverParams())
        ]
for api in apis
    @testset "Testing Driver: $(typeof(api))" begin
        @info "Testing Driver: $(api)"
        global dfg = deepcopy(api)
        include("interfaceTests.jl")
    end
end

if haskey(Pkg.installed(), "IncrementalInference")
    @info "------------------------------------------------------------------------"
    @info "These tests are using IncrementalInference to do additional driver tests"
    @info "------------------------------------------------------------------------"

    using IncrementalInference

    @info "------------------------------------------------------------------------"
    @info "Neo4J Travis Test"
    @info "------------------------------------------------------------------------"
    using Neo4j
    neo4jConnection = Neo4j.Connection("localhost", port=7474, user="neo4j", password="neo4j");
    graph = getgraph(neo4jConnection);
    @info "NEO4J graph:" + graph

    apis = [
        GraphsDFG{NoSolverParams}(),
        LightDFG{NoSolverParams}(),
        # MetaGraphsDFG{NoSolverParams}(),
        # SymbolDFG{NoSolverParams}(),
        # CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
        #                             "testUser", "testRobot", "testSession",
        #                             nothing,
        #                             nothing,
        #                             IncrementalInference.decodePackedType,
        #                             IncrementalInference.rebuildFactorMetadata!,
        #                             solverParams=SolverParams())
            ]
    for api in apis
        @testset "Testing Driver: $(typeof(api))" begin
            @info "Testing Driver: $(api)"
            global dfg = deepcopy(api)
            include("iifInterfaceTests.jl")
        end
    end
else
    @warn "Skipping IncrementalInference driver tests"
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
