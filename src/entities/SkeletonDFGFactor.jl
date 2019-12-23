"""
    $(TYPEDEF)
Skeleton factor with essentials.
"""
struct SkeletonDFGFactor <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    _variableOrderSymbols::Vector{Symbol}
end

#NOTE I feel like a want to force a variableOrderSymbols
SkeletonDFGFactor(label::Symbol, variableOrderSymbols::Vector{Symbol} = Symbol[]) = SkeletonDFGFactor(label, Symbol[], variableOrderSymbols)
