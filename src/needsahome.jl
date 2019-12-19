export buildSubgraphFromLabels!


"""
    $SIGNATURES
Construct a new factor graph object as a subgraph of `dfg <: AbstractDFG` based on the
variable labels `syms::Vector{Symbols}`.

SamC: Can we not just use _copyIntoGraph! for this? Looks like a small refactor to make it work.
Will paste in as-is for now and we can figure it out as we go.

Notes
- Slighly messy internals, but gets the job done -- some room for performance improvement.
Related
getVariableIds
"""
function buildSubgraphFromLabels!(dfg::G,
                                  syms::Vector{Symbol},
                                  destType::Type{<:AbstractDFG}=GraphsDFG; #Which one? I don't have a strong opinion on this.
                                  solvable::Int=0)::G where G <: AbstractDFG

  # data structure for cliq sub graph
  if G <: InMemoryDFGTypes
    #Same type
    cliqSubFg = G(params=getSolverParams(dfg))
  else
    #Default
    cliqSubFg = destType{typeof(getSolverParms(dfg))}(params=getSolverParams(dfg))
  end

  # add a little too many variables (since we need the factors)
  for sym in syms
    getSubgraphAroundNode(dfg, getVariable(dfg, sym), 2, false, cliqSubFg, solvable=solvable)
  end

  # remove excessive variables that were copied by neighbors distance 2
  currVars = getVariableIds(cliqSubFg)
  toDelVars = setdiff(currVars, syms)
  for dv in toDelVars
    # delete any neighboring factors first
    for fc in lsf(cliqSubFg, dv)
      deleteFactor!(cliqSubFg, fc)
    end

    # and the variable itself
    deleteVariable!(cliqSubFg, dv)
  end

  return cliqSubFg
end
