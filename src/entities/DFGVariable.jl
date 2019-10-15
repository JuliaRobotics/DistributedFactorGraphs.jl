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


abstract type AbstractVariableEstimate end
"""
    $TYPEDEF

Data container to store Parameteric Point Estimate (PPE) from a variety of types.

Notes
- `ppeType` is something like `:max/:mean/:modefit` etc.
- `solveKey` is from super-solve concept, starting with `:default`,
- `estimate` is the actual numerical estimate value,
- Additional information such as how the data is represented (ie softtype) is stored alongside this data container in the `DFGVariableSummary` container.
"""
struct VariableEstimate <: AbstractVariableEstimate
  solverKey::Symbol
  ppeType::Symbol
  estimate::Vector{Float64}
  lastUpdatedTimestamp::DateTime
end
VariableEstimate(solverKey::Symbol, type::Symbol, estimate::Vector{Float64}) = VariableEstimate(solverKey, type, estimate, now())

"""
    $(TYPEDEF)
Fundamental structure for a DFG variable with fields:
$(TYPEDFIELDS)
"""
mutable struct DFGVariable <: AbstractDFGVariable
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, Dict{Symbol, <: AbstractVariableEstimate}}
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
        DFGVariable(label, now(), Symbol[], Dict{Symbol, Dict{Symbol, VariableEstimate}}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), Dict{String, String}(), Dict{Symbol,AbstractBigDataEntry}(), 0, 0, _internalId)

DFGVariable(label::Symbol) =
        DFGVariable(label, now(), Symbol[], Dict{Symbol, VariableEstimate}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), Dict{String, String}(), Dict{Symbol,AbstractBigDataEntry}(), 0, 0, 0)

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
  #FIXME but back in later, it just slows everything down
  if !(@isdefined getDataWarnOnce)
    @warn "getData is deprecated, please use solverData(), future warnings in getData is suppressed"
    global getDataWarnOnce = true
  end
  # @warn "getData is deprecated, please use solverData()"
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
    estimateDict::Dict{Symbol, Dict{Symbol, <:AbstractVariableEstimate}}
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
