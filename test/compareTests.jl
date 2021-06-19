using Test
using DistributedFactorGraphs
using Dates

#TODO implement with tests on
# TestFunctorInferenceType1
# TestCCW1

## Generated compare functions
# VariableNodeData
vnd1 = VariableNodeData(TestVariableType1())
vnd2 = deepcopy(vnd1)
vnd3 = VariableNodeData(TestVariableType2())

@test vnd1 == vnd2
push!(vnd1.val, [1.0;])
# vnd2.val = Vector{Vector{Float64}}(undef,1)
push!(vnd2.val, [1.0;])
@test vnd1 == vnd2
vnd2.val[1] = [0.1;]
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
v1 = DFGVariable(:x1, TestVariableType1())
v2 = deepcopy(v1)
v3 = DFGVariable(:x2, TestVariableType2())

@test v1 == v2
v2.solvable = 0
@test !(v1 == v2)
@test !(v1 == v3)
@test !(DFGVariable(:x1, TestVariableType1()) == DFGVariable(:x1, TestVariableType2()))

# GenericFunctionNodeData
gfnd1 = GenericFunctionNodeData(true, true, [1,2], TestFunctorInferenceType1())
gfnd2 = deepcopy(gfnd1)
gfnd3 = GenericFunctionNodeData(true, true, [1,2], TestFunctorInferenceType2())

@test gfnd1 == gfnd2
@test !(gfnd1 == gfnd3)

# DFGFactor
f1 = DFGFactor(:f1, [:a, :b], gfnd1)
f2 = deepcopy(f1)
f3 = DFGFactor(:f1, [:b, :a], gfnd1)

@test f1 == f2
@test !(f1 == f3)


## Compare functions
vnd1 = VariableNodeData(TestVariableType1())
vnd2 = deepcopy(vnd1)
vnd3 = VariableNodeData(TestVariableType2())
@test compare(vnd1, vnd2)
@test !compare(vnd1, vnd3)

@test compare(vnd1, vnd2)
push!(vnd1.val, [1.0;])
push!(vnd2.val, [1.0;])
@test compare(vnd1, vnd2)
vnd2.val[1][1] = 0.1
@test !compare(vnd1, vnd2)
@test !compare(vnd1, vnd3)

gfnd1 = GenericFunctionNodeData(true, true, [1,2], TestFunctorInferenceType1())
gfnd2 = deepcopy(gfnd1)
gfnd3 = GenericFunctionNodeData(true, true, [1,2], PackedTestFunctorInferenceType1())

@test compare(gfnd1, gfnd2)
@test_broken !(compare(gfnd1, gfnd3))
