
using ManifoldsBase, Manifolds
using Test

# abstract type InferenceVariable end

##

Base.convert(::Type{<:Tuple}, ::typeof(Euclidean(1))) = (:Euclid,)
Base.convert(::Type{<:Tuple}, ::typeof(Euclidean(2))) = (:Euclid, :Euclid)

##

macro defVariable(structname, manifold)
  return esc(quote
      Base.@__doc__ struct $structname <: InferenceVariable end

      @assert ($manifold isa Manifold) "@defVariable of "*string($structname)*" requires that the "*string($manifold)*" be a subtype of `ManifoldsBase.Manifold`"

      # manifold must be is a <:Manifold
      Base.convert(::Type{<:Manifold}, ::Union{<:T, Type{<:T}}) where {T <: $structname} = $manifold 

      getManifold(::Type{M}) where {M <: $structname} = $manifold
      getManifold(::M) where {M <: $structname} = getManifold(M)
      
      getDimension(::Type{M}) where {M <: $structname} = manifold_dimension(getManifold(M))
      getDimension(::M) where {M <: $structname} = manifold_dimension(getManifold(M))
      # FIXME legacy API to be deprecated
      getManifolds(::Type{M}) where {M <: $structname} = convert(Tuple, $manifold)
      getManifolds(::M) where {M <: $structname} = convert(Tuple, $manifold)
  end)
end


##


ex = macroexpand(Main, :(@defVariable(TestVariableType1, Euclidean(1))) )


##

struct NotAManifold end

try
  @defVariable(MyVar, NotAManifold())
catch AssertionError
  @test true
end

##

@defVariable(TestVariableType1, Euclidean(1))
@defVariable(TestVariableType2, Euclidean(2))


##

@test getManifold( TestVariableType1) == Euclidean(1)
@test getManifold( TestVariableType2) == Euclidean(2)

# legacy
@test getManifolds(TestVariableType1) == (:Euclid,)
@test getDimension(TestVariableType1) === 1
@test getManifolds(TestVariableType2) == (:Euclid,:Euclid)
@test getDimension(TestVariableType2) === 2

##


@test getManifold( TestVariableType1()) == Euclidean(1)
@test getManifold( TestVariableType2()) == Euclidean(2)

# legacy
@test getManifolds(TestVariableType1()) == (:Euclid,)
@test getDimension(TestVariableType1()) === 1
@test getManifolds(TestVariableType2()) == (:Euclid,:Euclid)
@test getDimension(TestVariableType2()) === 2


##