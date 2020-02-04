using Test
using GraphPlot # For plotting tests
using Neo4j
using DistributedFactorGraphs
using Pkg
using Dates

## To run the IIF tests, you need a local Neo4j with user/pass neo4j:test
# To run a Docker image
# Install: docker pull neo4j
# Run: docker run -d --publish=7474:7474 --publish=7687:7687 --env NEO4J_AUTH=neo4j/test neo4j
##

# If you want to enable debugging logging (very verbose!)
# using Logging
# logger = SimpleLogger(stdout, Logging.Debug)
# global_logger(logger)

# Test each interface
apis = [
    GraphsDFG,
    LightDFG
    ]
for api in apis
    @testset "Testing Driver: $(api)" begin
        @info "Testing Driver: $(api)"
        global testDFGAPI = api
        include("interfaceTests.jl")
    end
end

# Test special cases
@testset "Plotting Tests" begin
    include("plottingTest.jl")
end

@testset "Data Store Tests" begin
    @test_skip include("DataStoreTests.jl")
end

@testset "Needs-a-Home Tests" begin
    include("needsahomeTests.jl")
end

#=
@testset "LightDFG subtype tests" begin
    for type in [(var=DFGVariableSummary, fac=DFGFactorSummary), (var=SkeletonDFGVariable,fac=SkeletonDFGFactor)]
        @testset "$(type.var) and $(type.fac) tests" begin
            @info "Testing $(type.var) and $(type.fac)"
            global VARTYPE = type.var
            global FACTYPE = type.fac
            include("LightDFGSummaryTypes.jl")
        end
    end
end

if get(ENV, "IIF_TEST", "") == "true"

    # Switch to our upstream test branch.
    Pkg.add(PackageSpec(name="IncrementalInference", rev="upstream/dfg_integration_test"))
    @info "------------------------------------------------------------------------"
    @info "These tests are using IncrementalInference to do additional driver tests"
    @info "------------------------------------------------------------------------"

    using IncrementalInference

    apis = [
        GraphsDFG{NoSolverParams}(),
        LightDFG{NoSolverParams}(),
        DistributedFactorGraphs.SymbolDFG{NoSolverParams}(),
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
            global dfg = deepcopy(api)
            include("iifInterfaceTests.jl")
        end

        @testset "FileDFG Testing Driver: $(typeof(api))" begin
            @info "FileDFG Testing Driver: $(typeof(api))"
            global dfg = deepcopy(api)
            include("fileDFGTests.jl")
        end
    end

    @testset "CGStructure Tests for CGDFG" begin
        # Run the CGStructure tests
        include("CGStructureTests.jl")
    end

    # Simple graph solving test
    @testset "Simple graph solving test" begin
        # This is just to validate we're not going to blow up downstream.
        apis = [
            GraphsDFG{SolverParams}(params=SolverParams()),
            LightDFG{SolverParams}(params=SolverParams())]
        for api in apis
            @info "Running simple solver test: $(typeof(api))"
            global dfg = deepcopy(api)
            include("solveTest.jl")
        end
    end
else
    @warn "Skipping IncrementalInference driver tests"
end
=#
