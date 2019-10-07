if typeof(dfg) <: CloudGraphsDFG
    @warn "TEST: Nuking all data for robot $(dfg.robotId)!"
    clearRobot!!(dfg)
end

####
# Johan, for these to work with CG, we need to use IIF's addVariable, addFactor, etc.
# so the variables and factors are set up correctly
####

# Building simple graph...
# Use IIF to add the variables and factors
v1 = addVariable!(dfg, :v1, ContinuousScalar, labels = [:POSE])
v2 = addVariable!(dfg, :v2, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfg, [:v1; :v2], LinearConditional(Normal(50.0,2.0)) )
#TODO: Get the prior to work - need KernelDensityEstimate for kde!
# pd = resample(kde!(Float64[-100.0;0.0;100.0;300.0],1,4,[3.0]), 100)
# fPrior = addFactor!(fg,[:v1], Prior( pd ) )

# @testset "Creating Graphs" begin
global dfg,v1,v2,f1

#TODO Fix
#test before anything changes
# @testset "Producing Dot Files" begin
#
#     @test toDot(dfg) ==  "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
#     @test toDotFile(dfg, "something.dot") == nothing
#     Base.rm("something.dot")
# end

@testset "Adding Removing Nodes" begin
    # NOTE: Using IIF calls here so we test end-to-end and have everything serialized correctly.
    dfg2 = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
    v1 = addVariable!(dfg2, :v1, ContinuousScalar)
    v2 = addVariable!(dfg2, :v2, ContinuousScalar)
    v3 = addVariable!(dfg2, :v3, ContinuousScalar)
    f1 = addFactor!(dfg2, [:v1; :v2], LinearConditional(Normal(50.0,2.0)) )
    # # Won't fail, will make :v1v2f2
    # #@test_throws ErrorException addFactor!(dfg2, [v1, v2], f1)
    f2 = addFactor!(dfg2, [:v2; :v3], LinearConditional(Normal(50.0,2.0)) )
    @test deleteVariable!(dfg2, v3).label == v3.label # Easier test -use the label for equivalency
    @test symdiff(ls(dfg2),[:v1,:v2]) == []
    @test deleteFactor!(dfg2, f2).label == f2.label
    @test lsf(dfg2) == [:v1v2f1]
end

# @testset "Listing Nodes" begin
#     global dfg,v1,v2,f1
#     @test length(ls(dfg)) == 2
#     @test length(lsf(dfg)) == 1
#     @test symdiff([:a, :b], getVariableIds(dfg)) == []
#     @test getFactorIds(dfg) == [:abf1]
#     #
#     @test lsf(dfg, :a) == [f1.label]
#     # Tags
#     @test ls(dfg, tags=[:POSE]) == [:a]
#     @test symdiff(ls(dfg, tags=[:POSE, :LANDMARK]), ls(dfg, tags=[:VARIABLE])) == []
#     # Regexes
#     @test ls(dfg, r"a") == [v1.label]
#     @test lsf(dfg, r"f*") == [f1.label]
#     # Accessors
#     @test getAddHistory(dfg) == [:a, :b] #, :abf1
#     @test getDescription(dfg) != nothing
#     @test getLabelDict(dfg) != nothing
#     # Existence
#     @test exists(dfg, :a) == true
#     @test exists(dfg, v1) == true
#     @test exists(dfg, :nope) == false
#     # Sorting of results
#     # TODO - this function needs to be cleaned up
#     unsorted = [:x1_3;:x1_6;:l1;:april1] #this will not work for :x1x2f1
#     @test sortDFG(unsorted) == sortVarNested(unsorted)
#     @test_skip sortDFG([:x1x2f1, :x1l1f1]) == [:x1l1f1, :x1x2f1]
# end
#
# # Gets
# @testset "Gets, Sets, and Accessors" begin
#     global dfg,v1,v2,f1
#     @test getVariable(dfg, v1.label) == v1
#     @test getFactor(dfg, f1.label) == f1
#     @test_throws Exception getVariable(dfg, :nope)
#     @test_throws Exception getVariable(dfg, "nope")
#     @test_throws Exception getFactor(dfg, :nope)
#     @test_throws Exception getFactor(dfg, "nope")
#
#     # Sets
#     v1Prime = deepcopy(v1)
#     @test updateVariable!(dfg, v1Prime) != v1
#     f1Prime = deepcopy(f1)
#     @test updateFactor!(dfg, f1Prime) != f1
#
#     # Accessors
#     @test label(v1) == v1.label
#     @test tags(v1) == v1.tags
#     @test timestamp(v1) == v1.timestamp
#     @test estimates(v1) == v1.estimateDict
#     @test DistributedFactorGraphs.estimate(v1, :notfound) == nothing
#     @test solverData(v1) === v1.solverDataDict[:default]
#     @test getData(v1) === v1.solverDataDict[:default]
#     @test solverData(v1, :default) === v1.solverDataDict[:default]
#     @test solverDataDict(v1) == v1.solverDataDict
#     @test internalId(v1) == v1._internalId
#
#     @test label(f1) == f1.label
#     @test tags(f1) == f1.tags
#     @test solverData(f1) == f1.data
#     # Deprecated functions
#     @test data(f1) == f1.data
#     @test getData(f1) == f1.data
#     # Internal function
#     @test internalId(f1) == f1._internalId
#
#     @test getSolverParams(dfg) != nothing
#     @test setSolverParams(dfg, getSolverParams(dfg)) == getSolverParams(dfg)
#
#     #solver data is initialized
#     @test !isInitialized(dfg, :a)
#     @test !isInitialized(v2)
#
#     @test !isInitialized(v2, key=:second)
#
# end
#
# @testset "Updating Nodes" begin
#     global dfg
#     #get the variable
#     var = getVariable(dfg, :a)
#     #make a copy and simulate external changes
#     newvar = deepcopy(var)
#     estimates(newvar)[:default] = Dict{Symbol, VariableEstimate}(
#         :max => VariableEstimate(:default, :max, [100.0]),
#         :mean => VariableEstimate(:default, :mean, [50.0]),
#         :ppe => VariableEstimate(:default, :ppe, [75.0]))
#     #update
#     updateVariableSolverData!(dfg, newvar)
#     #TODO maybe implement ==; @test newvar==var
#     Base.:(==)(varest1::VariableEstimate, varest2::VariableEstimate) = begin
#         varest1.lastUpdatedTimestamp == varest2.lastUpdatedTimestamp || return false
#         varest1.type == varest2.type || return false
#         varest1.solverKey == varest2.solverKey || return false
#         varest1.estimate == varest2.estimate || return false
#         return true
#     end
#     #For now spot check
#     @test_skip solverDataDict(newvar) == solverDataDict(var)
#     @test estimates(newvar) == estimates(var)
#
#     # Delete :default and replace to see if new ones can be added
#     delete!(estimates(newvar), :default)
#     estimates(newvar)[:second] = Dict{Symbol, VariableEstimate}(
#         :max => VariableEstimate(:default, :max, [10.0]),
#         :mean => VariableEstimate(:default, :mean, [5.0]),
#         :ppe => VariableEstimate(:default, :ppe, [7.0]))
#
#     # Persist to the original variable.
#     updateVariableSolverData!(dfg, newvar)
#     # At this point newvar will have only :second, and var should have both (it is the reference)
#     @test symdiff(collect(keys(estimates(var))), [:default, :second]) == Symbol[]
#     @test symdiff(collect(keys(estimates(newvar))), [:second]) == Symbol[]
#     # Get the source too.
#     @test symdiff(collect(keys(estimates(getVariable(dfg, :a)))), [:default, :second]) == Symbol[]
# end
#
# # Connectivity test
# @testset "Connectivity Test" begin
#     global dfg,v1,v2,f1
#     @test isFullyConnected(dfg) == true
#     @test hasOrphans(dfg) == false
#     addVariable!(dfg, DFGVariable(:orphan))
#     @test isFullyConnected(dfg) == false
#     @test hasOrphans(dfg) == true
# end
#
# # Adjacency matrices
# @testset "Adjacency Matrices" begin
#     global dfg,v1,v2,f1
#     # Normal
#     adjMat = getAdjacencyMatrix(dfg)
#     @test size(adjMat) == (2,4)
#     @test symdiff(adjMat[1, :], [nothing, :a, :b, :orphan]) == Symbol[]
#     @test symdiff(adjMat[2, :], [:abf1, :abf1, :abf1, nothing]) == Symbol[]
#     #sparse
#     adjMat, v_ll, f_ll = getAdjacencyMatrixSparse(dfg)
#     @test size(adjMat) == (1,3)
#
#     # Checking the elements of adjacency, its not sorted so need indexing function
#     indexOf = (arr, el1) -> findfirst(el2->el2==el1, arr)
#     @test adjMat[1, indexOf(v_ll, :orphan)] == 0
#     @test adjMat[1, indexOf(v_ll, :a)] == 1
#     @test adjMat[1, indexOf(v_ll, :b)] == 1
#     @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
#     @test symdiff(f_ll, [:abf1, :abf1, :abf1]) == Symbol[]
# end
#
# # Deletions
# @testset "Deletions" begin
#     deleteFactor!(dfg, :abf1)
#     @test getFactorIds(dfg) == []
#     deleteVariable!(dfg, :b)
#     @test symdiff([:a, :orphan], getVariableIds(dfg)) == []
#     #delete last also for the LightGraphs implementation coverage
#     deleteVariable!(dfg, :orphan)
#     @test symdiff([:a], getVariableIds(dfg)) == []
#     deleteVariable!(dfg, :a)
#     @test getVariableIds(dfg) == []
# end
#
#
# # Now make a complex graph for connectivity tests
# numNodes = 10
#
# dfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
# if typeof(dfg) <: CloudGraphsDFG
#     clearSession!!(dfg)
# end
#
# #change ready and backendset for x7,x8 for improved tests on x7x8f1
# verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
# #TODO fix this to use accessors
# verts[7].ready = 1
# # verts[7].backendset = 0
# verts[8].ready = 0
# verts[8].backendset = 1
#
# facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))
#
#
#
# @testset "Getting Neighbors" begin
#     global dfg,verts
#     # Trivial test to validate that intersect([], []) returns order of first parameter
#     @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
#     # Get neighbors tests
#     @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
#     neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
#     @test neighbors == [:x1, :x2]
#     # Testing aliases
#     @test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
#     @test getNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)
#
#     # ready and backendset
#     @test getNeighbors(dfg, :x5, ready=1) == Symbol[]
#     @test getNeighbors(dfg, :x5, ready=0) == [:x4x5f1,:x5x6f1]
#     @test getNeighbors(dfg, :x5, backendset=1) == Symbol[]
#     @test getNeighbors(dfg, :x5, backendset=0) == [:x4x5f1,:x5x6f1]
#     @test getNeighbors(dfg, :x7x8f1, ready=0) == [:x8]
#     @test getNeighbors(dfg, :x7x8f1, backendset=0) == [:x7]
#     @test getNeighbors(dfg, :x7x8f1, ready=1) == [:x7]
#     @test getNeighbors(dfg, :x7x8f1, backendset=1) == [:x8]
#     @test getNeighbors(dfg, verts[1], ready=0) == [:x1x2f1]
#     @test getNeighbors(dfg, verts[1], ready=1) == Symbol[]
#     @test getNeighbors(dfg, verts[1], backendset=0) == [:x1x2f1]
#     @test getNeighbors(dfg, verts[1], backendset=1) == Symbol[]
#
# end
#
# @testset "Getting Subgraphs" begin
#     # Subgraphs
#     dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     # Test include orphan factorsVoid
#     dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
#     @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     # Test adding to the dfg
#     dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     #
#     dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#
#     # DFG issue #95 - confirming that getSubgraphAroundNode retains order
#     # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
#     for fId in getVariableIds(dfg)
#         # Get a subgraph of this and it's related factors+variables
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#         # For each factor check that the order the copied graph == original
#         for fact in getFactors(dfgSubgraph)
#             @test fact._variableOrderSymbols == getFactor(dfg, fact.label)._variableOrderSymbols
#         end
#     end
# end
#
# @testset "Summaries and Summary Graphs" begin
#     factorFields = fieldnames(DFGFactorSummary)
#     variableFields = fieldnames(DFGVariableSummary)
#
#     summary = getSummary(dfg)
#     @test symdiff(collect(keys(summary.variables)), ls(dfg)) == Symbol[]
#     @test symdiff(collect(keys(summary.factors)), lsf(dfg)) == Symbol[]
#
#     summaryGraph = getSummaryGraph(dfg)
#     @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
#     @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
#     # Check all fields are equal for all variables
#     for v in ls(summaryGraph)
#         for field in variableFields
#             @test getfield(getVariable(dfg, v), field) == getfield(getVariable(summaryGraph, v), field)
#         end
#     end
#     for f in lsf(summaryGraph)
#         for field in factorFields
#             @test getfield(getFactor(dfg, f), field) == getfield(getFactor(summaryGraph, f), field)
#         end
#     end
# end
