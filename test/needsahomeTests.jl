using DistributedFactorGraphs
using Test

@testset "Needs-a-home tests" begin
    dfg = GraphsDFG{NoSolverParams}(params=NoSolverParams())
    struct TestInferenceVariable1 <: InferenceVariable end
    struct TestInferenceVariable2 <: InferenceVariable end

    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    f1 = DFGFactor{Int, :Symbol}(:f1)
    addVariable!(dfg, v1)
    addVariable!(dfg, v2)
    addFactor!(dfg, [v1, v2], f1)

    newdfg = buildSubgraphFromLabels!(dfg, [:b])
    @test ls(newdfg) == [:b]
    # Okay it looks like this function only accepts variables, is that right?
    @test_throws Exception newdfg = buildSubgraphFromLabels!(dfg, [:b, :f1])
    newdfg = buildSubgraphFromLabels!(dfg, [:b, :a])
    @test symdiff(ls(newdfg), [:b, :a]) == []

end
