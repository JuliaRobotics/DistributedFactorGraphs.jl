# IIF testCompareVariableFactors repeated in IIF

using DistributedFactorGraphs
using IncrementalInference
using Test

@testset "testing compare functions for variables and factors..." begin

    fg = initfg()

    v1 = addVariable!(fg, :x0, ContinuousScalar)
    f1 = addFactor!(fg, [:x0;], Prior(Normal()))

    @test compareVariable(v1,v1)
    @test compareFactor(f1,f1)

    v2 = addVariable!(fg, :x1, ContinuousScalar)
    f2 = addFactor!(fg, [:x0;:x1], LinearRelative(Normal(2.0, 0.1)))

    fg2 = deepcopy(fg)

    @test !compareVariable(v1,v2)

    # not testing different factors in this way
    # @test !compareFactor(f1,f2)

    @test compareAllVariables(fg, fg)

    @test compareAllVariables(fg, fg2)

    @test compareSimilarVariables(fg, fg)
    @test compareSimilarVariables(fg, fg2)

    @test compareSimilarFactors(fg, fg)
    @test compareSimilarFactors(fg, fg2)

    @test compareFactorGraphs(fg, fg)
    @test compareFactorGraphs(fg, fg2)

    tree = solveTree!(fg)

    x1a = getVariable(fg, :x0)
    x1b = getVariable(fg2, :x0)

    @test !compareVariable(x1a, x1b, skipsamples=false)

    @test !compareSimilarVariables(fg, fg2, skipsamples=false)
    @test !compareSimilarFactors(fg, fg2, skipsamples=false)

    @test compareFactorGraphs(fg, fg)
    @test !compareFactorGraphs(fg, fg2, skipsamples=false)

    initAll!(fg2)

    @test compareSimilarVariables(fg, fg2, skipsamples=true, skip=Symbol[:infoPerCoord;:initialized;:inferdim;:ppeDict;:solvedCount])
    # fg2 has been solved, so it should fail on the estimate dictionary
    @test !compareSimilarVariables(fg, fg2, skipsamples=true, skip=Symbol[:initialized;:inferdim])

    tree = buildTreeReset!(fg2)

    @test compareSimilarFactors(fg, fg2, skipsamples=true, skipcompute=true, skip=[:fullvariables])

    @test !compareSimilarFactors(fg, fg2, skipsamples=true, skipcompute=false)

    @test compareFactorGraphs(fg, fg2, skipsamples=true, skipcompute=true, skip=[:fullvariables; :infoPerCoord; :initialized; :inferdim; :ppeDict; :solvedCount])

end




@testset "test subgraph functions..." begin

    fg = initfg()

    addVariable!(fg, :x0, ContinuousScalar)
    addFactor!(fg, [:x0;], Prior(Normal()))

    addVariable!(fg, :x1, ContinuousScalar)
    addFactor!(fg, [:x0;:x1], LinearRelative(Normal(2.0, 0.1)))

    addVariable!(fg, :x2, ContinuousScalar)
    addFactor!(fg, [:x1;:x2], LinearRelative(Normal(4.0, 0.1)))

    addVariable!(fg, :l1, ContinuousScalar)
    addFactor!(fg, [:x1;:l1], LinearRelative(Rayleigh()))

    sfg = buildSubgraph(GraphsDFG, fg, [:x0;:x1])

    @warn "FIXME This is NOT supposed to pass"
    @test_skip compareFactorGraphs(fg, sfg, skip=[:labelDict;:addHistory;:logpath])
    # drawGraph(sfg)

end
