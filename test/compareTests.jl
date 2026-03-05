using Test
using DistributedFactorGraphs
using Dates

#TODO implement with tests on
# TestFunctorInferenceType1
# TestCCW1

## Generated compare functions
# State
vnd1 = State(:default, TestVariableType1())
vnd2 = deepcopy(vnd1)
vnd3 = State(:default, TestVariableType2())

@test vnd1 == vnd2
push!(DFG.refPoints(vnd1), [1.0;])
push!(DFG.refPoints(vnd2), [1.0;])
@test vnd1 == vnd2
DFG.refPoints(vnd2)[1] = [0.1;]
@test !(vnd1 == vnd2)
@test !(vnd1 == vnd3)

# VariableDFG
v1 = VariableDFG(:x1, TestVariableType1())
v2 = deepcopy(v1)
v3 = VariableDFG(:x2, TestVariableType2())

@test v1 == v2
setSolvable!(v2, 0)
@test !(v1 == v2)
@test !(v1 == v3)
@test !(VariableDFG(:x1, TestVariableType1()) == VariableDFG(:x1, TestVariableType2()))

facstate1 = DFG.Recipestate(; eliminated = true, potentialused = true)
facstate2 = deepcopy(facstate1)
facstate3 = DFG.Recipestate(; eliminated = true, potentialused = false)

@test facstate1 == facstate2
@test !(facstate1 == facstate3)

# FactorCompute
f1 = FactorCompute(:f1, [:a, :b], TestFunctorInferenceType1())
f2 = deepcopy(f1)
f3 = FactorCompute(:f1, [:b, :a], TestFunctorInferenceType1())

@test f1 == f2
@test !(f1 == f3)

## Compare functions
vnd1 = State(:default, TestVariableType1())
vnd2 = deepcopy(vnd1)
vnd3 = State(:default, TestVariableType2())
@test compare(vnd1, vnd2)
@test !compare(vnd1, vnd3)

@test compare(vnd1, vnd2)
push!(DFG.refPoints(vnd1), [1.0;])
push!(DFG.refPoints(vnd2), [1.0;])
@test compare(vnd1, vnd2)
DFG.refPoints(vnd2)[1] = [0.1;]
@test !compare(vnd1, vnd2)
@test !compare(vnd1, vnd3)
