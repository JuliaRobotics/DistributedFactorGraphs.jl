using GraphMakie
using DistributedFactorGraphs
# using DistributedFactorGraphs.DFGPlots
using Test
using LieGroups
##

# struct TestInferenceVariable1 <: StateType end
@defStateType TestInferenceVariable1 TranslationGroup(1) [0.0;]

# Now make a complex graph for connectivity tests
numNodes = 10
dfg = GraphsDFG{NoSolverParams}()
verts = map(n -> VariableCompute(Symbol("x$n"), TestInferenceVariable1()), 1:numNodes)
map(v -> addVariable!(dfg, v), verts)
map(
    n -> addFactor!(
        dfg,
        FactorCompute(
            Symbol("x$(n)x$(n+1)f1"),
            [verts[n].label, verts[n + 1].label],
            TestFunctorInferenceType1(),
        ),
    ),
    1:(numNodes - 1),
)

##

# Using GraphMakie plotting
plot = plotDFG(dfg)
@test plot !== nothing

##
