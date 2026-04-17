global dfg, v1, v2, f1
# dfg = GraphsDFG(; solverParams = SolverParams())
# Building simple graph...
@testset "Building a simple Graph" begin
    global dfg, v1, v2, f1
    # Use IIF to add the variables and factors
    v1 = addVariable!(dfg, :a, Position{1}; tags = [:POSE], solvable = 0)
    v2 = addVariable!(dfg, :b, Position{1}; tags = [:LANDMARK], solvable = 1)
    f1 = addFactor!(dfg, [:a; :b], LinearRelative(Normal(50.0, 2.0)); solvable = 0)
end
#test before anything changes
@testset "Producing Dot Files" begin
    global dfg
    todotstr = DFG.toDot(dfg)
    #TODO consider using a regex, but for now test all orders
    todota =
        cmp(
            todotstr,
            "graph graphname {\n2 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n",
        ) |> abs
    todotb =
        cmp(
            todotstr,
            "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n",
        ) |> abs
    todotc =
        cmp(
            todotstr,
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box];\na -- abf1\nb -- abf1\n}\n",
        ) |> abs
    todotd =
        cmp(
            todotstr,
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box];\nb -- abf1\na -- abf1\n}\n",
        ) |> abs
    todote =
        cmp(
            todotstr,
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\na -- abf1\nb -- abf1\n}\n",
        ) |> abs
    todotf =
        cmp(
            todotstr,
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\nb -- abf1\na -- abf1\n}\n",
        ) |> abs
    # @show todota, todotb, todotc, todotd, todote, todotf
    @test (todota < 1 || todotb < 1 || todotc < 1 || todotd < 1 || todote < 1 || todotf < 1)
    @test DFG.toDotFile(dfg, "something.dot") === nothing
    Base.rm("something.dot")
end

@testset "Testing CRUD, return and Failures from a GraphsDFG" begin
    global dfg
    # dfg to copy to
    # creating a whole new graph with the same labels
    T = typeof(dfg)
    dfg2 = T(; solverParams = SolverParams(), graphLabel = :testGraph)

    # Build a new in-memory IIF graph to transfer into the new graph.
    iiffg = initfg()
    v1 = deepcopy(addVariable!(iiffg, :a, Position{1}))
    v2 = deepcopy(addVariable!(iiffg, :b, Position{1}))
    v3 = deepcopy(addVariable!(iiffg, :c, Position{1}))
    f1 = deepcopy(addFactor!(iiffg, [:a; :b], LinearRelative(Normal(50.0, 2.0))))
    f2 = deepcopy(addFactor!(iiffg, [:b; :c], LinearRelative(Normal(10.0, 1.0))))

    # Add it to the new graph.
    @test addVariable!(dfg2, v1) == v1
    @test addVariable!(dfg2, v2) == v2
    @test mergeVariable!(dfg2, v3) == 1
    @test_throws LabelExistsError addVariable!(dfg2, v3)
    @test addFactor!(dfg2, f1) == f1
    @test_throws LabelExistsError addFactor!(dfg2, f1)
    # @test @test_logs (:warn, r"exist") mergeFactor!(dfg2, f2) == f2
    @test mergeFactor!(dfg2, f2) == 1
    @test_throws LabelExistsError addFactor!(dfg2, f2)

    @test deleteVariable!(dfg2, v3) == 2
    @test deleteVariable!(dfg2, v3) == 0

    @test issetequal(ls(dfg2), [:a, :b])
    @test deleteFactor!(dfg2, f2) == 0

    @test lsf(dfg2) == [:abf1]
end

@testset "Listing Nodes" begin
    global dfg, v1, v2, f1
    @test length(ls(dfg)) == 2
    @test length(lsf(dfg)) == 1 # Unless we add the prior!
    @test symdiff([:a, :b], listVariables(dfg)) == []
    @test listFactors(dfg) == [:abf1] # Unless we add the prior!
    # Additional testing for https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/201
    @test symdiff([:a, :b], listVariables(dfg; whereSolvable = >=(0))) == []
    @test listVariables(dfg; whereSolvable = >=(1)) == [:b]
    @test map(v -> v.label, getVariables(dfg; whereSolvable = >=(1))) == [:b]
    @test listFactors(dfg) == [:abf1]
    @test listFactors(dfg; whereSolvable = >=(1)) == []
    @test listFactors(dfg; whereSolvable = >=(0)) == [:abf1]
    @test map(f -> f.label, getFactors(dfg; whereSolvable = >=(0))) == [:abf1]
    @test map(f -> f.label, getFactors(dfg; whereSolvable = >=(1))) == []
    #
    @test lsf(dfg, :a) == [f1.label]
    # Tags
    @test ls(dfg; whereTags = ⊇([:POSE])) == [:a]
    @test symdiff(
        ls(dfg; whereTags = !isdisjoint([:POSE, :LANDMARK])),
        ls(dfg; whereTags = ⊇([:VARIABLE])),
    ) == []
    # Regexes
    @test ls(dfg; whereLabel = contains(r"a")) == [v1.label]
    @test lsf(dfg; whereLabel = contains(r"abf.*")) == [f1.label]

    # Accessors
    @test getDescription(dfg) !== nothing
    #TODO Deprecate
    # @test_throws ErrorException getLabelDict(dfg)
    # Existence
    @test exists(dfg, :a) == true
    @test exists(dfg, v1) == true
    @test exists(dfg, :nope) == false
    # isFactor and isVariable
    @test isFactor(dfg, f1.label)
    @test !isFactor(dfg, v1.label)
    @test isVariable(dfg, v1.label)
    @test !isVariable(dfg, f1.label)
    @test !isVariable(dfg, :doesntexist)
    @test !isFactor(dfg, :doesntexist)

    @test issetequal([:a, :b], listVariables(dfg))
    @show listFactors(dfg)
    @test issetequal([:abf1], listFactors(dfg))

    # @test @test_deprecated getVariableIds(dfg) == listVariables(dfg)
    # @test @test_deprecated getFactorIds(dfg) == listFactors(dfg)

    @test getObservation(dfg, :abf1) === f1.observation
    @test getObservation(f1) === f1.observation

    @test !isPrior(dfg, :abf1) # f1 is not a prior
    @test lsfPriors(dfg) == []

    @test DFG.lsfTypes(dfg)[1] <: LinearRelative

    @test ls(dfg, LinearRelative) == [:abf1]
    @test lsf(dfg, LinearRelative{1, Normal{Float64}}) == [:abf1]

    @test getStateKind(v1) isa Position{1}
    @test getStateKind(dfg, :a) isa Position{1}

    @test DFG.lsTypes(dfg) == [Position{1}]

    @test issetequal(ls(dfg, Position{1}), [:a, :b])

    varNearTs = findVariablesNearTimestamp(dfg, now())

    @test varNearTs[1][1] == [:b]
end

# Gets
@testset "Gets, Sets, and Accessors" begin
    global dfg, v1, v2, f1
    @test getVariable(dfg, v1.label) == v1
    @test getFactor(dfg, f1.label) == f1
    @test_throws LabelNotFoundError getVariable(dfg, :nope)
    @test_throws MethodError getVariable(dfg, "nope")
    @test_throws LabelNotFoundError getFactor(dfg, :nope)
    @test_throws MethodError getFactor(dfg, "nope")

    # Sets
    v1Prime = deepcopy(v1)
    @test mergeVariable!(dfg, v1Prime) == 1 #Maybe move to crud
    f1Prime = deepcopy(f1)
    @test mergeFactor!(dfg, f1Prime) == 1 #Maybe move to crud

    # Accessors
    @test getLabel(v1) == v1.label
    @test DFG.refTags(v1) === v1.tags
    @test getTimestamp(v1) == v1.timestamp
    @test getState(v1, :default) === v1.states[:default]
    @test refStates(v1) == v1.states

    @test typeof(getStateKind(v1)) == Position{1}
    @test typeof(getStateKind(v2)) == Position{1}
    @test typeof(getStateKind(v1)) == Position{1}

    @test getLabel(f1) == f1.label
    @test DFG.refTags(f1) === f1.tags
    @test DFG.getRecipestate(f1) === f1.state
    @test getObservation(f1) === f1.observation

    @test getSolverParams(dfg) !== nothing
    @test setSolverParams!(dfg, getSolverParams(dfg)) == getSolverParams(dfg)

    #solver data is initialized
    @test !isInitialized(dfg, :a)
    @test !isInitialized(v2)

    @test_throws LabelNotFoundError isInitialized(v2, :second)

    # Graph and Agent small data tests
    agentlabel = :testAgent
    DFG.addAgent!(dfg, DFG.Agent(; label = agentlabel))
    agentBloblets = [Bloblet(:a, "43"), Bloblet(:b, "Hello")]
    graphBloblets = [Bloblet(:c, "44"), Bloblet(:d, "Hello")]
    DFG.addAgentBloblets!(dfg, agentlabel, agentBloblets)
    DFG.addGraphBloblets!(dfg, graphBloblets)
    @test DFG.listAgentBloblets(dfg, agentlabel) == [:a, :b]
    @test DFG.listGraphBloblets(dfg) == [:c, :d]
end

@testset "Data Entries" begin
    de1 = Blobentry(:key1, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :test)

    de2 = Blobentry(:key2, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :test)

    de2_update = Blobentry(
        :key2,
        DFG.Multihash(sha2_256, rand(UInt8, 32)),
        UInt32(0),
        :test;
        mimetype = MIME("image/jpg"),
    )

    #add
    v1 = getVariable(dfg, :a)
    @test addBlobentry!(v1, de1) == de1
    @test addVariableBlobentry!(dfg, :a, de2) == de2
    @test_throws LabelExistsError addBlobentry!(v1, de1)
    @test de2 in getBlobentries(v1)

    #get
    @test deepcopy(de1) == getBlobentry(v1, :key1)
    @test deepcopy(de2) == getVariableBlobentry(dfg, :a, :key2)
    @test_throws LabelNotFoundError getBlobentry(v2, :key1)
    @test_throws LabelNotFoundError getVariableBlobentry(dfg, :b, :key1)

    #update
    @test mergeVariableBlobentry!(dfg, :a, de2_update) == 1
    @test deepcopy(de2_update) == getVariableBlobentry(dfg, :a, :key2)
    @test mergeVariableBlobentry!(dfg, :b, de2_update) == 1

    #list
    entries = getVariableBlobentries(dfg, :a)
    @test length(entries) == 2
    @test issetequal(map(e -> e.label, entries), [:key1, :key2])
    @test length(getVariableBlobentries(dfg, :b)) == 1

    @test issetequal(listVariableBlobentries(dfg, :a), [:key1, :key2])
    @test listVariableBlobentries(dfg, :b) == Symbol[:key2]

    #delete
    @test deleteBlobentry!(v1, :key1) == 1
    @test listBlobentries(v1) == Symbol[:key2]
    #delete from ddfg
    @test deleteVariableBlobentry!(dfg, :a, :key2) == 1
    @test listBlobentries(v1) == Symbol[]
end

# Connectivity test
@testset "Connectivity Test" begin
    global dfg, v1, v2, f1
    @test isConnected(dfg) == true
    # @test @test_deprecated isFullyConnected(dfg) == true
    # @test @test_deprecated hasOrphans(dfg) == false
    addVariable!(dfg, :orphan, Position{1}; tags = [:POSE], solvable = 0)
    @test isConnected(dfg) == false
end

# Adjacency matrices
@testset "Adjacency Matrices" begin
    global dfg, v1, v2, f1

    #sparse
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg)
    @test size(adjMat) == (1, 3)

    # Checking the elements of adjacency, its not sorted so need indexing function
    indexOf = (arr, el1) -> findfirst(el2 -> el2 == el1, arr)
    @test adjMat[1, indexOf(v_ll, :orphan)] == 0
    @test adjMat[1, indexOf(v_ll, :a)] == 1
    @test adjMat[1, indexOf(v_ll, :b)] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:abf1, :abf1, :abf1]) == Symbol[]

    # Filtered - REF DFG #201
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg; whereSolvable = >=(1))
    @test size(adjMat) == (0, 1)

    # sparse
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg; whereSolvable = >=(1))
    @test size(adjMat) == (0, 1)
    @test issetequal(v_ll, [:b])
    @test f_ll == []
end

# Deletions
@testset "Deletions" begin
    deleteFactor!(dfg, :abf1)
    @test listFactors(dfg) == []
    deleteVariable!(dfg, :b)
    @test symdiff([:a, :orphan], listVariables(dfg)) == []
    #delete last also for the Graphs implementation coverage
    deleteVariable!(dfg, :orphan)
    @test symdiff([:a], listVariables(dfg)) == []
    deleteVariable!(dfg, :a)
    @test listVariables(dfg) == []
end

# Now make a complex graph for connectivity tests
numNodes = 10

#change solvable and solveInProgress for x7,x8 for improved tests on x7x8f1
verts = map(n -> addVariable!(dfg, Symbol("x$n"), Position{1}; tags = [:POSE]), 1:numNodes)
#TODO fix this to use accessors
setSolvable!(verts[7], 1)
setSolvable!(verts[8], 0)
#call update to set it on cloud
mergeVariable!(dfg, verts[7])
mergeVariable!(dfg, verts[8])

facts = map(
    n -> addFactor!(
        dfg,
        [verts[n], verts[n + 1]],
        LinearRelative(Normal(50.0, 2.0));
        solvable = 0,
    ),
    1:(numNodes - 1),
)

@testset "Getting Neighbors" begin
    global dfg, verts
    # Trivial test to validate that intersect([], []) returns order of first parameter
    @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
    # Get neighbors tests
    @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = listNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test neighbors == [:x1, :x2]
    # Testing aliases
    @test listNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test listNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

    # solvable checks
    @test listNeighbors(dfg, :x5; whereSolvable = >=(1)) == Symbol[]
    @test symdiff(listNeighbors(dfg, :x5; whereSolvable = >=(0)), [:x4x5f1, :x5x6f1]) == []
    @test symdiff(listNeighbors(dfg, :x5), [:x4x5f1, :x5x6f1]) == []
    @test listNeighbors(dfg, :x7x8f1; whereSolvable = >=(0)) == [:x7, :x8]
    @test listNeighbors(dfg, :x7x8f1; whereSolvable = >=(1)) == [:x7]
    @test listNeighbors(dfg, verts[1]; whereSolvable = >=(0)) == [:x1x2f1]
    @test listNeighbors(dfg, verts[1]; whereSolvable = >=(1)) == Symbol[]
    @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
end

#TODO make sure similar testing exists then delete
# @testset "Getting Subgraphs" begin
#     # Subgraphs
#     dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     # Test include orphan factorsVoid
#     @test_broken begin
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
#         @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#         # Test adding to the dfg
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
#         @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     end
#     dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#
#     @test_broken begin
#         # DFG issue #201 Test include orphan factors with filtering - should only return x7 with solvable=1
#         dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=0)
#         @test symdiff([:x7, :x8, :x7x8f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#         # Filter - always returns the node you start at but filters around that.
#         dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=1)
#         @test symdiff([:x7x8f1, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     end
#     # DFG issue #95 - confirming that getSubgraphAroundNode retains order
#     # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
#     for fId in listVariables(dfg)
#         # Get a subgraph of this and it's related factors+variables
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#         # For each factor check that the order the copied graph == original
#         for fact in getFactors(dfgSubgraph)
#             @test fact.variableorder == getFactor(dfg, fact.label).variableorder
#         end
#     end
# end

@testset "Summaries and Summary Graphs" begin
    factorFields = fieldnames(FactorSummary)
    variableFields = fieldnames(VariableSummary)

    summaryGraph = getSummaryGraph(dfg)
    @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
    @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
    # Check all fields are equal for all variables
    for v in ls(summaryGraph)
        for field in variableFields
            a = getproperty(getVariable(dfg, v), field)
            b = getproperty(getVariable(summaryGraph, v), field)
            if field == :solvable
                @test a[] == b[]
            else
                @test a == b
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            a = getproperty(getFactor(dfg, f), field)
            b = getproperty(getFactor(summaryGraph, f), field)
            if field == :solvable
                @test a[] == b[]
            else
                @test a == b
            end
        end
    end
end
