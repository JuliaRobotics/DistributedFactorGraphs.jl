import Base: convert, ==

##==============================================================================

##==============================================================================


"""
    $SIGNATURES

Return `::Bool` on whether given factor `fc::Symbol` is a prior in factor graph `dfg`.
"""
function isPrior(dfg::G, fc::Symbol)::Bool where G <: AbstractDFG
  fco = getFactor(dfg, fc)
  getfnctype(fco) isa FunctorSingleton
end

"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.
"""
function lsfPriors(dfg::G)::Vector{Symbol} where G <: AbstractDFG
  priors = Symbol[]
  fcts = lsf(dfg)
  for fc in fcts
    if isPrior(dfg, fc)
      push!(priors, fc)
    end
  end
  return priors
end


##==============================================================================
