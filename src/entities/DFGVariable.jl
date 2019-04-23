"""
$(TYPEDEF)
"""
mutable struct VariableNodeData
  val::Array{Float64,2}
  bw::Array{Float64,2}
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1} # Likely deprecate
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  groundtruth::Union{Nothing, Dict{ Tuple{Symbol, Vector{Float64}} } } # not packed yet
  softtype
  initialized::Bool
  ismargin::Bool
  dontmargin::Bool
  VariableNodeData() = new()
  # function VariableNodeData(x1,x2,x3,x4,x5,x6,x7,x8,x9)
  #   @warn "Deprecated use of VariableNodeData(11 param), use 13 parameters instead"
  #   new(x1,x2,x3,x4,x5,x6,x7,x8,x9, nothing, true, false, false) # TODO ensure this is initialized true is working for most cases
  # end
  VariableNodeData(x1::Array{Float64,2},
                   x2::Array{Float64,2},
                   x3::Vector{Int},
                   x4::Vector{Int},
                   x5::Int,
                   x6::Bool,
                   x7::Int,
                   x8::Vector{Int},
                   x9::Union{Nothing, Dict{ Tuple{Symbol, Vector{Float64}} } },
                   x10,
                   x11::Bool,
                   x12::Bool,
                   x13::Bool) =
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13)
end

struct VariableEstimate
  estimate::Vector{Float64}
  type::Symbol
  key::Symbol
end

"""
    $(SIGNATURES)
Fundamental structure for a DFG variable.
"""
mutable struct DFGVariable <: DFGNode
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, VariableEstimate}
    solverDataDict::Dict{Symbol, VariableNodeData}
    smallData::Any
    bigData::Any
    _internalId::Int64
    DFGVariable(label::Symbol, _internalId::Int64) = new(label, now(), Symbol[], Dict{Symbol, VariableEstimate}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), nothing, nothing, _internalId)
    DFGVariable(label::Symbol) = new(label, now(), Symbol[], Dict{Symbol, VariableEstimate}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), nothing, nothing, 0)
end

# Accessors
label(v::DFGVariable) = v.label
timestamp(v::DFGVariable) = v.timestamp
tags(v::DFGVariable) = v.tags
estimates(v::DFGVariable) = v.estimateDict
estimate(v::DFGVariable, key::Symbol) = haskey(v.estimateDict, key) ? v.estimateDict[key] : nothing
#solverData(v::DFGVariable) = haskey(v.solverDataDict, :default) ? v.solverDataDict[:default] : nothing
solverData(v::DFGVariable, key::Symbol=:default) = haskey(v.solverDataDict, key) ? v.solverDataDict[key] : nothing
solverDataDict(v::DFGVariable) = v.solverDataDict
id(v::DFGVariable) = v._internalId
# Todo: Complete this.
smallData(v::DFGVariable) = v.smallData
bigData(v::DFGVariable) = v.bigData
