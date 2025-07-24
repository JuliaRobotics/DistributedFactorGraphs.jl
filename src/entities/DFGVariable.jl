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
    """
    Globally unique identifier.
    """
    id::Union{UUID, Nothing} = nothing # If it's blank it doesn't exist in the DB.
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
    BayesNetOutVertIDs::Vector{Symbol} = Symbol[]
    dimIDs::Vector{Int} = Int[] # TODO Likely deprecate

    dims::Int = getDimension(T) #TODO should we deprecate in favor of N
    """
    Flag used by junction (Bayes) tree construction algorithm to know whether this variable has yet been included in the tree construction.
    """
    eliminated::Bool = false
    BayesNetVertID::Symbol = :NOTHING #  Union{Nothing, }
    separator::Vector{Symbol} = Symbol[]
    """
    False if initial numerical values are not yet available or stored values are not ready for further processing yet.
    """
    initialized::Bool = false
    """
    Stores the amount information (per measurement dimension) captured in each coordinate dimension.
    """
    infoPerCoord::Vector{Float64} = zeros(getDimension(T))
    """
    Should this variable solveKey be treated as marginalized in inference computations.
    """
    ismargin::Bool = false
    """
    Should this variable solveKey always be kept fluid and not be automatically marginalized.
    """
    dontmargin::Bool = false
    """
    Convenience flag on whether a solver is currently busy working on this variable solveKey.
    """
    solveInProgress::Int = 0
    """
    How many times has a solver updated this variable solveKey estimte.
    """
    solvedCount::Int = 0
    """
    solveKey identifier associated with this State object.
    """
    solveKey::Symbol = :default
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
    id::Union{UUID, Nothing} # If it's blank it doesn't exist in the DB.
    vecval::Vector{Float64}
    dimval::Int
    vecbw::Vector{Float64}
    dimbw::Int
    BayesNetOutVertIDs::Vector{Symbol} # Int
    dimIDs::Vector{Int}
    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol # Int
    separator::Vector{Symbol} # Int
    variableType::String
    initialized::Bool
    infoPerCoord::Vector{Float64}
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    solveKey::Symbol
    covar::Vector{Float64}
    _version::VersionNumber = _getDFGVersion()
end

#FIXME remove once solveKey field is renamed to `label`
getLabel(packedstate::PackedState) = packedstate.solveKey

# maybe add
# createdTimestamp::DateTime#!
# lastUpdatedTimestamp::DateTime#!

StructTypes.StructType(::Type{PackedState}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{PackedState}) = :id
StructTypes.omitempties(::Type{PackedState}) = (:id,)

##==============================================================================
## PointParametricEst
##==============================================================================

##------------------------------------------------------------------------------
## AbstractPointParametricEst interface
##------------------------------------------------------------------------------

abstract type AbstractPointParametricEst end

##------------------------------------------------------------------------------
## MeanMaxPPE
##------------------------------------------------------------------------------
"""
    $TYPEDEF

Data container to store Parameteric Point Estimate (PPE) for mean and max.
"""
Base.@kwdef struct MeanMaxPPE <: AbstractPointParametricEst
    id::Union{UUID, Nothing} = nothing # If it's blank it doesn't exist in the DB.
    # repeat key value internally (from a design request by Sam)
    solveKey::Symbol
    suggested::Vector{Float64}
    max::Vector{Float64}
    mean::Vector{Float64}
    _type::String = "MeanMaxPPE"
    _version::VersionNumber = _getDFGVersion()
    createdTimestamp::Union{ZonedDateTime, Nothing} = nothing
    lastUpdatedTimestamp::Union{ZonedDateTime, Nothing} = nothing
end

StructTypes.StructType(::Type{MeanMaxPPE}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{MeanMaxPPE}) = :id
function StructTypes.omitempties(::Type{MeanMaxPPE})
    return (:id, :createdTimestamp, :lastUpdatedTimestamp)
end

##------------------------------------------------------------------------------
## Constructors

function MeanMaxPPE(
    solveKey::Symbol,
    suggested::Vector{Float64},
    max::Vector{Float64},
    mean::Vector{Float64},
)
    return MeanMaxPPE(
        nothing,
        solveKey,
        suggested,
        max,
        mean,
        "MeanMaxPPE",
        _getDFGVersion(),
        now(tz"UTC"),
        now(tz"UTC"),
    )
end

## Metadata
"""
    $SIGNATURES
Return the fields of MeanMaxPPE that are estimates.
NOTE: This is needed for each AbstractPointParametricEst.
Closest we can get to a decorator pattern.
"""
getEstimateFields(::MeanMaxPPE) = [:suggested, :max, :mean]

##==============================================================================
## DFG Variables
##==============================================================================

"""
    $(TYPEDEF)

The Variable information packed in a way that accomdates multi-lang using json.

Notes:
- timestamp is a `ZonedDateTime` in UTC.
- nstime can be used as mission time, with the convention that the timestamp millis coincide with the mission start nstime
  - e.g. timestamp is `2020-01-01 06:30:01.250 UTC` and first nstime is `250_000_000`.
"""
Base.@kwdef struct VariableDFG <: AbstractGraphVariable
    id::Union{UUID, Nothing} = nothing
    label::Symbol
    tags::Vector{Symbol} = Symbol[]
    timestamp::ZonedDateTime = now(tz"UTC")
    nstime::String = "0"
    ppes::Vector{MeanMaxPPE} = MeanMaxPPE[]
    blobEntries::Vector{Blobentry} = Blobentry[]
    variableType::String
    _version::VersionNumber = _getDFGVersion()
    metadata::String = "e30="
    solvable::Int = 1
    solverData::Vector{PackedState} = PackedState[]
end
# maybe add to variable
# createdTimestamp::DateTime
# lastUpdatedTimestamp::DateTime

#IIF like contruction helper for packed variable
function VariableDFG(
    label::Symbol,
    variableType::String;
    tags::Vector{Symbol} = Symbol[],
    timestamp::ZonedDateTime = now(tz"UTC"),
    solvable::Int = 1,
    nanosecondtime::Int64 = 0,
    smalldata::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
    kwargs...,
)
    union!(tags, [:VARIABLE])

    pacvar = VariableDFG(;
        label,
        variableType,
        nstime = string(nanosecondtime),
        solvable,
        tags,
        metadata = base64encode(JSON3.write(smalldata)),
        timestamp,
        kwargs...,
    )

    return pacvar
end

StructTypes.StructType(::Type{VariableDFG}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{VariableDFG}) = :id
StructTypes.omitempties(::Type{VariableDFG}) = (:id,)

function getMetadata(v::VariableDFG)
    return JSON3.read(base64decode(v.metadata), Dict{Symbol, SmallDataTypes})
end

function setMetadata!(v::VariableDFG, metadata::Dict{Symbol, SmallDataTypes})
    return error("FIXME: Metadata is not currently mutable in a Variable")
    # v.metadata = base64encode(JSON3.write(metadata))
end

##------------------------------------------------------------------------------
## VariableCompute lv2
##------------------------------------------------------------------------------
"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct VariableCompute{T <: StateType, P, N} <: AbstractGraphVariable
    """The ID for the variable"""
    id::Union{UUID, Nothing} = nothing
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime = now(localzone())
    """Nanoseconds since a user-understood epoch (i.e unix epoch, robot boot time, etc.)"""
    nstime::Nanosecond = Nanosecond(0)
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    ppeDict::Dict{Symbol, AbstractPointParametricEst} =
        Dict{Symbol, AbstractPointParametricEst}()
    """Dictionary of solver data. May be a subset of all solutions if a solver label was specified in the get call.
    Accessors: [`addState!`](@ref), [`mergeState!`](@ref), and [`deleteState!`](@ref)"""
    solverDataDict::Dict{Symbol, State{T, P, N}} = Dict{Symbol, State{T, P, N}}()
    """Dictionary of small data associated with this variable.
    Accessors: [`getMetadata`](@ref), [`setMetadata!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    dataDict::Dict{Symbol, Blobentry} = Dict{Symbol, Blobentry}()
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref(1)
end

##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default VariableCompute constructor.
"""
function VariableCompute(
    label::Symbol,
    T::Type{<:StateType};
    timestamp::ZonedDateTime = now(localzone()),
    solvable::Union{Int, Base.RefValue{Int}} = Ref(1),
    kwargs...,
)
    solvable isa Int && (solvable = Ref(solvable))

    N = getDimension(T)
    P = getPointType(T)
    return VariableCompute{T, P, N}(; label, timestamp, solvable, kwargs...)
end

function VariableCompute(label::Symbol, variableType::StateType; kwargs...)
    return VariableCompute(label, typeof(variableType); kwargs...)
end

function VariableCompute(label::Symbol, solverData::State; kwargs...)
    return VariableCompute(;
        label,
        solverDataDict = Dict(:default => solverData),
        kwargs...,
    )
end

Base.getproperty(x::VariableCompute, f::Symbol) = begin
    if f == :solvable
        getfield(x, f)[]
    else
        getfield(x, f)
    end
end

Base.setproperty!(x::VariableCompute, f::Symbol, val) = begin
    if f == :solvable
        getfield(x, f)[] = val
    else
        setfield!(x, f, val)
    end
end

getMetadata(v::VariableCompute) = v.smallData

function setMetadata!(v::VariableCompute, metadata::Dict{Symbol, SmallDataTypes})
    v.smallData !== metadata && empty!(v.smallData)
    return merge!(v.smallData, metadata)
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
Base.@kwdef struct VariableSummary <: AbstractGraphVariable
    """The ID for the variable"""
    id::Union{UUID, Nothing}
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    ppeDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the variableType for the underlying variable.
    Accessor: [`getVariableType`](@ref)"""
    variableTypeName::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    dataDict::Dict{Symbol, Blobentry}
end

function VariableSummary(id, label, timestamp, tags, ::Nothing, variableTypeName, ::Nothing)
    return VariableSummary(
        id,
        label,
        timestamp,
        tags,
        Dict{Symbol, MeanMaxPPE}(),
        variableTypeName,
        Dict{Symbol, Blobentry}(),
    )
end

StructTypes.names(::Type{VariableSummary}) = ((:variableTypeName, :variableType),)

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
    """The ID for the variable"""
    id::Union{UUID, Nothing} = nothing
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
    id::Union{UUID, Nothing} = nothing,
)
    return VariableSkeleton(id, label, tags)
end

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::VariableCompute)
    return VariableSummary(
        v.id,
        v.label,
        v.timestamp,
        copy(v.tags),
        deepcopy(v.ppeDict),
        Symbol(typeof(getVariableType(v))),
        v.dataDict,
    )
end

function VariableSkeleton(v::AbstractGraphVariable)
    return VariableSkeleton(v.id, v.label, copy(v.tags))
end
