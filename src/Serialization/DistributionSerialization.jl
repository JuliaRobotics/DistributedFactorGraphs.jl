## ================================================================================
## there are 2 ways of dealing with types that don't pack out of the box
## 1) define pack and unpack methods for them.
## 2) use StructUtils.jl with a custom StructStyle.

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
