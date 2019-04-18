
"""
    $(SIGNATURES)
Fundamental structure for a DFG variable.
"""
mutable struct DFGVariable <: DFGNode
    label::Symbol
    #TODO: Populate
    _internalId::Int64
    DFGVariable(label::Symbol) = new(label, 0)
    DFGVariable(label::Symbol, _internalId::Int64) = new(label, _internalId)
end
