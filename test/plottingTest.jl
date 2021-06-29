using GraphPlot
using DistributedFactorGraphs
# using DistributedFactorGraphs.DFGPlots
using Test
using Manifolds

# struct TestInferenceVariable1 <: InferenceVariable end
@defVariable TestInferenceVariable1 Euclidean(1) [0.0;]

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = LightDFG{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n"), TestInferenceVariable1()), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, DFGFactor{TestFunctorInferenceType1}(Symbol("x$(n)x$(n+1)f1"), [verts[n].label, verts[n+1].label])), 1:(numNodes-1))

# Using GraphPlot plotting
plot = dfgplot(dfg)
@test plot != nothing


#TODO test something more
#NOTE just running function to see if it plots
iobuf = IOBuffer()
dfgplot(iobuf, MIME("application/prs.juno.plotpane+html"), dfg)
@test length(take!(iobuf)) > 1e3
