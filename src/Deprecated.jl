## ================================================================================
## LEGACY ON TIMESTAMPS, TODO DEPRECATE
##=================================================================================


Base.promote_rule(::Type{DateTime}, ::Type{ZonedDateTime}) = DateTime
function Base.convert(::Type{DateTime}, ts::ZonedDateTime)
    @warn "DFG now uses ZonedDateTime, temporary promoting and converting to DateTime local time"
    return DateTime(ts, Local)
end

## ================================================================================
## Deprecate before v0.17
##=================================================================================


Base.propertynames(x::VariableNodeData, private::Bool=false) = private ? (:inferdim, :infoPerCoord) : (:infoPerCoord,)

Base.getproperty(x::VariableNodeData,f::Symbol) = begin
  if f == :inferdim
    Base.depwarn("vnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :getproperty)
    # @warn "vnd.inferdim is deprecated, use .infoPerCoord instead"
    getfield(x, :infoPerCoord)
  else
    getfield(x,f)
  end
end

function Base.setproperty!(x::VariableNodeData, f::Symbol, val::Real)
  _val = if f == :inferdim
    Base.depwarn("vnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :setproperty!)
    f = :infoPerCoord
    Float64[val;]
  else
    val
  end
  return setfield!(x, f, _val)
end

function Base.setproperty!(x::VariableNodeData, f::Symbol, val::AbstractVector{<:Real})
  if f == :inferdim
    Base.depwarn("vnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :setproperty!)
    f = :infoPerCoord
  end
  return setfield!(x, f, val)
end

#

Base.propertynames(x::PackedVariableNodeData, private::Bool=false) = private ? (:inferdim, :infoPerCoord) : (:infoPerCoord,)

Base.getproperty(x::PackedVariableNodeData,f::Symbol) = begin
  if f == :inferdim
    Base.depwarn("pvnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :getproperty)
    getfield(x, :infoPerCoord)
  else
    getfield(x,f)
  end
end

function Base.setproperty!(x::PackedVariableNodeData, f::Symbol, val::Real)
  _val = if f == :inferdim
    Base.depwarn("pvnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :setproperty!)
    f = :infoPerCoord
    Float64[val;]
  else
    val
  end
  return setfield!(x, f, _val)
end

function Base.setproperty!(x::PackedVariableNodeData, f::Symbol, val::AbstractVector{<:Real})
  if f == :inferdim
    Base.depwarn("pvnd.inferdim::Float64 is deprecated, use vnd.infoPerCoord::Vector{Float64} instead", :setproperty!)
    f = :infoPerCoord
  end
  return setfield!(x, f, val)
end


@deprecate VariableNodeData(val::Vector,bw::AbstractMatrix{<:Real},BayesNetOutVertIDs::AbstractVector{Symbol},dimIDs::AbstractVector{Int},dims::Int,eliminated::Bool,BayesNetVertID::Symbol,separator::AbstractVector{Symbol},variableType,initialized::Bool,inferdim::Real,w...;kw...) VariableNodeData(val,bw,BayesNetOutVertIDs,dimIDs,dims,eliminated,BayesNetVertID,separator,variableType,initialized,Float64[inferdim;],w...;kw...)


## ================================================================================
## Deprecate before v0.19
##=================================================================================

const FunctorInferenceType = AbstractFactor       # will eventually deprecate
const PackedInferenceType = AbstractPackedFactor  # will eventually deprecate

## ================================================================================
## Deprecate before v0.20
##=================================================================================

export DefaultDFG

const DefaultDFG = LightDFG

#