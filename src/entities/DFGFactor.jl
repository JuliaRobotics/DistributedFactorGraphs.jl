##==============================================================================
## Abstract Types
##==============================================================================

# TODO consider changing this to AbstractFactor
abstract type AbstractFactor end
abstract type AbstractPackedFactor end

abstract type AbstractPrior <: AbstractFactor end
abstract type AbstractRelative <: AbstractFactor end
# abstract type AbstractRelativeRoots <: AbstractRelative end    # TODO deprecate
abstract type AbstractRelativeMinimize <: AbstractRelative end
abstract type AbstractManifoldMinimize <: AbstractRelative end

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
Base.@kwdef mutable struct GenericFunctionNodeData{
    T <: Union{<:AbstractPackedFactor, <:AbstractFactor, <:FactorOperationalMemory},
}
    eliminated::Bool = false
    potentialused::Bool = false
    edgeIDs::Vector{Int} = Int[]
    fnc::T
    multihypo::Vector{Float64} = Float64[] # TODO re-evaluate after refactoring w #477
    certainhypo::Vector{Int} = Int[]
    nullhypo::Float64 = 0.0
    solveInProgress::Int = 0
    inflation::Float64 = 0.0
end

# TODO should we move non FactorOperationalMemory to DFGFactor: 
# fnc, multihypo, nullhypo, inflation ?
# that way we split solverData <: FactorOperationalMemory and constants
# TODO see if above ever changes?

## Constructors

##------------------------------------------------------------------------------
## PackedFunctionNodeData and FunctionNodeData

const PackedFunctionNodeData{T} =
    GenericFunctionNodeData{T} where {T <: AbstractPackedFactor}
function PackedFunctionNodeData(args...; kw...)
    return PackedFunctionNodeData{typeof(args[4])}(args...; kw...)
end

const FunctionNodeData{T} = GenericFunctionNodeData{
    T,
} where {T <: Union{<:AbstractFactor, <:FactorOperationalMemory}}
FunctionNodeData(args...; kw...) = FunctionNodeData{typeof(args[4])}(args...; kw...)

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

# Packed Factor
Base.@kwdef struct PackedFactor <: AbstractDFGFactor
    id::Union{UUID, Nothing} = nothing
    label::Symbol
    tags::Vector{Symbol}
    _variableOrderSymbols::Vector{Symbol}
    timestamp::ZonedDateTime
    nstime::String
    fnctype::String
    solvable::Int
    data::String
    metadata::String
    _version::String = string(_getDFGVersion())
end

StructTypes.StructType(::Type{PackedFactor}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{PackedFactor}) = :id
StructTypes.omitempties(::Type{PackedFactor}) = (:id,)

## DFGFactor lv2

"""
$(TYPEDEF)
Complete factor structure for a DistributedFactorGraph factor.

DevNotes
- TODO make consistent the order of fields skeleton Skeleton, Summary, thru DFGFactor
  - e.g. timestamp should be a later field.

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
    _variableOrderSymbols::NTuple{N, Symbol}
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
    function DFGFactor{T}(
        label::Symbol,
        timestamp::Union{DateTime, ZonedDateTime},
        nstime::Nanosecond,
        tags::Set{Symbol},
        solverData::GenericFunctionNodeData{T},
        solvable::Int,
        _variableOrderSymbols::NTuple{N, Symbol};
        id::Union{UUID, Nothing} = nothing,
        smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    ) where {T, N}
        return new{T, N}(
            id,
            label,
            tags,
            _variableOrderSymbols,
            timestamp,
            nstime,
            Ref(solverData),
            Ref(solvable),
            smallData,
        )
    end
end

##------------------------------------------------------------------------------
## Constructors

"""
$(SIGNATURES)

Construct a DFG factor given a label.
"""
function DFGFactor(
    label::Symbol,
    timestamp::Union{DateTime, ZonedDateTime},
    nstime::Nanosecond,
    tags::Set{Symbol},
    solverData::GenericFunctionNodeData{T},
    solvable::Int,
    _variableOrderSymbols::Tuple;
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
) where {T}
    return DFGFactor{T}(
        label,
        timestamp,
        nstime,
        tags,
        solverData,
        solvable,
        _variableOrderSymbols;
        id = id,
        smallData = smallData,
    )
end

function DFGFactor{T}(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol},
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    data::GenericFunctionNodeData{T} = GenericFunctionNodeData(; fnc = T());
    kw...,
) where {T}
    return DFGFactor(
        label,
        timestamp,
        Nanosecond(0),
        Set{Symbol}(),
        data,
        1,
        Tuple(variableOrderSymbols);
        kw...,
    )
end
#

# TODO standardize new fields in kw constructors, .id
function DFGFactor(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol},
    data::GenericFunctionNodeData{T};
    tags::Set{Symbol} = Set{Symbol}(),
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    solvable::Int = 1,
    nstime::Nanosecond = Nanosecond(0),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
) where {T}
    return DFGFactor{T}(
        label,
        timestamp,
        nstime,
        tags,
        data,
        solvable,
        Tuple(variableOrderSymbols);
        id,
        smallData,
    )
end

Base.getproperty(x::DFGFactor, f::Symbol) = begin
    if f == :solvable || f == :solverData
        getfield(x, f)[]
    elseif f == :_variableOrderSymbols
        [getfield(x, f)...]
    else
        getfield(x, f)
    end
end

function Base.setproperty!(x::DFGFactor, f::Symbol, val)
    if f == :solvable || f == :solverData
        getfield(x, f)[] = val
    else
        setfield!(x, f, val)
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
    """Internal cache of the ordering of the neighbor variables. Rather use listNeighbors to get the list as this is an internal value.
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
    """Internal cache of the ordering of the neighbor variables. Rather use listNeighbors to get the list as this is an internal value.
    Accessors: [`getVariableOrder`](@ref)"""
    _variableOrderSymbols::Vector{Symbol}
end

##------------------------------------------------------------------------------
## Constructors

#NOTE I feel like a want to force a variableOrderSymbols
function SkeletonDFGFactor(
    id::Union{UUID, Nothing},
    label::Symbol,
    variableOrderSymbols::Vector{Symbol} = Symbol[],
)
    return SkeletonDFGFactor(id, label, Set{Symbol}(), variableOrderSymbols)
end
function SkeletonDFGFactor(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol} = Symbol[];
    id::Union{UUID, Nothing} = nothing,
    tags = Set{Symbol}(),
)
    return SkeletonDFGFactor(id, label, tags, variableOrderSymbols)
end

StructTypes.StructType(::Type{SkeletonDFGFactor}) = StructTypes.OrderedStruct()
StructTypes.idproperty(::Type{SkeletonDFGFactor}) = :id
StructTypes.omitempties(::Type{SkeletonDFGFactor}) = (:id,)

##==============================================================================
## Define factor levels
##==============================================================================
const FactorDataLevel0 = Union{DFGFactor, DFGFactorSummary, PackedFactor, SkeletonDFGFactor}
const FactorDataLevel1 = Union{DFGFactor, DFGFactorSummary, PackedFactor}
const FactorDataLevel2 = Union{DFGFactor}

##==============================================================================
## Conversion constructors
##==============================================================================

function DFGFactorSummary(f::DFGFactor)
    return DFGFactorSummary(
        f.id,
        f.label,
        deepcopy(f.tags),
        deepcopy(f._variableOrderSymbols),
        f.timestamp,
    )
end

function SkeletonDFGFactor(f::FactorDataLevel1)
    return SkeletonDFGFactor(
        f.id,
        f.label,
        deepcopy(f.tags),
        deepcopy(f._variableOrderSymbols),
    )
end
