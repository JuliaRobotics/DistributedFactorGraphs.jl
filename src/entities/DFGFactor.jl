##==============================================================================
## Abstract Types
##==============================================================================

# TODO consider changing this to AbstractFactor
abstract type AbstractFactor end
abstract type AbstractPackedFactor end

abstract type AbstractPrior <: AbstractFactor end
abstract type AbstractRelative <: AbstractFactor end
abstract type AbstractRelativeRoots <: AbstractRelative end    # NOTE Cannot be used for partials
abstract type AbstractRelativeMinimize <: AbstractRelative end
abstract type AbstractManifoldMinimize <: AbstractRelative end # FIXME move here from IIF

# NOTE DF, Convolution is IIF idea, but DFG should know about "FactorOperationalMemory"
# DF, IIF.CommonConvWrapper <: FactorOperationalMemory #
# NOTE was `<: Function` as unnecessary
abstract type FactorOperationalMemory end
# TODO to be removed from DFG,
# we can add to IIF or have IIF.CommonConvWrapper <: FactorOperationalMemory directly
# abstract type ConvolutionObject <: FactorOperationalMemory end

##==============================================================================
## GenericFunctionNodeData
##==============================================================================

"""
$(TYPEDEF)

Notes
- S::Symbol

Designing (WIP)
- T <: Union{FactorOperationalMemory, AbstractPackedFactor}
- in IIF.CCW{T <: DFG.AbstractFactor}
- in DFG.AbstractRelativeMinimize <: AbstractFactor
- in Main.SomeFactor <: AbstractRelativeMinimize
"""
Base.@kwdef mutable struct GenericFunctionNodeData{T<:Union{<:AbstractPackedFactor, <:AbstractFactor, <:FactorOperationalMemory}}
    eliminated::Bool
    potentialused::Bool
    edgeIDs::Vector{Int}
    fnc::T
    multihypo::Vector{Float64} # TODO re-evaluate after refactoring w #477
    certainhypo::Vector{Int}
    nullhypo::Float64
    solveInProgress::Int
    inflation::Float64
end

## Constructors

GenericFunctionNodeData{T}() where T =
    GenericFunctionNodeData(false, false, Int[], T())

function GenericFunctionNodeData(   eliminated::Bool,
                                    potentialused::Bool,
                                    edgeIDs::Vector{Int},
                                    fnc::T,
                                    multihypo::Vector{<:Real}=Float64[],
                                    certainhypo::Vector{Int}=Int[],
                                    nullhypo::Real=0,
                                    solveInP::Int=0,
                                    inflation::Real=0.0 ) where T
    return GenericFunctionNodeData{T}(eliminated, potentialused, edgeIDs, fnc, multihypo, certainhypo, nullhypo, solveInP, inflation)
end


##------------------------------------------------------------------------------
## PackedFunctionNodeData and FunctionNodeData

const PackedFunctionNodeData{T} = GenericFunctionNodeData{T} where T <: AbstractPackedFactor
PackedFunctionNodeData(args...) = PackedFunctionNodeData{typeof(args[4])}(args...)

const FunctionNodeData{T} = GenericFunctionNodeData{T} where T <: Union{<:AbstractFactor, <:FactorOperationalMemory}
FunctionNodeData(args...) = FunctionNodeData{typeof(args[4])}(args...)


# PackedFunctionNodeData(x2, x3, x4, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where T <: AbstractPackedFactor =
#     GenericFunctionNodeData{T}(x2, x3, x4, x6, multihypo, certainhypo, x9)
# FunctionNodeData(x2, x3, x4, x6::T, multihypo::Vector{Float64}=[], certainhypo::Vector{Int}=Int[], x9::Int=0) where T <: Union{AbstractFactor, FactorOperationalMemory} =
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
Base.@kwdef struct DFGFactor{T, N} <: AbstractDFGFactor
    """The ID for the factor"""
    id::Union{UUID, Nothing}
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Internal cache of the ordering of the neighbor variables. Rather use getVariableOrder to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
    _variableOrderSymbols::NTuple{N,Symbol}
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime
    """Nano second time, for more resolution on timestamp (only subsecond information)"""
    nstime::Nanosecond
    """Solver data.
    Accessors: [`getSolverData`](@ref), [`setSolverData!`](@ref)"""
    solverData::Base.RefValue{GenericFunctionNodeData{T}}
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData`](@ref), [`setSmallData!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes}
    # Inner constructor
    function DFGFactor{T}(label::Symbol,
                 timestamp::Union{DateTime,ZonedDateTime},
                 nstime::Nanosecond,
                 tags::Set{Symbol},
                 solverData::GenericFunctionNodeData{T},
                 solvable::Int,
                 _variableOrderSymbols::NTuple{N,Symbol};
                 id::Union{UUID, Nothing} = nothing,
                smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()) where {T,N}
        return new{T,N}(id, label, tags, _variableOrderSymbols, timestamp, nstime, Ref(solverData), Ref(solvable), smallData)
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
          _variableOrderSymbols::Tuple;
          id::Union{UUID, Nothing} = nothing,
          smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()) where {T} =
          DFGFactor{T}(label, timestamp, nstime, tags, solverData, solvable, _variableOrderSymbols, id=id, smallData=smallData)


DFGFactor{T}(label::Symbol, variableOrderSymbols::Vector{Symbol}, timestamp::Union{DateTime,ZonedDateTime}=now(localzone()), data::GenericFunctionNodeData{T} = GenericFunctionNodeData{T}()) where {T} =
                DFGFactor(label, timestamp, Nanosecond(0), Set{Symbol}(), data, 1, Tuple(variableOrderSymbols))


DFGFactor(label::Symbol,
          variableOrderSymbols::Vector{Symbol},
          data::GenericFunctionNodeData{T};
          tags::Set{Symbol}=Set{Symbol}(),
          timestamp::Union{DateTime,ZonedDateTime}=now(localzone()),
          solvable::Int=1,
          nstime::Nanosecond = Nanosecond(0),
          id::Union{UUID, Nothing} = nothing,
          smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()) where {T} =
                DFGFactor{T}(label, timestamp, nstime, tags, data, solvable, Tuple(variableOrderSymbols), id=id, smallData=smallData)



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
Base.@kwdef struct DFGFactorSummary <: AbstractDFGFactor
    """The ID for the factor"""
    id::Union{UUID, Nothing}
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
    _variableOrderSymbols::Vector{Symbol}
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::ZonedDateTime
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
Base.@kwdef struct SkeletonDFGFactor <: AbstractDFGFactor
    """The ID for the factor"""
    id::Union{UUID, Nothing}
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
