## ================================================================================
## Test serializing and deserializing variables, states, and beliefs
## ================================================================================

using Test
using JSON
using DistributedFactorGraphs
using StaticArrays
using LinearAlgebra
using LieGroups

DFG.@defStateTypeN Pose{N} SpecialEuclideanGroup(N; variant = :right) ArrayPartition(
    zeros(SVector{N, Float64}),
    SMatrix{N, N, Float64}(I),
)
Pose2 = Pose{2}

## Build a test variable with states, bloblets, and blobentries
function make_test_variable()
    v = DFG.VariableDFG(:x1, Pose{3}())

    state = addState!(v, State(:default, Pose{3}()))
    addState!(v, State(:parametric, Pose{3}()))

    # Add sample points to the default state's belief
    push!(state.belief.points, DFG.getPointIdentity(Pose{3}()))
    G = DFG.getManifold(Pose{3}())
    push!(state.belief.points, rand(G, ArrayPartition))

    # Add bloblets and a blobentry
    DFG.addBloblet!(v, DFG.Bloblet(:a, "1"))
    DFG.addBloblet!(v, DFG.Bloblet(:b, "2"))
    addBlobentry!(v, DFG.Blobentry(:bel; metadata = (start = 54, N = 20, s = :test)))

    return v
end

@testset "Serializing Variables" begin
    @testset "BeliefRepresentation round-trip" begin
        bel = DFG.BeliefRepresentation(Pose{3}())
        push!(bel.points, DFG.getPointIdentity(Pose{3}()))
        G = DFG.getManifold(Pose{3}())
        push!(bel.points, rand(G, ArrayPartition))

        jstr = JSON.json(bel; pretty = true, style = DFG.DFGJSONStyle())
        parsed = JSON.parse(jstr, DFG.BeliefRepresentation; style = DFG.DFGJSONStyle())
        @test bel == parsed
    end

    @testset "GaussianDensityKind round-trip" begin
        dim = DFG.getDimension(Pose{3}())
        bel = DFG.BeliefRepresentation(
            DFG.GaussianDensityKind(),
            Pose{3}();
            means = [DFG.getPointIdentity(Pose{3}())],
            covariances = [diagm(ones(dim))],
        )
        jstr = JSON.json(bel; pretty = true, style = DFG.DFGJSONStyle())
        parsed = JSON.parse(jstr, DFG.BeliefRepresentation; style = DFG.DFGJSONStyle())
        @test bel == parsed
    end

    @testset "State round-trip" begin
        v = make_test_variable()
        state = v.states[:default]

        jstr = JSON.json(state; pretty = true, style = DFG.DFGJSONStyle())
        parsed = JSON.parse(jstr, State; style = DFG.DFGJSONStyle())
        @test state == parsed
    end

    @testset "VariableDFG round-trip" begin
        v = make_test_variable()

        jstr = JSON.json(v; pretty = true, style = DFG.DFGJSONStyle())
        parsed = JSON.parse(jstr, DFG.VariableDFG; style = DFG.DFGJSONStyle())
        @test v == parsed
    end

    @testset "VariableDFG parsefile round-trip" begin
        v = make_test_variable()
        jstr = JSON.json(v; pretty = true, style = DFG.DFGJSONStyle())

        tmpfile = tempname() * ".json"
        write(tmpfile, jstr)
        parsed = JSON.parsefile(tmpfile, DFG.VariableDFG; style = DFG.DFGJSONStyle())
        @test v == parsed
        rm(tmpfile; force = true)
    end

    @testset "VariableSummary from VariableDFG" begin
        v = make_test_variable()
        vs = VariableSummary(v)
        @test vs.label == :x1
        @test vs.tags == v.tags
        @test vs.solvable[] == v.solvable[]
    end

    @testset "VariableSkeleton from VariableDFG" begin
        v = make_test_variable()
        vsk = VariableSkeleton(v)
        @test vsk.label == :x1
        @test vsk.tags == v.tags
    end
end

# TODO deprecated v0.29, remove this test and unpackOldState
@testset "Serializing Old State" begin
    oldstates = JSON.parsefile(@__DIR__() * "/data/oldstate.json")
    states = DFG.unpackOldState.(oldstates)
    # just a spot check
    @test issetequal(getLabel.(states), [:default, :parametric, :graphinit])
end
