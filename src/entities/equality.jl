# ==============================================================================
# (==)
# ==============================================================================
import Base.==
## @generated compare
# Reference https://github.com/JuliaLang/julia/issues/4648

#=
For now abstract `StateType`s are considered equal if they are the same type, dims, and manifolds (labels are deprecated)
If your implentation has aditional properties such as `DynPose2` with `ut::Int64` (microsecond time) or support different manifolds
implement compare if needed.
=#
# ==(a::StateType,b::StateType) = typeof(a) == typeof(b) && a.dims == b.dims && a.manifolds == b.manifolds

==(a::FactorCache, b::FactorCache) = typeof(a) == typeof(b)

==(a::AbstractObservation, b::AbstractObservation) = typeof(a) == typeof(b)

# Generate compares automatically for all in this union
const GeneratedCompareUnion = Union{
    BeliefRepresentation,
    State,
    Blobentry,
    Bloblet,
    VariableSkeleton,
    FactorSkeleton,
    Recipehyper,
    Recipestate,
}

@generated function ==(x::T, y::T) where {T <: GeneratedCompareUnion}
    return mapreduce(n -> :(x.$n == y.$n), (a, b) -> :($a && $b), fieldnames(x))
end

function ==(x::T, y::T) where {T <: AbstractGraphFactor}
    ignored = [:solvercache, :solvable]
    tp = mapreduce(
        n -> getproperty(x, n) == getproperty(y, n),
        (a, b) -> a && b,
        setdiff(propertynames(x), ignored),
    )
    return tp && getSolvable(x) == getSolvable(y)
end

function ==(x::T, y::T) where {T <: AbstractGraphVariable}
    ignored = [:solvable]
    tp = mapreduce(
        n -> getproperty(x, n) == getproperty(y, n),
        (a, b) -> a && b,
        setdiff(propertynames(x), ignored),
    )
    return tp && getSolvable(x) == getSolvable(y)
end
