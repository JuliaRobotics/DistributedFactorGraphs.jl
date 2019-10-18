# using Revise
using Neo4j
using DistributedFactorGraphs
using IncrementalInference
using Test
using Logging
# Debug logging
logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

dfg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                            "testUser", "testRobot", "sandbox",
                            nothing,
                            nothing,
                            IncrementalInference.decodePackedType,
                            IncrementalInference.rebuildFactorMetadata!,
                            solverParams=SolverParams())
clearRobot!!(dfg)
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE])
v2 = addVariable!(dfg, :b, ContinuousScalar, labels = [:LANDMARK])
v3 = addVariable!(dfg, :c, ContinuousScalar, labels = [:LANDMARK])
v4 = addVariable!(dfg, :d, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfg, [:a; :b, :c, :d], LinearConditional(Normal(50.0,2.0)) )
v1 == deepcopy(v1)
v1_back == getVariable(dfg, :a)
getNeighbors(f1)
f1._variableOrderSymbols

T = typeof(dfg)
if T <: CloudGraphsDFG
    dfg2 = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                                        "testUser", "testRobot", "testSession2",
                                        nothing,
                                        nothing,
                                        IncrementalInference.decodePackedType,
                                        IncrementalInference.rebuildFactorMetadata!,
                                        solverParams=SolverParams())
else
    dfg2 = T()
end
iiffg = initfg()
v1 = deepcopy(addVariable!(iiffg, :a, ContinuousScalar))
v2 = deepcopy(addVariable!(iiffg, :b, ContinuousScalar))
v3 = deepcopy(addVariable!(iiffg, :c, ContinuousScalar))
f1 = deepcopy(addFactor!(iiffg, [:a; :b], LinearConditional(Normal(50.0,2.0)) ))
f2 = deepcopy(addFactor!(iiffg, [:b; :c], LinearConditional(Normal(10.0,1.0)) ))

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

dv3 = deleteVariable!(dfg2, v3)
#TODO write compare if we want to compare complete one, for now just label
# @test dv3 == v3
@test dv3.label == v3.label
@test_throws ErrorException deleteVariable!(dfg2, v3)

@test symdiff(ls(dfg2),[:a,:b]) == []
df2 = deleteFactor!(dfg2, f2)
#TODO write compare if we want to compare complete one, for now just label
# @test df2 == f2
@test df2.label == f2.label
@test_throws ErrorException deleteFactor!(dfg2, f2)

@test lsf(dfg2) == [:abf1]

@test length(ls(dfg)) == 2
@test length(lsf(dfg)) == 1 # Unless we add the prior!
@test symdiff([:a, :b], getVariableIds(dfg)) == []
@test getFactorIds(dfg) == [:abf1] # Unless we add the prior!
#
@test lsf(dfg, :a) == [f1.label]
# Tags
@test ls(dfg, tags=[:POSE]) == [:a]
@test symdiff(ls(dfg, tags=[:POSE, :LANDMARK]), ls(dfg, tags=[:VARIABLE])) == []
# Regexes
@test ls(dfg, r"a") == [v1.label]
# TODO: Check that this regular expression works on everything else!
# it works with the .
# REF: https://stackoverflow.com/questions/23834692/using-regular-expression-in-neo4j
@test lsf(dfg, r"abf.*") == [f1.label]

# Accessors
@test getAddHistory(dfg) == [:a, :b] #, :abf1
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
@test tags(v1) == v1.tags
@test timestamp(v1) == v1.timestamp
@test estimates(v1) == v1.estimateDict
@test DistributedFactorGraphs.estimate(v1, :notfound) == nothing
@test solverData(v1) === v1.solverDataDict[:default]
@test getData(v1) === v1.solverDataDict[:default]
@test solverData(v1, :default) === v1.solverDataDict[:default]
@test solverDataDict(v1) == v1.solverDataDict
@test internalId(v1) == v1._internalId

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
