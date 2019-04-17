mutable struct DFGFactor <: DFGNode
    label::Symbol
    #TODO: Populate
    _internalId::Int64
    DFGFactor(label::Symbol) = new(label, 0)
    DFGFactor(label::Symbol, _internalId::Int64) = new(label, _internalId)
end
