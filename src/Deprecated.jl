##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.9
##==============================================================================

include("../attic/GraphsDFG/GraphsDFG.jl")
@reexport using .GraphsDFGs

@deprecate getInternalId(args...) error("getInternalId is no longer in use")

@deprecate loadDFG(source::String, iifModule::Module, dest::AbstractDFG) loadDFG!(dest, source)


# leave a bit longer
#NOTE buildSubgraphFromLabels! does not have a 1-1 replacement in DFG
# if you have a set of variables and factors use copyGraph
# if you want neighbors automaticallyinclued use buildSubgraph
# if you want a clique subgraph use buildCliqueSubgraph! from IIF
function buildSubgraphFromLabels!(dfg::AbstractDFG,
                                  syms::Vector{Symbol};
                                  subfg::AbstractDFG=LightDFG(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )
  #
  Base.depwarn("buildSubgraphFromLabels! is deprecated use copyGraph, buildSubgraph or buildCliqueSubgraph!(IIF)", :buildSubgraphFromLabels!)
  # add a little too many variables (since we need the factors)
  for sym in syms
    if solvable <= getSolvable(dfg, sym)
      getSubgraphAroundNode(dfg, getVariable(dfg, sym), 2, false, subfg, solvable=solvable)
    end
  end

  # remove excessive variables that were copied by neighbors distance 2
  currVars = listVariables(subfg)
  toDelVars = setdiff(currVars, syms)
  for dv in toDelVars
    # delete any neighboring factors first
    for fc in lsf(subfg, dv)
      deleteFactor!(subfg, fc)
    end

    # and the variable itself
    deleteVariable!(subfg, dv)
  end

  # delete any factors not in the allowed list
  if allowedFactors != nothing
    delFcts = setdiff(lsf(subfg), allowedFactors)
    for dfct in delFcts
      deleteFactor!(subfg, dfct)
    end
  end

  # orphaned variables are allowed, but not orphaned factors

  return subfg
end


## TODO: I think these are handy, so move to Factor and Variable
Base.getproperty(x::DFGFactor,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGFactor,f::Symbol, val) = begin
    if f == :solvable
        setfield!(x,f,val)
        getfield(x,:_dfgNodeParams).solvable = val
    else
        setfield!(x,f,val)
    end
end

Base.getproperty(x::DFGVariable,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable = val
    else
        setfield!(x,f,val)
    end
end
