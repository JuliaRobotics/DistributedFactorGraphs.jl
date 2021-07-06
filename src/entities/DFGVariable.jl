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
mutable struct VariableNodeData{T<:InferenceVariable, P}
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
    inferdim::Float64
    ismargin::Bool

    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    solveKey::Symbol

    events::Dict{Symbol,Threads.Condition}

    # VariableNodeData{T,P}() = new{T,P}()
    VariableNodeData{T,P}(w...)  where {T <:InferenceVariable, P} = new{T,P}(w...)
    VariableNodeData{T,P}(;solveKey::Symbol=:default ) where {T <:InferenceVariable, P} = new{T,P}(
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
            0.0, 
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
                    bw::Matrix{<:Real},
                    BayesNetOutVertIDs::AbstractVector{Symbol},
                    dimIDs::AbstractVector{Int},
                    dims::Int,
                    eliminated::Bool,
                    BayesNetVertID::Symbol,
                    separator::Array{Symbol,1},
                    variableType::T,
                    initialized::Bool,
                    inferdim::Float64,
                    ismargin::Bool,
                    dontmargin::Bool,
                    solveInProgress::Int=0,
                    solvedCount::Int=0,
                    solveKey::Symbol=:default,
                    events::Dict{Symbol,Threads.Condition}=Dict{Symbol,Threads.Condition}()
                ) where {T <: InferenceVariable, P} = VariableNodeData{T,P}( 
                                        val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                        eliminated,BayesNetVertID,separator,
                                        variableType,initialized,inferdim,ismargin,
                                        dontmargin, solveInProgress, solvedCount, solveKey, events  )
#


#

VariableNodeData(val::Vector{P},
                 bw::Matrix{<:Real},
                 BayesNetOutVertIDs::AbstractVector{Symbol},
                 dimIDs::AbstractVector{Int},
                 dims::Int,
                 eliminated::Bool,
                 BayesNetVertID::Symbol,
                 separator::AbstractVector{Symbol},
                 variableType::T,
                 initialized::Bool,
                 inferdim::Float64,
                 ismargin::Bool,
                 dontmargin::Bool,
                 solveInProgress::Int=0,
                 solvedCount::Int=0,
                 solveKey::Symbol=:default
                 ) where {T <: InferenceVariable, P} =
                   VariableNodeData{T,P}(   val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                            eliminated,BayesNetVertID,separator,
                                            variableType,initialized,inferdim,ismargin,
                                            dontmargin, solveInProgress, solvedCount,
                                            solveKey  )
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
                        variableType, false, 0.0, false, 
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
    variableType::String
    initialized::Bool
    inferdim::Float64
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    solveKey::Symbol
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
                         solveKey::Symbol) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16, solvedCount, solveKey)
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
                          solveKey::Symbol) = new(
                                convert(Vector{Float64},x1),x2,
                                convert(Vector{Float64},x3),x4,
                                convert(Vector{Symbol},x5),
                                convert(Vector{Int},x6),x7,x8,x9,
                                convert(Vector{Symbol},x10),x11,x12,x13,x14,x15,x16, solvedCount, solveKey)
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
struct MeanMaxPPE{P} <: AbstractPointParametricEst
    solveKey::Symbol #repeated because of Sam's request
    suggested::P
    max::P
    mean::P
    lastUpdatedTimestamp::DateTime
end

##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solveKey::Symbol, suggested::P, max::P, mean::P) where P = MeanMaxPPE{P}(solveKey, suggested, max, mean, now(UTC))

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
struct DFGVariable{T<:InferenceVariable} <: AbstractDFGVariable
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
        DFGVariable{T}(label, ZonedDateTime(timestamp, localzone()), nstime, tags, estimateDict, solverDataDict, smallData, dataDict, Ref(solvable))
    else
        DFGVariable{T}(label, timestamp, nstime, tags, estimateDict, solverDataDict, smallData, dataDict, Ref(solvable))
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
struct DFGVariableSummary <: AbstractDFGVariable
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
        DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getVariableType(v))), v.dataDict)

SkeletonDFGVariable(v::VariableDataLevel1) =
            SkeletonDFGVariable(v.label, deepcopy(v.tags))
