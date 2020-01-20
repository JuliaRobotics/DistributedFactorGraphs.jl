export buildSubgraphFromLabels!, buildSubgraphFromLabels!_SPECIAL
export buildSubgraphFromLabels


"""
    $SIGNATURES
Construct a new factor graph object as a subgraph of `dfg <: AbstractDFG` based on the
variable labels `syms::Vector{Symbols}`.

SamC: Can we not just use _copyIntoGraph! for this? Looks like a small refactor to make it work.
Will paste in as-is for now and we can figure it out as we go.

Notes
- Slighly messy internals, but gets the job done -- some room for performance improvement.
- Defaults to GraphDFG, but likely to change to LightDFG in future.

DevNotes
- TODO: still needs to be consolidated with `DFG._copyIntoGraph`

Related

getVariableIds, _copyIntoGraph!
"""
function buildSubgraphFromLabels!(dfg::GSRC,
                                  syms::Vector{Symbol};
                                  subfg::GDST=(GSRC <: InMemoryDFGTypes ? GSRC : GraphsDFG)(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )::GDST where {GSRC <: AbstractDFG, GDST <: AbstractDFG}
  #

  # add a little too many variables (since we need the factors)
  for sym in syms
    if solvable <= getSolvable(dfg, sym)
      getSubgraphAroundNode(dfg, getVariable(dfg, sym), 2, false, subfg, solvable=solvable)
    end
  end

  # remove excessive variables that were copied by neighbors distance 2
  currVars = getVariableIds(subfg)
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

function buildSubgraphFromLabels(dfg::GSRC,
                                  syms::Vector{Symbol};
                                  subfg::GDST=(GSRC <: InMemoryDFGTypes ? GSRC : GraphsDFG)(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )::GDST where {GSRC <: AbstractDFG, GDST <: AbstractDFG}
  #
  @warn "Deprecated buildSubgraphFromLabels, use buildSubgraphFromLabels! instead."
  buildSubgraphFromLabels!(dfg, syms, subfg=subfg, solvable=solvable, allowedFactors=allowedFactors )
end


## KEEPING COMMENT, WANT TO BE CONSOLIDATED WITH FUNCTION ABOVE -- KEEPING ONLY ONE FOR MAINTAINABILITY
## STILL NEEDS TO BE CONSOLIDATED WITH `DFG._copyIntoGraph`
# """
#     $SIGNATURES
#
# IIF clique specific version of building subgraphs.  This is was an unfortunate rewrite of the existing `buildSubgraphFromLabels!` function above.  Currently halfway consolidated.  Tests required to ensure these two functions can be reduced to and will perform the same in both.
#
# DevNotes
# - DF: Could we somehow better consolidate the functionality of this method into `buildSubgraphFromLabels!` above, which in turn should be consolidated as SamC suggests.
# - Since this function has happened more than once, it seems the name `buildSubgraphFromLabels!` might stick around, even if it just becomes a wrapper.
#
# Related
#
# buildSubgraphFromLabels!, _copyIntoGraph!, getVariableIds
# """
# function buildSubgraphFromLabels!_SPECIAL(dfg::G,
#                                           # frontals::Vector{Symbol},
#                                           syms::Vector{Symbol};
#                                           subfg::AbstractDFG=(G <: InMemoryDFGTypes ? G :         GraphsDFG)(params=getSolverParams(dfg)),
#                                           solvable::Int=0,
#                                           allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )::G  where G <: AbstractDFG
#   #
#   # for sym in separators
#   #   (solvable <= getSolvable(dfg, sym)) && DFG.addVariable!(subfg, deepcopy(DFG.getVariable(dfg, sym)))
#   # end
#
#   addfac = Symbol[]
#   for sym in syms # frontals
#     if solvable <= getSolvable(dfg, sym)
#       addVariable!(subfg, deepcopy(getVariable(dfg, sym)))
#       append!(addfac, getNeighbors(dfg, sym, solvable=solvable))
#     end
#   end
#
#   # allowable factors as intersect between connected an user list
#   usefac = allowedFactors == nothing ? addfac : intersect(allowedFactors, addfac)
#
#   allvars = ls(subfg)
#   for sym in usefac
#     fac = getFactor(dfg, sym)
#     vos = fac._variableOrderSymbols
#     #TODO don't add duplicates to start with
#     if !exists(subfg,fac) && (vos ⊆ allvars) && (solvable <= getSolvable(dfg, sym))
#       addFactor!(subfg, fac._variableOrderSymbols, deepcopy(fac))
#     end
#   end
#
#   # remove orphans
#   for fct in getFactors(subfg)
#     # delete any neighboring factors first
#     if length(getNeighbors(subfg, fct)) != length(fct._variableOrderSymbols)
#       deleteFactor!(subfg, fc)
#       @error "deleteFactor! this should not happen"
#     end
#   end
#
#   return subfg
# end
