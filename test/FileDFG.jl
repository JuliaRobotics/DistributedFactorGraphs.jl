using Revise
using Test
using DistributedFactorGraphs
using IncrementalInference, RoME

# Make a simple graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())

# Add the first pose :x0
x0 = addVariable!(dfg, :x0, Pose2)
IncrementalInference.compareVariable(x0, getVariable(dfg, :x0))

# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(dfg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Drive around in a hexagon
for i in 0:5
    psym = Symbol("x$i")
    nsym = Symbol("x$(i+1)")
    addVariable!(dfg, nsym, Pose2)
    pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
    addFactor!(dfg, [psym;nsym], pp )
end

saveDFG(dfg "/tmp/fileDFG")
