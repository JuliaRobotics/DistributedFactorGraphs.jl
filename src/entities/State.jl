##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType

##==============================================================================
## StoredBelief
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

# TODO naming? Density, DensityRepresentation, StoredBelief, BeliefState, etc?
# TODO flatten in State? likeley not for easier serialization of points.
@kwdef struct StoredBelief{T <: StateType, P}
    statekind::T = T()# NOTE duplication for serialization, TODO maybe only in State and therefore belief cannot deserialize separately.
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

#FIXME remove old name before v0.29
const BeliefRepresentation = StoredBelief

JSON.omit_empty(::Type{<:StoredBelief}) = true

function StoredBelief(T::AbstractStateType)
    return StoredBelief{typeof(T), getPointType(T)}(; statekind = T)
end

function StoredBelief(::NonparametricDensityKind, T::AbstractStateType; kwargs...)
    return StoredBelief{typeof(T), getPointType(T)}(;
        statekind = T,
        densitykind = NonparametricDensityKind(),
        bandwidth = zeros(getDimension(T), getDimension(T)),
        kwargs...,
    )
end

function StoredBelief(::GaussianDensityKind, T::AbstractStateType; kwargs...)
    return StoredBelief{typeof(T), getPointType(T)}(;
        statekind = T,
        densitykind = GaussianDensityKind(),
        bandwidth = nothing,
        kwargs...,
    )
end

function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{StoredBelief{T, P}},
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

function resolveStoredBeliefType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return StoredBelief{typeof(statekind), getPointType(statekind)}
end

@choosetype StoredBelief resolveStoredBeliefType

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
    Generic stored belief for this state.
    """
    belief::StoredBelief{T, P} = StoredBelief{T, P}()#; statekind = T())
    """List of symbols for separator variables for this state, used in variable elimination and inference computations."""
    separator::Vector{Symbol} = Symbol[]
    """False if initial numerical values are not yet available or stored values are not ready for further processing yet."""
    initialized::Bool = false
    """Stores the amount of information captured in each coordinate dimension."""
    observability::Vector{Float64} = Float64[]#zeros(getDimension(T)) #TODO renamed from infoPerCoord in v0.29
    """Should this state be treated as marginalized in inference computations."""
    marginalized::Bool = false #TODO renamed from ismargin v0.29
    """How many times has a solver updated this state estimate."""
    solves::Int = 0 # TODO renamed from solvedCount v0.29

    #TODO belief container that can be used for active solver beliefs such as a HomotopyDensity
    # The type is defined by a trait saved in the StoredBelief and 
    # verbs such as `hydrate!(state)` `persist!(state)` can be used at data at checkpoints.
    # Forcing an explicit `persist!` acts as a state checkpoint, 
    #ensuring the graph only ever stores fully committed solver results rather than half-computed intermediate math.
    # abstract type AbstractActiveBelief end
    # active_belief::Base.RefValue{<:AbstractActiveBelief} = Ref{AbstractActiveBelief}() & (ignore = true,)
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
        belief = StoredBelief{T, P}(; statekind = T()),
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

"""
    @defStateType StructName manifold point_identity

A macro to create a new variable type with name `StructName` associated with a given manifold and identity point.

- `StructName` is the name of the new variable type, which will be defined as a subtype of `StateType`.
- `manifold` is an object that must be a subtype of `ManifoldsBase.AbstractManifold`.
- `point_identity` is the identity point on the manifold, used as a reference for operations.

This macro is useful for defining variable types that are not parameterized by dimension, and for associating them with a specific manifold and identity point.

See the [Manifolds.jl documentation on creating your own manifolds](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html) for more information.

Example:
```
DFG.@defStateType Pose2 SpecialEuclideanGroup(2) ArrayPartition([0;0.0],[1 0; 0 1.0])
```
"""
macro defStateType(structname, manifold, point_identity)
    return esc(
        quote
            Base.@__doc__ struct $structname <: StateType{Any} end

            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "defStateType of " *
                                                     string($structname) *
                                                     " requires that the " *
                                                     string($manifold) *
                                                     " be a subtype of `ManifoldsBase.AbstractManifold`"

            DFG.getManifold(::Type{$structname}) = $manifold

            DFG.getPointType(::Type{$structname}) = typeof($point_identity)

            DFG.getPointIdentity(::Type{$structname}) = $point_identity
        end,
    )
end

"""
    @defStateTypeN StructName manifold point_identity

A macro to create a new variable type with name `StructName` that is parameterized by `N` and associated with a given manifold and identity point.

- `StructName` is the name of the new variable type, which will be defined as a subtype of `StateType{N}`.
- `manifold` is an object that must be a subtype of `ManifoldsBase.AbstractManifold`.
- `point_identity` is the identity point on the manifold, used as a reference for operations.

This macro is useful for defining variable types that are parameterized by dimension or other type parameters (e.g., `Pose{N}`), and for associating them with a specific manifold and identity point.

See the [Manifolds.jl documentation on creating your own manifolds](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html) for more information.

Example:
```
DFG.@defStateTypeN Pose{N} SpecialEuclideanGroup(N) ArrayPartition(zeros(SVector{N, Float64}), SMatrix{N, N, Float64}(I))
```
"""
macro defStateTypeN(structname, manifold, point_identity)
    return esc(
        quote
            Base.@__doc__ struct $structname <: StateType{N} end

            DFG.getManifold(::Type{$structname}) where {N} = $manifold

            DFG.getPointType(::Type{$structname}) where {N} = typeof($point_identity)

            DFG.getPointIdentity(::Type{$structname}) where {N} = $point_identity
        end,
    )
end
