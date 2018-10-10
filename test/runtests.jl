using Base: Test
using DistributedFactorGraphs


# Just to test the arguments with a mock API
@testset "MockAPI" begin
    include("mockAPI.jl")

    v = DFGVariable(0, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
    f = DFGFactor(0, "x0f0", [], GenericFunctionNodeData{Int64, Symbol}())
    @test dfg.addV!(dfg, v) == v
    @test dfg.addF!(dfg, f) == f
    @test dfg.getV(dfg, 1).id == 1
    @test dfg.getV(dfg, "x0").id == 0
    @test dfg.getF(dfg, 1).id == 1
    @test dfg.getF(dfg, "x0f0").id == 1
    @test dfg.updateV!(dfg, v) == v
    @test dfg.updateF!(dfg, f) == f
    @test dfg.deleteV!(dfg, v) == v
    @test dfg.deleteV!(dfg, "x0").label == "x0"
    @test dfg.deleteV!(dfg, 0).id == 0
    @test dfg.deleteF!(dfg, f) == f
    @test length(dfg.ls(dfg)) == 0
    @test length(dfg.ls(dfg, v)) == 0
    @test length(dfg.ls(dfg, 0)) == 0
    @test length(dfg.subGraph(dfg, Int64[])) == 0
    @test size(dfg.adjacencyMatrix(dfg)) == (0, 0)
end
