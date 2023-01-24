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
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef mutable struct VariableNodeData{T<:InferenceVariable, P}
    id::Union{UUID, Nothing} # If it's blank it doesn't exist in the DB.
    val::Vector{P}
    bw::Matrix{Float64}
    BayesNetOutVertIDs::Vector{Symbol}
    dimIDs::Vector{Int} # Likely deprecate

    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol #  Union{Nothing, }
    separator::Vector{Symbol}

    variableType::T
    initialized::Bool
    """
    Replacing previous `inferdim::Float64`, new `.infoPerCoord::Vector{Float64}` will in 
    future stores the amount information (per measurement dimension) captured in each 
    coordinate dimension.
    """
    infoPerCoord::Vector{Float64}
    ismargin::Bool

    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    solveKey::Symbol

    events::Dict{Symbol,Threads.Condition}

    VariableNodeData{T,P}(w...)  where {T <:InferenceVariable, P} = new{T,P}(w...)
    VariableNodeData{T,P}(;solveKey::Symbol=:default ) where {T <:InferenceVariable, P} = new{T,P}(
            nothing,
            Vector{P}(), 
            zeros(0,0), 
            Symbol[], 
            Int[], 
            0, 
            false, 
            :NOTHING, 
            Symbol[], 
            T(), 
            false, 
            Float64[0.0;], 
            false, 
            false, 
            0, 
            0, 
            solveKey, 
            Dict{Symbol,Threads.Condition}() )
    #
end

##------------------------------------------------------------------------------
## Constructors

VariableNodeData{T}(;solveKey::Symbol=:default ) where T <: InferenceVariable = VariableNodeData{T, getPointType(T)}(solveKey=solveKey)

VariableNodeData(   val::Vector{P},
                    bw::AbstractMatrix{<:Real},
                    BayesNetOutVertIDs::AbstractVector{Symbol},
                    dimIDs::AbstractVector{Int},
                    dims::Int,
                    eliminated::Bool,
                    BayesNetVertID::Symbol,
                    separator::AbstractVector{Symbol},
                    variableType::T,
                    initialized::Bool,
                    ipc::AbstractVector{<:Real},
                    ismargin::Bool,
                    dontmargin::Bool,
                    solveInProgress::Int=0,
                    solvedCount::Int=0,
                    solveKey::Symbol=:default,
                    events::Dict{Symbol,Threads.Condition}=Dict{Symbol,Threads.Condition}();
                    id::Union{UUID, Nothing}=nothing
                ) where {T <: InferenceVariable, P} =
                    VariableNodeData{T,P}(  id, val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                            eliminated,BayesNetVertID,separator,
                                            variableType,initialized,ipc,ismargin,
                                            dontmargin, solveInProgress, solvedCount,
                                            solveKey, events  )
#

function VariableNodeData(variableType::T; solveKey::Symbol=:default) where T <: InferenceVariable
    #
    # p0 = getPointIdentity(T)
    P0 = Vector{getPointType(T)}()
    # P0[1] = p0
    BW = zeros(0,0)
    # BW[1] = zeros(getDimension(T))
    VariableNodeData(   P0, BW, Symbol[], Int[], 
                        0, false, :NOTHING, Symbol[], 
                        variableType, false, [0.0], false, 
                        false, 0, 0, solveKey  )
end



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
    _version::String = _getDFGVersion()
end

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
    _version::String = _getDFGVersion()
    createdTimestamp::Union{ZonedDateTime, Nothing} = nothing
    lastUpdatedTimestamp::Union{ZonedDateTime, Nothing} = nothing
end

##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solveKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64}, mean::Vector{Float64}) = MeanMaxPPE(nothing, solveKey, suggested, max, mean, "MeanMaxPPE", _getDFGVersion(), now(tz"UTC"), now(tz"UTC"))

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

const SmallDataTypes = Union{Int, Float64, String, Bool, Vector{Int}, Vector{Float64}, Vector{String}, Vector{Bool}}

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
Base.@kwdef struct DFGVariable{T<:InferenceVariable} <: AbstractDFGVariable
    """The ID for the variable"""
    id::Union{UUID, Nothing}
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::ZonedDateTime
    """Nano second time, for more resolution on timestamp (only subsecond information)"""
    nstime::Nanosecond
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    ppeDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: [`addVariableSolverData!`](@ref), [`updateVariableSolverData!`](@ref), and [`deleteVariableSolverData!`](@ref)"""
    solverDataDict::Dict{Symbol, <: VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData`](@ref), [`setSmallData!`](@ref)"""
    smallData::Dict{Symbol, SmallDataTypes}
    """Dictionary of large data associated with this variable.
    Accessors: [`addDataEntry!`](@ref), [`getDataEntry`](@ref), [`updateDataEntry!`](@ref), and [`deleteDataEntry!`](@ref)"""
    dataDict::Dict{Symbol, AbstractDataEntry}
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
end

##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
function DFGVariable(label::Symbol, variableType::Type{T};
            id::Union{UUID,Nothing}=nothing,
            timestamp::Union{DateTime,ZonedDateTime}=now(localzone()),
            nstime::Nanosecond = Nanosecond(0),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T,P}}=Dict{Symbol, VariableNodeData{T,getPointType(T)}}(),
            smallData::Dict{Symbol, SmallDataTypes}=Dict{Symbol, SmallDataTypes}(),
            dataDict::Dict{Symbol, AbstractDataEntry}=Dict{Symbol,AbstractDataEntry}(),
            solvable::Int=1) where {T <: InferenceVariable, P}
    #
    if timestamp isa DateTime
        DFGVariable{T}(id, label, ZonedDateTime(timestamp, localzone()), nstime, tags, estimateDict, solverDataDict, smallData, dataDict, Ref(solvable))
    else
        DFGVariable{T}(id, label, timestamp, nstime, tags, estimateDict, solverDataDict, smallData, dataDict, Ref(solvable))
    end
end

DFGVariable(label::Symbol, 
            variableType::T; 
            solverDataDict::Dict{Symbol, VariableNodeData{T,P}}=Dict{Symbol, VariableNodeData{T,getPointType(T)}}(),
            kw...) where {T <: InferenceVariable, P} = DFGVariable(label, T; solverDataDict=solverDataDict, kw...)
#

function DFGVariable(label::Symbol,
            solverData::VariableNodeData{T};
            timestamp::Union{DateTime,ZonedDateTime}=now(localzone()),
            nstime::Nanosecond = Nanosecond(0),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            smallData::Dict{Symbol, SmallDataTypes}=Dict{Symbol, SmallDataTypes}(),
            dataDict::Dict{Symbol, <: AbstractDataEntry}=Dict{Symbol,AbstractDataEntry}(),
            solvable::Int=1) where {T <: InferenceVariable}
    #
    if timestamp isa DateTime
        DFGVariable{T}(label, ZonedDateTime(timestamp, localzone()), nstime, tags, estimateDict, Dict{Symbol, VariableNodeData{T, getPointType(T)}}(:default=>solverData), smallData, dataDict, Ref(solvable))
    else
        DFGVariable{T}(label, timestamp, nstime, tags, estimateDict, Dict{Symbol, VariableNodeData{T, getPointType(T)}}(:default=>solverData), smallData, dataDict, Ref(solvable))
    end
end

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
# TODO: can't see the reason to overwrite copy, leaving it here for now
# function Base.copy(o::DFGVariable)::DFGVariable
#     return DFGVariable(o.label, getVariableType(o)(), tags=copy(o.tags), estimateDict=copy(o.estimateDict),
#                         solverDataDict=copy(o.solverDataDict), smallData=copy(o.smallData),
#                         dataDict=copy(o.dataDict), solvable=getSolvable(o))
# end

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
    Accessors: [`addDataEntry!`](@ref), [`getDataEntry`](@ref), [`updateDataEntry!`](@ref), and [`deleteDataEntry!`](@ref)"""
    dataDict::Dict{Symbol, AbstractDataEntry}
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
    id::Union{UUID, Nothing}
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(nothing, label, Set{Symbol}())


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
