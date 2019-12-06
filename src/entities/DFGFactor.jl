
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
    data::GenericFunctionNodeData{T, S}
    solvable::Int
    timestamp::DateTime
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
    # TODO back to front ts and _internalId for legacy reasons
    DFGFactor{T, S}(label::Symbol, _internalId::Int64=0, ts::DateTime=now()) where {T, S} = new{T, S}(label, Symbol[], GenericFunctionNodeData{T, S}(), 0, ts, 0, Symbol[])
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

"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGFactor.
"""
mutable struct DFGFactorSummary <: AbstractDFGFactor
    label::Symbol
    tags::Vector{Symbol}
    _internalId::Int64
    _variableOrderSymbols::Vector{Symbol}
end

# SKELETON DFG
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

# Accessors

const FactorDataLevel0 = Union{DFGFactor, DFGFactorSummary, SkeletonDFGFactor}
const FactorDataLevel1 = Union{DFGFactor, DFGFactorSummary}
# const FactorDataLevel2 = Union{DFGFactor}

"""
$SIGNATURES

Return the label for a factor.
"""
label(f::FactorDataLevel0) = f.label

"""
$SIGNATURES

Return the tags for a variable.
"""
tags(f::FactorDataLevel0) = f.tags

"""
$SIGNATURES

Set the tags for a factor.
"""
setTags!(f::FactorDataLevel0, tags::Vector{Symbol}) = f.tags = tags

"""
$SIGNATURES

Get the timestamp from a DFGFactor object.

DEPRECATED -> use getTimestamp instead.
"""
function timestamp(v::FactorDataLevel1)
  @warn "timestamp deprecated, use getTimestamp instead"
  v.timestamp
end

"""
$SIGNATURES

Get the timestamp from a DFGFactor object.
"""
getTimestamp(v::FactorDataLevel1) = v.timestamp

"""
$SIGNATURES

Set the timestamp of a DFGFactor object.
"""
setTimestamp!(v::FactorDataLevel1, ts::DateTime) = v.timestamp = ts

"""
$SIGNATURES

Return the internal ID for a variable.
"""
internalId(f::FactorDataLevel1) = f._internalId

"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function solverData(f::F) where F <: DFGFactor
  return f.data
end
"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function data(f::DFGFactor)::GenericFunctionNodeData
  @warn "data() is deprecated, please use solverData()"
  return f.data
end
"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getData(f::DFGFactor)::GenericFunctionNodeData
  #FIXME but back in later, it just slows everything down
  if !(@isdefined getDataWarnOnce)
    @warn "getData is deprecated, please use solverData(), future warnings in getData is suppressed"
    global getDataWarnOnce = true
  end
  # @warn "getData is deprecated, please use solverData()"
  return f.data
end
