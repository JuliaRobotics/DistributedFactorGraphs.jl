# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

# Data levels
const DataLevel0 = Union{VariableDataLevel0, FactorDataLevel0}
const DataLevel1 = Union{VariableDataLevel1, FactorDataLevel1}
const DataLevel2 = Union{VariableDataLevel2, FactorDataLevel2}

"""
$SIGNATURES

Return the label for a DFGNode.
"""
getLabel(v::DataLevel0) = v.label

"""
$SIGNATURES

Return the tags for a DFGNode.
"""
getTags(v::DataLevel0) = v.tags


"""
$SIGNATURES

Set the tags for a DFGNode.
"""
function setTags!(f::DataLevel0, tags::Union{Vector{Symbol},Set{Symbol}})
  empty!(f.tags)
  union!(f.tags, tags)
end

"""
$SIGNATURES

Get the timestamp of a DFGNode.
"""
getTimestamp(v::DataLevel1) = v.timestamp


"""
$SIGNATURES

Return the internal ID for DFGNode.
"""
getInternalId(v::DataLevel2) = v._dfgNodeParams._internalId

getInternalId(v::Union{DFGVariableSummary, DFGFactorSummary}) = v._internalId


##

"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.  Useful for ensuring atomic transactions.

Related:
- isSolveInProgress
"""
getSolvable(var::Union{DFGVariable, DFGFactor})::Int = var._dfgNodeParams.solvable
#TODO DataLevel2

"""
    $SIGNATURES

Get 'solvable' parameter for either a variable or factor.
"""
function getSolvable(dfg::AbstractDFG, sym::Symbol)
  if isVariable(dfg, sym)
    return getVariable(dfg, sym)._dfgNodeParams.solvable
  elseif isFactor(dfg, sym)
    return getFactor(dfg, sym)._dfgNodeParams.solvable
  end
end


"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.
returns true if `getSolvable` > 0
Related:
- `getSolvable`(@ref)
"""
isSolvable(node::Union{DFGVariable, DFGFactor}) = getSolvable(node) > 0


"""
    $SIGNATURES

Which variables or factors are currently being used by an active solver.  Useful for ensuring atomic transactions.

DevNotes:
- Will be renamed to `data.solveinprogress` which will be in VND, not DFGNode -- see DFG #201

Related

isSolvable
"""
function getSolveInProgress(var::Union{DFGVariable, DFGFactor}, solveKey::Symbol=:default)::Int
    # Variable
    var isa DFGVariable && return haskey(getSolverDataDict(var), solveKey) ? getSolverDataDict(var)[solveKey].solveInProgress : 0
    # Factor
    return getSolverData(var).solveInProgress
end


isSolveInProgress(node::Union{DFGVariable, DFGFactor}, solvekey::Symbol=:default) = getSolveInProgress(node, solvekey) > 0


"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(dfg::AbstractDFG, sym::Symbol, solvable::Int)::Int
  if isVariable(dfg, sym)
    getVariable(dfg, sym)._dfgNodeParams.solvable = solvable
  elseif isFactor(dfg, sym)
    getFactor(dfg, sym)._dfgNodeParams.solvable = solvable
  end
  return solvable
end

"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(node::N, solvable::Int)::Int where N <: DFGNode
  node._dfgNodeParams.solvable = solvable
  return solvable
end
