"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGFactor.
"""
struct DFGFactorSummary <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
end
