using GraphPlot
using Neo4j
using DistributedFactorGraphs
using IncrementalInference

@testset "test fourdoor early example" begin

DistributedFactorGraphs.CloudGraphsDFG{SolverParams}() = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                                                                    "testUser", "testRobot", "testSession",
                                                                    nothing,
                                                                    nothing,
                                                                    IncrementalInference.decodePackedType,
                                                                    IncrementalInference.rebuildFactorMetadata!,
                                                                    solverParams=SolverParams())

N=100
# fg = initfg(CloudGraphsDFG{SolverParams}())
fg = initfg(GraphsDFG{SolverParams})

doors = reshape(Float64[-100.0;0.0;100.0;300.0],1,4)
pd = kde!(doors,[3.0])
pd = resample(pd,N);
bws = getBW(pd)[:,1]
doors2 = getPoints(pd);


addVariable!(fg,:x0,ContinuousScalar,N=N)
addFactor!(fg,[:x0], Prior( pd ) )

# tem = 2.0*randn(1,N)+getVal(v1)+50.0
addVariable!(fg,:x2, ContinuousScalar, N=N)
addFactor!(fg, [:x0; :x2], LinearConditional(Normal(50.0,2.0)) )
# addFactor!(fg, [v1;v2], Odo(50.0*ones(1,1),[2.0]',[1.0]))


# monocular sighting would look something like
#addFactor!(fg, Mono, [:x3,:l1], [14.0], [1.0], [1.0])
#addFactor!(fg, Mono, [:x4,:l1], [11.0], [1.0], [1.0])

addVariable!(fg,:x3,ContinuousScalar, N=N)
addFactor!(fg,[:x2;:x3], LinearConditional( Normal(50.0,4.0)) )
addFactor!(fg,[:x3], Prior( pd ))

addVariable!(fg,:x4,ContinuousScalar, N=N)
addFactor!(fg,[:x3;:x4], LinearConditional( Normal(50.0,2.0)) )


addVariable!(fg, :l1, ContinuousScalar, N=N)
addFactor!(fg, [:x3,:l1], Ranged([64.0],[0.5],[1.0]))
addFactor!(fg, [:x4,:l1], Ranged([16.0],[0.5],[1.0]))



addVariable!(fg,:x5,ContinuousScalar, N=N)
addFactor!(fg,[:x4;:x5], LinearConditional( Normal(50.0,2.0)) )


addVariable!(fg,:x6,ContinuousScalar, N=N)
addFactor!(fg,[:x5;:x6], LinearConditional( Normal(40.0,1.20)) )


addVariable!(fg,:x7,ContinuousScalar, N=N)
addFactor!(fg,[:x6;:x7], LinearConditional( Normal(60.0,2.0)) )

# ensureAllInitialized!(fg)

mlc = MixturePrior(Normal.(doors[1,:], bws[1]), 0.25*ones(4))

# getSample(mlc)

addFactor!(fg,[:x7], mlc )


dfgplot(fg)

tree, smt, hist = solveTree!(fg)


end

#
