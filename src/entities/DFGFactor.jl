##==============================================================================
## Abstract Types
##==============================================================================

abstract type InferenceType end
abstract type PackedInferenceType end

abstract type FunctorInferenceType <: Function end

# NOTE DF, Convolution is IIF idea, but DFG should know about "FactorOperationalMemory"
# DF, IIF.CommonConvWrapper <: FactorOperationalMemory #
abstract type FactorOperationalMemory <: Function end
# TODO to be removed from DFG,
# we can add to IIF or have IIF.CommonConvWrapper <: FactorOperationalMemory directly
# abstract type ConvolutionObject <: FactorOperationalMemory end

abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

##==============================================================================
## GenericFunctionNodeData
##==============================================================================

"""
$(TYPEDEF)

Notes
- S::Symbol

Designing (WIP)
- T <: Union{FactorOperationalMemory, PackedInferenceType}
# in IIF.CCW{T <: DFG.InferenceType}
# in IIF.FunctorPairwiseMinimize <: InferenceType # DFG whatever, something, we'll figure it out
# in Main/User, SomeFactor <: FunctorPairwiseMinimize
"""
mutable struct GenericFunctionNodeData{T<:Union{PackedInferenceType, FunctorInferenceType, FactorOperationalMemory}, S<:Union{Symbol, AbstractString}}
    fncargvID::Vector{Symbol}
    eliminated::Bool
    potentialused::Bool
    edgeIDs::Array{Int,1}
    frommodule::S # JT TODO remove frommodule, not used at all as far as i can tell
    fnc::T
    multihypo::Vector{Float64} # likely to moved when GenericWrapParam is refactored
    certainhypo::Vector{Int}
    solveInProgress::Int
    GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
    GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, multihypo::Vector{<:Real}=Float64[], certainhypo::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, multihypo, certainhypo, x9)
    GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, multihypo::Vector{<:Real}=Float64[], certainhypo::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, multihypo, certainhypo, x9)
    # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end

## Constructors

##------------------------------------------------------------------------------
## PackedFunctionNodeData and FunctionNodeData

# Simply for convenience - don't export, TODO Its used in IIF so maybe it should be exported
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, multihypo, certainhypo, x9)
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where {T <: Union{FunctorInferenceType, FactorOperationalMemory}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, multihypo, certainhypo, x9)

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
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::DateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Solver data.
    Accessors: [`getSolverData`](@ref), [`setSolverData!`](@ref)"""
    solverData::GenericFunctionNodeData{T, S}
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)
    TODO: Switch to `DFGNodeParams`"""
    solvable::Int #TODO we can go with DFGNodeParams or Reference the solvable field with getproperty overload
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    _dfgNodeParams::DFGNodeParams
    """Internal cache of the ordering of the neighbor variables. Rather use getVariableOrder to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
    _variableOrderSymbols::Vector{Symbol}
end

##------------------------------------------------------------------------------
## Constructors

#TODO _internalId?
"""
$(SIGNATURES)

Construct a DFG factor given a label.
"""
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
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::DateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
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
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
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
## Convertion constructors
##==============================================================================

DFGFactorSummary(f::DFGFactor) =
    DFGFactorSummary(f.label, f.timestamp, deepcopy(f.tags), f._dfgNodeParams._internalId, deepcopy(f._variableOrderSymbols))

SkeletonDFGFactor(f::FactorDataLevel1) =
    SkeletonDFGFactor(f.label, deepcopy(f.tags), deepcopy(f._variableOrderSymbols))
