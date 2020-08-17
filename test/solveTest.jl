#TODO Test with standard generated graphs from IIF
# Add some nodes.
v1 = addVariable!(dfg, :a, ContinuousScalar, tags = [:POSE])
addFactor!(dfg, [:a], Prior(Normal(0,1)))
v2 = addVariable!(dfg, :b, ContinuousScalar, tags = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, tags = [:LANDMARK])
f1 = addFactor!(dfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(dfg, [:b; :c], LinearConditional(Normal(50.0,2.0)) )

# Solve it
tree, smtasks = solveTree!(dfg)
