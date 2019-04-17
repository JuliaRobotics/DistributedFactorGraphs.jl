
abstract type InferenceType end
abstract type PackedInferenceType end
abstract type FunctorInferenceType <: Function end
abstract type InferenceVariable end

abstract type DFGNode end

abstract type AbstractDFG
end

mutable struct DFGVariable <: DFGNode
    label::Symbol
    #TODO: Populate
    _internalId::Int64
    DFGVariable(label::Symbol) = new(label, 0)
    DFGVariable(label::Symbol, _internalId::Int64) = new(label, _internalId)
end
mutable struct DFGFactor <: DFGNode
    label::Symbol
    #TODO: Populate
    _internalId::Int64
    DFGFactor(label::Symbol) = new(label, 0)
    DFGFactor(label::Symbol, _internalId::Int64) = new(label, _internalId)
end
