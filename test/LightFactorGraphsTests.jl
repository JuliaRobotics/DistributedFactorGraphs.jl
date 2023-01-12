using Test
using DistributedFactorGraphs

using DistributedFactorGraphs.GraphsDFGs.FactorGraphs


@testset "GraphsDFGs.FactorGraphs BiMaps" begin

    @test isa(FactorGraphs.BiDictMap(), FactorGraphs.BiDictMap{Int64})
    bi = FactorGraphs.BiDictMap{Int}()

    @test (bi[1] = :x1) == :x1
    @test bi[:x1] == 1
    @test (bi[2] = :x1) == :x1
    @test bi[:x1] == 2
    @test_throws KeyError bi[1]

    @test haskey(bi,2)
    @test !haskey(bi,1)
    @test haskey(bi,:x1)
    @test !haskey(bi,:x10)

    @test (bi[:x10] = 10) == 10
    @test bi[10] == :x10

    @test (bi[:x11] = 10) == 10

    @test !haskey(bi,:x10)

    bi[1] = :x1
    bi[:x1] = 2
    bi[3] = :x1
    bi[4] = :x2
    bi[:x3] = 4

    @test length(bi.sym_int) == 3
    @test length(bi.int_sym) == 3
    @test length(bi) == 3
    @test !(isempty(bi))

end

@testset "GraphsDFGs.FactorGraphs" begin


    @test isa(FactorGraphs.FactorGraph(), FactorGraph{Int64,AbstractDFGVariable,AbstractDFGFactor})

    fg = FactorGraphs.FactorGraph{Int, SkeletonDFGVariable, SkeletonDFGFactor}()

    @test !FactorGraphs.is_directed(fg)
    @test !FactorGraphs.is_directed(FactorGraph{Int, SkeletonDFGVariable, SkeletonDFGFactor})

    @test isa(zero(fg), FactorGraph{Int64, SkeletonDFGVariable, SkeletonDFGFactor})

    # @test
    @test FactorGraphs.addVariable!(fg, SkeletonDFGVariable(:a))
    @test @test_logs (:error, r"already") !FactorGraphs.addVariable!(fg, SkeletonDFGVariable(:a))
    @test FactorGraphs.addVariable!(fg, SkeletonDFGVariable(:b))

    @test FactorGraphs.addFactor!(fg,  [:a,:b], SkeletonDFGFactor(:abf1, [:a,:b]))
    @test @test_logs (:error, r"already") !FactorGraphs.addFactor!(fg,  [:a,:b], SkeletonDFGFactor(:abf1, [:a,:b]))
    @test @test_logs (:error, r"not found") !FactorGraphs.addFactor!(fg,  [:a,:c], SkeletonDFGFactor(:acf1, [:a,:c]))

    @test eltype(fg) == Int

    @test FactorGraphs.edgetype(fg) == FactorGraphs.LightGraphs.SimpleGraphs.SimpleEdge{Int64}

    @test FactorGraphs.has_vertex(fg, 1)
    @test !FactorGraphs.has_vertex(fg, 4)

    @test FactorGraphs.has_edge(fg, FactorGraphs.LightGraphs.SimpleGraphs.SimpleEdge(1,3))

    @test FactorGraphs.rem_edge!(fg, FactorGraphs.LightGraphs.SimpleGraphs.SimpleEdge(2,3))
    @test !FactorGraphs.has_edge(fg, FactorGraphs.LightGraphs.SimpleGraphs.SimpleEdge(2,3))


end
