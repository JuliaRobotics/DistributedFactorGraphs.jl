using GraphPlot
using DistributedFactorGraphs
using IncrementalInference

dfg = GraphsDFG{SolverParams}(params=SolverParams())
v1 = addVariable!(dfg, :x0, ContinuousScalar, labels = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, labels = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, labels = [:LANDMARK], solvable=1)
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearConditional(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearConditional(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearConditional(Normal(-10.0,5.0)), solvable=1)

dfgplot(dfg)


function a(v::Vector{<:DFGVariable})::Nothing
    print(v)
    return nothing
end
a([v1])
