using DistributedFactorGraphs
using IncrementalInference
using Test

@testset "FileDFG Tests" begin
    for filename in ["/tmp/fileDFG", "/tmp/FileDFGExtension.tar.gz"]
        global dfg
        dfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)

        if typeof(dfg) <: CloudGraphsDFG
            @warn "TEST: Nuking all data for user '$(dfg.userId)', robot '$(dfg.robotId)'!"
            clearRobot!!(dfg)
        end

        # Same graph as iifInterfaceTests.jl
        numNodes = 5

        #change ready and solvable for x7,x8 for improved tests on x7x8f1
        verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
        #TODO fix this to use accessors
        verts[3].solvable = 1
        verts[4].solvable = 0
        getSolverData(verts[4]).solveInProgress = 1
        #call update to set it on cloud
        updateVariable!(dfg, verts[3])
        updateVariable!(dfg, verts[4])

        setSolvedCount!(verts[1], 5)
        # Add some bigData to x1, x2
        addBigDataEntry!(verts[1], GeneralBigDataEntry(:testing, :testing; mimeType="application/nuthin!"))
        addBigDataEntry!(verts[2], FileBigDataEntry(:testing2, "/dev/null"))
        #call update to set it on cloud
        updateVariable!(dfg, verts[1])
        updateVariable!(dfg, verts[2])

        facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))

        # Save and load the graph to test.
        saveDFG(dfg, filename)

        copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
        @info "Going to load $filename"
        retDFG = loadDFG(filename, Main, copyDfg, loaddir="/tmp")

        @test issetequal(ls(dfg), ls(retDFG))
        @test issetequal(lsf(dfg), lsf(retDFG))
        for var in ls(dfg)
            @test getVariable(dfg, var) ≈ getVariable(retDFG, var)
        end
        for fact in lsf(dfg)
            @test getFactor(dfg, fact) ≈ getFactor(retDFG, fact)
        end

        @test length(getBigDataEntries(getVariable(retDFG, :x1))) == 1
        @test typeof(getBigDataEntry(getVariable(retDFG, :x1),:testing)) == GeneralBigDataEntry
        @test length(getBigDataEntries(getVariable(retDFG, :x2))) == 1
        @test typeof(getBigDataEntry(getVariable(retDFG, :x2),:testing2)) == FileBigDataEntry
    end
end
