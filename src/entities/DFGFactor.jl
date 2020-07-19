##==============================================================================
## Abstract Types
##==============================================================================

abstract type FunctorInferenceType <: Function end
abstract type PackedInferenceType end

# NOTE DF, Convolution is IIF idea, but DFG should know about "FactorOperationalMemory"
# DF, IIF.CommonConvWrapper <: FactorOperationalMemory #
abstract type FactorOperationalMemory <: Function end
# TODO to be removed from DFG,
# we can add to IIF or have IIF.CommonConvWrapper <: FactorOperationalMemory directly
# abstract type ConvolutionObject <: FactorOperationalMemory end

abstract type AbstractPrior <: FunctorInferenceType end
abstract type AbstractRelativeFactor <: FunctorInferenceType end
abstract type AbstractRelativeFactorMinimize <: FunctorInferenceType end

##==============================================================================
## GenericFunctionNodeData
##==============================================================================

"""
$(TYPEDEF)

Notes
- S::Symbol

Designing (WIP)
- T <: Union{FactorOperationalMemory, PackedInferenceType}
- in IIF.CCW{T <: DFG.FunctorInferenceType}
- in DFG.AbstractRelativeFactorMinimize <: FunctorInferenceType
- in Main.SomeFactor <: AbstractRelativeFactorMinimize
"""
mutable struct GenericFunctionNodeData{T<:Union{PackedInferenceType, FunctorInferenceType, FactorOperationalMemory}}
    eliminated::Bool
    potentialused::Bool
    edgeIDs::Vector{Int}
    fnc::T
    multihypo::Vector{Float64} # TODO re-evaluate after refactoring w #477
    certainhypo::Vector{Int}
    nullhypo::Float64
    solveInProgress::Int

    # TODO deprecate all these inner constructors at end of DFG v0.9.x (was added for GFND.nullhypo::Float64 breaking change)
    GenericFunctionNodeData{T}() where T = new{T}()
    GenericFunctionNodeData{T}(el,po,ed,fn,mu::Vector{<:Real},ce::Vector{Int},so::Int) where T = new{T}(el,po,ed,fn,mu,ce,0.0,so)
    GenericFunctionNodeData{T}(el,po,ed,fn,mu::Vector{<:Real},ce::Vector{Int},nu::Real,so::Int) where T = new{T}(el,po,ed,fn,mu,ce,nu,so)
end

## Constructors

GenericFunctionNodeData{T}() where T =
    GenericFunctionNodeData{T}(false, false, Int[], T(), Float64[], Int[], 0, 0)

function GenericFunctionNodeData(eliminated::Bool,
                                 potentialused::Bool,
                                 edgeIDs::Vector{Int},
                                 fnc::T,
                                 multihypo::Vector{<:Real}=Float64[],
                                 certainhypo::Vector{Int}=Int[],
                                 nullhypo::Real=0,
                                 solveInP::Int=0) where T
    return GenericFunctionNodeData{T}(eliminated, potentialused, edgeIDs, fnc, multihypo, certainhypo, nullhypo, solveInP)
end


##------------------------------------------------------------------------------
## PackedFunctionNodeData and FunctionNodeData

const PackedFunctionNodeData{T} = GenericFunctionNodeData{T} where T <: PackedInferenceType
PackedFunctionNodeData(args...) = PackedFunctionNodeData{typeof(args[4])}(args...)

const FunctionNodeData{T} = GenericFunctionNodeData{T} where T <: Union{FunctorInferenceType, FactorOperationalMemory}
FunctionNodeData(args...) = FunctionNodeData{typeof(args[4])}(args...)


# PackedFunctionNodeData(x2, x3, x4, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where T <: PackedInferenceType =
#     GenericFunctionNodeData{T}(x2, x3, x4, x6, multihypo, certainhypo, x9)
# FunctionNodeData(x2, x3, x4, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where T <: Union{FunctorInferenceType, FactorOperationalMemory} =
#     GenericFunctionNodeData{T}(x2, x3, x4, x6, multihypo, certainhypo, x9)

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
struct DFGFactor{T, N} <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime
    """Nano second time, for more resolution on timestamp (only subsecond information)"""
    nstime::Nanosecond
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Solver data.
    Accessors: [`getSolverData`](@ref), [`setSolverData!`](@ref)"""
    solverData::Base.RefValue{GenericFunctionNodeData{T}}
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Internal cache of the ordering of the neighbor variables. Rather use getVariableOrder to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
    _variableOrderSymbols::NTuple{N,Symbol}
    # Inner constructor
    function DFGFactor{T}(label::Symbol,
                 timestamp::Union{DateTime,ZonedDateTime},
                 nstime::Nanosecond,
                 tags::Set{Symbol},
                 solverData::GenericFunctionNodeData{T},
                 solvable::Int,
                 _variableOrderSymbols::NTuple{N,Symbol}) where {T,N}

        #TODO Deprecate remove in v0.10.
        if timestamp isa DateTime
            Base.depwarn("DFGFactor timestamp field is now a ZonedTimestamp", :DFGFactor)
            return new{T,N}(label, ZonedDateTime(timestamp, localzone()), nstime, tags, Ref(solverData), Ref(solvable), _variableOrderSymbols)
        end
        return new{T,N}(label, timestamp, nstime, tags, Ref(solverData), Ref(solvable), _variableOrderSymbols)
    end

end

##------------------------------------------------------------------------------
## Constructors

"""
$(SIGNATURES)

Construct a DFG factor given a label.
"""
DFGFactor(label::Symbol,
          timestamp::Union{DateTime,ZonedDateTime},
          nstime::Nanosecond,
          tags::Set{Symbol},
          solverData::GenericFunctionNodeData{T},
          solvable::Int,
          _variableOrderSymbols::Tuple) where {T} =
          DFGFactor{T}(label, timestamp, nstime, tags, solverData, solvable, _variableOrderSymbols)


DFGFactor{T}(label::Symbol, variableOrderSymbols::Vector{Symbol}, timestamp::Union{DateTime,ZonedDateTime}=now(localzone()), data::GenericFunctionNodeData{T} = GenericFunctionNodeData{T}()) where {T} =
                DFGFactor(label, timestamp, Nanosecond(0), Set{Symbol}(), data, 1, Tuple(variableOrderSymbols))


DFGFactor(label::Symbol,
          variableOrderSymbols::Vector{Symbol},
          data::GenericFunctionNodeData{T};
          tags::Set{Symbol}=Set{Symbol}(),
          timestamp::Union{DateTime,ZonedDateTime}=now(localzone()),
          solvable::Int=1,
          nstime::Nanosecond = Nanosecond(0)) where {T} =
                DFGFactor{T}(label, timestamp, nstime, tags, data, solvable, Tuple(variableOrderSymbols))



Base.getproperty(x::DFGFactor,f::Symbol) = begin
    if f == :solvable || f == :solverData
        getfield(x, f)[]
    elseif f == :_variableOrderSymbols
        [getfield(x,f)...]
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGFactor,f::Symbol, val) = begin
    if f == :solvable || f == :solverData
        getfield(x,f)[] = val
    elseif f == :timestamp && val isa DateTime
    #     #TODO Deprecation - Remove in v0.10
        Base.depwarn("DFGFactor timestamp field is now a ZonedTimestamp", :setproperty!)
        setfield!(x,:timestamp, ZonedDateTime(val,  localzone()))
    else
        setfield!(x,f,val)
    end
end
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
    timestamp::ZonedDateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
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
    DFGFactorSummary(f.label, f.timestamp, deepcopy(f.tags), deepcopy(f._variableOrderSymbols))

SkeletonDFGFactor(f::FactorDataLevel1) =
    SkeletonDFGFactor(f.label, deepcopy(f.tags), deepcopy(f._variableOrderSymbols))
