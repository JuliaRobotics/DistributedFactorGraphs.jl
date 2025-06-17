##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractPackedFactorObservation end
abstract type AbstractFactorObservation end

abstract type AbstractPrior <: AbstractFactorObservation end
abstract type AbstractRelative <: AbstractFactorObservation end
abstract type AbstractRelativeMinimize <: AbstractRelative end
abstract type AbstractManifoldMinimize <: AbstractRelative end

# NOTE DF, Convolution is IIF idea, but DFG should know about "FactorSolverCache"
# DF, IIF.CommonConvWrapper <: FactorSolverCache #
# NOTE was `<: Function` as unnecessary
abstract type FactorSolverCache end
# TODO to be removed from DFG,
# we can add to IIF or have IIF.CommonConvWrapper <: FactorSolverCache directly
# abstract type ConvolutionObject <: FactorSolverCache end

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

# TODO should we move non FactorSolverCache to FactorCompute: 
# fnc, multihypo, nullhypo, inflation ?
# that way we split solverData <: FactorSolverCache and constants
# TODO see if above ever changes?

## Constructors

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
    data::Union{Nothing, String} = nothing #TODO deprecate data completely, left as a bridge to old serialization structure
    metadata::String
    _version::String = string(_getDFGVersion())
    state::FactorState
    observJSON::String # serialized observation
    # blobEntries::Vector{Blobentry}#TODO should factor have blob entries?
end

#TODO type not in DFG FactorDFG, should it be?
# _type::String
# createdTimestamp::DateTime
# lastUpdatedTimestamp::DateTime

StructTypes.StructType(::Type{FactorDFG}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{FactorDFG}) = :id
StructTypes.omitempties(::Type{FactorDFG}) = (:id, :data)

#TODO deprecate, added in v0.27 as a bridge to new serialization structure
function FactorDFG(
    id::Union{UUID, Nothing},
    label::Symbol,
    tags::Set{Symbol},
    _variableOrderSymbols::Vector{Symbol},
    timestamp::ZonedDateTime,
    nstime::String,
    fnctype::String,
    solvable::Int,
    data::Union{Nothing, String},
    metadata::String,
    _version::String,
    state::Union{Nothing, FactorState} = nothing,
    observJSON::Union{Nothing, String} = nothing,
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
        nothing, #TODO deprecate data completely
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
abstract type InferenceType <: AbstractPackedFactorObservation end

#TODO deprecate InferenceType in favor of AbstractPackedFactorObservation v0.26

# Packed Factor constructor
function assembleFactorName(xisyms::Union{Vector{String}, Vector{Symbol}})
    return Symbol(xisyms..., "_f", randstring(4))
end

getFncTypeName(fnc::AbstractPackedFactorObservation) = split(string(typeof(fnc)), ".")[end]

function FactorDFG(
    xisyms::Vector{Symbol},
    fnc::AbstractPackedFactorObservation;
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
Base.@kwdef struct FactorCompute{FT <: AbstractFactorObservation, N} <: AbstractDFGFactor
    """The ID for the factor"""
    id::Union{UUID, Nothing} = nothing #TODO deprecate id
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
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Dictionary of small data associated with this variable.
    Accessors: [`getMetadata`](@ref), [`setMetadata!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()

    #refactor fields
    """Observation function or measurement for this factor.
    Accessors: [`getObservation`](@ref)(@ref)"""
    observation::FT
    """Describes the current state of the factor. Persisted in serialization.
    Accessors: [`getFactorState`](@ref)"""
    state::FactorState
    """Temporary, non-persistent memory used internally by the solver for intermediate numerical computations and buffers.  
    `solvercache` is lazily allocated and only used during factor operations; it is not serialized or retained after solving.
    Accessors: [`getCache`](@ref), [`setCache!`](@ref)"""
    solvercache::Base.RefValue{<:FactorSolverCache} #TODO easy of use vs. performance as container is abstract in any case.
end

##------------------------------------------------------------------------------
## Constructors

# TODO standardize new fields in kw constructors, .id
function FactorCompute(
    label::Symbol,
    variableOrder::Union{Vector{Symbol}, Tuple},
    observation::AbstractFactorObservation,
    state::FactorState = FactorState(),
    cache = nothing;
    tags::Set{Symbol} = Set{Symbol}(),
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    solvable::Int = 1,
    nstime::Nanosecond = Nanosecond(0),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    solverData = nothing,
)
    if !isnothing(solverData)
        Base.depwarn("`FactorCompute` solverData is deprecated", :FactorCompute)
    end

    if isnothing(cache)
        solvercache = Ref{FactorSolverCache}()
    else
        solvercache = Ref(cache)
    end

    return FactorCompute(
        id,
        label,
        tags,
        Tuple(variableOrder),
        timestamp,
        nstime,
        Ref(solvable),
        smallData,
        observation,
        state,
        solvercache,
    )
end

function Base.getproperty(x::FactorCompute, f::Symbol)
    if f == :solvable
        getfield(x, f)[]
    elseif f == :solverData
        # TODO remove, deprecated in v0.27
        error(
            "`solverData` is obsolete in `FactorCompute`. Use `getObservation`, `getState` or `getCache` instead.",
        )
    elseif f == :_variableOrderSymbols
        [getfield(x, f)...]
    else
        getfield(x, f)
    end
end

function Base.setproperty!(x::FactorCompute, f::Symbol, val)
    if f == :solvable
        getfield(x, f)[] = val
    elseif f == :solverData
        error(
            "`solverData` is obsolete in `FactorCompute`. Use `Observation`, `State` or `Cache` instead.",
        )
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
