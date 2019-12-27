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
