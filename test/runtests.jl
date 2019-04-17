using Test
using DataFrames
using DistributedFactorGraphs
using DistributedFactorGraphs.GraphsJl

dfg = GraphsDFG()
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
    @test updateVariable(dfg, v1Prime) != v1
    f1Prime = deepcopy(f1)
    @test updateFactor(dfg, f1Prime) != f1
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
    addVariable!(dfg, DFGVariable(:orphan))
    @test isFullyConnected(dfg) == false
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
dfg = GraphsDFG()
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
    @test all([v in [:x1, :x1x2f1, :x2] for v in map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])])
    # Test include orphan factorsVoid
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
    @test all([v in [:x1, :x1x2f1] for v in map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])])
    # Test adding to the dfg
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
    @test all([v in [:x1, :x1x2f1, :x2] for v in map(n -> n.label, [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])])
end
