#TODO don't know what to do if it is uninitalized
#so for now defining a Singleton for the default
struct SingletonInferenceVariable <: InferenceVariable end

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
  # Tonio surprise TODO
  # frontalonly::Bool
end

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
               solveInProgress::Int=0) where T <: InferenceVariable =
                  VariableNodeData{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,eliminated,BayesNetVertID,separator,
                                      softtype::T,initialized,inferdim,ismargin,dontmargin, solveInProgress)


VariableNodeData{T}() where {T <:InferenceVariable} =
        VariableNodeData{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], T(), false, 0.0, false, false, 0)

VariableNodeData(softtype::T) where T <: InferenceVariable =
        VariableNodeData{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], softtype, false, 0.0, false, false, 0)

"""
$(TYPEDEF)
Packed VariabeNodeData for serializing DFGVariables.

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
                         x16::Int) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16)
end

# AbstractPointParametricEst interface
abstract type AbstractPointParametricEst end
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
MeanMaxPPE(solverKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64},mean::Vector{Float64}) = MeanMaxPPE(solverKey, suggested, max, mean, now())

getMaxPPE(est::AbstractPointParametricEst) = est.max
getMeanPPE(est::AbstractPointParametricEst) = est.mean
getSuggestedPPE(est::AbstractPointParametricEst) = est.suggested
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = est.lastUpdatedTimestamp

VariableEstimate(params...) = errror("VariableEstimate is depreciated, please use MeanMaxPPE")


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
    Accessors: `getLabels`, `addLabels!`, and `deleteLabels!`"""
    tags::Vector{Symbol}
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getLabels`, `addLabels`, and `deleteLabels`"""
    estimateDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: `addVariableSolverData!`, `updateVariableSolverData!`, and `deleteVariableSolverData!`"""
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: `addSmallData!`, `updateSmallData!`, and `deleteSmallData!`"""
    smallData::Dict{String, String}
    """Dictionary of large data associated with this variable.
    Accessors: `addSmallData!`, `updateSmallData!`, and `deleteSmallData!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Solvable flag for the variable.
    Accessors: `getSolvable`, `setSolvable!`
    TODO: Switch to `DFGNodeParams`"""
    solvable::Int
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
end

"""
    $SIGNATURES
DFGVariable constructors.
"""
DFGVariable(label::Symbol, softtype::T, _internalId::Int64 = 0) where {T <: InferenceVariable}  =
    DFGVariable{T}(label, now(), Symbol[],
              Dict{Symbol, MeanMaxPPE}(),
              Dict{Symbol, VariableNodeData{T}}(:default => VariableNodeData{T}()),
              Dict{String, String}(),
              Dict{Symbol,AbstractBigDataEntry}(), 0, _internalId)
