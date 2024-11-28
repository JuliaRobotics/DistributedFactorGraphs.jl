using GraphPlot
using DistributedFactorGraphs
# using DistributedFactorGraphs.DFGPlots
using Test
using Manifolds

##

# struct TestInferenceVariable1 <: InferenceVariable end
@defVariable TestInferenceVariable1 Euclidean(1) [0.0;]

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = GraphsDFG{NoSolverParams}()
verts = map(n -> VariableCompute(Symbol("x$n"), TestInferenceVariable1()), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(
    n -> addFactor!(
        dfg,
        FactorCompute{TestFunctorInferenceType1}(
            Symbol("x$(n)x$(n+1)f1"),
            [verts[n].label, verts[n + 1].label],
        ),
    ),
    1:(numNodes - 1),
)

##

# Using GraphPlot plotting
plot = plotDFG(dfg)
@test plot !== nothing

##
