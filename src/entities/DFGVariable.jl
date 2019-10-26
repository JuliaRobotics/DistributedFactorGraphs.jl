#TODO don't know what to do if it is uninitalized
#so for now defining a Singleton for the default
struct SingletonInferenceVariable <: InferenceVariable end

"""
$(TYPEDEF)
"""
mutable struct VariableNodeData #TODO v0.5.0 {T<:InferenceVariable}
  val::Array{Float64,2}
  bw::Array{Float64,2}
  BayesNetOutVertIDs::Array{Symbol,1}
  dimIDs::Array{Int,1} # Likely deprecate
  dims::Int
  eliminated::Bool
  BayesNetVertID::Symbol #  Union{Nothing, }
  separator::Array{Symbol,1}
  softtype::InferenceVariable #TODO v0.5.0 T
  initialized::Bool
  inferdim::Float64
  ismargin::Bool
  dontmargin::Bool
  # Tonio surprise TODO
  # frontalonly::Bool
  # A valid, packable default constructor is needed.

end
VariableNodeData() = VariableNodeData(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], SingletonInferenceVariable(), false, 0.0, false, false)

"""
$(TYPEDEF)
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
                         x15::Bool ) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15)
end

# AbstractPointParametricEst interface
abstract type AbstractPointParametricEst end
"""
    $TYPEDEF

Data container to store Parameteric Point Estimate (PPE) for mean and max.
"""
struct MeanMaxPPE <: AbstractPointParametricEst
    solverKey::Symbol #repeated because of Sam's request
    max::Vector{Float64}
    mean::Vector{Float64}
    lastUpdatedTimestamp::DateTime
end
MeanMaxPPE(solverKey::Symbol,max::Vector{Float64},mean::Vector{Float64}) = MeanMaxPPE(solverKey, max, mean, now())

getMaxPPE(est::AbstractPointParametricEst) = est.max
getMeanPPE(est::AbstractPointParametricEst) = est.mean
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = est.lastUpdatedTimestamp


VariableEstimate(params...) = errror("VariableEstimate is depreciated, please use MeanMaxPPE")


"""
    $(TYPEDEF)
Fundamental structure for a DFG variable with fields:
$(TYPEDFIELDS)
"""
mutable struct DFGVariable <: AbstractDFGVariable
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, <: AbstractPointParametricEst}
    solverDataDict::Dict{Symbol, VariableNodeData}
    smallData::Dict{String, String}
    bigData::Dict{Symbol, AbstractBigDataEntry}
    ready::Int
    backendset::Int
    _internalId::Int64
end

"""
    $SIGNATURES
DFGVariable constructors.
"""
DFGVariable(label::Symbol, _internalId::Int64) =
        DFGVariable(label, now(), Symbol[], Dict{Symbol, MeanMaxPPE}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), Dict{String, String}(), Dict{Symbol,AbstractBigDataEntry}(), 0, 0, _internalId)

DFGVariable(label::Symbol) =
        DFGVariable(label, now(), Symbol[], Dict{Symbol, MeanMaxPPE}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), Dict{String, String}(), Dict{Symbol,AbstractBigDataEntry}(), 0, 0, 0)

# Accessors
label(v::DFGVariable) = v.label
timestamp(v::DFGVariable) = v.timestamp
tags(v::DFGVariable) = v.tags
estimates(v::DFGVariable) = v.estimateDict
estimate(v::DFGVariable, key::Symbol=:default) = haskey(v.estimateDict, key) ? v.estimateDict[key] : nothing

"""
    $SIGNATURES

Retrieve the soft type name symbol for a DFGVariable or DFGVariableSummary. ie :Point2, Pose2, etc.
"""
softtype(v::DFGVariable)::Symbol = Symbol(typeof(getSofttype(v)))

"""
    $SIGNATURES

Retrieve solver data structure stored in a variable.
"""
solverData(v::DFGVariable, key::Symbol=:default) = haskey(v.solverDataDict, key) ? v.solverDataDict[key] : nothing
"""
    $SIGNATURES

Retrieve data structure stored in a variable.
"""
function getData(v::DFGVariable; solveKey::Symbol=:default)::VariableNodeData
  @warn "getData is deprecated, please use solverData()"
  return v.solverDataDict[solveKey]
end
"""
    $SIGNATURES

Set solver data structure stored in a variable.
"""
setSolverData(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) = v.solverDataDict[key] = data
solverDataDict(v::DFGVariable) = v.solverDataDict
internalId(v::DFGVariable) = v._internalId
# Todo: Complete this.
smallData(v::DFGVariable) = v.smallData
bigData(v::DFGVariable) = v.bigData

"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGVariable.
"""
mutable struct DFGVariableSummary <: AbstractDFGVariable
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, <:AbstractPointParametricEst}
    softtypename::Symbol
    _internalId::Int64
end
label(v::DFGVariableSummary) = v.label
timestamp(v::DFGVariableSummary) = v.timestamp
tags(v::DFGVariableSummary) = v.tags
estimates(v::DFGVariableSummary) = v.estimateDict
estimate(v::DFGVariableSummary, key::Symbol=:default) = haskey(v.estimateDict, key) ? v.estimateDict[key] : nothing
softtype(v::DFGVariableSummary)::Symbol = v.softtypename
internalId(v::DFGVariableSummary) = v._internalId



# SKELETON DFG
"""
	$(TYPEDEF)
Skeleton factor with essentials.
"""
struct SkeletonDFGFactor <: AbstractDFGFactor
    label::Symbol
	tags::Vector{Symbol}
	_variableOrderSymbols::Vector{Symbol}
end

#NOTE I feel like a want to force a variableOrderSymbols
SkeletonDFGFactor(label::Symbol, variableOrderSymbols::Vector{Symbol} = Symbol[]) = SkeletonDFGFactor(label, Symbol[], variableOrderSymbols)

label(f::SkeletonDFGFactor) = f.label
tags(f::SkeletonDFGFactor) = f.tags
