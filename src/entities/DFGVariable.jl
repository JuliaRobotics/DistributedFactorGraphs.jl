##==============================================================================
## Abstract Types
##==============================================================================

abstract type InferenceVariable end

##==============================================================================
## VariableNodeData
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
Base.@kwdef mutable struct VariableNodeData{T <: InferenceVariable, P, N}
    "DEPRECATED remove in DFG v0.22"
    variableType::T = T() #tricky deprecation, also change covar to using N and not variableType
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
        SMatrix{getDimension(variableType), getDimension(variableType), Float64}[]
    BayesNetOutVertIDs::Vector{Symbol} = Symbol[]
    dimIDs::Vector{Int} = Int[] # TODO Likely deprecate

    dims::Int = getDimension(variableType) #TODO should we deprecate in favor of N
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
    infoPerCoord::Vector{Float64} = zeros(getDimension(variableType))
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
    solveKey identifier associated with this VariableNodeData object.
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
function VariableNodeData{T}(; kwargs...) where {T <: InferenceVariable}
    return VariableNodeData{T, getPointType(T), getDimension(T)}(; kwargs...)
end
function VariableNodeData(variableType::InferenceVariable; kwargs...)
    return VariableNodeData{typeof(variableType)}(; kwargs...)
end

##==============================================================================
## PackedVariableNodeData.jl
##==============================================================================

"""
$(TYPEDEF)
Packed VariableNodeData structure for serializing DFGVariables.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef mutable struct PackedVariableNodeData
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
    _version::String = string(_getDFGVersion())
end
# maybe add
# createdTimestamp::DateTime#!
# lastUpdatedTimestamp::DateTime#!

StructTypes.StructType(::Type{PackedVariableNodeData}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{PackedVariableNodeData}) = :id
StructTypes.omitempties(::Type{PackedVariableNodeData}) = (:id,)

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
    _version::String = string(_getDFGVersion())
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
        string(_getDFGVersion()),
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

export Variable

"""
    $(TYPEDEF)

The Variable information packed in a way that accomdates multi-lang using json.
"""
Base.@kwdef struct Variable <: AbstractDFGVariable
    id::Union{UUID, Nothing} = nothing
    label::Symbol
    tags::Vector{Symbol} = Symbol[]
    timestamp::ZonedDateTime = now(tz"UTC")
    nstime::String = "0"
    ppes::Vector{MeanMaxPPE} = MeanMaxPPE[]
    blobEntries::Vector{BlobEntry} = BlobEntry[]
    variableType::String
    _version::String = string(_getDFGVersion())
    metadata::String = "e30="
    solvable::Int = 1
    solverData::Vector{PackedVariableNodeData} = PackedVariableNodeData[]
end
# maybe add to variable
# createdTimestamp::DateTime
# lastUpdatedTimestamp::DateTime

#IIF like contruction helper for packed variable
function Variable(
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

    pacvar = Variable(;
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
const PackedVariable = Variable

StructTypes.StructType(::Type{Variable}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{Variable}) = :id
StructTypes.omitempties(::Type{Variable}) = (:id,)

function getMetadata(v::Variable)
    return JSON3.read(base64decode(v.metadata), Dict{Symbol, SmallDataTypes})
end

function setMetadata!(v::Variable, metadata::Dict{Symbol, SmallDataTypes})
    return error("FIXME: Metadata is not currently mutable in a Variable")
    # v.metadata = base64encode(JSON3.write(metadata))
end

##------------------------------------------------------------------------------
## DFGVariable lv2
##------------------------------------------------------------------------------
"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct DFGVariable{T <: InferenceVariable, P, N} <: AbstractDFGVariable
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
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: [`addVariableSolverData!`](@ref), [`updateVariableSolverData!`](@ref), and [`deleteVariableSolverData!`](@ref)"""
    solverDataDict::Dict{Symbol, VariableNodeData{T, P, N}} =
        Dict{Symbol, VariableNodeData{T, P, N}}()
    """Dictionary of small data associated with this variable.
    Accessors: [`getMetadata`](@ref), [`setMetadata!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobEntry!`](@ref), [`getBlobEntry`](@ref), [`updateBlobEntry!`](@ref), and [`deleteBlobEntry!`](@ref)"""
    dataDict::Dict{Symbol, BlobEntry} = Dict{Symbol, BlobEntry}()
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref(1)
end

##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
function DFGVariable(
    label::Symbol,
    T::Type{<:InferenceVariable};
    timestamp::ZonedDateTime = now(localzone()),
    solvable::Union{Int, Base.RefValue{Int}} = Ref(1),
    kwargs...,
)
    solvable isa Int && (solvable = Ref(solvable))

    N = getDimension(T)
    P = getPointType(T)
    return DFGVariable{T, P, N}(; label, timestamp, solvable, kwargs...)
end

function DFGVariable(label::Symbol, variableType::InferenceVariable; kwargs...)
    return DFGVariable(label, typeof(variableType); kwargs...)
end

function DFGVariable(label::Symbol, solverData::VariableNodeData; kwargs...)
    return DFGVariable(; label, solverDataDict = Dict(:default => solverData), kwargs...)
end

Base.getproperty(x::DFGVariable, f::Symbol) = begin
    if f == :solvable
        getfield(x, f)[]
    else
        getfield(x, f)
    end
end

Base.setproperty!(x::DFGVariable, f::Symbol, val) = begin
    if f == :solvable
        getfield(x, f)[] = val
    else
        setfield!(x, f, val)
    end
end

getMetadata(v::DFGVariable) = v.smallData

function setMetadata!(v::DFGVariable, metadata::Dict{Symbol, SmallDataTypes})
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
Base.@kwdef struct VariableSummary <: AbstractDFGVariable
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
    Accessors: [`addBlobEntry!`](@ref), [`getBlobEntry`](@ref), [`updateBlobEntry!`](@ref), and [`deleteBlobEntry!`](@ref)"""
    dataDict::Dict{Symbol, BlobEntry}
end

function VariableSummary(
    id,
    label,
    timestamp,
    tags,
    ::Nothing,
    variableTypeName,
    ::Nothing,
)
    return VariableSummary(
        id,
        label,
        timestamp,
        tags,
        Dict{Symbol, MeanMaxPPE}(),
        variableTypeName,
        Dict{Symbol, BlobEntry}(),
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
Base.@kwdef struct VariableSkeleton <: AbstractDFGVariable
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

StructTypes.StructType(::Type{VariableSkeleton}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{VariableSkeleton}) = :id
StructTypes.omitempties(::Type{VariableSkeleton}) = (:id,)

##==============================================================================
# Define variable levels
##==============================================================================
const VariableDataLevel0 =
    Union{DFGVariable, VariableSummary, Variable, VariableSkeleton}
const VariableDataLevel1 = Union{DFGVariable, VariableSummary, Variable}
const VariableDataLevel2 = Union{DFGVariable}

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::DFGVariable)
    return VariableSummary(
        v.id,
        v.label,
        v.timestamp,
        deepcopy(v.tags),
        deepcopy(v.ppeDict),
        Symbol(typeof(getVariableType(v))),
        v.dataDict,
    )
end

function VariableSkeleton(v::VariableDataLevel1)
    return VariableSkeleton(v.id, v.label, deepcopy(v.tags))
end
