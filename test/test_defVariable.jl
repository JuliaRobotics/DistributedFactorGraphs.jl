using Manifolds
using Test

@testset "Testing @defVariable" begin
##

struct NotAManifold end

@test_throws AssertionError  @defVariable(MyVar, NotAManifold(), Matrix{3})

##

@defVariable(TestVarType1, Euclidean(3), Vector{Float64})
@defVariable(TestVarType2, SpecialEuclidean(3), ProductRepr{Tuple{Vector{Float64}, Matrix{Float64}}})


##

@test getManifold( TestVarType1) == Euclidean(3)
@test getManifold( TestVarType2) == SpecialEuclidean(3)

@test getDimension(TestVarType1) === 3
@test getDimension(TestVarType2) === 6

@test getPointType(TestVarType1) == Vector{Float64}
@test getPointType(TestVarType2) == ProductRepr{Tuple{Vector{Float64}, Matrix{Float64}}}
##


@test getManifold( TestVarType1()) == Euclidean(3)
@test getManifold( TestVarType2()) == SpecialEuclidean(3)

@test getDimension(TestVarType1()) === 3
@test getDimension(TestVarType2()) === 6

@test getPointType(TestVarType1()) == Vector{Float64}
@test getPointType(TestVarType2()) == ProductRepr{Tuple{Vector{Float64}, Matrix{Float64}}}

end
