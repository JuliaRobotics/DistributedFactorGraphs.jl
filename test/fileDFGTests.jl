using DistributedFactorGraphs
using IncrementalInference
using Test
using TimeZones
using UUIDs
##

@testset "FileDFG Tests" begin
    for filename in ["/tmp/fileDFG", "/tmp/FileDFGExtension.tar.gz"]
        global dfg
        dfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)

        # Same graph as iifInterfaceTests.jl
        numNodes = 5

        # Arranging some random data
        verts = map(
            n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar; tags = [:POSE]),
            1:numNodes,
        )
        map(v -> setSolvable!(v, Int(round(rand()))), verts)
        map(v -> getSolverData(verts[4]).solveInProgress = Int(round(rand())), verts)
        map(v -> setSolvedCount!(v, Int(round(10 * rand()))), verts)

        # Add some data entries
        map(
            v -> addBlobEntry!(
                v,
                BlobEntry(
                    nothing,
                    nothing,
                    uuid4(),
                    :testing,
                    :store,
                    "",
                    "",
                    "",
                    "",
                    "",
                    now(localzone()),
                    "BlobEntry",
                    string(DFG._getDFGVersion()),
                ),
            ),
            verts,
        )
        map(
            v -> addBlobEntry!(
                v,
                BlobEntry(
                    nothing,
                    nothing,
                    uuid4(),
                    :testing2,
                    :store,
                    "",
                    "",
                    "",
                    "",
                    "",
                    ZonedDateTime(2014, 5, 30, 21, tz"UTC-4"),
                    "BlobEntry",
                    string(DFG._getDFGVersion()),
                ),
            ),
            verts,
        )

        # Add some PPEs
        ppe1 = MeanMaxPPE(:default, [1.0], [0.2], [3.456])
        ppe2 = MeanMaxPPE(;
            solveKey = :other,
            suggested = [1.0],
            mean = [0.2],
            max = [3.456],
            createdTimestamp = ZonedDateTime(2014, 5, 30, 21, tz"UTC-4"),
        )
        map(v -> addPPE!(dfg, getLabel(v), deepcopy(ppe1)), verts)
        map(v -> addPPE!(dfg, getLabel(v), deepcopy(ppe2)), verts)

        #call update to set it on cloud
        updateVariable!.(dfg, verts)

        facts = map(
            n -> addFactor!(
                dfg,
                [verts[n], verts[n + 1]],
                LinearRelative(Normal(50.0, 2.0)),
            ),
            1:(numNodes - 1),
        )
        map(f -> setSolvable!(f, Int(round(rand()))), facts)
        map(f -> f.solverData.eliminated = rand() > 0.5, facts)
        map(f -> f.solverData.potentialused = rand() > 0.5, facts)
        updateFactor!.(dfg, facts)

        #test multihypo
        addFactor!(
            dfg,
            [:x1, :x2, :x3],
            LinearRelative(Normal(50.0, 2.0));
            multihypo = [1, 0.3, 0.7],
        )

        #test user/robot/session metadata

        #test user/robot/session blob entries
        be = BlobEntry(
            nothing,
            nothing,
            uuid4(),
            :testing2,
            :store,
            "",
            "",
            "",
            "",
            "",
            ZonedDateTime(2023, 2, 3, 20, tz"UTC+1"),
            "BlobEntry",
            string(DFG._getDFGVersion()),
        )

        addSessionBlobEntry!(dfg, be)
        #TODO addRobotBlobEntry!(dfg, be)
        #TODO addUserBlobEntry!(dfg, be)
        smallUserData = Dict{Symbol, SmallDataTypes}(:a => "42", :b => "small_user")
        smallRobotData = Dict{Symbol, SmallDataTypes}(:a => "43", :b => "small_robot")
        smallSessionData = Dict{Symbol, SmallDataTypes}(:a => "44", :b => "small_session")

        setUserData!(dfg, smallUserData)
        setRobotData!(dfg, smallRobotData)
        setSessionData!(dfg, smallSessionData)

        # Save and load the graph to test.
        saveDFG(filename, dfg)

        @info "Going to load $filename"
        copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
        @test_throws AssertionError loadDFG!(
            DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg),
            "badfilename",
        )

        retDFG = loadDFG!(copyDfg, filename)

        @test issetequal(ls(dfg), ls(retDFG))
        @test issetequal(lsf(dfg), lsf(retDFG))
        for var in ls(dfg)
            @test getVariable(dfg, var) == getVariable(retDFG, var)
        end
        for fact in lsf(dfg)
            @test compareFactor(
                getFactor(dfg, fact),
                getFactor(retDFG, fact),
                skip = [:timezone, :zone],
            ) # Timezones
            # :hypotheses, :certainhypo, :multihypo, # Multihypo
            # :eliminated, 
            # :potentialused])
        end

        # Check data entries
        for v in ls(dfg)
            @test getBlobEntries(getVariable(dfg, v)) ==
                  getBlobEntries(getVariable(retDFG, v))
            @test issetequal(listPPEs(dfg, v), listPPEs(retDFG, v))
            for ppe in listPPEs(dfg, v)
                @test getPPE(dfg, v, ppe) == getPPE(retDFG, v, ppe)
            end
        end

        # test the duplicate order #581
        saveDFG(dfg, filename)
    end
end

##

@testset "FileDFG Regression Tests" begin
    @info "If any of these tests fail, we have breaking changes"
    for file in filter(f -> endswith(f, ".tar.gz"), readdir(joinpath(@__DIR__, "data")))
        loadFile = joinpath(@__DIR__, "data", file)
        global dfg
        dfgCopy = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
        retDFG = loadDFG!(dfgCopy, loadFile)
        # It should have failed if there were any issues.
        # Trivial check as well
        @test issetequal(ls(retDFG), [:x1, :x2, :x3, :x4, :x5])
        @test issetequal(lsf(retDFG), [:x3x4f1, :x4x5f1, :x1x2f1, :x2x3f1, :x1x2x3f1])
    end
end

##
