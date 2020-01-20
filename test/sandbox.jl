using DistributedFactorGraphs
struct TestInferenceVariable1 <: InferenceVariable end
a = DFGVariable(:a, TestInferenceVariable1())
b = copy(a)

d1 = getSolverData(a)
pop!(solverDataDict(a), :default)
d2 = getSolverData(b)

d1.dims = 6
d2.dims
