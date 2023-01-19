using Test
using GraphPlot # For plotting tests
using DistributedFactorGraphs
using Pkg
using Dates
using TimeZones
using SHA
using UUIDs

## To run the IIF tests, you need a local Neo4j with user/pass neo4j:test
# To run a Docker image
# NOTE: that Neo4j.jl doesn't currently support > Neo4j 3.x
# Install: docker pull neo4j:3.5.6
# Run: docker run -d --publish=7474:7474 --publish=7687:7687 --env NEO4J_AUTH=neo4j/test neo4j:3.5.6
##

# If you want to enable debugging logging (very verbose!)
# using Logging
# logger = SimpleLogger(stdout, Logging.Debug)
# global_logger(logger)

include("testTranscodeTypeUnmarshaling.jl")
include("test_defVariable.jl")

include("testBlocks.jl")

@testset "Test generated ==" begin
    include("compareTests.jl")
end

@testset "Testing LightDFG.FactorGraphs functions" begin
    include("LightFactorGraphsTests.jl")
end


apis = [
    GraphsDFG,
    LightDFG,
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
    include("consol_DataEntryBlobTests.jl")
end

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

    apis = Vector{AbstractDFG}()
    push!(apis, GraphsDFG(solverParams=SolverParams(), userId="test@navability.io"))

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

    @testset "IIF Compare Tests" begin
        #run a copy of compare tests from IIF
        include("iifCompareTests.jl")
    end

    # Simple graph solving test
    @testset "Simple graph solving test" begin
        # This is just to validate we're not going to blow up downstream.
        apis = [
            # GraphsDFG{SolverParams}(),
            LightDFG(solverParams=SolverParams(), userId="test@navability.io"),
            ]
        for api in apis
            @info "Running simple solver test: $(typeof(api))"
            global dfg = deepcopy(api)
            include("solveTest.jl")
        end
    end
else
    @warn "Skipping IncrementalInference driver tests"
end


struct NotImplementedDFG{T} <: AbstractDFG{T} end

@testset "No Interface tests" begin
    dfg = NotImplementedDFG{NoSolverParams}()
    v1 = SkeletonDFGVariable(:v1)
    f1 = SkeletonDFGFactor(:f1)

    @test_throws ErrorException exists(dfg, v1)
    @test_throws ErrorException exists(dfg, f1)

    @test_throws ErrorException exists(dfg, :s)
    @test_throws ErrorException addVariable!(dfg, v1)

    @test_throws ErrorException getVariable(dfg, :a)
    @test_throws ErrorException getFactor(dfg, :a)
    @test_throws ErrorException updateVariable!(dfg, v1)
    @test_throws ErrorException updateFactor!(dfg, f1)

    @test_throws ErrorException deleteVariable!(dfg, :a)
    @test_throws ErrorException deleteFactor!(dfg, :a)
    @test_throws ErrorException getVariables(dfg)
    @test_throws ErrorException getFactors(dfg)
    @test_throws ErrorException isConnected(dfg)
    @test_throws ErrorException getNeighbors(dfg, v1)
    @test_throws ErrorException getNeighbors(dfg, :a)

    @test_throws ErrorException _getDuplicatedEmptyDFG(dfg)

    @test_throws ErrorException isVariable(dfg, :a)
    @test_throws ErrorException isFactor(dfg, :a)

end
