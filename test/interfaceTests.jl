dfg = testDFGAPI{NoSolverParams}()

#add types for softtypes
struct TestInferenceVariable1 <: InferenceVariable end
struct TestInferenceVariable2 <: InferenceVariable end

v1 = DFGVariable(:a, TestInferenceVariable1())
v2 = DFGVariable(:b, TestInferenceVariable2())
f1 = DFGFactor{Int, :Symbol}(:f1)

#add tags for filters
append!(v1.tags, [:VARIABLE, :POSE])
append!(v2.tags, [:VARIABLE, :LANDMARK])
append!(f1.tags, [:FACTOR])

st1 = TestInferenceVariable1()
st2 = TestInferenceVariable2()

v1.solverDataDict[:default].softtype = deepcopy(st1)
v2.solverDataDict[:default].softtype = deepcopy(st2)

# NOTE: Just for testing
# Override compareAllSpecial for testing our DFGFactor{Int, :Symbol}
# as we don't have IIF which overloads with the proper compareSpecial(::CommonConvWrapper)
import DistributedFactorGraphs: compareAllSpecial
function compareAllSpecial(A::T1, B::T2;
                    skip=Symbol[], show::Bool=true) where {T1 <: Int, T2 <: Int}
  #
  T1 != T2 && return false
  return compareAll(A, B, skip=skip, show=show)
end

# @testset "Creating Graphs" begin
global dfg,v1,v2,f1
addVariable!(dfg, v1)
addVariable!(dfg, v2)
addFactor!(dfg, [v1, v2], f1)
@test_throws Exception addFactor!(dfg, DFGFactor{Int, :Symbol}("f2"), [v1, DFGVariable("Nope")])
# end

@testset "Adding Removing Nodes" begin
    dfg2 = testDFGAPI{NoSolverParams}()
    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    v3 = DFGVariable(:c, TestInferenceVariable1())
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
    # Tags
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
    # Sorting of results
    # TODO - this function needs to be cleaned up
    unsorted = [:x1_3;:x1_6;:l1;:april1] #this will not work for :x1x2f1
    @test sortDFG(unsorted) == sortVarNested(unsorted)
    @test_skip sortDFG([:x1x2f1, :x1l1f1]) == [:x1l1f1, :x1x2f1]
end

# Gets
@testset "Gets, Sets, and Accessors" begin
    global dfg,v1,v2,f1
    @test getVariable(dfg, v1.label) == v1
    @test getVariable(dfg, v2.label) != v1
    @test getFactor(dfg, f1.label) == f1
    f2 = deepcopy(f1)
    f2.label = :something
    @test f2 != f1
    @test_throws Exception getVariable(dfg, :nope)
    @test_throws Exception getVariable(dfg, "nope")
    @test_throws Exception getFactor(dfg, :nope)
    @test_throws Exception getFactor(dfg, "nope")

    # Sets
    v1Prime = deepcopy(v1)
    #updateVariable! returns the variable updated, so should be equal
    @test updateVariable!(dfg, v1Prime) == v1
    f1Prime = deepcopy(f1)
    #updateFactor! returns the factor updated, so should be equal
    @test updateFactor!(dfg, f1Prime) == f1

    # Accessors
    @test label(v1) == v1.label
    @test tags(v1) == v1.tags
    @test timestamp(v1) == v1.timestamp
    @test estimates(v1) == v1.estimateDict
    @test estimate(v1, :notfound) == nothing
    @test solverData(v1) === v1.solverDataDict[:default]
    @test getData(v1) === v1.solverDataDict[:default]
    @test solverData(v1, :default) === v1.solverDataDict[:default]
    @test solverDataDict(v1) == v1.solverDataDict
    @test internalId(v1) == v1._internalId

    @test softtype(v1) == Symbol(typeof(st1))
    @test softtype(v2) == Symbol(typeof(st2))
    @test getSofttype(v1) == st1

    @test label(f1) == f1.label
    @test tags(f1) == f1.tags
    @test solverData(f1) == f1.data
    # Deprecated functions
    @test data(f1) == f1.data
    @test getData(f1) == f1.data
    # Internal function
    @test internalId(f1) == f1._internalId

    @test getSolverParams(dfg) != nothing
    @test setSolverParams(dfg, getSolverParams(dfg)) == getSolverParams(dfg)

    #solver data is initialized
    @test !isInitialized(dfg, :a)
    @test !isInitialized(v2)

    @test !isInitialized(v2, key=:second)

    # Session, robot, and user small data tests
    smallUserData = Dict{Symbol, String}(:a => "42", :b => "Hello")
    smallRobotData = Dict{Symbol, String}(:a => "43", :b => "Hello")
    smallSessionData = Dict{Symbol, String}(:a => "44", :b => "Hello")
    setUserData(dfg, deepcopy(smallUserData))
    setRobotData(dfg, deepcopy(smallRobotData))
    setSessionData(dfg, deepcopy(smallSessionData))
    @test getUserData(dfg) == smallUserData
    @test getRobotData(dfg) == smallRobotData
    @test getSessionData(dfg) == smallSessionData

end

@testset "BigData" begin
    oid = zeros(UInt8,12); oid[12] = 0x01
    de1 = MongodbBigDataEntry(:key1, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x02
    de2 = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x03
    de2_update = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    #add
    v1 = getVariable(dfg, :a)
    @test addBigDataEntry!(v1, de1)
    @test addBigDataEntry!(dfg, :a, de2)
    @test addBigDataEntry!(v1, de1)

    #get
    @test deepcopy(de1) == getBigDataEntry(v1, :key1)
    @test deepcopy(de2) == getBigDataEntry(dfg, :a, :key2)
    @test_throws Any getBigDataEntry(v2, :key1)
    @test_throws Any getBigDataEntry(dfg, :b, :key1)

    #update
    @test updateBigDataEntry!(dfg, :a, de2_update)
    @test deepcopy(de2_update) == getBigDataEntry(dfg, :a, :key2)
    @test !updateBigDataEntry!(dfg, :b, de2_update)

    #list
    entries = getBigDataEntries(dfg, :a)
    @test length(entries) == 2
    @test symdiff(map(e->e.key, entries), [:key1, :key2]) == Symbol[]
    @test length(getBigDataEntries(dfg, :b)) == 0

    @test symdiff(getBigDataKeys(dfg, :a), [:key1, :key2]) == Symbol[]
    @test getBigDataKeys(dfg, :b) == Symbol[]

    #delete
    @test deepcopy(de1) == deleteBigDataEntry!(v1, :key1)
    @test getBigDataKeys(v1) == Symbol[:key2]
    #delete from dfg
    @test deepcopy(de2_update) == deleteBigDataEntry!(dfg, :a, :key2)
    @test getBigDataKeys(v1) == Symbol[]
end

@testset "Updating Nodes" begin
    global dfg
    #get the variable
    var = getVariable(dfg, :a)
    #make a copy and simulate external changes
    newvar = deepcopy(var)
    estimates(newvar)[:default] = MeanMaxPPE(:default, [150.0], [100.0], [50.0])
    #update
    mergeUpdateVariableSolverData!(dfg, newvar)

    #For now spot check
    @test solverDataDict(newvar) == solverDataDict(var)
    @test estimates(newvar) == estimates(var)

    # Delete :default and replace to see if new ones can be added
    delete!(estimates(newvar), :default)
    estimates(newvar)[:second] = MeanMaxPPE(:second, [15.0], [10.0], [5.0])

    # Persist to the original variable.
    mergeUpdateVariableSolverData!(dfg, newvar)
    # At this point newvar will have only :second, and var should have both (it is the reference)
    @test symdiff(collect(keys(estimates(var))), [:default, :second]) == Symbol[]
    @test symdiff(collect(keys(estimates(newvar))), [:second]) == Symbol[]
    # Get the source too.
    @test symdiff(collect(keys(estimates(getVariable(dfg, :a)))), [:default, :second]) == Symbol[]
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

    # Checking the elements of adjacency, its not sorted so need indexing function
    indexOf = (arr, el1) -> findfirst(el2->el2==el1, arr)
    @test adjMat[1, indexOf(v_ll, :orphan)] == 0
    @test adjMat[1, indexOf(v_ll, :a)] == 1
    @test adjMat[1, indexOf(v_ll, :b)] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:f1, :f1, :f1]) == Symbol[]
end

# Deletions
@testset "Deletions" begin
    deleteFactor!(dfg, :f1)
    @test getFactorIds(dfg) == []
    deleteVariable!(dfg, :b)
    @test symdiff([:a, :orphan], getVariableIds(dfg)) == []
    #delete last also for the LightGraphs implementation coverage
    deleteVariable!(dfg, :orphan)
    @test symdiff([:a], getVariableIds(dfg)) == []
    deleteVariable!(dfg, :a)
    @test getVariableIds(dfg) == []
end


# Now make a complex graph for connectivity tests
numNodes = 10
dfg = testDFGAPI{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n"), TestInferenceVariable1()), 1:numNodes)
#change ready and backendset for x7,x8 for improved tests on x7x8f1
verts[7].ready = 1
verts[8].backendset = 1

# Can't change the softtypes now.
# #force softytypes to first 2 vertices.
# verts[1].solverDataDict[:default].softtype = deepcopy(st1)
# verts[2].solverDataDict[:default].softtype = deepcopy(st2)

map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, [verts[n], verts[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:(numNodes-1))

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

    # DFG issue #95 - confirming that getSubgraphAroundNode retains order
    # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
    for fId in getVariableIds(dfg)
        # Get a subgraph of this and it's related factors+variables
        dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
        # For each factor check that the order the copied graph == original
        for fact in getFactors(dfgSubgraph)
            @test fact._variableOrderSymbols == getFactor(dfg, fact.label)._variableOrderSymbols
        end
    end
end

@testset "Summaries and Summary Graphs" begin
    factorFields = fieldnames(DFGFactorSummary)
    variableFields = fieldnames(DFGVariableSummary)

    summary = getSummary(dfg)
    @test symdiff(collect(keys(summary.variables)), ls(dfg)) == Symbol[]
    @test symdiff(collect(keys(summary.factors)), lsf(dfg)) == Symbol[]

    summaryGraph = getSummaryGraph(dfg)
    @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
    @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
    # Check all fields are equal for all variables
    for v in ls(summaryGraph)
        for field in variableFields
            if field != :softtypename
                @test getfield(getVariable(dfg, v), field) == getfield(getVariable(summaryGraph, v), field)
            else
                @test softtype(getVariable(dfg, v)) == softtype(getVariable(summaryGraph, v))
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            @test getfield(getFactor(dfg, f), field) == getfield(getFactor(summaryGraph, f), field)
        end
    end
end

@testset "Producing Dot Files" begin
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI{NoSolverParams}()
    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    f1 = DFGFactor{Int, :Symbol}(:f1)
    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    addFactor!(dotdfg, [v1, v2], f1)

    @test toDot(dotdfg) == "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"f1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
    @test toDotFile(dotdfg, "something.dot") == nothing
    Base.rm("something.dot")

end
