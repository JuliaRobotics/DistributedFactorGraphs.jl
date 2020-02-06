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

# TODO, dink meer aan: Trait based softtypes or hard type for VariableNodeData
# Test InferenceVariable Types
struct TestSofttype1 <: InferenceVariable
    dims::Int
    manifolds::Tuple{Symbol}
    TestSofttype1() = new(1,(:Euclid,))
end

struct TestSofttype2 <: InferenceVariable
    dims::Int
    manifolds::Tuple{Symbol, Symbol}
    TestSofttype2() = new(2,(:Euclid,:Circular,))
end


# Test Factor Types TODO same with factor type if I can figure out what it is and how it works
struct TestFunctorInferenceType1 <: FunctorInferenceType end

struct TestCCW1{T} <: ConvolutionObject where {T<:FunctorInferenceType} end


@testset "Test generated ==" begin
    include("compareTests.jl")
end

# Test each interface
apis = [
    LightDFG,
    GraphsDFG,
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
    include("DataStoreTests.jl")
end

@testset "Needs-a-Home Tests" begin
    include("needsahomeTests.jl")
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
    Pkg.add(PackageSpec(name="IncrementalInference", rev="develop"))
    @info "------------------------------------------------------------------------"
    @info "These tests are using IncrementalInference to do additional driver tests"
    @info "------------------------------------------------------------------------"

    using IncrementalInference

    apis = [
        GraphsDFG{SolverParams}(),
        LightDFG{SolverParams}(),
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

struct NotImplementedDFG <: AbstractDFG end


@testset "No Interface tests" begin
    dfg = NotImplementedDFG()
    v1 = SkeletonDFGVariable(:v1)
    f1 = SkeletonDFGFactor(:f1)

    @test_throws ErrorException exists(dfg, v1)
    @test_throws ErrorException exists(dfg, f1)
    #TODO FIXME
    # @test_throws ErrorException exists(dfg, :s)
    @test_throws ErrorException addVariable!(dfg, v1)
    @test_throws ErrorException addFactor!(dfg, [v1, v1], f1)
    @test_throws ErrorException addFactor!(dfg,[:a, :b], f1)
    #TODO only implement addFactor!(dfg, f1)
    @test_throws ErrorException getVariable(dfg, :a)
    @test_throws ErrorException getFactor(dfg, :a)
    @test_throws ErrorException updateVariable!(dfg, v1)
    @test_throws ErrorException updateFactor!(dfg, f1)

    @test_throws ErrorException deleteVariable!(dfg, :a)
    @test_throws ErrorException deleteFactor!(dfg, :a)
    @test_throws ErrorException getVariables(dfg)
    @test_throws ErrorException getFactors(dfg)
    @test_throws ErrorException isFullyConnected(dfg)
    @test_throws ErrorException getNeighbors(dfg, v1)
    @test_throws ErrorException getNeighbors(dfg, v1)
end
