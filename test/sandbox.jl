# using HTTP
#
# HTTP.WebSockets.open("ws://127.0.0.1:5000/ws/fb2f2bc2-03ec-49ca-8493-ec9ebb0053ec") do ws
#     x = readavailable(ws)
#     @show x
#     println(String(x))
#
#     for i in 1:10
#         write(ws, "Hello $i")
#         x = readavailable(ws)
#         @show x
#         println(String(x))
#         sleep(1)
#     end
# end

using DistributedFactorGraphs
using IncrementalInference

user = "testUser"

dfg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                            user, "testRobot", "testSession",
                            "Description of test Session",
                            nothing,
                            nothing,
                            IncrementalInference.decodePackedType,
                            IncrementalInference.rebuildFactorMetadata!,
                            solverParams=SolverParams())

dfg2=_getDuplicatedEmptyDFG(dfg)

# Add some nodes.
clearSession!!(dfg)
createDfgSessionIfNotExist(dfg)
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE])
addFactor!(dfg, [:a], Prior(Normal(0,1)))
v2 = addVariable!(dfg, :b, ContinuousScalar, labels = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(dfg, [:b; :c], LinearConditional(Normal(50.0,2.0)) )

# Solve the cloud graph directly.
ensureSolvable!(dfg)
ensureAllInitialized!(dfg)
solveTree!(dfg)

# Copy it locally to solve it.
#localDfg = copyGraph!(LightDFG, dfg)
destDFG = LightDFG(getDFGInfo(dfg)...)
copyGraph!(destDFG, dfg, ls(dfg), lsf(dfg); deepcopyNodes=true)
solveTree!(destDFG)



localDfg = LightDFG(getDFGInfo(dfg)...)
v1 = addVariable!(localDfg, :a, ContinuousScalar, labels = [:POSE])
addFactor!(localDfg, [:a], Prior(Normal(0,1)))
v2 = addVariable!(localDfg, :b, ContinuousScalar, labels = [:POSE])
v3 = addVariable!(localDfg, :c, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(localDfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(localDfg, [:b; :c], LinearConditional(Normal(50.0,2.0)) )
