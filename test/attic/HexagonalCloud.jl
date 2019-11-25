using Revise
using Neo4j # So that DFG initializes the database driver.
using RoME
using DistributedFactorGraphs
using Test, Dates
# start with an empty factor graph object
# fg = initfg()
cloudFg = CloudGraphsDFG{SolverParams}("localhost", 7474, "neo4j", "test",
    "testUser", "testRobot", "testSession",
    nothing,
    nothing,
    IncrementalInference.decodePackedType,
    IncrementalInference.rebuildFactorMetadata!,
    solverParams=SolverParams())
# cloudFg = GraphsDFG{SolverParams}(params=SolverParams())
clearSession!!(cloudFg)

# Add the first pose :x0
x0 = addVariable!(cloudFg, :x0, Pose2)

# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(cloudFg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Drive around in a hexagon in the cloud
for i in 0:5
    psym = Symbol("x$i")
    nsym = Symbol("x$(i+1)")
    addVariable!(cloudFg, nsym, Pose2)
    pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    addFactor!(cloudFg, [psym;nsym], pp )
end

# Right, let's copy it into local memory for solving...
localFg = GraphsDFG{SolverParams}(params=SolverParams())
DistributedFactorGraphs._copyIntoGraph!(cloudFg, localFg, union(getVariableIds(cloudFg), getFactorIds(cloudFg)), true)
# Duplicate for later
localFgCopy = deepcopy(localFg)

# Some checks
@test symdiff(getVariableIds(localFg), getVariableIds(cloudFg)) == []
@test symdiff(getFactorIds(localFg), getFactorIds(cloudFg)) == []
@test isFullyConnected(localFg)
# Show it
toDotFile(localFg, "/tmp/localfg.dot")

tree, smtasks = solveTree!(localFg)

# solveTree!(cloudFg)

# Checking estimates
for variable in getVariables(localFg)
    @show variable.label
    @show variable.estimateDict

    # means = mean(getData(variable).val, dims=2)[:]
    # variable.estimateDict[:default] = Dict{Symbol, VariableEstimate}(:Mean => VariableEstimate(:default, :Mean, means, now()))
end

bel = getKDE(getVariable(localFg, :x0))
bel

# Push updates back to cloud.
updateGraphSolverData!(localFg, cloudFg, ls(localFg))

# Pull back to local
updateGraphSolverData!(cloudFg, localFgCopy, ls(cloudFg))
