using Test
using DistributedFactorGraphs
using IncrementalInference, RoME
using Dates

# Make a simple graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())
# Add the first pose :x0
x0 = addVariable!(dfg, :x0, Pose2)
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

# Save with no solution
saveFolder = "/tmp/fileDFG"
saveDFG(dfg, saveFolder)
@test readdir("$saveFolder/variables") == ["x0.json", "x1.json", "x2.json", "x3.json", "x4.json", "x5.json", "x6.json"]
@test readdir("$saveFolder/factors") == ["x0f1.json", "x0x1f1.json", "x1x2f1.json", "x2x3f1.json", "x3x4f1.json", "x4x5f1.json", "x5x6f1.json"]

retDFG = loadDFG(saveFolder, IncrementalInference)
@test symdiff(ls(dfg), ls(dfg)) == []
@test symdiff(lsf(dfg), lsf(retDFG)) == []

# Now solve the graph and update the solver results
# TODO: When PPE estimates are available, make the update happen here
for variable in getVariables(dfg)
    variable.estimateDict[:default] = Dict{Symbol, VariableEstimate}(:MAP => VariableEstimate(:default, :MAP, round.(rand(3)*1000), now()))
end
saveDFG(dfg, saveFolder)
retDFG = loadDFG(saveFolder, IncrementalInference)
for retVar in getVariables(retDFG)
    origVar = getVariable(dfg, retVar.label).estimateDict[:default][:MAP]
    @test retVar.estimateDict[:default][:MAP].estimate == origVar.estimate
    @test retVar.estimateDict[:default][:MAP].type == origVar.type
    @test retVar.estimateDict[:default][:MAP].solverKey == origVar.solverKey
end

# Now saving solverDataDict
tree, smtasks = batchSolve!(dfg, treeinit=true, drawpdf=false, show=false,
                            returntasks=true, limititers=50,
                            upsolve=true, downsolve=true  )
saveDFG(dfg, saveFolder)
retDFG = loadDFG(saveFolder, IncrementalInference)
x0 = getVariable(dfg, :x0)
x0ret = getVariable(retDFG, :x0)
solverData(x0) == solverData(x0ret)
# Success!
