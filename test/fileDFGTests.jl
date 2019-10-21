@testset "FileDFG Tests" begin

    if typeof(dfg) <: CloudGraphsDFG
        @warn "TEST: Nuking all data for user '$(dfg.userId)', robot '$(dfg.robotId)'!"
        clearRobot!!(dfg)
    end

    # Same graph as iifInterfaceTests.jl
    numNodes = 10

    #change ready and backendset for x7,x8 for improved tests on x7x8f1
    verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
    #TODO fix this to use accessors
    verts[7].ready = 1
    # verts[7].backendset = 0
    verts[8].ready = 0
    verts[8].backendset = 1
    #call update to set it on cloud
    updateVariable!(dfg, verts[7])
    updateVariable!(dfg, verts[8])

    facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))

    # Save and load the graph to test.
    saveFolder = "/tmp/fileDFG"
    saveDFG(dfg, saveFolder)

    copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
    retDFG = loadDFG(saveFolder, Main, copyDfg)
    @test symdiff(ls(dfg), ls(retDFG)) == []
    @test symdiff(lsf(dfg), lsf(retDFG)) == []
    for var in ls(dfg)
        @test getVariable(dfg, var) == getVariable(retDFG, var)
    end
    for fact in lsf(dfg)
        @test getFactor(dfg, fact) == getFactor(retDFG, fact)
    end
end
