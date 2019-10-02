"""
	$(TYPEDEF)
Skeleton variable with essentials.
"""
struct SkeletonDFGVariable <: AbstractDFGVariable
	label::Symbol
	tags::Vector{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(label, Symbol[])

label(v::SkeletonDFGVariable) = v.label
tags(v::SkeletonDFGVariable) = v.tags

"""
	$(TYPEDEF)
Skeleton factor with essentials.
"""
struct SkeletonDFGFactor <: AbstractDFGFactor
    label::Symbol
	tags::Vector{Symbol}
	_variableOrderSymbols::Vector{Symbol}
	#TODO consider changing this to a NTyple with parameter N:
	# _variableOrderSymbols::NTuple{N,Symbol}
end
SkeletonDFGFactor(label::Symbol) = SkeletonDFGFactor(label, Symbol[], Symbol[])

label(f::SkeletonDFGFactor) = f.label
tags(f::SkeletonDFGFactor) = f.tags
