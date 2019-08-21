dfg = testDFGAPI{NoSolverParams}()
v1 = DFGVariable(:a)
v2 = DFGVariable(:b)
f1 = DFGFactor{Int, :Symbol}(:f1)

#add tags for filters
append!(v1.tags,[:VARIABLE, :POSE])
append!(v2.tags, [:VARIABLE, :LANDMARK])
append!(f1.tags, [:FACTOR])

# @testset "Creating Graphs" begin
global dfg,v1,v2,f1
addVariable!(dfg, v1)
addVariable!(dfg, v2)
addFactor!(dfg, [v1, v2], f1)
@test_throws Exception addFactor!(dfg, DFGFactor{Int, :Symbol}("f2"), [v1, DFGVariable("Nope")])
# end

@testset "Adding Removing Nodes" begin
    dfg2 = testDFGAPI{NoSolverParams}()
    v1 = DFGVariable(:a)
    v2 = DFGVariable(:b)
    v3 = DFGVariable(:c)
    f1 = DFGFactor{Int, :Symbol}(:f1)
    f2 = DFGFactor{Int, :Symbol}(:f2)
    # @testset "Creating Graphs" begin
    @test addVariable!(dfg2, v1)
    @test addVariable!(dfg2, v2)
    @test_throws ErrorException updateVariable!(dfg2, v3)
    @test addVariable!(dfg2, v3)
    @test_throws ErrorException addVariable!(dfg2, v3)
    @test addFactor!(dfg2, [v1, v2], f1)
    @test_throws ErrorException addFactor!(dfg2, [v1, v2], f1)
    @test_throws ErrorException updateFactor!(dfg2, f2)
    @test addFactor!(dfg2, [:b, :c], f2)
    @test deleteVariable!(dfg2, v3) == v3
    @test symdiff(ls(dfg2),[:a,:b]) == []
    @test deleteFactor!(dfg2, f2) == f2
    @test lsf(dfg2) == [:f1]
end

@testset "Listing Nodes" begin
    global dfg,v1,v2,f1
    @test length(ls(dfg)) == 2
    @test length(lsf(dfg)) == 1
    @test symdiff([:a, :b], getVariableIds(dfg)) == []
    @test getFactorIds(dfg) == [:f1]
    #
    @test lsf(dfg, :a) == [f1.label]
    #tags
    @test ls(dfg, tags=[:POSE]) == [:a]
    @test symdiff(ls(dfg, tags=[:POSE, :LANDMARK]), ls(dfg, tags=[:VARIABLE])) == []
    # Regexes
    @test ls(dfg, r"a") == [v1.label]
    @test lsf(dfg, r"f*") == [f1.label]
    # Accessors
    @test getAddHistory(dfg) == [:a, :b] #, :f1
    @test getDescription(dfg) != nothing
    @test getLabelDict(dfg) != nothing
    # Existence
    @test exists(dfg, :a) == true
    @test exists(dfg, v1) == true
    @test exists(dfg, :nope) == false
end

# Gets
@testset "Gets, Sets, and Accessors" begin
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

    # Accessors
    @test label(v1) == v1.label
    @test timestamp(v1) == v1.timestamp
    @test estimates(v1) == v1.estimateDict
    @test estimate(v1, :notfound) == nothing
    @test solverData(v1) === v1.solverDataDict[:default]
    @test solverData(v1, :default) === v1.solverDataDict[:default]
    @test solverDataDict(v1) == v1.solverDataDict
    @test id(v1) == v1._internalId

    @test label(f1) == f1.label
    @test data(f1) == f1.data
    @test id(f1) == f1._internalId
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
    @test symdiff(adjMat[1, :], [nothing, :a, :b, :orphan]) == Symbol[]
    @test symdiff(adjMat[2, :], [:f1, :f1, :f1, nothing]) == Symbol[]
    #sparse
    adjMat, v_ll, f_ll = getAdjacencyMatrixSparse(dfg)
    @test size(adjMat) == (1,3)
    #TODO hoe om te toets, volgorde nie altyd dieselfde nie
    # @test adjMat[1, 1] == 0
    # @test adjMat[1, 2] == 1
    # @test adjMat[1, 3] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:f1, :f1, :f1]) == Symbol[]

    # Dataframe
    adjDf = getAdjacencyMatrixDataFrame(dfg)
    @test size(adjDf) == (1,4)
end

# Deletions
# Not supported at present
@testset "Deletions" begin
    deleteFactor!(dfg, :f1)
    @test getFactorIds(dfg) == []
    deleteVariable!(dfg, :b)
    @test symdiff([:a, :orphan], getVariableIds(dfg)) == []
end


# Now make a complex graph for connectivity tests
numNodes = 10
dfg = testDFGAPI{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n")), 1:numNodes)
#change ready and backendset for x7,x8 for improved tests on x7x8f1
verts[7].ready = 1
verts[8].backendset = 1
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, [verts[n], verts[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:(numNodes-1))
# map(n -> addFactor!(dfg, [verts[n], verts[n+2]], DFGFactor(Symbol("x$(n)x$(n+2)f2"))), 1:2:(numNodes-2))

@testset "Getting Neighbors" begin
    global dfg,verts
    # Trivial test to validate that intersect([], []) returns order of first parameter
    @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
    # Get neighbors tests
    @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test neighbors == [:x1, :x2]
    # Testing aliases
    @test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test getNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

    # ready and backendset
    @test getNeighbors(dfg, :x5, ready=1) == Symbol[]
    @test getNeighbors(dfg, :x5, ready=0) == [:x4x5f1,:x5x6f1]
    @test getNeighbors(dfg, :x5, backendset=1) == Symbol[]
    @test getNeighbors(dfg, :x5, backendset=0) == [:x4x5f1,:x5x6f1]
    @test getNeighbors(dfg, :x7x8f1, ready=0) == [:x8]
    @test getNeighbors(dfg, :x7x8f1, backendset=0) == [:x7]
    @test getNeighbors(dfg, :x7x8f1, ready=1) == [:x7]
    @test getNeighbors(dfg, :x7x8f1, backendset=1) == [:x8]
    @test getNeighbors(dfg, verts[1], ready=0) == [:x1x2f1]
    @test getNeighbors(dfg, verts[1], ready=1) == Symbol[]
    @test getNeighbors(dfg, verts[1], backendset=0) == [:x1x2f1]
    @test getNeighbors(dfg, verts[1], backendset=1) == Symbol[]

end

@testset "Getting Subgraphs" begin
    # Subgraphs
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test include orphan factorsVoid
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
    @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test adding to the dfg
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    #
    dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
end

@testset "Producing Dot Files" begin
    if testDFGAPI != GraphsDFG
        @warn "Skipping non Graphs.jl toDot functions"
        @test_skip 1==0#toDot(dfg)
        @test_skip 1==0#toDotFile(dfg, "something.dot")
    else
        @test toDot(dfg) == "graph graphname {\n18 [\"label\"=\"x8x9f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n2 [\"label\"=\"x2\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 11\n2 -- 12\n16 [\"label\"=\"x6x7f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n11 [\"label\"=\"x1x2f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n7 [\"label\"=\"x7\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n7 -- 16\n7 -- 17\n9 [\"label\"=\"x9\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n9 -- 18\n9 -- 19\n10 [\"label\"=\"x10\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n10 -- 19\n19 [\"label\"=\"x9x10f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n17 [\"label\"=\"x7x8f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n8 [\"label\"=\"x8\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n8 -- 17\n8 -- 18\n6 [\"label\"=\"x6\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n6 -- 15\n6 -- 16\n4 [\"label\"=\"x4\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n4 -- 13\n4 -- 14\n3 [\"label\"=\"x3\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n3 -- 12\n3 -- 13\n5 [\"label\"=\"x5\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n5 -- 14\n5 -- 15\n13 [\"label\"=\"x3x4f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n14 [\"label\"=\"x4x5f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n15 [\"label\"=\"x5x6f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n12 [\"label\"=\"x2x3f1\",\"shape\"=\"ellipse\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"x1\",\"shape\"=\"box\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 11\n}\n"

        @test toDotFile(dfg, "something.dot") == nothing
        Base.rm("something.dot")
    end
end
