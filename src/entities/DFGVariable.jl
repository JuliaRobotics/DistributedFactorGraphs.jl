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
Base.@kwdef mutable struct State{T <: StateType, P, N}
    label::Symbol
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

    dims::Int = getDimension(T) #TODO should we deprecate in favor of N
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
    observability::Vector{Float64} = zeros(getDimension(T)) #TODO renamed from infoPerCoord
    """
    Should this variable solveKey be treated as marginalized in inference computations.
    """
    marginalized::Bool = false #TODO renamed from ismargin 
    """
    Should this variable solveKey always be kept fluid and not be automatically marginalized.
    """
    dontmargin::Bool = false
    """
    How many times has a solver updated this variable solveKey estimte.
    """
    solves::Int = 0 # TODO renamed from solvedCount
    """
    solveKey identifier associated with this State object.
    """
    solveKey::Symbol = :default # TODO replaced by label
    """
    Future proofing field for when more multithreading operations on graph nodes are implemented, these conditions are meant to be used for atomic write transactions to this VND.
    """
    events::Dict{Symbol, Threads.Condition} = Dict{Symbol, Threads.Condition}()
    #
end

##------------------------------------------------------------------------------
## Constructors
function State{T}(; kwargs...) where {T <: StateType}
    return State{T, getPointType(T), getDimension(T)}(; kwargs...)
end
function State(variableType::StateType; kwargs...)
    return State{typeof(variableType)}(; kwargs...)
end

function State(state::State; kwargs...)
    return State{typeof(getVariableType(state))}(;
        (key => deepcopy(getproperty(state, key)) for key in fieldnames(State))...,
        kwargs...,
    )
end
##==============================================================================
## PackedState.jl
##==============================================================================

"""
$(TYPEDEF)
Packed State structure for serializing DFGVariables.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef mutable struct PackedState
    label::Symbol
    vecval::Vector{Float64}
    dimval::Int
    vecbw::Vector{Float64}
    dimbw::Int
    # BayesNetOutVertIDs::Vector{Symbol} # Int
    dims::Int
    # eliminated::Bool # TODO Questionable usage, set but never read?
    # BayesNetVertID::Symbol # Int #TODO deprecate
    separator::Vector{Symbol} # Int #TODO maybe remove from State and have in variable only.
    variableType::String
    initialized::Bool
    observability::Vector{Float64} # TODO renamed from infoPerCoord
    marginalized::Bool # TODO renamed from ismargin 
    dontmargin::Bool
    solves::Int # TODO renamed from solvedCount
    solveKey::Symbol #TODO replaced by label
    covar::Vector{Float64}
    _version::VersionNumber = _getDFGVersion()
end

#FIXME remove once solveKey field is renamed to `label`
getLabel(packedstate::PackedState) = packedstate.solveKey

# maybe add
# createdTimestamp::DateTime#!
# lastUpdatedTimestamp::DateTime#!


##==============================================================================
## DFG Variables
##==============================================================================

##------------------------------------------------------------------------------
## VariableCompute
##------------------------------------------------------------------------------
# The Variable information packed in a way that accomdates multi-lang using json.

# Notes:
# - timestamp is a `ZonedDateTime` in UTC.
# - nstime can be used as mission time, with the convention that the timestamp millis coincide with the mission start nstime
#   - e.g. timestamp is `2020-01-01 06:30:01.250 UTC` and first nstime is `250_000_000`.

"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
StructUtils.@kwarg struct VariableDFG{T <: StateType, P, N} <: AbstractGraphVariable
    # """The ID for the variable"""
    # id::Union{UUID, Nothing} = nothing #NOTE removed in v0.29
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::NanoDate = ndnow(UTC) #NOTE changed to NanoDate in v0.29
    """Nanoseconds since a user-understood epoch (i.e unix epoch, robot boot time, etc.)"""
    steadytime::Union{Nothing, Nanosecond} = nothing #NOTE changed to NanoDate in v0.29
    #nstime::String = "0" #NOTE different uses, as 0-999_999 nanosecond part of timestamp now in timestamp, as steady timestamp now in steadytime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    # """Dictionary of parametric point estimates keyed by solverDataDict keys
    # Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    # ppeDict::Dict{Symbol, AbstractPointParametricEst} = 
    #     Dict{Symbol, AbstractPointParametricEst}() #NOTE removed in v0.29
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
    solvable::Base.RefValue{Int} = Ref(1)
    # TODO autotype or version and statetype
    _autotype::Nothing = nothing & (name = :type, lower = _ -> TypeMetadata(VariableDFG))
end

refStates(v::VariableDFG) = v.states

const VariableCompute = VariableDFG
##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default VariableCompute constructor.
"""
function VariableCompute(
    label::Symbol,
    T::Type{<:StateType};
    timestamp::Union{NanoDate, ZonedDateTime} = ndnow(UTC),
    solvable::Union{Int, Base.RefValue{Int}} = Ref(1),
    kwargs...,
)
    if timestamp isa ZonedDateTime
        # TODO @warn
        timestamp = NanoDate(timestamp)
    end
    solvable isa Int && (solvable = Ref(solvable))

    N = getDimension(T)
    P = getPointType(T)
    return VariableCompute{T, P, N}(; label, timestamp, solvable, kwargs...)
end

function VariableCompute(label::Symbol, state::State; kwargs...)
    return VariableCompute(;
        label,
        states = OrderedDict(state.label => state),
        kwargs...,
    )
end

#IIF like contruction helper for VariableDFG
function VariableDFG(
    label::Symbol,
    stateType::StateType;
    tags::Vector{Symbol} = Symbol[],
    timestamp::Union{NanoDate, ZonedDateTime} = ndnow(UTC),
    solvable::Union{Int, Base.RefValue{Int}} = Ref(1),
    nanosecondtime = nothing,
    smalldata = nothing,
    kwargs...,
)
    if timestamp isa ZonedDateTime
        # TODO @warn
        timestamp = NanoDate(timestamp)
    end
    if !isnothing(nanosecondtime)
        Base.depwarn("nanosecondtime kwarg is deprecated, use steadytime instead", :VariableDFG)
        steadytime = Nanosecond(nanosecondtime)
    end
    if !isnothing(smalldata)
        Base.depwarn("smalldata kwarg is deprecated, use bloblets instead", :VariableDFG)
        #TODO convert smalldata to bloblets
    end
    union!(tags, [:VARIABLE])

    return VariableDFG(
        label,
        stateType;
        steadytime,
        solvable,
        tags,
        timestamp,
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
    timestamp::NanoDate
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Symbol for the variableType for the underlying variable.
    Accessor: [`getVariableType`](@ref)"""
    variableTypeName::Symbol & (json = (name = "variableType",)) # TODO check from StructTypes.names(::Type{VariableSummary}) = ((:variableTypeName, :variableType),)
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
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
end

function VariableSkeleton(
    label::Symbol,
    tags = Set{Symbol}();
)
    return VariableSkeleton(label, tags)
end

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::VariableCompute)
    return VariableSummary(
        v.label,
        v.timestamp,
        copy(v.tags),
        Symbol(typeof(getVariableType(v))),
        copy(v.blobentries),
    )
end

function VariableSkeleton(v::AbstractGraphVariable)
    return VariableSkeleton(v.label, copy(v.tags))
end
