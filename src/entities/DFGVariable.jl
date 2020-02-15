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
mutable struct VariableNodeData{T<:InferenceVariable}
    val::Array{Float64,2}
    bw::Array{Float64,2}
    BayesNetOutVertIDs::Array{Symbol,1}
    dimIDs::Array{Int,1} # Likely deprecate
    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol #  Union{Nothing, }
    separator::Array{Symbol,1}
    softtype::T
    initialized::Bool
    inferdim::Float64
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    VariableNodeData{T}() where {T <:InferenceVariable} =
    new{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], T(), false, 0.0, false, false, 0, 0)
    VariableNodeData{T}(val::Array{Float64,2},
                        bw::Array{Float64,2},
                        BayesNetOutVertIDs::Array{Symbol,1},
                        dimIDs::Array{Int,1},
                        dims::Int,eliminated::Bool,
                        BayesNetVertID::Symbol,
                        separator::Array{Symbol,1},
                        softtype::T,
                        initialized::Bool,
                        inferdim::Float64,
                        ismargin::Bool,
                        dontmargin::Bool,
                        solveInProgress::Int=0,
                        solvedCount::Int=0) where T <: InferenceVariable =
                            new{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                   eliminated,BayesNetVertID,separator,
                                   softtype::T,initialized,inferdim,ismargin,
                                   dontmargin, solveInProgress, solvedCount)
end

##------------------------------------------------------------------------------
## Constructors

VariableNodeData(val::Array{Float64,2},
                 bw::Array{Float64,2},
                 BayesNetOutVertIDs::Array{Symbol,1},
                 dimIDs::Array{Int,1},
                 dims::Int,eliminated::Bool,
                 BayesNetVertID::Symbol,
                 separator::Array{Symbol,1},
                 softtype::T,
                 initialized::Bool,
                 inferdim::Float64,
                 ismargin::Bool,
                 dontmargin::Bool,
                 solveInProgress::Int=0,
                 solvedCount::Int=0) where T <: InferenceVariable =
                   VariableNodeData{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                       eliminated,BayesNetVertID,separator,
                                       softtype::T,initialized,inferdim,ismargin,
                                       dontmargin, solveInProgress, solvedCount)


VariableNodeData(softtype::T) where T <: InferenceVariable =
    VariableNodeData{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], softtype, false, 0.0, false, false, 0, 0)

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
mutable struct PackedVariableNodeData
    vecval::Array{Float64,1}
    dimval::Int
    vecbw::Array{Float64,1}
    dimbw::Int
    BayesNetOutVertIDs::Array{Symbol,1} # Int
    dimIDs::Array{Int,1}
    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol # Int
    separator::Array{Symbol,1} # Int
    softtype::String
    initialized::Bool
    inferdim::Float64
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    PackedVariableNodeData() = new()
    PackedVariableNodeData(x1::Vector{Float64},
                         x2::Int,
                         x3::Vector{Float64},
                         x4::Int,
                         x5::Vector{Symbol}, # Int
                         x6::Vector{Int},
                         x7::Int,
                         x8::Bool,
                         x9::Symbol, # Int
                         x10::Vector{Symbol}, # Int
                         x11::String,
                         x12::Bool,
                         x13::Float64,
                         x14::Bool,
                         x15::Bool,
                         x16::Int,
                         solvedCount::Int) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16, solvedCount)
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
struct MeanMaxPPE <: AbstractPointParametricEst
    solverKey::Symbol #repeated because of Sam's request
    suggested::Vector{Float64}
    max::Vector{Float64}
    mean::Vector{Float64}
    lastUpdatedTimestamp::DateTime
end
##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solverKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64},mean::Vector{Float64}) = MeanMaxPPE(solverKey, suggested, max, mean, now())


##==============================================================================
## DFG Variables
##==============================================================================

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
struct DFGVariable{T<:InferenceVariable} <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: `addPPE!`, `updatePPE!`, and `deletePPE!`"""
    ppeDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: `addVariableSolverData!`, `updateVariableSolverData!`, and `deleteVariableSolverData!`"""
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData`](@ref), [`setSmallData!`](@ref)"""
    smallData::Dict{String, String}#Ref{Dict{String, String}} #why was Ref here?
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
end

##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
DFGVariable(label::Symbol, softtype::T;
            timestamp::DateTime=now(),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T}}=Dict{Symbol, VariableNodeData{T}}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, tags, estimateDict, solverDataDict, smallData, bigData, DFGNodeParams(solvable, _internalId))


DFGVariable(label::Symbol,
            solverData::VariableNodeData{T};
            timestamp::DateTime=now(),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, tags, estimateDict, Dict{Symbol, VariableNodeData{T}}(:default=>solverData), smallData, bigData, DFGNodeParams(solvable, _internalId))

##------------------------------------------------------------------------------
function Base.copy(o::DFGVariable)::DFGVariable
    return DFGVariable(o.label, getSofttype(o)(), tags=copy(o.tags), estimateDict=copy(o.estimateDict),
                        solverDataDict=copy(o.solverDataDict), smallData=copy(o.smallData),
                        bigData=copy(o.bigData), solvable=getSolvable(o), _internalId=getInternalId(o))
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
struct DFGVariableSummary <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: `addPPE!`, `updatePPE!`, and `deletePPE!`"""
    ppeDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the softtype for the underlying variable.
    Accessor: `getSofttype`"""
    softtypename::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
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
struct SkeletonDFGVariable <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(label, Set{Symbol}())


##==============================================================================
# Define variable levels
##==============================================================================
const VariableDataLevel0 = Union{DFGVariable, DFGVariableSummary, SkeletonDFGVariable}
const VariableDataLevel1 = Union{DFGVariable, DFGVariableSummary}
const VariableDataLevel2 = Union{DFGVariable}

##==============================================================================
## converters
##==============================================================================

function Base.convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getSofttype(v))), v.bigData, v._internalId)
end

#TODO Test
function Base.convert(::Type{SkeletonDFGVariable}, v::VariableDataLevel1)
    return SkeletonDFGVariable(v.label, deepcopy(v.tags))
end
