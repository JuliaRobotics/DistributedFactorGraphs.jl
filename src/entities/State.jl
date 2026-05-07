
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
    belief::HomotopyDensityDFG{T, P} = HomotopyDensityDFG{T, P}()#; statekind = T())
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

# ==============================================================================
#  FUTURE VIEW WRAPPER (Internal DFG Placeholder)
# ==============================================================================
# NOTE: The `HomotopyDensityDFG` is currently expressive and fast enough that 
# DFG does not need to store a resolved view next to it in memory. 
#
# If future profiling requires it, DFG will introduce a verbose View wrapper 
# to hold the raw data alongside the instantiated read-only math object.
#
# abstract type AbstractHomotopyBeliefView end
# 
# struct HomotopyBeliefView{T, P, M} <: AbstractHomotopyBeliefView
#     stored::HomotopyDensityDFG{T, P}
#     math_engine::M # Read-only instantiated solver object (e.g., AMP.HomotopyDensity)
# end

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
        belief = HomotopyDensityDFG{T, P}(; statekind = T()),
        separator = Symbol[],
        initialized = false,
        observability = Float64[],
        marginalized = false,
        solves = 0,
        statekind = T(),
    )
end


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
