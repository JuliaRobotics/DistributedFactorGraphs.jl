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

#TODO is this mutable
@kwdef mutable struct FactorState
    eliminated::Bool = false
    potentialused::Bool = false
    multihypo::Vector{Float64} = Float64[] # TODO re-evaluate after refactoring w #477
    certainhypo::Vector{Int} = Int[]
    nullhypo::Float64 = 0.0
    solveInProgress::Int = 0 #TODO maybe deprecated or move to operational memory, also why Int?
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
# | FactorSkeleton    |   X   |   x  |           |          |            |
# | FactorSummary     |   X   |   X  |     X     |          |            |
# | FactorDFG         |   X   |   X  |     X     |     X    |      X*    |
# | FactorCompute     |   X   |   X  |     X     |     X    |      X     |
# *not available without reconstruction

"""
    $(TYPEDEF)

The Factor information packed in a way that accomdates multi-lang using json.
"""

#TODO do we have parameter for packed observation or is it already a string?
#TODO Same with metadata?
Base.@kwdef struct FactorDFG <: AbstractDFGFactor
    id::Union{UUID, Nothing} = nothing
    label::Symbol
    tags::Set{Symbol}
    _variableOrderSymbols::Vector{Symbol}
    timestamp::ZonedDateTime
    nstime::String
    fnctype::String
    solvable::Int
    data::String
    metadata::String
    _version::String = string(_getDFGVersion())
    state::FactorState
    observJSON::String # serialized opbservation
    # blobEntries::Vector{Blobentry}#TODO should factor have blob entries?
end

#TODO type not in DFG FactorDFG, should it be?
# _type::String
# createdTimestamp::DateTime
# lastUpdatedTimestamp::DateTime

StructTypes.StructType(::Type{FactorDFG}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{FactorDFG}) = :id
StructTypes.omitempties(::Type{FactorDFG}) = (:id,)

#TODO deprecate, added in v0.26 as a bridge to new serialization structure
function FactorDFG(
    id::Union{UUID, Nothing},
    label::Symbol,
    tags::Set{Symbol},
    _variableOrderSymbols::Vector{Symbol},
    timestamp::ZonedDateTime,
    nstime::String,
    fnctype::String,
    solvable::Int,
    data::String,
    metadata::String,
    _version::String,
    state::Union{Nothing, FactorState},
    observJSON::Union{Nothing, String},
)
    if isnothing(state) || isnothing(observJSON)
        fd = JSON3.read(data)
        state = FactorState(
            fd.eliminated,
            fd.potentialused,
            fd.multihypo,
            fd.certainhypo,
            fd.nullhypo,
            fd.solveInProgress,
            fd.inflation,
        )
        observJSON = JSON3.write(fd.fnc)
    end
    return FactorDFG(
        id,
        label,
        tags,
        _variableOrderSymbols,
        timestamp,
        nstime,
        fnctype,
        solvable,
        data,
        metadata,
        _version,
        state,
        observJSON,
    )
end

FactorDFG(f::FactorDFG) = f

# TODO consolidate to just one type
"""
$(TYPEDEF)
Abstract parent type for all InferenceTypes, which are the
observation functions inside of factors.
"""
abstract type InferenceType <: AbstractPackedFactor end

#TODO deprecate InferenceType in favor of AbstractPackedFactor v0.26

# this is the GenericFunctionNodeData for packed types
#TODO deprecate FactorData in favor of FactorState (with no more distinction between packed and compute)
const FactorData = PackedFunctionNodeData{AbstractPackedFactor}

# Packed Factor constructor
function assembleFactorName(xisyms::Union{Vector{String}, Vector{Symbol}})
    return Symbol(xisyms..., "_f", randstring(4))
end

getFncTypeName(fnc::AbstractPackedFactor) = split(string(typeof(fnc)), ".")[end]

function FactorDFG(
    xisyms::Vector{Symbol},
    fnc::AbstractPackedFactor;
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
    state = FactorState(; multihypo, nullhypo, inflation)

    fnctype = getFncTypeName(fnc)

    union!(tags, [:FACTOR])
    # create factor 
    factor = FactorDFG(;
        label,
        tags = Set(tags),
        _variableOrderSymbols = xisyms,
        timestamp,
        nstime = string(nstime),
        fnctype,
        solvable,
        metadata = base64encode(JSON3.write(metadata)),
        state,
        observJSON = JSON3.write(fnc),
        data = "", #TODO deprecate data completely
    )

    return factor
end

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
Base.@kwdef struct FactorCompute{FT <: AbstractFactor, N} <: AbstractDFGFactor
    """The ID for the factor"""
    id::Union{UUID, Nothing} = nothing
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
    """Nano second time"""
    nstime::Nanosecond
    """Solver data.
    Accessors: [`getSolverData`](@ref), [`setSolverData!`](@ref)"""
    solverData::Base.RefValue{<:GenericFunctionNodeData}
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Dictionary of small data associated with this variable.
    Accessors: [`getMetadata`](@ref), [`setMetadata!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()

    #refactor fields
    observation::FT
    state::FactorState
    computeMem::Base.RefValue{<:FactorOperationalMemory} #TODO easy of use vs. performance as container is abstract in any case.
end

##------------------------------------------------------------------------------
## Constructors

#TODO consolidate constructors, currently IIF calls only
# DFGFactor(
#     Symbol(namestring),
#     varOrderLabels,
#     solverData;
#     tags = Set(union(tags, [:FACTOR])),
#     solvable,
#     timestamp = _zonedtime(timestamp),
# )

function FactorCompute(
    label::Symbol,
    timestamp::Union{DateTime, ZonedDateTime},
    nstime::Nanosecond,
    tags::Set{Symbol},
    solverData::GenericFunctionNodeData,
    solvable::Int,
    variableOrder::Union{Vector{Symbol}, Tuple};
    observation = getFactorType(solverData),
    state::FactorState = FactorState(),
    computeMem::Base.RefValue{<:FactorOperationalMemory} = Ref{FactorOperationalMemory}(),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
)
    return FactorCompute(
        id,
        label,
        tags,
        Tuple(variableOrder),
        timestamp,
        nstime,
        Ref(solverData),
        Ref(solvable),
        smallData,
        observation,
        state,
        computeMem,
    )
end

# TODO standardize new fields in kw constructors, .id
function FactorCompute(
    label::Symbol,
    variableOrder::Union{Vector{Symbol}, Tuple},
    solverData::GenericFunctionNodeData;
    tags::Set{Symbol} = Set{Symbol}(),
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    solvable::Int = 1,
    nstime::Nanosecond = Nanosecond(0),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
)
    observation = getFactorType(solverData)
    state = FactorState(
        solverData.eliminated,
        solverData.potentialused,
        solverData.multihypo,
        solverData.certainhypo,
        solverData.nullhypo,
        solverData.solveInProgress,
        solverData.inflation,
    )

    if solverData.fnc isa FactorOperationalMemory
        computeMem = Ref(solverData.fnc)
    else
        computeMem = Ref{FactorOperationalMemory}()
    end

    return FactorCompute(
        label,
        timestamp,
        nstime,
        tags,
        solverData,
        solvable,
        Tuple(variableOrder);
        observation,
        computeMem,
        id,
        smallData,
        state,
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
const FactorDataLevel0 = Union{FactorCompute, FactorSummary, FactorDFG, FactorSkeleton}
const FactorDataLevel1 = Union{FactorCompute, FactorSummary, FactorDFG}
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
