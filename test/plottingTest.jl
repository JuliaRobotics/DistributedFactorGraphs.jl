using GraphPlot
using DistributedFactorGraphs
# using DistributedFactorGraphs.DFGPlots
using Test

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = GraphsDFG{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n")), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, [verts[n], verts[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:(numNodes-1))

# Using GraphPlot plotting
plot = dfgplot(dfg)
@test plot != nothing
