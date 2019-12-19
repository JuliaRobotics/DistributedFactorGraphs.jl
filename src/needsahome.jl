export buildSubgraphFromLabels!


"""
    $SIGNATURES
Construct a new factor graph object as a subgraph of `dfg <: AbstractDFG` based on the
variable labels `syms::Vector{Symbols}`.

SamC: Can we not just use _copyIntoGraph! for this? Looks like a small refactor to make it work.
Will paste in as-is for now and we can figure it out as we go.

Notes
- Slighly messy internals, but gets the job done -- some room for performance improvement.
- Defaults to GraphDFG, but likely to change to LightDFG in future.

Related

getVariableIds, _copyIntoGraph!
"""
function buildSubgraphFromLabels!(dfg::G,
                                  syms::Vector{Symbol},
                                  destType::Type{<:AbstractDFG}=GraphsDFG;
                                  solvable::Int=0)::G where G <: AbstractDFG
  #
  #Same type
  LocalGraphType = G <: InMemoryDFGTypes ? G : destType{typeof(getSolverParms(dfg))}
  # data structure for cliq sub graph
  cliqSubFg = LocalGraphType(params=getSolverParams(dfg))

  # add a little too many variables (since we need the factors)
  for sym in syms
    if solvable <= getSolvable(dfg, sym)
      getSubgraphAroundNode(dfg, getVariable(dfg, sym), 2, false, cliqSubFg, solvable=solvable)
    end
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


"""
    $SIGNATURES

IIF clique specific version of building subgraphs.

Notes
- Special snowflake that adds only factors related to `frontals`.

DevNotes
- DF: Could we somehow better consolidate the functionality of this method into `buildSubgraphFromLabels!` above, which in turn should be consolidated as SamC suggests.
- Since this function has happened more than once, it seems the name `buildSubgraphFromLabels!` might stick around, even if it just becomes a wrapper.

Related

_copyIntoGraph!
"""
function buildSubgraphFromLabels!(dfg::AbstractDFG,
                                  cliqSubFg::AbstractDFG,
                                  frontals::Vector{Symbol},
                                  separators::Vector{Symbol};
                                  solvable::Int=0)
  #
  for sym in separators
    (solvable <= getSolvable(dfg, sym)) && DFG.addVariable!(cliqSubFg, deepcopy(DFG.getVariable(dfg, sym)))
  end

  addfac = Symbol[]
  for sym in frontals
    if solvable <= getSolvable(dfg, sym)
      DFG.addVariable!(cliqSubFg, deepcopy(DFG.getVariable(dfg, sym)))
      append!(addfac, getNeighbors(dfg,sym))
    end
  end

  allvars = ls(cliqSubFg)
  for sym in addfac
    fac = DFG.getFactor(dfg, sym)
    vos = fac._variableOrderSymbols
    #TODO don't add duplicates to start with
    if !exists(cliqSubFg,fac) && vos ⊆ allvars && solvable <= getSolvable(dfg, sym)
      DFG.addFactor!(cliqSubFg, fac._variableOrderSymbols, deepcopy(fac))
    end
  end

  # remove orphans
  for fct in DFG.getFactors(cliqSubFg)
    # delete any neighboring factors first
    if length(getNeighbors(cliqSubFg, fct)) != length(fct._variableOrderSymbols)
      DFG.deleteFactor!(cliqSubFg, fc)
      @error "deleteFactor! this should not happen"
    end
  end

  return cliqSubFg
end
