using Test
using DataFrames
using DistributedFactorGraphs
using DistributedFactorGraphs.GraphsJlAPI

dfg = GraphsDFG()
v1 = DFGVariable(:a)
v2 = DFGVariable(:b)
addVariable!(dfg, v1)
@test_throws Exception addVariable!(dfg, v1)
addVariable!(dfg, v2)
f1 = DFGFactor(:f1)
addFactor!(dfg, f1, [v1, v2])
@test_throws Exception addFactor!(dfg, DFGFactor("f2"), [v1, DFGVariable("Nope")])

@test length(ls(dfg)) == 2
@test length(lsf(dfg)) == 1
# Regexes
@test ls(dfg, r"a") == [v1]
@test lsf(dfg, r"f*") == [f1]

# Gets
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

# Deletions
# Not supported at present
@warn "Deletions with Graph.jl is not supported at present"

# Connectivity test
@test isFullyConnected(dfg) == true
addVariable!(dfg, DFGVariable(:orphan))
@test isFullyConnected(dfg) == false

# Adjacency matrices
adjMat = getAdjacencyMatrixDataFrame(dfg)
@test size(adjMat) == (4,4)

# Testing
using Test
using DataFrames
using DistributedFactorGraphs
using DistributedFactorGraphs.GraphsJlAPI

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = GraphsDFG()
verts = map(n -> DFGVariable(Symbol("x$n")), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, DFGFactor(Symbol("x$(n)x$(n+1)f1")), [verts[n], verts[n+1]]), 1:(numNodes-1))
# map(n -> addFactor!(dfg, [verts[n], verts[n+2]], DFGFactor(Symbol("x$(n)x$(n+2)f2"))), 1:2:(numNodes-2))
adjMat = getAdjacencyMatrixDataFrame(dfg)

# Get neighbors tests
@test getNeighbors(dfg, verts[1]) == [:x1x2f1]
neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
@test all([v in [:x1, :x2] for v in neighbors])
# Testing alias
@test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))

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
