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
Base.@kwdef mutable struct VariableNodeData{T<:InferenceVariable, P, N}
    "DEPRECATED remove in DFG v0.21"
    variableType::T=T() #tricky deprecation, also change covar to using N and not variableType
    """
    Globally unique identifier.
    """
    id::Union{UUID, Nothing} = nothing # If it's blank it doesn't exist in the DB.
    """
    Vector of on-manifold points used to represent a ManifoldKernelDensity (or parametric) belief.
    """
    val::Vector{P} = Vector{P}()
    """
    Common kernel bandwith parameter used with ManifoldKernelDensity, and as legacy also stores covariance until a dedicated field is created for parametric case.
    """
    bw::Matrix{Float64} = zeros(0,0)
    "Parametric (Gaussian) covariance."
    covar::Vector{SMatrix{N, N, Float64}} = SMatrix{getDimension(variableType), getDimension(variableType), Float64}[]
    BayesNetOutVertIDs::Vector{Symbol} = Symbol[]
    dimIDs::Vector{Int} = Int[] # TODO Likely deprecate

    dims::Int = 0
    """
    Flag used by junction (Bayes) tree construction algorith to know whether this variable has yet been included in the tree construction.
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
    infoPerCoord::Vector{Float64} = Float64[0.0;]
    """
    Should this variable solveKey be treated as marginalized in inference computations.
    """
    ismargin::Bool = false
    """
    Shoudl this variable solveKey always be kept fluid and not be automatically marginalized.
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
    solveKey identifier associated with thsi VariableNodeData object.
    """
    solveKey::Symbol = :default
    """
    Future proofing field for when more multithreading operations on graph nodes are implemented, these conditions are meant to be used for atomic write transactions to this VND.
    """
    events::Dict{Symbol,Threads.Condition} = Dict{Symbol,Threads.Condition}()
    #
end


##------------------------------------------------------------------------------
## Constructors
VariableNodeData{T}(; kwargs...) where T <: InferenceVariable = VariableNodeData{T,getPointType(T),getDimension(T)}(; kwargs...)
VariableNodeData(variableType::InferenceVariable; kwargs...) = VariableNodeData{typeof(variableType)}(;kwargs...)


##==============================================================================
## PackedVariableNodeData.jl
##==============================================================================

"""
$(TYPEDEF)
Packed VariabeNodeData structure for serializing DFGVariables.

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
    covar::Vector{Vector{Float64}}
    _version::String = string(_getDFGVersion())
end

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
StructTypes.omitempties(::Type{MeanMaxPPE}) = (:id,:createdTimestamp,:lastUpdatedTimestamp)

##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solveKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64}, mean::Vector{Float64}) = MeanMaxPPE(nothing, solveKey, suggested, max, mean, "MeanMaxPPE", string(_getDFGVersion()), now(tz"UTC"), now(tz"UTC"))

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

# Packed Variable
Base.@kwdef struct PackedVariable
    # NOTE: This has to match the order of the JSON deserializer as we're using OrderedStructs.
    id::Union{UUID, Nothing}
    label::Symbol
    tags::Vector{Symbol}
    timestamp::ZonedDateTime
    nstime::Int
    ppes::Vector{MeanMaxPPE}
    blobEntries::Vector{BlobEntry}
    variableType::String
    _version::String
    metadata::String
    solvable::Int
    solverData::Vector{PackedVariableNodeData}
end

StructTypes.StructType(::Type{PackedVariable}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{PackedVariable}) = :id
StructTypes.omitempties(::Type{PackedVariable}) = (:id,)

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
Base.@kwdef struct DFGVariable{T<:InferenceVariable, P, N} <: AbstractDFGVariable
    """The ID for the variable"""
    id::Union{UUID, Nothing} = nothing
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime = now(localzone())
    """Nano second time, for more resolution on timestamp (only subsecond information)"""
    nstime::Nanosecond = Nanosecond(0) 
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    ppeDict::Dict{Symbol, AbstractPointParametricEst} = Dict{Symbol, AbstractPointParametricEst}()
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: [`addVariableSolverData!`](@ref), [`updateVariableSolverData!`](@ref), and [`deleteVariableSolverData!`](@ref)"""
    solverDataDict::Dict{Symbol, VariableNodeData{T,P,N}} = Dict{Symbol, VariableNodeData{T,P,N}}()
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData`](@ref), [`setSmallData!`](@ref)"""
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
    estimateDict=nothing,
    timestamp=now(localzone()),
    solvable::Union{Int, Base.RefValue{Int}}=Ref(1),
    kwargs...
)
    #TODO deprecated, remove in v0.21 should have already been deprecated
    if !isnothing(estimateDict)
        error("Keyword argument `estimateDict` is deprecated use `ppeDict`")
    end
    if !isa(timestamp, ZonedDateTime)
        @warn "timestamp<:DateTime is deprecated, timestamp must be a ZonedDateTime, using local zone."
        timestamp = ZonedDateTime(timestamp,localzone())
    end

    solvable isa Int && (solvable = Ref(solvable))

    N = getDimension(T)
    P = getPointType(T)
    DFGVariable{T,P,N}(;label, timestamp, solvable, kwargs...)
end

DFGVariable(label::Symbol, variableType::InferenceVariable; kwargs...) = DFGVariable(label, typeof(variableType); kwargs...)

DFGVariable(label::Symbol, solverData::VariableNodeData; kwargs...) = DFGVariable(;label, solverDataDict=Dict(:default=>solverData), kwargs...)

Base.getproperty(x::DFGVariable,f::Symbol) = begin
    if f == :solvable
        getfield(x,f)[]
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
    if f == :solvable
        getfield(x,f)[] = val
    else
        setfield!(x,f,val)
    end
end


##------------------------------------------------------------------------------
## DFGVariableSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Summary variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct DFGVariableSummary <: AbstractDFGVariable
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
    Accessors: [`addDataEntry!`](@ref), [`getBlobEntry`](@ref), [`updateDataEntry!`](@ref), and [`deleteDataEntry!`](@ref)"""
    dataDict::Dict{Symbol, BlobEntry}
end


##------------------------------------------------------------------------------
## SkeletonDFGVariable.jl
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct SkeletonDFGVariable <: AbstractDFGVariable
    """The ID for the variable"""
    id::Union{UUID, Nothing} = nothing
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
end

SkeletonDFGVariable(label::Symbol, tags=Set{Symbol}(); id::Union{UUID, Nothing}=nothing) = SkeletonDFGVariable(id, label, tags)

StructTypes.StructType(::Type{SkeletonDFGVariable}) = StructTypes.UnorderedStruct()
StructTypes.idproperty(::Type{SkeletonDFGVariable}) = :id
StructTypes.omitempties(::Type{SkeletonDFGVariable}) = (:id,)

##==============================================================================
# Define variable levels
##==============================================================================
const VariableDataLevel0 = Union{DFGVariable, DFGVariableSummary, SkeletonDFGVariable}
const VariableDataLevel1 = Union{DFGVariable, DFGVariableSummary}
const VariableDataLevel2 = Union{DFGVariable}

##==============================================================================
## Convertion constructors
##==============================================================================

DFGVariableSummary(v::DFGVariable) =
        DFGVariableSummary(v.id, v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getVariableType(v))), v.dataDict)

SkeletonDFGVariable(v::VariableDataLevel1) =
            SkeletonDFGVariable(v.id, v.label, deepcopy(v.tags))
