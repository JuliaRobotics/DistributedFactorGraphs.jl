using Test
using GraphMakie # For plotting tests
using DistributedFactorGraphs
using Pkg
using Dates
using TimeZones
using SHA
using UUIDs
using Aqua

using DistributedFactorGraphs: ArrayPartition, OrderedDict

# If you want to enable debugging logging (very verbose!)
# using Logging
# logger = SimpleLogger(stdout, Logging.Debug)
# global_logger(logger)

include("test_defVariable.jl")

include("testBlocks.jl")

@testset "Test generated ==" begin
    include("compareTests.jl")
end

@testset "Testing GraphsDFG.FactorGraphs functions" begin
    include("FactorGraphsTests.jl")
end

apis = [GraphsDFG]

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

@testset "GraphsDFG subtype tests" begin
    for type in [
        (var = VariableSummary, fac = FactorSummary),
        (var = VariableSkeleton, fac = FactorSkeleton),
    ]
        @testset "$(type.var) and $(type.fac) tests" begin
            @info "Testing $(type.var) and $(type.fac)"
            global VARTYPE = type.var
            global FACTYPE = type.fac
            include("GraphsDFGSummaryTypes.jl")
        end
    end
end

if get(ENV, "IIF_TEST", "true") == "true"

    # Switch to our upstream test branch.
    #FIXME This is a temporary fix to use the develop branch of IIF.
    # Pkg.add(PackageSpec(; name = "IncrementalInference", rev = "upstream/dfg_integration_test"))
    # Pkg.add(PackageSpec(; name = "IncrementalInference", rev = "develop"))
    Pkg.add(
        PackageSpec(;
            url = "https://github.com/JuliaRobotics/IncrementalInference.jl.git",
            subdir = "IncrementalInferenceTypes",
            rev = "develop",
        ),
    )
    Pkg.add(
        PackageSpec(;
            url = "https://github.com/JuliaRobotics/IncrementalInference.jl.git",
            subdir = "IncrementalInference",
            rev = "develop",
        ),
    )
    @info "------------------------------------------------------------------------"
    @info "These tests are using IncrementalInference to do additional driver tests"
    @info "------------------------------------------------------------------------"

    using IncrementalInference

    apis = Vector{AbstractDFG}()
    push!(apis, GraphsDFG(; solverParams = SolverParams()))

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
            GraphsDFG(; solverParams = SolverParams()),
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
    v1 = VariableSkeleton(:v1)
    f1 = FactorSkeleton(:f1, [:v1])

    @test_throws ErrorException exists(dfg, v1)
    @test_throws ErrorException exists(dfg, f1)

    @test_throws ErrorException exists(dfg, :s)
    @test_throws ErrorException addVariable!(dfg, v1)

    @test_throws ErrorException getVariable(dfg, :a)
    @test_throws ErrorException getFactor(dfg, :a)
    @test_throws ErrorException mergeVariable!(dfg, v1)
    @test_throws ErrorException mergeFactor!(dfg, f1)

    @test_throws ErrorException deleteVariable!(dfg, :a)
    @test_throws ErrorException deleteFactor!(dfg, :a)
    @test_throws ErrorException getVariables(dfg)
    @test_throws ErrorException getFactors(dfg)
    @test_throws ErrorException isConnected(dfg)
    @test_throws ErrorException listNeighbors(dfg, v1)
    @test_throws ErrorException listNeighbors(dfg, :a)

    @test_throws ErrorException DFG._getDuplicatedEmptyDFG(dfg)

    @test_throws ErrorException isVariable(dfg, :a)
    @test_throws ErrorException isFactor(dfg, :a)
end

@testset "Testing Code Quality with Aqua" begin
    Aqua.test_ambiguities([DistributedFactorGraphs])
    Aqua.test_unbound_args(DistributedFactorGraphs)
    Aqua.test_undefined_exports(DistributedFactorGraphs)
    Aqua.test_piracies(DistributedFactorGraphs)
    Aqua.test_project_extras(DistributedFactorGraphs)
    Aqua.test_stale_deps(DistributedFactorGraphs; ignore = [:Colors])
    Aqua.test_deps_compat(DistributedFactorGraphs)
    # Aqua.test_project_toml_formatting(DistributedFactorGraphs) # deprecated in Aqua.jl v0.8
end
