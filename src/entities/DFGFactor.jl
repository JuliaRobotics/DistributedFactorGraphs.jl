##==============================================================================
## Abstract Types
##==============================================================================

abstract type InferenceType end
abstract type PackedInferenceType end

abstract type FunctorInferenceType <: Function end

abstract type ConvolutionObject <: Function end

abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

##==============================================================================
## GenericFunctionNodeData
##==============================================================================

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

## Constructors

##------------------------------------------------------------------------------
## PackedFunctionNodeData and FunctionNodeData

# Simply for convenience - don't export, TODO Its used in IIF so maybe it should be exported
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, x7, x8, x9)
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7, x8, x9)

##==============================================================================
## Factors
##==============================================================================
#
# |                   | label | tags | timestamp | solvable | solverData |
# |-------------------|:-----:|:----:|:---------:|:--------:|:----------:|
# | SkeletonDFGFactor |   X   |   x  |           |          |            |
# | DFGFactorSummary  |   X   |   X  |     X     |          |            |
# | DFGFactor         |   X   |   X  |     X     |     X    |      X     |

## DFGFactor lv2

"""
$(TYPEDEF)
Complete factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
mutable struct DFGFactor{T, S} <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Solver data.
    Accessors: `getSolverData`, `setSolverData!`"""
    solverData::GenericFunctionNodeData{T, S}
    """Solvable flag for the factor.
    Accessors: `getSolvable`, `setSolvable!`
    TODO: Switch to `DFGNodeParams`"""
    solvable::Int #TODO we can go with DFGNodeParams or Reference the solvable field with getproperty overload
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: `getVariableOrder`"""
    _variableOrderSymbols::Vector{Symbol}
end

##------------------------------------------------------------------------------
## Constructors

"""
$(SIGNATURES)

Construct a DFG factor given a label.
"""
#TODO _internalId?
DFGFactor{T, S}(label::Symbol, internalId::Int64=0, timestamp::DateTime=now()) where {T, S} =
                DFGFactor(label, timestamp, Set{Symbol}(), GenericFunctionNodeData{T, S}(), 1, DFGNodeParams(1, internalId), Symbol[])


DFGFactor(label::Symbol,
          variableOrderSymbols::Vector{Symbol},
          data::GenericFunctionNodeData{T, S};
          tags::Set{Symbol}=Set{Symbol}(),
          timestamp::DateTime=now(),
          solvable::Int=1,
          _internalId::Int64=0) where {T, S} =
                DFGFactor{T,S}(label,timestamp,tags,data,solvable,DFGNodeParams(solvable, _internalId),variableOrderSymbols)



##------------------------------------------------------------------------------
## DFGFactorSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Read-only summary factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct DFGFactorSummary <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`"""
    timestamp::DateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: `getVariableOrder`"""
    _variableOrderSymbols::Vector{Symbol}
end

##------------------------------------------------------------------------------
## SkeletonDFGFactor lv0
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct SkeletonDFGFactor <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: `getLabel`"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: `getVariableOrder`"""
    _variableOrderSymbols::Vector{Symbol}
end

##------------------------------------------------------------------------------
## Constructors

#NOTE I feel like a want to force a variableOrderSymbols
SkeletonDFGFactor(label::Symbol, variableOrderSymbols::Vector{Symbol} = Symbol[]) = SkeletonDFGFactor(label, Set{Symbol}(), variableOrderSymbols)

##==============================================================================
## Define factor levels
##==============================================================================
const FactorDataLevel0 = Union{DFGFactor, DFGFactorSummary, SkeletonDFGFactor}
const FactorDataLevel1 = Union{DFGFactor, DFGFactorSummary}
const FactorDataLevel2 = Union{DFGFactor}

##==============================================================================
## Convert
##==============================================================================
function Base.convert(::Type{DFGFactorSummary}, f::DFGFactor)
    return DFGFactorSummary(f.label, f.timestamp, deepcopy(f.tags), f._dfgNodeParams._internalId, deepcopy(f._variableOrderSymbols))
end

#TODO TEST
function Base.convert(::Type{SkeletonDFGFactor}, f::FactorDataLevel1)
    return SkeletonDFGFactor(f.label, deepcopy(f.tags), deepcopy(f._variableOrderSymbols))
end
