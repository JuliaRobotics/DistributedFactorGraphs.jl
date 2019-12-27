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
