# using GraphPlot
using DistributedFactorGraphs
using DistributedFactorGraphs.DFGPlots
using Test

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = GraphsDFG{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n")), 1:numNodes)
#change ready and backendset for x7,x8 for improved tests on x7x8f1
verts[7].ready = 1
verts[8].backendset = 1
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, [verts[n], verts[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:(numNodes-1))

# Using toDot
dot = toDot(dfg)
@test dot != nothing

# Using GraphViz plotting
plot = dfgplot(dfg)
@test plot != nothing
