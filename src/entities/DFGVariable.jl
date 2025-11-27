##==============================================================================
## Abstract Types
##==============================================================================

abstract type AbstractStateType{N} end
const StateType = AbstractStateType

##==============================================================================
## State
##==============================================================================

"""
$(TYPEDEF)
Data container for solver-specific data.

  ---
T: Variable type, such as Position1, or RoME.Pose2, etc.
P: Variable point type, the type of the manifold point.
N: Manifold dimension.
Fields:
$(TYPEDFIELDS)
"""
@kwdef mutable struct State{T <: StateType, P, N}
    """
    Identifier associated with this State object.
    """
    label::Symbol # TODO renamed from solveKey
    """
    Vector of on-manifold points used to represent a ManifoldKernelDensity (or parametric) belief.
    """
    val::Vector{P} = Vector{P}()
    """
    Common kernel bandwith parameter used with ManifoldKernelDensity, see field `covar` for the parametric covariance.
    """
    bw::Matrix{Float64} = zeros(0, 0)
    "Parametric (Gaussian) covariance."
    covar::Vector{SMatrix{N, N, Float64}} =
        SMatrix{getDimension(T), getDimension(T), Float64}[]
    # BayesNetOutVertIDs::Vector{Symbol} = Symbol[] #TODO looks unused?

    # dims::Int = getDimension(T) #TODO should we deprecate in favor of N
    # """
    # Flag used by junction (Bayes) tree construction algorithm to know whether this variable has yet been included in the tree construction.
    # """
    # eliminated::Bool = false
    # BayesNetVertID::Symbol = :NOTHING #  Union{Nothing, } #TODO deprecate
    separator::Vector{Symbol} = Symbol[]
    """
    False if initial numerical values are not yet available or stored values are not ready for further processing yet.
    """
    initialized::Bool = false
    """
    Stores the amount information (per measurement dimension) captured in each coordinate dimension.
    """
    observability::Vector{Float64} = Float64[]#zeros(getDimension(T)) #TODO renamed from infoPerCoord
    """
    Should this state be treated as marginalized in inference computations.
    """
    marginalized::Bool = false #TODO renamed from ismargin 
    # """
    # Should this variable solveKey always be kept fluid and not be automatically marginalized.
    # """
    # dontmargin::Bool = false
    """
    How many times has a solver updated this state estimate.
    """
    solves::Int = 0 # TODO renamed from solvedCount
    # """
    # Future proofing field for when more multithreading operations on graph nodes are implemented, these conditions are meant to be used for atomic write transactions to this VND.
    # """
    # events::Dict{Symbol, Threads.Condition} = Dict{Symbol, Threads.Condition}()
    #
    statetype::Symbol = Symbol(stringVariableType(T()))
end

##------------------------------------------------------------------------------
## Constructors
function State{T}(; kwargs...) where {T <: StateType}
    return State{T, getPointType(T), getDimension(T)}(; kwargs...)
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

StructUtils.structlike(::Type{<:State}) = false
StructUtils.lower(state::State) = DFG.packState(state)
StructUtils.lift(::Type{<:State}, obj) = DFG.unpackState(obj)

##------------------------------------------------------------------------------
## States - OrderedDict{Symbol, State}
const States = OrderedDict{Symbol, State{T, P, N}} where {T <: AbstractStateType, P, N}

StructUtils.dictlike(::Type{<:States}) = false
StructUtils.structlike(::Type{<:States}) = false
StructUtils.arraylike(::Type{<:States}) = false

function StructUtils.lower(states::States)
    return map(collect(values(states))) do (state)
        return StructUtils.lower(state)
    end
end

function StructUtils.lift(
    ::StructUtils.StructStyle,
    S::Type{<:States{T}},
    json_vector::Vector,
) where {T}
    states = S()
    foreach(json_vector) do obj
        return push!(states, Symbol(obj.label) => StructUtils.make(State{T}, obj))
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

"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
@kwdef struct VariableDFG{T <: StateType, P, N} <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone = tdz_now() #NOTE changed to TimeDateZone in v0.29
    # """Nanoseconds since a user-understood epoch (i.e unix epoch, robot boot time, etc.)"""
    # steadytime::Union{Nothing, Nanosecond} = nothing #NOTE changed to TimeDateZone in v0.29
    #nstime::String = "0" #NOTE different uses, as 0-999_999 nanosecond part of timestamp now in timestamp, as steady timestamp now in steadytime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    """Dictionary of state data. May be a subset of all solutions if a solver label was specified in the get call.
    Accessors: [`addState!`](@ref), [`mergeState!`](@ref), and [`deleteState!`](@ref)"""
    states::OrderedDict{Symbol, State{T, P, N}} = OrderedDict{Symbol, State{T, P, N}}() #NOTE field renamed from solverDataDict in v0.29
    """Dictionary of small data associated with this variable.
    Accessors: [`getBloblet`](@ref), [`setBloblet!`](@ref)"""
    bloblets::Bloblets = Bloblets() #NOTE changed from smallData in v0.29
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    blobentries::Blobentries = Blobentries() #NOTE renamed from dataDict in v0.29
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref{Int}(1) #& (lower = getindex,)
    statetype::Symbol = Symbol(stringVariableType(T()))
    # TODO autotype or version and statetype
    _autotype::Nothing = nothing #& (name = :type, lower = _ -> TypeMetadata(VariableDFG))
end
version(::Type{<:VariableDFG}) = v"0.29"
refStates(v::VariableDFG) = v.states

#NOTE fielddefaults and fieldtags not through @kwarg macro due to error with State{T, P, N}
function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{VariableDFG{T, P, N}},
) where {T, P, N}
    return (
        timestamp = tdz_now(),
        tags = Set{Symbol}(),
        # states = OrderedDict{Symbol, State{T, P, N}}(),
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

function resolveVariableType(lazyobj)
    T = parseVariableType(lazyobj.statetype[])
    return VariableDFG{T, getPointType(T), getDimension(T)}
end

@choosetype VariableDFG resolveVariableType

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
    statetype::Union{T, Type{T}};
    tags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    timestamp::Union{TimeDateZone, ZonedDateTime} = tdz_now(),
    solvable::Union{Int, Base.RefValue{Int}} = Ref{Int}(1),
    # steadytime::Union{Nothing, Nanosecond} = nothing,
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

    N = getDimension(T)
    P = getPointType(T)
    return VariableDFG{T, P, N}(; label, solvable, tags, timestamp, kwargs...)
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
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol}
    """Symbol for the state type for the underlying variable."""
    statetype::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    blobentries::Blobentries
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
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
end

function VariableSkeleton(label::Symbol, tags = Set{Symbol}();)
    return VariableSkeleton(label, tags)
end

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::VariableCompute{T}) where {T}
    return VariableSummary(
        v.label,
        v.timestamp,
        copy(v.tags),
        Symbol(stringVariableType(T())),
        copy(v.blobentries),
    )
end

function VariableSkeleton(v::AbstractGraphVariable)
    return VariableSkeleton(v.label, copy(v.tags))
end
