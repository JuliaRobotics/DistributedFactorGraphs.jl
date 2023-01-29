## ================================================================================
## LEGACY ON TIMESTAMPS, TODO DEPRECATE
##=================================================================================


Base.promote_rule(::Type{DateTime}, ::Type{ZonedDateTime}) = DateTime
function Base.convert(::Type{DateTime}, ts::ZonedDateTime)
    @warn "DFG now uses ZonedDateTime, temporary promoting and converting to DateTime local time"
    return DateTime(ts, Local)
end


## ================================================================================
## Add @deprecate in v0.19, remove after v0.20
##=================================================================================


# TODO ADD DEPRECATION
packVariable(::AbstractDFG, v::DFGVariable) = packVariable(v) 

# # FIXME ON FIRE, THIS OLD CONSTRUCTOR SHOULD BE DELETED
# function GenericFunctionNodeData(   eliminated::Bool,
#                                     potentialused::Bool,
#                                     edgeIDs::Vector{Int},
#                                     fnc::T,
#                                     multihypo::Vector{<:Real}=Float64[],
#                                     certainhypo::Vector{Int}=Int[],
#                                     nullhypo::Real=0,
#                                     solveInProgress::Int=0,
#                                     inflation::Real=0.0 ) where T
#     return GenericFunctionNodeData{T}(; eliminated, potentialused, edgeIDs, fnc, multihypo, certainhypo, nullhypo, solveInProgress, inflation)
# end

# GenericFunctionNodeData{T}() where T = GenericFunctionNodeData(;fnc=T())


# GenericFunctionNodeData{T}() where T =
#     GenericFunctionNodeData( false, false, Int[], T())

## ================================================================================
## Deprecate before v0.20 - Kept longer with error
##=================================================================================

@deprecate packVariableNodeData(fg::AbstractDFG, d::VariableNodeData) packVariableNodeData(d::VariableNodeData)
@deprecate unpackVariableNodeData(fg::AbstractDFG, d::PackedVariableNodeData) unpackVariableNodeData(d::PackedVariableNodeData)

function getTypeFromSerializationModule(dfg::G, moduleType::Symbol) where G <: AbstractDFG
  error("Deprecating getTypeFromSerializationModule(dfg,symbol), use getTypeFromSerializationModule(string) instead.")
  st = nothing
  try
      st = getfield(Main, Symbol(moduleType))
  catch ex
      @error "Unable to deserialize packed variableType $(moduleType)"
      io = IOBuffer()
      showerror(io, ex, catch_backtrace())
      err = String(take!(io))
      @error(err)
  end
  return st
end

## ================================================================================
## Deprecate before v0.20
##=================================================================================

export DefaultDFG

const DefaultDFG = GraphsDFG

export LightDFG
LightDFG(args...; kwargs...) = error("LightDFG is deprecated and replaced with GraphsDFG")


# better deprecation cycle from before v0.19
@deprecate deepcopySupersolve!(w...;kw...) cloneSolveKey!(w...;kw...)
@deprecate deepcopySolvekeys!(w...;kw...) cloneSolveKey!(w...;kw...)


## ================================================================================
## Deprecate before v0.19 - Kept longer with error
##=================================================================================

# Base.getproperty(x::VariableNodeData,f::Symbol) = begin
#   if f == :inferdim
#     error("vnd.inferdim::Float64 was deprecated and is now obsolete, use vnd.infoPerCoord::Vector{Float64} instead")
#   else
#     getfield(x,f)
#   end
# end

# function Base.setproperty!(x::VariableNodeData, f::Symbol, val)
#   if f == :inferdim
#     error("vnd.inferdim::Float64 was deprecated and is now obsolete, use vnd.infoPerCoord::Vector{Float64} instead")
#   end
#   return setfield!(x, f, convert(fieldtype(typeof(x), f), val))
# end

# Base.getproperty(x::PackedVariableNodeData,f::Symbol) = begin
#   if f == :inferdim
#     error("pvnd.inferdim::Float64 was deprecated and is now obsolete, use vnd.infoPerCoord::Vector{Float64} instead")
#   else
#     getfield(x,f)
#   end
# end

# function Base.setproperty!(x::PackedVariableNodeData, f::Symbol, val)
#   if f == :inferdim
#     error("pvnd.inferdim::Float64 was deprecated and is now obsolete, use vnd.infoPerCoord::Vector{Float64} instead")
#   end
#   return setfield!(x, f, convert(fieldtype(typeof(x), f), val))
# end



# function VariableNodeData(val::Vector,
#                           bw::AbstractMatrix{<:Real},
#                           BayesNetOutVertIDs::AbstractVector{Symbol},
#                           dimIDs::AbstractVector{Int},
#                           dims::Int,
#                           eliminated::Bool,
#                           BayesNetVertID::Symbol,
#                           separator::AbstractVector{Symbol},
#                           variableType,
#                           initialized::Bool,
#                           inferdim::Real,
#                           w...; kw...)
#   error("VariableNodeData field inferdim was deprecated and is now obsolete, use infoPerCoord instead")
# end



## ================================================================================
## Deprecate before v0.19
##=================================================================================

# # FIXME, change this to a deprecation in v0.19
# export deepcopySupersolve!, deepcopySolvekeys!
# const deepcopySupersolve! = cloneSolveKey!
# # @deprecate deepcopySupersolve!(w...;kw...) cloneSolveKey!(w...;kw...)
# const deepcopySolvekeys! = cloneSolveKey!
# # @deprecate deepcopySolvekeys!(w...;kw...) cloneSolveKey!(w...;kw...)

# @deprecate dfgplot(w...;kw...) plotDFG(w...;kw...)

# export FunctorInferenceType, PackedInferenceType

# const FunctorInferenceType = AbstractFactor       # will eventually deprecate
# const PackedInferenceType = AbstractPackedFactor  # will eventually deprecate


#