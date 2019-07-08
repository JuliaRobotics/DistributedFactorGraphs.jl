
# Originally from IncrementalInference

abstract type InferenceType end
abstract type PackedInferenceType end

abstract type FunctorInferenceType <: Function end

abstract type InferenceVariable end
abstract type ConvolutionObject <: Function end

abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

"""
$(TYPEDEF)
"""
mutable struct GenericFunctionNodeData{T, S}
  fncargvID::Vector{Symbol}
  eliminated::Bool
  potentialused::Bool
  edgeIDs::Array{Int,1}
  frommodule::S #Union{Symbol, AbstractString}
  fnc::T
  multihypo::String # likely to moved when GenericWrapParam is refactored
  certainhypo::Vector{Int}
  GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8)
  GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8)
  # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end

"""
    $(SIGNATURES)
Fundamental structure for a DFG factor.
"""
mutable struct DFGFactor{T, S} <: DFGNode
    label::Symbol
    tags::Vector{Symbol}
    data::GenericFunctionNodeData{T, S}
    ready::Int
    backendset::Int
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
    DFGFactor{T, S}(label::Symbol) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, 0, 0, Symbol[])
    DFGFactor{T, S}(label::Symbol, _internalId::Int64) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, 0, _internalId, Symbol[])
end

# const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
# FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="", x8::Vector{Int}=Int[]) where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7, x8)

label(f::F) where F <: DFGFactor = f.label
data(f::F) where F <: DFGFactor = f.data
id(f::F) where F <: DFGFactor = f._internalId
