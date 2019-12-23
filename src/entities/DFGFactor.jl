
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
  solveInProgress::Int
  GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
  GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
  # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end

"""
    $(TYPEDEF)

Fundamental structure for a DFG factor.
"""
mutable struct DFGFactor{T, S} <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    solverData::GenericFunctionNodeData{T, S}
    solvable::Int
    timestamp::DateTime
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
    # TODO back to front ts and _internalId for legacy reasons
    DFGFactor{T, S}(label::Symbol, _internalId::Int64=0, timestamp::DateTime=now()) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, timestamp, 0, Symbol[])
    # DFGFactor{T, S}(label::Symbol, _internalId::Int64) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, now(), _internalId, Symbol[])
end

"""
    $(SIGNATURES)

Convenience constructor for DFG factor.
"""
DFGFactor(label::Symbol; tags::Vector{Symbol}=Symbol[], data::GenericFunctionNodeData{T, S}=GenericFunctionNodeData{T, S}(), solvable::Int=0, timestamp::DateTime=now(), _internalId::Int64=0, _variableOrderSymbols::Vector{Symbol}=Symbol[]) where {T, S} = DFGFactor{T,S}(label,tags,data,solvable,timestamp,_internalId,_variableOrderSymbols)

# Simply for convenience - don't export
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, x7, x8, x9)
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
