# Debug logging
using Test
using Logging
using Neo4j
using DistributedFactorGraphs
using IncrementalInference, RoME
using Test, Dates
# logger = SimpleLogger(stdout, Logging.Debug)
# global_logger(logger)

dfg = GraphsDFG{SolverParams}(;
    userId="testUser", robotId="testRobot", sessionId="testSession",
    params=SolverParams())

# Add the first pose :x0
x0 = addVariable!(dfg, :x0, Pose2)

# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(dfg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Drive around in a hexagon in the cloud
for i in 0:5
    psym = Symbol("x$i")
    nsym = Symbol("x$(i+1)")
    addVariable!(dfg, nsym, Pose2)
    pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    addFactor!(dfg, [psym;nsym], pp )
end

tree, smtasks = solveTree!(dfg)

# Checking estimates
for variable in getVariables(dfg)
    @show variable.label
    @show variable.estimateDict

    # means = mean(getData(variable).val, dims=2)[:]
    # variable.estimateDict[:default] = Dict{Symbol, VariableEstimate}(:Mean => VariableEstimate(:default, :Mean, means, now()))
end

x1 = getVariable(dfg, :x1)
x1.estimateDict[:default]

bel = getKDE(getVariable(localFg, :x0))
bel

# Push updates back to cloud.
updateGraphSolverData!(localFg, cloudFg, ls(localFg))

# Pull back to local
updateGraphSolverData!(cloudFg, localFgCopy, ls(cloudFg))
