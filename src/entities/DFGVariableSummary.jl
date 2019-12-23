"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGVariable.
"""
struct DFGVariableSummary <: AbstractDFGVariable
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, <:AbstractPointParametricEst}
    softtypename::Symbol
    _internalId::Int64
end
