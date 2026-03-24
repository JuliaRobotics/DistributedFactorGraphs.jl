##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType

##==============================================================================
## BeliefRepresentation
##==============================================================================
abstract type AbstractDensityKind end

"""Single Gaussian (mean + covariance)."""
struct GaussianDensityKind <: AbstractDensityKind end

"""Kernel density / particle-based (points + shared bandwidth)."""
struct NonparametricDensityKind <: AbstractDensityKind end

"""Homotopy between particles and Gaussian."""
struct HomotopyDensityKind <: AbstractDensityKind end

function StructUtils.lower(::StructUtils.StructStyle, p::AbstractDensityKind)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractDensityKind resolvePackedType

# TODO naming? Density, DensityRepresentation, BeliefRepresentation, BeliefState, etc?
# TODO flatten in State? likeley not for easier serialization of points.
@kwdef struct BeliefRepresentation{T <: StateType, P}
    statekind::T = T()# NOTE duplication for serialization, TODO maybe only in State and therefore belief cannot deserialize seperately.
    """Discriminator for which representation is active."""
    densitykind::AbstractDensityKind = NonparametricDensityKind()

    #--- Parametric fields (Gaussian / GMM / Homotopy leading modes) ---
    """On-manifold component means.
    Gaussian: length 1. Homotopy: leading (tree_kernel) means."""
    means::Vector{P} = P[] # previously `val[1]` for Gaussian
    """Component covariances, matching `means`."""
    covariances::Vector{Matrix{Float64}} = Matrix{Float64}[] # previously `covar` existed but was stored in `bw` (hacky)
    "Component weights, matching `means`."
    weights::Vector{Float64} = Float64[]

    #--- Non-parametric / Homotopy leaves ---
    """On-manifold sample points. For KDE/HomotopyDensity, these are the leaf kernel means."""
    points::Vector{P} = P[] # previously `val`
    """Shared kernel bandwidth matrix used with ManifoldKernelDensity, see field `covar` for the parametric covariance"""
    bandwidth::Union{Nothing, Matrix{Float64}} = zeros(getDimension(T), getDimension(T)) #previously `bw` ---
    # bandwidth::Matrix{Float64} = zeros(getDimension(T), getDimension(T))
    # TODO is bandwidth[s] matrix or vector or ::Vector{Matrix{Float64} or ::Vector{Vector{Float64}?
    # JSON.parse(JSON.json(zeros(0, 0)), Matrix{Float64}) errors, so trying with nothing union
end

JSON.omit_empty(::Type{<:BeliefRepresentation}) = true

function BeliefRepresentation(T::AbstractStateType)
    return BeliefRepresentation{typeof(T), getPointType(T)}(; statekind = T)
end

function BeliefRepresentation(::NonparametricDensityKind, T::AbstractStateType; kwargs...)
    return BeliefRepresentation{typeof(T), getPointType(T)}(;
        statekind = T,
        densitykind = NonparametricDensityKind(),
        bandwidth = zeros(getDimension(T), getDimension(T)),
        kwargs...,
    )
end

function BeliefRepresentation(::GaussianDensityKind, T::AbstractStateType; kwargs...)
    return BeliefRepresentation{typeof(T), getPointType(T)}(;
        statekind = T,
        densitykind = GaussianDensityKind(),
        bandwidth = nothing,
        kwargs...,
    )
end

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{BeliefRepresentation{T, P}},
) where {T, P}
    return (
        statekind = T(),
        densitykind = NonparametricDensityKind(),
        means = P[],
        covariances = Matrix{Float64}[],
        weights = Float64[],
        points = P[],
        bandwidth = nothing,
    )
end

function resolveBeliefRepresentationType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return BeliefRepresentation{typeof(statekind), getPointType(statekind)}
end

@choosetype BeliefRepresentation resolveBeliefRepresentationType

##==============================================================================
## State
##==============================================================================

"""
$(TYPEDEF)
Data container for solver-specific data.

  ---
T: Variable type, such as Position1, or RoME.Pose2, etc.
P: Variable point type, the type of the manifold point.
Fields:
$(TYPEDFIELDS)
"""
@kwdef mutable struct State{T <: StateType, P}
    """Identifier associated with this State object."""
    label::Symbol # TODO renamed from solveKey
    """Singleton type for the state, eg. Pose{3}(), Position{2}(), etc. Used for dispatch and serialization."""
    statekind::T = T()
    """
    Generic Belief representation for this state, including the discriminator for which representation is active 
    and the associated fields for each representation kind.
    """
    belief::BeliefRepresentation{T, P} = BeliefRepresentation{T, P}()#; statekind = T())
    """List of symbols for separator variables for this state, used in variable elimination and inference computations."""
    separator::Vector{Symbol} = Symbol[]
    """False if initial numerical values are not yet available or stored values are not ready for further processing yet."""
    initialized::Bool = false
    """Stores the amount information (per measurement dimension) captured in each coordinate dimension."""
    observability::Vector{Float64} = Float64[]#zeros(getDimension(T)) #TODO renamed from infoPerCoord in v0.29
    """Should this state be treated as marginalized in inference computations."""
    marginalized::Bool = false #TODO renamed from ismargin v0.29
    """How many times has a solver updated this state estimate."""
    solves::Int = 0 # TODO renamed from solvedCount v0.29

    #TODO belief cache that can be used for caching HomotopyDensity (StateCache or BeliefCache)
    # abstract type AbstractStateCache end
    # const StateCache = AbstractStateCache
    # solvercache::Base.RefValue{<:StateCache} = Ref{StateCache}() & (ignore = true,)
end

# OLD deprecated fields, removed in v0.29, kept here for reference during transition
# val::Vector{P} = Vector{P}()
# bw::Matrix{Float64} = zeros(0, 0)
# covar::Vector{Matrix{Float64}} = Matrix{Float64}[]
# BayesNetOutVertIDs::Vector{Symbol} = Symbol[]
# dims::Int = getDimension(T) 
# eliminated::Bool = false
# BayesNetVertID::Symbol = :NOTHING #  Union{Nothing, }
# events::Dict{Symbol, Threads.Condition} = Dict{Symbol, Threads.Condition}()    
# dontmargin::Bool = false

##------------------------------------------------------------------------------
## Constructors
function State{T}(; kwargs...) where {T <: StateType}
    return State{T, getPointType(T)}(; kwargs...)
end
function State(label::Symbol, variableType::StateType; kwargs...)
    return State{typeof(variableType)}(; label, kwargs...)
end

function State(state::State; kwargs...)
    return State{typeof(getStateKind(state))}(;
        (key => deepcopy(getproperty(state, key)) for key in fieldnames(State))...,
        kwargs...,
    )
end

# TODO consider omitting empty fields in State, needs constructor that can take nothing.
# JSON.omit_empty(::Type{<:State}) = true

# Field defaults and tags for State, not through @kwarg macro due to error with State{T, P, N}
function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{State{T, P}},
) where {T, P}
    return (
        belief = BeliefRepresentation{T, P}(; statekind = T()),
        separator = Symbol[],
        initialized = false,
        observability = Float64[],
        marginalized = false,
        solves = 0,
        statekind = T(),
    )
end

refMeans(state::State) = state.belief.means
refCovariances(state::State) = state.belief.covariances
refWeights(state::State) = state.belief.weights
refPoints(state::State) = state.belief.points
refBandwidth(state::State) = state.belief.bandwidth

getDensityKind(state::State) = state.belief.densitykind

# we can also do somthing like this:
function getComponent(state::State, i)
    return (
        mean = refMeans(state)[i],
        cov = refCovariances(state)[i],
        weight = refWeights(state)[i],
    )
end

##------------------------------------------------------------------------------
## States - OrderedDict{Symbol, State}
const States = OrderedDict{Symbol, State{T, P}} where {T <: AbstractStateType, P}

StructUtils.dictlike(::Type{<:States}) = false
StructUtils.structlike(::Type{<:States}) = false
StructUtils.arraylike(::Type{<:States}) = false

function StructUtils.lower(states::States)
    return map(collect(values(states))) do (state)
        return state
    end
end

# Lazy lift: receives the LazyValue directly and parses each element lazily.
# States is lowered as a JSON array, so on deserialization StructUtils sees a
# Vector and needs lift to reconstruct the OrderedDict.  Dispatching on
# JSON.LazyValue keeps every element lazy so nested matrices parse correctly
# (avoids StructUtils.MultiDimClosure receiving String keys from eager objects).
function StructUtils.lift(
    style::StructUtils.StructStyle,
    S::Type{<:States{T}},
    lazystates::JSON.LazyValue,
    tags::NamedTuple = (;),
) where {T}
    StateT = State{T, getPointType(T)}
    states = S()
    StructUtils.applyeach(lazystates) do i, lazy_element
        state = JSON.parse(lazy_element, StateT; style = style)
        return push!(states, state.label => state)
    end
    return states, nothing
end

##==============================================================================
## DFG Variables
##==============================================================================

##------------------------------------------------------------------------------
## VariableCompute
##------------------------------------------------------------------------------
# The Variable information packed in a way that accomdates multi-lang using json.

variable_timestamp_note = """
!!! note    
    This single timestamp does not represent the temporal uncertainty of non-parametric beliefs.
    A single timestamp value cannot capture the distribution of temporal 
    information across all particles/points in a belief. For problems where time is a state variable 
    requiring inference (e.g., `SGal3` which includes temporal components), include time as part of 
    your state type rather than relying on this metadata field.
"""

#TODO move solvable to State, and update filters
"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
@kwdef struct VariableDFG{T <: StateType, P} <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable event timestamp (UTC-based) with timezone support.    
    $variable_timestamp_note
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone = now_tdz() #NOTE changed to TimeDateZone in v0.29
    # """Nanoseconds since a user-understood epoch (e.g unix epoch, robot boot time, etc.)"""
    # nstime::String = "0" #NOTE deprecated field in v0.29
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    """Dictionary of state data. May be a subset of all solutions if a solver label was specified in the get call.
    Accessors: [`addState!`](@ref), [`mergeState!`](@ref), and [`deleteState!`](@ref)"""
    states::OrderedDict{Symbol, State{T, P}} = OrderedDict{Symbol, State{T, P}}() #NOTE field renamed from solverDataDict in v0.29
    """Dictionary of small data associated with this variable.
    Accessors: [`getBloblet`](@ref), [`addBloblet!`](@ref)"""
    bloblets::Bloblets = Bloblets() #NOTE changed from smallData in v0.29
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    blobentries::Blobentries = Blobentries() #NOTE renamed from dataDict in v0.29
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref{Int}(1) #& (lower = getindex,)
    statekind::T = T()
    # TODO autotype or version and statekind
    _autotype::Nothing = nothing #& (name = :type, lower = _ -> TypeMetadata(VariableDFG))
end
version(::Type{<:VariableDFG}) = v"0.29"
refStates(v::VariableDFG) = v.states

#NOTE fielddefaults and fieldtags not through @kwarg macro due to error with State{T, P, N}
function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{VariableDFG{T, P}},
) where {T, P}
    return (
        timestamp = now_tdz(),
        tags = Set{Symbol}(),
        states = OrderedDict{Symbol, State{T, P}}(),
        bloblets = Bloblets(),
        blobentries = Blobentries(),
        solvable = Ref(1),
        _autotype = nothing,
    )
end

function StructUtils.fieldtags(::StructUtils.StructStyle, ::Type{<:VariableDFG})
    return (
        _autotype = (name = :type, lower = _ -> TypeMetadata(VariableDFG)),
        # solvable = (lower = getindex,),
    )
end

function resolveVariableDFGType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return VariableDFG{typeof(statekind), getPointType(statekind)}
end

@choosetype VariableDFG resolveVariableDFGType

# JSON.omit_empty(::DistributedFactorGraphs.DFGJSONStyle, ::Type{<:VariableDFG}) = true

const VariableCompute = VariableDFG
##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default VariableDFG constructor.
"""
#IIF like contruction helper for VariableDFG
function VariableDFG(
    label::Symbol,
    ::Union{T, Type{T}}; # statekind
    tags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    timestamp::Union{TimeDateZone, ZonedDateTime} = now_tdz(),
    solvable::Union{Int, Base.RefValue{Int}} = Ref{Int}(1),
    nanosecondtime = nothing,
    smalldata = nothing,
    kwargs...,
) where {T <: StateType}
    if timestamp isa ZonedDateTime
        # TODO @warn
        timestamp = TimeDateZone(timestamp)
    end
    if !isnothing(nanosecondtime)
        Base.depwarn(
            "nanosecondtime kwarg is deprecated, use `timestamp` or `bloblets` instead",
            :VariableDFG,
        )
    end
    if !isnothing(smalldata)
        Base.depwarn("smalldata kwarg is deprecated, use bloblets instead", :VariableDFG)
        #TODO convert smalldata to bloblets
    end
    if solvable isa Int
        solvable = Ref(solvable)
    end
    union!(tags, [:VARIABLE])

    P = getPointType(T)
    return VariableDFG{T, P}(; label, solvable, tags, timestamp, kwargs...)
end

function VariableDFG(label::Symbol, state::State; kwargs...)
    return VariableDFG(
        label,
        getStateKind(state);
        states = OrderedDict(state.label => state),
        kwargs...,
    )
end

# Base.getproperty(x::VariableCompute, f::Symbol) = begin
#     if f == :solvable
#         getfield(x, f)[]
#     else
#         getfield(x, f)
#     end
# end

# Base.setproperty!(x::VariableCompute, f::Symbol, val) = begin
#     if f == :solvable
#         getfield(x, f)[] = val
#     else
#         setfield!(x, f, val)
#     end
# end

"""
    $SIGNATURES

Merge the contents of `src` into `dest` by only patching child collections/containers.
Notes:
- Cascades into collections (`tags`, `states`, `blobentries`, `bloblets`).
- Assumes `label`, `timestamp`, and `statekind` are immutable and does not update them.
"""
function patch!(dest::VariableDFG{T}, src::VariableDFG{T}) where {T}
    dest === src && return dest # avoid unnecessary work if same object

    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    dest.timestamp != src.timestamp && throw(
        MergeConflictError(
            "Variables has different timestamps: $(dest.timestamp) vs $(src.timestamp).",
        ),
    )
    # you will get a method error if statekind is different, so maybe we don't need to check that here.

    union!(dest.tags, src.tags)
    merge!(dest.states, src.states)
    merge!(dest.blobentries, src.blobentries)
    merge!(dest.bloblets, src.bloblets)

    dest.solvable[] = src.solvable[]

    return dest
end

##------------------------------------------------------------------------------
## VariableSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Summary variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
@tags struct VariableSummary <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable event timestamp.
    $variable_timestamp_note
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol}
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Symbol for the state type for the underlying variable."""
    statekind::AbstractStateType
end

##------------------------------------------------------------------------------
## VariableSkeleton.jl
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct VariableSkeleton <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
end

function VariableSkeleton(label::Symbol, tags = Set{Symbol}();)
    return VariableSkeleton(label, tags)
end

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::VariableDFG{T}) where {T}
    return VariableSummary(v.label, v.timestamp, copy(v.tags), deepcopy(v.solvable), T())
end

function VariableSkeleton(v::AbstractGraphVariable)
    return VariableSkeleton(v.label, copy(v.tags))
end

##==============================================================================
## patch! for Summary/Skeleton types
##==============================================================================

function patch!(dest::VariableSummary, src::VariableSummary)
    dest === src && return dest
    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    dest.timestamp != src.timestamp && throw(
        MergeConflictError(
            "Variables has different timestamps: $(dest.timestamp) vs $(src.timestamp).",
        ),
    )
    dest.statekind !== src.statekind && throw(
        MergeConflictError(
            "Variables has different statekinds: $(dest.statekind) vs $(src.statekind).",
        ),
    )

    union!(dest.tags, src.tags)
    dest.solvable[] = src.solvable[]

    return dest
end

function patch!(dest::VariableSkeleton, src::VariableSkeleton)
    dest === src && return dest
    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    union!(dest.tags, src.tags)
    return dest
end
