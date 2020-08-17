using DistributedFactorGraphs
using IncrementalInference

dfg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                            "testUser", "testRobot", "testSession",
                            "description of test session",
                            solverParams=SolverParams())

# Nuke the user
clearUser!!(dfg)

# Add some nodes.
v1 = addVariable!(dfg, :a, ContinuousScalar, tags = [:POSE])
v2 = addVariable!(dfg, :b, ContinuousScalar, tags = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, tags = [:LANDMARK])
addFactor!(dfg, [:a], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(dfg, [:b; :c], LinearConditional(Normal(50.0,2.0)) )

# Pull and solve this graph
dfgLocal = LightDFG{SolverParams}(solverParams=SolverParams())
DistributedFactorGraphs.getSubgraph(dfg, union(ls(dfg), lsf(dfg)), true, dfgLocal)

# Solve it
tree, smtasks = solveTree!(dfgLocal)
