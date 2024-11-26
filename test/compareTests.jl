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
push!(vnd2.val, [1.0;])
@test vnd1 == vnd2
vnd2.val[1] = [0.1;]
@test !(vnd1 == vnd2)
@test !(vnd1 == vnd3)

# MeanMaxPPE
ppe1 = MeanMaxPPE(:default, [1.0], [2.0], [3.0])
ppe2 = deepcopy(ppe1)
ppe3 = MeanMaxPPE(:default, [2.0], [3.0], [4.0])

@test ppe1 == ppe2
ppe2.max[1] = 0.1
@test !(ppe1 == ppe2)
@test !(ppe1 == ppe3)

# VariableCompute
v1 = VariableCompute(:x1, TestVariableType1())
v2 = deepcopy(v1)
v3 = VariableCompute(:x2, TestVariableType2())

@test v1 == v2
v2.solvable = 0
@test !(v1 == v2)
@test !(v1 == v3)
@test !(VariableCompute(:x1, TestVariableType1()) == VariableCompute(:x1, TestVariableType2()))

# GenericFunctionNodeData
gfnd1 = GenericFunctionNodeData(;
    eliminated = true,
    potentialused = true,
    edgeIDs = [1, 2],
    fnc = TestFunctorInferenceType1(),
)
gfnd2 = deepcopy(gfnd1)
gfnd3 = GenericFunctionNodeData(;
    eliminated = true,
    potentialused = true,
    edgeIDs = [1, 2],
    fnc = TestFunctorInferenceType2(),
)

@test gfnd1 == gfnd2
@test !(gfnd1 == gfnd3)

# FactorCompute
f1 = FactorCompute(:f1, [:a, :b], gfnd1)
f2 = deepcopy(f1)
f3 = FactorCompute(:f1, [:b, :a], gfnd1)

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

gfnd1 = GenericFunctionNodeData(;
    eliminated = true,
    potentialused = true,
    edgeIDs = [1, 2],
    fnc = TestFunctorInferenceType1(),
)
gfnd2 = deepcopy(gfnd1)
gfnd3 = GenericFunctionNodeData(;
    eliminated = true,
    potentialused = true,
    edgeIDs = [1, 2],
    fnc = PackedTestFunctorInferenceType1(),
)

@test compare(gfnd1, gfnd2)
@test_broken !(compare(gfnd1, gfnd3))
