using DistributedFactorGraphs
using IncrementalInference
dfg = LightDFG{NoSolverParams}()

@testset "FileDFG Tests" begin

    if typeof(dfg) <: CloudGraphsDFG
        @warn "TEST: Nuking all data for user '$(dfg.userId)', robot '$(dfg.robotId)'!"
        clearRobot!!(dfg)
    end

    # Same graph as iifInterfaceTests.jl
    numNodes = 10

    #change ready and solvable for x7,x8 for improved tests on x7x8f1
    verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
    #TODO fix this to use accessors
    verts[7].solvable = 1
    verts[8].solvable = 0
    solverData(verts[8]).solveInProgress = 1
    setSolvedCount!(verts[1], 5)
    #call update to set it on cloud
    updateVariable!(dfg, verts[7])
    updateVariable!(dfg, verts[8])

    # Add some bigData to x1, x2
    addBigDataEntry!(verts[1], GeneralBigDataEntry(:testing, :testing; mimeType="application/nuthin!"))
    addBigDataEntry!(verts[2], FileBigDataEntry(:testing2, "/dev/null"))
    #call update to set it on cloud
    updateVariable!(dfg, verts[1])
    updateVariable!(dfg, verts[2])

    facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))

    # Save and load the graph to test.
    saveFolder = "/tmp/fileDFG"
    saveDFG(dfg, saveFolder)

    copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
    @info "Going to load $saveFolder"
    retDFG = loadDFG(saveFolder*".tar.gz", Main, copyDfg, loaddir="/tmp")

    @test symdiff(ls(dfg), ls(retDFG)) == []
    @test symdiff(lsf(dfg), lsf(retDFG)) == []
    for var in ls(dfg)
        @test getVariable(dfg, var) == getVariable(retDFG, var)
    end
    for fact in lsf(dfg)
        @test getFactor(dfg, fact) == getFactor(retDFG, fact)
    end

    @test length(getBigDataEntries(getVariable(retDFG, :x1))) == 1
    @test typeof(getBigDataEntry(getVariable(retDFG, :x1),:testing)) == GeneralBigDataEntry
    @test length(getBigDataEntries(getVariable(retDFG, :x2))) == 1
    @test typeof(getBigDataEntry(getVariable(retDFG, :x2),:testing2)) == FileBigDataEntry

end
