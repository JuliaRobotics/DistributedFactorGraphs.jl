##==============================================================================
## Abstract Types
##==============================================================================
abstract type AbstractObservation end
const Observation = AbstractObservation

abstract type AbstractPriorObservation <: AbstractObservation end
const PriorObservation = AbstractPriorObservation

abstract type AbstractRelativeObservation <: AbstractObservation end
const RelativeObservation = AbstractRelativeObservation

# TODO https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/pull/1127#discussion_r2154672975 and #1138
abstract type AbstractFactorCache end
const FactorCache = AbstractFactorCache #
#TODO consider making AbstractFactorCache{T <: AbstractObservation}

##==============================================================================
## Factor State
##==============================================================================

#TODO is this mutable
@kwdef mutable struct Recipehyper
    multihypo::Vector{Float64} = Float64[] # TODO re-evaluate after refactoring w #477
    nullhypo::Float64 = 0.0
    inflation::Float64 = 0.0
end

@kwdef mutable struct Recipestate
    eliminated::Bool = false
    potentialused::Bool = false
end

##==============================================================================
## Factors
##==============================================================================
#
# |                   | label | tags | timestamp | solvable | solverData |
# |-------------------|:-----:|:----:|:---------:|:--------:|:----------:|
# | FactorSkeleton    |   X   |   x  |           |          |            |
# | FactorSummary     |   X   |   X  |     X     |          |            |
# | FactorDFG         |   X   |   X  |     X     |     X    |      X*    |
# *not available without reconstruction

# Packed Factor constructor
function assembleFactorName(xisyms)
    return Symbol(xisyms..., "_f", randstring(4))
end

"""
$(TYPEDEF)
Complete factor structure for a DistributedFactorGraph factor.

Fields:
$(TYPEDFIELDS)
"""
StructUtils.@kwarg struct FactorDFG{T <: AbstractObservation, N} <: AbstractGraphFactor
    # """The ID for the factor"""
    # id::Union{UUID, Nothing} = nothing #NOTE v0.29 REMOVED
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}([:FACTOR])
    """Ordered list of the neighbor variables.
    Accessors: [`getVariableOrder`](@ref)"""
    variableorder::NTuple{N, Symbol} & (choosetype = x->NTuple{length(x), Symbol},) # NOTE v0.29 renamed from _variableOrderSymbols
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone = now_tdz() # NOTE v0.29 changed from ZonedDateTime
    # TODO
    # """(Optional) Steady (monotonic) time in nanoseconds `Nanosecond` (`Int64``)"""
    # nstime::Nanosecond #NOTE v0.29 REMOVED as not used, add when needed, or now as steadytime.
    """Solvable flag for the factor.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref{Int}(1) #& (lower = getindex, lift = Ref)
    """Dictionary of small data associated with this variable.
    Accessors: [`getBloblet`](@ref), [`addBloblet!`](@ref)"""
    bloblets::Bloblets = Bloblets() #NOTE v0.29 changed from smallData::Dict{Symbol, MetadataTypes} = Dict{Symbol, MetadataTypes}()
    """Observation function or measurement for this factor.
    Accessors: [`getObservation`](@ref)(@ref)"""
    observation::T & (lower = pack_lower, choosetype = DFG.resolvePackedType)#TODO finalise serializd type
    """Hyperparameters associated with this factor."""
    hyper::Recipehyper = Recipehyper()
    """Describes the current state of the factor. Persisted in serialization."""
    state::Recipestate = Recipestate()
    """Temporary, non-persistent memory used internally by the solver for intermediate numerical computations and buffers.  
    `solvercache` is lazily allocated and only used during factor operations; it is not serialized or retained after solving.
    Accessors: [`getCache`](@ref), [`setCache!`](@ref)"""
    solvercache::Base.RefValue{<:FactorCache} = Ref{FactorCache}() & (ignore = true,)#TODO easy of use vs. performance as container is abstract in any case.
    """Blobentries associated with this factor."""
    blobentries::Blobentries = Blobentries() #NOTE v0.29 added
    """Internal: used for automatic type metadata generation."""
    _autotype::Nothing = nothing & (name = :type, lower = _ -> TypeMetadata(FactorDFG))
end

version(::Type{<:FactorDFG}) = v"0.29.0"

##------------------------------------------------------------------------------
## Constructors - IIF like
function FactorDFG(
    variableorder::Union{<:Tuple, Vector{Symbol}},
    observation::AbstractObservation;
    label::Symbol = assembleFactorName(variableorder),
    timestamp::Union{TimeDateZone, ZonedDateTime} = now_tdz(),
    tags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}([:FACTOR]),
    bloblets::Bloblets = Bloblets(),
    multihypo::Vector{Float64} = Float64[],
    nullhypo::Float64 = 0.0,
    inflation::Real = 3.0,
    solvable::Int = 1,
    nstime = nothing,
    metadata = nothing,
)
    # deprecated in v0.29
    if !isnothing(nstime)
        Base.depwarn("`FactorDFG` nstime is deprecated", :FactorDFG)
    end
    # deprecated in v0.29
    if !isnothing(metadata)
        Base.depwarn("`FactorDFG` metadata is deprecated, use bloblets instead", :FactorDFG)
    end

    if timestamp isa ZonedDateTime
        Base.depwarn(
            "`FactorDFG` timestamp as `ZonedDateTime` is deprecated, use `TimeDateZone` instead",
            :FactorDFG,
        )
        timestamp = TimeDateZone(timestamp.utc_datetime)
    end

    # create factor data
    hyper = Recipehyper(; multihypo, nullhypo, inflation)
    state = Recipestate()

    union!(tags, [:FACTOR])
    # create factor 
    factor = FactorDFG(;
        label,
        tags = Set(tags),
        variableorder = Tuple(variableorder),
        timestamp,
        solvable = Ref(solvable),
        bloblets,
        hyper,
        state,
        observation,
    )

    return factor
end

# TODO standardize new fields in kw constructors, .id
function FactorDFG(
    label::Symbol,
    variableorder::Union{Vector{Symbol}, Tuple},
    observation::AbstractObservation,
    hyper::Recipehyper = Recipehyper(),
    state::Recipestate = Recipestate(),
    cache = nothing;
    tags::Set{Symbol} = Set{Symbol}([:FACTOR]),
    timestamp::Union{DateTime, ZonedDateTime, TimeDateZone} = now_tdz(),
    solvable::Int = 1,
    bloblets::Bloblets = Bloblets(),
    blobentries::Blobentries = Blobentries(),
    nstime = nothing,
    smallData = nothing,
)
    #TODO deprecated in v0.29
    if !isnothing(nstime)
        Base.depwarn("`FactorDFG` nstime is deprecated", :FactorDFG)
    end
    if !isnothing(smallData)
        Base.depwarn(
            "`FactorDFG` smallData is deprecated, use bloblets instead",
            :FactorDFG,
        )
    end

    if isnothing(cache)
        solvercache = Ref{FactorCache}()
    else
        solvercache = Ref(cache)
    end

    # TODO v0.29 deprecate ZonedDateTime or convert internally
    if timestamp isa ZonedDateTime
        timestamp = TimeDateZone(timestamp)
    end

    return FactorDFG(
        label,
        tags,
        Tuple(variableorder),
        timestamp,
        Ref(solvable),
        bloblets,
        observation,
        hyper,
        state,
        solvercache,
        blobentries,
        nothing,
    )
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
@tags struct FactorSummary <: AbstractGraphFactor
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol}
    """Ordered list of the neighbor variables.
    Accessors: [`getVariableOrder`](@ref)"""
    variableorder::Tuple{Vararg{Symbol}} & (choosetype = x->NTuple{length(x), Symbol},) #TODO changed to NTuple
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone
end

function FactorSummary(
    label::Symbol,
    variableorder::Union{Vector{Symbol}, Tuple};
    timestamp::TimeDateZone = now_tdz(),
    tags::Set{Symbol} = Set{Symbol}(),
)
    return FactorSummary(label, tags, Tuple(variableorder), timestamp)
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
@tags struct FactorSkeleton <: AbstractGraphFactor
    """Factor label, e.g. :x1f1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol}
    """Ordered list of the neighbor variables.
    Accessors: [`getVariableOrder`](@ref)"""
    variableorder::Tuple{Vararg{Symbol}} & (choosetype = x->NTuple{length(x), Symbol},)
end

##------------------------------------------------------------------------------
## Constructors

function FactorSkeleton(
    label::Symbol,
    variableorder::Union{Vector{Symbol}, Tuple};
    tags = Set{Symbol}([:FACTOR]),
)
    return FactorSkeleton(label, tags, Tuple(variableorder))
end

##==============================================================================
## Conversion constructors
##==============================================================================

function FactorSummary(f::FactorDFG)
    return FactorSummary(f.label, copy(f.tags), f.variableorder, f.timestamp)
end

function FactorSkeleton(f::AbstractGraphFactor)
    return FactorSkeleton(f.label, copy(f.tags), f.variableorder)
end
