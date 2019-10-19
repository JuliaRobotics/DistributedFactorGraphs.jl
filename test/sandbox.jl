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

numNodes = 10
#change ready and backendset for x7,x8 for improved tests on x7x8f1
verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
#TODO fix this to use accessors
verts[7].ready = 1
# verts[7].backendset = 0
verts[8].ready = 0
verts[8].backendset = 1
#call update to set it on cloud
updateVariable!(dfg, verts[7])
updateVariable!(dfg, verts[8])

facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))

# Get neighbors tests
@test getNeighbors(dfg, verts[1]) == [:x1x2f1]
neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
@test neighbors == [:x1, :x2]
# Testing aliases
@test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
@test getNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

# ready and backendset
@test getNeighbors(dfg, :x5, ready=1) == Symbol[]
#TODO Confirm: test failed on GraphsDFG, don't know if the order is important for isa variable.
@test symdiff(getNeighbors(dfg, :x5, ready=0), [:x4x5f1,:x5x6f1]) == []
@test getNeighbors(dfg, :x5, backendset=1) == Symbol[]
@test symdiff(getNeighbors(dfg, :x5, backendset=0),[:x4x5f1,:x5x6f1]) == []
@test getNeighbors(dfg, :x7x8f1, ready=0) == [:x8]
@test getNeighbors(dfg, :x7x8f1, backendset=0) == [:x7]
@test getNeighbors(dfg, :x7x8f1, ready=1) == [:x7]
@test getNeighbors(dfg, :x7x8f1, backendset=1) == [:x8]
@test getNeighbors(dfg, verts[1], ready=0) == [:x1x2f1]
@test getNeighbors(dfg, verts[1], ready=1) == Symbol[]
@test getNeighbors(dfg, verts[1], backendset=0) == [:x1x2f1]
@test getNeighbors(dfg, verts[1], backendset=1) == Symbol[]
