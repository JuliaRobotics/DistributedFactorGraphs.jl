using DistributedFactorGraphs
using Test

struct TestInferenceVariable1 <: InferenceVariable end
struct TestInferenceVariable2 <: InferenceVariable end

@testset "Needs-a-home tests" begin
    dfg = LightDFG{NoSolverParams}(params=NoSolverParams())

    # Build a graph
    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    f1 = DFGFactor{TestFunctorInferenceType1}(:f1)
    addVariable!(dfg, v1)
    addVariable!(dfg, v2)
    addFactor!(dfg, [v1, v2], f1)

    # Standard tests
    newdfg = buildSubgraphFromLabels!(dfg, [:b])
    @test ls(newdfg) == [:b]
    # Okay it looks like this function only accepts variables, is that right?
    @test_throws Exception newdfg = buildSubgraphFromLabels!(dfg, [:b, :f1])
    newdfg = buildSubgraphFromLabels!(dfg, [:b, :a])
    @test symdiff(ls(newdfg), [:b, :a]) == []
    @test lsf(newdfg) == [:f1]

    # Check solvable filter
    @test setSolvable!(getVariable(dfg, :a), 1) == 1
    @test setSolvable!(getVariable(dfg, :b), 0) == 0
    @test setSolvable!(getFactor(dfg, :f1), 1) == 1
    newdfg = buildSubgraphFromLabels!(dfg, [:b, :a]; solvable = 1)
    @test ls(newdfg) == [:a]
end
