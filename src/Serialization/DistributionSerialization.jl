## ================================================================================
## Types that don't serialize cleanly through StructUtils can use pack/unpack.
##
## Pattern:
##   1. Define a "Packed" companion struct with only serializable fields.
##   2. Overload `DFG.pack(x::OriginalType) -> PackedType`.
##   3. Overload `DFG.unpack(p::PackedType) -> OriginalType`.
##
## The Packed envelope + DFGJSONStyle handles the rest automatically:
## serialization calls pack(), embeds TypeMetadata, and deserialization
## resolves the packed type, builds it via StructUtils.make, then calls unpack().
##
## Alternatively, for scalar-like types, use StructUtils.lower/lift directly
## with a custom StructStyle (see DFGStructStyles.jl for examples).
## ================================================================================

## 1) Overloads of Distributions.jl types not packing out of the box
# TODO make Distributions extension or move to IncrementalInferenceTypes as not to have Distributions.jl as a dependency of DFG
struct PackedMvNormal
    μ::Vector{Float64}
    Σ::Matrix{Float64}
end

pack(d::Distributions.MvNormal) = PackedMvNormal(Distributions.params(d)...)
unpack(pd::PackedMvNormal) = Distributions.MvNormal(pd.μ, pd.Σ)

struct PackedCategorical
    p::Vector{Float64}
end

pack(d::Distributions.Categorical) = PackedCategorical(Distributions.params(d)...)
unpack(pd::PackedCategorical) = Distributions.Categorical(pd.p)
