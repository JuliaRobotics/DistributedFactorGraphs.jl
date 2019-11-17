# using Revise
# using Neo4j

# Debug logging
# using DistributedFactorGraphs
using Test
using Logging
using Neo4j
using DistributedFactorGraphs
using IncrementalInference
logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

dfg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                            "testUser", "testRobot", "testSession",
                            nothing,
                            nothing,
                            IncrementalInference.decodePackedType,
                            IncrementalInference.rebuildFactorMetadata!,
                            solverParams=SolverParams())
user = User(Symbol(dfg.userId), "Bob Zack", "Description", Dict{Symbol, String}())
@test_throws Exception createUser(dfg, user) == user

isFullyConnected(dfg)
hasOrphans(dfg)
dfgSubgraph = getSubgraphAroundNode(dfg, getVariable(dfg, :x1), 2)
