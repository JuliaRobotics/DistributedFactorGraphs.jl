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
    solverKey::Symbol
    events::Dict{Symbol,Threads.Condition}
    VariableNodeData{T}() where {T <:InferenceVariable} =
    new{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], T(), false, 0.0, false, false, 0, 0, Dict{Symbol,Threads.Condition}())
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
                        solvedCount::Int=0,
                        solverKey::Symbol=:default,
                        events::Dict{Symbol,Threads.Condition}=Dict{Symbol,Threads.Condition}()) where T <: InferenceVariable =
                            new{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                   eliminated,BayesNetVertID,separator,
                                   softtype::T,initialized,inferdim,ismargin,
                                   dontmargin, solveInProgress, solvedCount, solverKey, events)
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
                 solvedCount::Int=0,
                 solverKey::Symbol=:default
                 ) where T <: InferenceVariable =
                   VariableNodeData{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                       eliminated,BayesNetVertID,separator,
                                       softtype::T,initialized,inferdim,ismargin,
                                       dontmargin, solveInProgress, solvedCount,
                                       solverKey)


VariableNodeData(softtype::T; solverKey::Symbol=:default) where T <: InferenceVariable =
    VariableNodeData{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], softtype, false, 0.0, false, false, 0, 0, solverKey)

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
    solverKey::Symbol
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
                         solvedCount::Int,
                         solverKey::Symbol) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16, solvedCount, solverKey)
     # More permissive constructor needed for unmarshalling
     PackedVariableNodeData(x1::Vector,
                          x2::Int,
                          x3::Vector,
                          x4::Int,
                          x5::Vector, # Int
                          x6::Vector,
                          x7::Int,
                          x8::Bool,
                          x9::Symbol, # Int
                          x10::Vector, # Int
                          x11::String,
                          x12::Bool,
                          x13::Float64,
                          x14::Bool,
                          x15::Bool,
                          x16::Int,
                          solvedCount::Int,
                          solverKey::Symbol) = new(
                                convert(Vector{Float64},x1),x2,
                                convert(Vector{Float64},x3),x4,
                                convert(Vector{Symbol},x5),
                                convert(Vector{Int},x6),x7,x8,x9,
                                convert(Vector{Symbol},x10),x11,x12,x13,x14,x15,x16, solvedCount, solverKey)
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
    lastUpdatedTimestamp::ZonedDateTime
end

##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solverKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64}, mean::Vector{Float64}) = MeanMaxPPE(solverKey, suggested, max, mean, now(tz"UTC"))

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
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::DateTime
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
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData`](@ref), [`setSmallData!`](@ref)"""
    smallData::Dict{String, String}#Ref{Dict{String, String}} #why was Ref here?
    """Dictionary of large data associated with this variable.
    Accessors: [`addBigDataEntry!`](@ref), [`getBigDataEntry`](@ref), [`updateBigDataEntry!`](@ref), and [`deleteBigDataEntry!`](@ref)"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
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
DFGVariable(label::Symbol, softtype::T;
            timestamp::DateTime=now(),
            nstime::Nanosecond = Nanosecond(0),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T}}=Dict{Symbol, VariableNodeData{T}}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, nstime, tags, estimateDict, solverDataDict, smallData, bigData, Ref(solvable))


DFGVariable(label::Symbol,
            solverData::VariableNodeData{T};
            timestamp::DateTime=now(),
            nstime::Nanosecond = Nanosecond(0),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, nstime, tags, estimateDict, Dict{Symbol, VariableNodeData{T}}(:default=>solverData), smallData, bigData, Ref(solvable))

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
#     return DFGVariable(o.label, getSofttype(o)(), tags=copy(o.tags), estimateDict=copy(o.estimateDict),
#                         solverDataDict=copy(o.solverDataDict), smallData=copy(o.smallData),
#                         bigData=copy(o.bigData), solvable=getSolvable(o))
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
struct DFGVariableSummary <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable timestamp.
    Accessors: [`getTimestamp`](@ref), [`setTimestamp`](@ref)"""
    timestamp::DateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: [`addPPE!`](@ref), [`updatePPE!`](@ref), and [`deletePPE!`](@ref)"""
    ppeDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the softtype for the underlying variable.
    Accessor: [`getSofttype`](@ref)"""
    softtypename::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: [`addBigDataEntry!`](@ref), [`getBigDataEntry`](@ref), [`updateBigDataEntry!`](@ref), and [`deleteBigDataEntry!`](@ref)"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
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
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`getTags`](@ref), [`mergeTags!`](@ref), and [`removeTags!`](@ref)"""
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
## Convertion constructors
##==============================================================================

DFGVariableSummary(v::DFGVariable) =
        DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getSofttype(v))), v.bigData)

SkeletonDFGVariable(v::VariableDataLevel1) =
            SkeletonDFGVariable(v.label, deepcopy(v.tags))
