using Manifolds
using Test
using LinearAlgebra

@testset "Testing @defVariable" begin
##

struct NotAManifold end

@test_throws AssertionError  @defVariable(MyVar, NotAManifold(), zeros(3,3))

##

@defVariable(TestVarType1, Euclidean(3), zeros(3))
@defVariable(TestVarType2, SpecialEuclidean(3), ArrayPartition(zeros(3), diagm(ones(3))))


##

@test getManifold( TestVarType1) == Euclidean(3)
@test getManifold( TestVarType2) == SpecialEuclidean(3)

@test getDimension(TestVarType1) === 3
@test getDimension(TestVarType2) === 6

@test getPointType(TestVarType1) == Vector{Float64}
# @test getPointType(TestVarType2) == ProductRepr{Tuple{Vector{Float64}, Matrix{Float64}}}

@test getPointIdentity(TestVarType1) == zeros(3)
@test getPointIdentity(TestVarType2).x[1] == ArrayPartition(zeros(3), diagm(ones(3))).x[1]
@test getPointIdentity(TestVarType2).x[2] == ArrayPartition(zeros(3), diagm(ones(3))).x[2]

##


@test getManifold( TestVarType1()) == Euclidean(3)
@test getManifold( TestVarType2()) == SpecialEuclidean(3)

@test getDimension(TestVarType1()) === 3
@test getDimension(TestVarType2()) === 6

@test getPointType(TestVarType1()) == Vector{Float64}
@test getPointType(TestVarType2()) == ArrayPartition{Float64, Tuple{Vector{Float64}, Matrix{Float64}}}

@test getPointIdentity(TestVarType1()) == zeros(3)
@test getPointIdentity(TestVarType2()).x[1] == ArrayPartition(zeros(3), diagm(ones(3))).x[1]
@test getPointIdentity(TestVarType2()).x[2] == ArrayPartition(zeros(3), diagm(ones(3))).x[2]

end
