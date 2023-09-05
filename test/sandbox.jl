using DistributedFactorGraphs
using Neo4j
using Profile
using BenchmarkTools
using IncrementalInference

neo4jConnection =
    Neo4j.Connection("localhost"; port = 7474, user = "neo4j", password = "test")
graph = Neo4j.getgraph(neo4jConnection)
neo4jInstance = Neo4jInstance(neo4jConnection, graph)

dfg = Neo4jDFG{SolverParams}(
    neo4jInstance,
    "test@navability.io",
    "DefaultRobot",
    "Session_a892c5",
    "Description of test session",
    Symbol[],
    SolverParams();
    createSessionNodes = false,
    blobStores = Dict{Symbol, AbstractBlobStore}(),
)
createDfgSessionIfNotExist(dfg)

v1 = addVariable!(dfg, :a, Position{1}; tags = [:POSE], solvable = 0)
v2 = addVariable!(dfg, :b, ContinuousScalar; tags = [:LANDMARK], solvable = 1)
f1 = addFactor!(dfg, [:a; :b], LinearRelative(Normal(50.0, 2.0)); solvable = 0)

lsWho(dfg, :Position)
