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
            # Need to recreate this, otherwise there is going to be an issue when creating the nodes.
            createDfgSessionIfNotExist(dfg)
        end

        # Same graph as iifInterfaceTests.jl
        numNodes = 5

        # Arranging some random data
        verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
        map(v -> setSolvable!(v, Int(round(rand()))), verts)
        map(v -> getSolverData(verts[4]).solveInProgress=Int(round(rand())), verts)
        map(v -> setSolvedCount!(v, Int(round(10*rand()))), verts)

        # Add some data entries
        map(v -> addDataEntry!(v, BlobStoreEntry(:testing, uuid4(), :store, "", "", "", "", now(localzone()))), verts)
        map(v -> addDataEntry!(v, BlobStoreEntry(:testing2, uuid4(), :store, "", "", "", "", ZonedDateTime(2014, 5, 30, 21, tz"UTC-4"))), verts)

        # Add some PPEs
        ppe1 = MeanMaxPPE(:default, [1.0], [0.2], [3.456])
        ppe2 = MeanMaxPPE(:other, [1.0], [0.2], [3.456], ZonedDateTime(2014, 5, 30, 21, tz"UTC-4"))
        map(v -> addPPE!(dfg, getLabel(v), deepcopy(ppe1)), verts)
        map(v -> addPPE!(dfg, getLabel(v), deepcopy(ppe2)), verts)

        #call update to set it on cloud
        updateVariable!.(dfg, verts)


        facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))
        map(f -> setSolvable!(f, Int(round(rand()))), facts)
        map(f -> f.solverData.multihypo = [1, 0.1, 0.9], facts)
        map(f -> f.solverData.eliminated = rand() > 0.5, facts)
        map(f -> f.solverData.potentialused = rand() > 0.5, facts)
        updateFactor!.(dfg, facts)
        
        # Save and load the graph to test.
        saveDFG(filename, dfg)

        @info "Going to load $filename"
        copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
        @test_throws AssertionError loadDFG!(DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg),"badfilename")

        retDFG = loadDFG!(copyDfg, filename)

        @test issetequal(ls(dfg), ls(retDFG))
        @test issetequal(lsf(dfg), lsf(retDFG))
        for var in ls(dfg)
            @test getVariable(dfg, var) == getVariable(retDFG, var)
        end
        for fact in lsf(dfg)
            @test compareFactor(getFactor(dfg, fact), 
                getFactor(retDFG, fact),
                skip=[
                    :hypotheses, :certainhypo, :multihypo, # Multihypo
                    :eliminated, 
                    :timezone, :zone, # Timezones
                    :potentialused])
        end
        
        # Check data entries
        for v in ls(dfg)
            @test getDataEntries(getVariable(dfg, v)) == getDataEntries(getVariable(retDFG, v))
            @test issetequal(listPPEs(dfg, v), listPPEs(retDFG, v))
            for ppe in listPPEs(dfg, v)
                @test getPPE(dfg, v, ppe) == getPPE(retDFG, v, ppe)
            end
        end
        
        # test the duplicate order #581
        saveDFG(dfg, filename)
    end
end

@testset "FileDFG Regression Tests" begin
    @info "If any of these tests fail, we have breaking changes"
    for file in readdir(joinpath(@__DIR__, "data"))
        loadFile = joinpath(@__DIR__, "data", file)
        global dfg
        dfgCopy = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
        retDFG = loadDFG!(dfgCopy, loadFile)        
        # It should have failed if there were any issues.
        # Trivial check as well
        @test issetequal(ls(retDFG), [:x1, :x2, :x3, :x4, :x5])
        @test issetequal(lsf(retDFG), [:x3x4f1, :x4x5f1, :x1x2f1, :x2x3f1])
    end
end