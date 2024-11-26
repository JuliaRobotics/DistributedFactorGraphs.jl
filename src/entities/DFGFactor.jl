##==============================================================================
## Abstract Types
##==============================================================================

# TODO consider changing this to AbstractFactor
abstract type AbstractFactor end
abstract type AbstractPackedFactor end

abstract type AbstractPrior <: AbstractFactor end
abstract type AbstractRelative <: AbstractFactor end
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

# TODO should we move non FactorOperationalMemory to FactorCompute: 
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
# | FactorSkeleton |   X   |   x  |           |          |            |
# | FactorSummary  |   X   |   X  |     X     |          |            |
# | PackedFactor      |   X   |   X  |     X     |     X    |      X*    |
# | FactorCompute         |   X   |   X  |     X     |     X    |      X     |
# *not available without reconstruction

"""
    $(TYPEDEF)

The Factor information packed in a way that accomdates multi-lang using json.
"""
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
    # blobEntries::Vector{BlobEntry}#TODO should factor have blob entries?
end
#TODO type not in DFG PackedFactor, should it be?
# _type::String
# createdTimestamp::DateTime
# lastUpdatedTimestamp::DateTime

PackedFactor(f::PackedFactor) = f

# TODO consolidate to just one type
"""
$(TYPEDEF)
Abstract parent type for all InferenceTypes, which are the
functions inside of factors.
"""
abstract type InferenceType <: DFG.AbstractPackedFactor end
# this is the GenericFunctionNodeData for packed types
const FactorData = PackedFunctionNodeData{InferenceType}

# Packed Factor constructor
function assembleFactorName(xisyms::Union{Vector{String}, Vector{Symbol}})
    return Symbol(xisyms..., "f_", string(uuid4())[1:4])
end

getFncTypeName(fnc::InferenceType) = split(string(typeof(fnc)), ".")[end]

function Factor(
    xisyms::Vector{Symbol},
    fnc::InferenceType;
    multihypo::Vector{Float64} = Float64[],
    nullhypo::Float64 = 0.0,
    solvable::Int = 1,
    tags::Vector{Symbol} = Symbol[],
    timestamp::ZonedDateTime = TimeZones.now(tz"UTC"),
    inflation::Real = 3.0,
    label::Symbol = assembleFactorName(xisyms),
    nstime::Int = 0,
    metadata::Dict{Symbol, DFG.SmallDataTypes} = Dict{Symbol, DFG.SmallDataTypes}(),
)
    # create factor data
    factordata = FactorData(; fnc, multihypo, nullhypo, inflation)

    fnctype = getFncTypeName(fnc)

    union!(tags, [:FACTOR])
    # create factor 
    factor = PackedFactor(;
        label,
        tags,
        _variableOrderSymbols = xisyms,
        timestamp,
        nstime = string(nstime),
        fnctype,
        solvable,
        data = base64encode(JSON3.write(factordata)),
        metadata = base64encode(JSON3.write(metadata)),
    )

    return factor
end

StructTypes.StructType(::Type{PackedFactor}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{PackedFactor}) = :id
StructTypes.omitempties(::Type{PackedFactor}) = (:id,)

## FactorCompute lv2

"""
$(TYPEDEF)
Complete factor structure for a DistributedFactorGraph factor.

DevNotes
- TODO make consistent the order of fields skeleton Skeleton, Summary, thru FactorCompute
  - e.g. timestamp should be a later field.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct FactorCompute{T, N} <: AbstractDFGFactor
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
    Accessors: [`getMetadata`](@ref), [`setMetadata!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes}
    # Inner constructor
    function FactorCompute{T}(
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
function FactorCompute(
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
    return FactorCompute{T}(
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

function FactorCompute{T}(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol},
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    data::GenericFunctionNodeData{T} = GenericFunctionNodeData(; fnc = T());
    kw...,
) where {T}
    return FactorCompute(
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
function FactorCompute(
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
    return FactorCompute{T}(
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

Base.getproperty(x::FactorCompute, f::Symbol) = begin
    if f == :solvable || f == :solverData
        getfield(x, f)[]
    elseif f == :_variableOrderSymbols
        [getfield(x, f)...]
    else
        getfield(x, f)
    end
end

function Base.setproperty!(x::FactorCompute, f::Symbol, val)
    if f == :solvable || f == :solverData
        getfield(x, f)[] = val
    else
        setfield!(x, f, val)
    end
end
##------------------------------------------------------------------------------
## FactorSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Read-only summary factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct FactorSummary <: AbstractDFGFactor
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

function FactorSummary(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol};
    timestamp::ZonedDateTime = now(localzone()),
    tags::Set{Symbol} = Set{Symbol}(),
    id::Union{UUID, Nothing} = nothing,
)
    return FactorSummary(id, label, tags, variableOrderSymbols, timestamp)
end

##------------------------------------------------------------------------------
## FactorSkeleton lv0
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct FactorSkeleton <: AbstractDFGFactor
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
function FactorSkeleton(
    id::Union{UUID, Nothing},
    label::Symbol,
    variableOrderSymbols::Vector{Symbol} = Symbol[],
)
    @warn "FactorSkeleton(id::Union{UUID, Nothing}...) is deprecated, use FactorSkeleton(label, variableOrderSymbols) instead"
    return FactorSkeleton(id, label, Set{Symbol}(), variableOrderSymbols)
end
function FactorSkeleton(
    label::Symbol,
    variableOrderSymbols::Vector{Symbol};
    id::Union{UUID, Nothing} = nothing,
    tags = Set{Symbol}(),
)
    return FactorSkeleton(id, label, tags, variableOrderSymbols)
end

StructTypes.StructType(::Type{FactorSkeleton}) = StructTypes.OrderedStruct()
StructTypes.idproperty(::Type{FactorSkeleton}) = :id
StructTypes.omitempties(::Type{FactorSkeleton}) = (:id,)

##==============================================================================
## Define factor levels
##==============================================================================
const FactorDataLevel0 = Union{FactorCompute, FactorSummary, PackedFactor, FactorSkeleton}
const FactorDataLevel1 = Union{FactorCompute, FactorSummary, PackedFactor}
const FactorDataLevel2 = Union{FactorCompute}

##==============================================================================
## Conversion constructors
##==============================================================================

function FactorSummary(f::FactorCompute)
    return FactorSummary(
        f.id,
        f.label,
        deepcopy(f.tags),
        deepcopy(f._variableOrderSymbols),
        f.timestamp,
    )
end

function FactorSkeleton(f::FactorDataLevel1)
    return FactorSkeleton(
        f.id,
        f.label,
        deepcopy(f.tags),
        deepcopy(f._variableOrderSymbols),
    )
end
