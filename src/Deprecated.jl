# deprecation staging area

## quick deprecation handle
import Base: propertynames, getproperty

Base.propertynames(x::VariableDataLevel1, private::Bool=false) = private ? (:estimateDict, :ppeDict) : (:ppeDict,)

Base.getproperty(x::VariableDataLevel1,f::Symbol) = begin
    if f == :estimateDict
      @warn "estimateDict is deprecated, use ppeDict instead"
      getfield(x, :ppeDict)
    else
      getfield(x,f)
    end
  end



"""
$SIGNATURES

Return the estimates for a variable.
"""
function getEstimates(v::VariableDataLevel1)
  @warn "Deprecated getEstimates, use getVariablePPE/getPPE instead."
  getVariablePPEs(vari)
end

"""
  $SIGNATURES

Return the estimates for a variable.

DEPRECATED, estimates -> getVariablePPEs/getPPEs
"""
function estimates(v::VariableDataLevel1)
  @warn "Deprecated estimates, use getVariablePPEs/getPPE instead."
  getVariablePPEs(v)
end

"""
  $SIGNATURES

Return a keyed estimate (default is :default) for a variable.

DEPRECATED use getVariablePPE/getPPE instead.
"""
function getEstimate(v::VariableDataLevel1, key::Symbol=:default)
@warn "Deprecated getEstimate, use getVariablePPE/getPPE instead."
getVariablePPE(v, key)
end

"""
$SIGNATURES

Return a keyed estimate (default is :default) for a variable.
"""
function estimate(v::VariableDataLevel1, key::Symbol=:default)
  @warn "DEPRECATED estimate, use getVariablePPE/getPPE instead."
  getVariablePPE(v, key)
end


"""
$SIGNATURES

Return the softtype for a variable.

DEPRECATED, softtype -> getSofttype
"""
function softtype(v::VariableDataLevel1)
    @warn "Deprecated softtype, use getSofttype instead."
    getSofttype(v)
end
