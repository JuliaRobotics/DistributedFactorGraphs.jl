"""
$(TYPEDEF)
"""
mutable struct VariableNodeData
  val::Array{Float64,2}
  bw::Array{Float64,2}
  BayesNetOutVertIDs::Array{Symbol,1}
  dimIDs::Array{Int,1} # Likely deprecate
  dims::Int
  eliminated::Bool
  BayesNetVertID::Union{Nothing, Symbol} # TODO Drop union type from here
  separator::Array{Symbol,1}
  groundtruth::Union{Nothing, Dict{ Tuple{Symbol, Vector{Float64}} } } # not packed yet
  softtype
  initialized::Bool
  partialinit::Bool
  ismargin::Bool
  dontmargin::Bool
  VariableNodeData() = new()
  # function VariableNodeData(x1,x2,x3,x4,x5,x6,x7,x8,x9)
  #   @warn "Deprecated use of VariableNodeData(11 param), use 13 parameters instead"
  #   new(x1,x2,x3,x4,x5,x6,x7,x8,x9, nothing, true, false, false) # TODO ensure this is initialized true is working for most cases
  # end
  VariableNodeData(x1::Array{Float64,2},
                   x2::Array{Float64,2},
                   x3::Vector{Symbol},
                   x4::Vector{Int},
                   x5::Int,
                   x6::Bool,
                   x7::Union{Nothing, Symbol},
                   x8::Vector{Symbol},
                   x9::Union{Nothing, Dict{ Tuple{Symbol, Vector{Float64}} } },
                   x10,
                   x11::Bool,
                   x12::Bool,
                   x13::Bool,
                   x14::Bool) =
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14)
end

"""
$(TYPEDEF)
"""
mutable struct PackedVariableNodeData
  vecval::Array{Float64,1}
  dimval::Int
  vecbw::Array{Float64,1}
  dimbw::Int
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1}
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  # groundtruth::NothingUnion{ Dict{ Tuple{Symbol, Vector{Float64}} } }
  softtype::String
  initialized::Bool
  partialinit::Bool
  ismargin::Bool
  dontmargin::Bool
  PackedVariableNodeData() = new()
  PackedVariableNodeData(x5::Vector{Float64},
                         x6::Int,
                         x7::Vector{Float64},
                         x8::Int,
                         x9::Vector{Int},
                         x10::Vector{Int},
                         x11::Int,
                         x12::Bool,
                         x13::Int,
                         x14::Vector{Int},
                         x15::String,
                         x16::Bool,
                         x17::Bool,
                         x18::Bool,
                         x19::Bool ) = new(x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19)
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
    ready::Int
    backendset::Int
    _internalId::Int64
    DFGVariable(label::Symbol, _internalId::Int64) = new(label, now(), Symbol[], Dict{Symbol, VariableEstimate}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), nothing, nothing, 0, 0, _internalId)
    DFGVariable(label::Symbol) = new(label, now(), Symbol[], Dict{Symbol, VariableEstimate}(), Dict{Symbol, VariableNodeData}(:default => VariableNodeData()), nothing, nothing, 0, 0, 0)
end

# Accessors
label(v::DFGVariable) = v.label
timestamp(v::DFGVariable) = v.timestamp
tags(v::DFGVariable) = v.tags
estimates(v::DFGVariable) = v.estimateDict
estimate(v::DFGVariable, key::Symbol=:default) = haskey(v.estimateDict, key) ? v.estimateDict[key] : nothing
#solverData(v::DFGVariable) = haskey(v.solverDataDict, :default) ? v.solverDataDict[:default] : nothing
solverData(v::DFGVariable, key::Symbol=:default) = haskey(v.solverDataDict, key) ? v.solverDataDict[key] : nothing
setSolverData(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) = v.solverDataDict[key] = data
solverDataDict(v::DFGVariable) = v.solverDataDict
id(v::DFGVariable) = v._internalId
# Todo: Complete this.
smallData(v::DFGVariable) = v.smallData
bigData(v::DFGVariable) = v.bigData
