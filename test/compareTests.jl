using Test
using DistributedFactorGraphs
using Dates

# VariableNodeData
vnd1 = VariableNodeData(TestSofttype1())
vnd2 = deepcopy(vnd1)
vnd3 = VariableNodeData(TestSofttype2())

@test vnd1 == vnd2
vnd2.val = zeros(1,1)
@test vnd1 == vnd2
vnd2.val[1] = 0.1
@test !(vnd1 == vnd2)
@test !(vnd1 == vnd3)

# MeanMaxPPE
ppe1 = MeanMaxPPE(:default, [1.], [2.], [3.])
ppe2 = deepcopy(ppe1)
ppe3 = MeanMaxPPE(:default, [2.], [3.], [4.])

@test ppe1 == ppe2
ppe2.max[1] = 0.1
@test !(ppe1 == ppe2)
@test !(ppe1 == ppe3)


# DFGVariable
v1 = DFGVariable(:x1, TestSofttype1())
v2 = deepcopy(v1)
v3 = DFGVariable(:x2, TestSofttype2())

@test v1 == v2
v2.solvable = 0
@test !(v1 == v2)
@test !(v1 == v3)
@test !(DFGVariable(:x1, TestSofttype1()) == DFGVariable(:x1, TestSofttype2()))

# GenericFunctionNodeData
gfnd1 = GenericFunctionNodeData([:a,:b], true, true, [1,2], :symbol, sin)
gfnd2 = deepcopy(gfnd1)
gfnd3 = GenericFunctionNodeData([:a,:b], true, true, [1,2], :symbol, cos)

@test gfnd1 == gfnd2
gfnd2.fncargvID = [:a, :b]
@test gfnd1 == gfnd2
gfnd2.fncargvID = [:b, :a]
@test !(gfnd1 == gfnd2)
@test !(gfnd1 == gfnd3)

# DFGFactor
f1 = DFGFactor(:f1, [:a, :b], gfnd1)
f2 = deepcopy(f1)
f3 = DFGFactor(:f1, [:b, :a], gfnd1)

@test f1 == f2
f2.solverData = gfnd1
@test f1 == f2
f2.solverData = gfnd2
@test !(f1 == f2)
@test !(f1 == f3)
