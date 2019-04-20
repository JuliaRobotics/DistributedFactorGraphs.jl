dfg = testDFGAPI()
v1 = DFGVariable(:a)
v2 = DFGVariable(:b)
f1 = DFGFactor(:f1)
@testset "Creating Graphs" begin
    global dfg,v1,v2,f1
    addVariable!(dfg, v1)
    @test_throws Exception addVariable!(dfg, v1)
    addVariable!(dfg, v2)
    addFactor!(dfg, f1, [v1, v2])
    @test_throws Exception addFactor!(dfg, DFGFactor("f2"), [v1, DFGVariable("Nope")])
end

@testset "Listing Nodes" begin
    global dfg,v1,v2,f1
    @test length(ls(dfg)) == 2
    @test length(lsf(dfg)) == 1
    # Regexes
    @test ls(dfg, r"a") == [v1]
    @test lsf(dfg, r"f*") == [f1]
end

# Gets
@testset "Gets and Sets" begin
    global dfg,v1,v2,f1
    @test getVariable(dfg, v1.label) == v1
    @test getFactor(dfg, f1.label) == f1
    @test_throws Exception getVariable(dfg, :nope)
    @test_throws Exception getVariable(dfg, "nope")
    @test_throws Exception getFactor(dfg, :nope)
    @test_throws Exception getFactor(dfg, "nope")

    # Sets
    v1Prime = deepcopy(v1)
    @test updateVariable!(dfg, v1Prime) != v1
    f1Prime = deepcopy(f1)
    @test updateFactor!(dfg, f1Prime) != f1
end

# Deletions
# Not supported at present
@testset "Deletions" begin
    @warn "Deletions with Graph.jl is not supported at present"
end

# Connectivity test
@testset "Connectivity Test" begin
    global dfg,v1,v2,f1
    @test isFullyConnected(dfg) == true
    @test hasOrphans(dfg) == false
    addVariable!(dfg, DFGVariable(:orphan))
    @test isFullyConnected(dfg) == false
    @test hasOrphans(dfg) == true
end

# Adjacency matrices
@testset "Adjacency Matrices" begin
    global dfg,v1,v2,f1
    # Normal
    adjMat = getAdjacencyMatrix(dfg)
    @test size(adjMat) == (2,4)
    @test adjMat[1, :] == [nothing, :a, :b, :orphan]
    @test adjMat[2, :] == [:f1, :f1, :f1, nothing]
    # Dataframe
    adjDf = getAdjacencyMatrixDataFrame(dfg)
    @test size(adjDf) == (1,4)
end

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = testDFGAPI()
verts = map(n -> DFGVariable(Symbol("x$n")), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, DFGFactor(Symbol("x$(n)x$(n+1)f1")), [verts[n], verts[n+1]]), 1:(numNodes-1))
# map(n -> addFactor!(dfg, [verts[n], verts[n+2]], DFGFactor(Symbol("x$(n)x$(n+2)f2"))), 1:2:(numNodes-2))

@testset "Getting Neighbors" begin
    global dfg,verts
    # Get neighbors tests
    @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test all([v in [:x1, :x2] for v in neighbors])
    # Testing aliases
    @test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test getNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)
end

@testset "Getting Subgraphs" begin
    # Subgraphs
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
    # Only returns x1 and x2
    @test setdiff([:x1, :x1x2f1, :x2], map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])) == []
    # Test include orphan factorsVoid
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
    @test setdiff([:x1, :x1x2f1], map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])) == []
    # Test adding to the dfg
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
    @test setdiff([:x1, :x1x2f1, :x2], map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])) == []
end

@testset "Producting Dot Files" begin
    @test toDot(dfg) == "graph graphname {\n18 [\"label\"=\"x8x9f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n2 [\"label\"=\"x2\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 11\n2 -- 12\n16 [\"label\"=\"x6x7f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n11 [\"label\"=\"x1x2f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n7 [\"label\"=\"x7\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n7 -- 16\n7 -- 17\n9 [\"label\"=\"x9\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n9 -- 18\n9 -- 19\n10 [\"label\"=\"x10\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n10 -- 19\n19 [\"label\"=\"x9x10f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n17 [\"label\"=\"x7x8f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n8 [\"label\"=\"x8\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n8 -- 17\n8 -- 18\n6 [\"label\"=\"x6\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n6 -- 15\n6 -- 16\n4 [\"label\"=\"x4\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n4 -- 13\n4 -- 14\n3 [\"label\"=\"x3\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n3 -- 12\n3 -- 13\n5 [\"label\"=\"x5\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n5 -- 14\n5 -- 15\n13 [\"label\"=\"x3x4f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n14 [\"label\"=\"x4x5f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n15 [\"label\"=\"x5x6f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n12 [\"label\"=\"x2x3f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"x1\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 11\n}\n"

    @test toDotFile(dfg, "something.dot") == nothing
end
