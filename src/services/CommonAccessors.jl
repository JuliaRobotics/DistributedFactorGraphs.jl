##==============================================================================
## Common Accessors
##==============================================================================
# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

# Data levels
const DataLevel0 = Union{VariableDataLevel0, FactorDataLevel0}
const DataLevel1 = Union{VariableDataLevel1, FactorDataLevel1}
const DataLevel2 = Union{VariableDataLevel2, FactorDataLevel2}

##------------------------------------------------------------------------------
## label
##------------------------------------------------------------------------------

"""
$SIGNATURES

Return the label for a DFGNode.
"""
getLabel(v::DataLevel0) = v.label

##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------

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

##------------------------------------------------------------------------------
## timestamp
##------------------------------------------------------------------------------

"""
$SIGNATURES

Get the timestamp of a DFGNode.
"""
getTimestamp(v::DataLevel1) = v.timestamp


"""
    $SIGNATURES

Set the timestamp of a Variable/Factor object in a factor graph.
Note:
Since `timestamp` is not mutable `setTimestamp!` calls `updateVariable!` internally.
See also [`setTimestamp`](@ref)
"""
function setTimestamp!(dfg::AbstractDFG, lbl::Symbol, ts::DateTime)
    if isVariable(dfg, lbl)
        return updateVariable!(dfg, setTimestamp(getVariable(dfg,lbl), ts))
    else
        return updateFactor!(dfg, setTimestamp(getFactor(dfg,lbl), ts))
    end
end



##------------------------------------------------------------------------------
## _internalId
##------------------------------------------------------------------------------

"""
$SIGNATURES

Return the internal ID for DFGNode.
"""
getInternalId(v::DataLevel2) = v._dfgNodeParams._internalId

getInternalId(v::Union{DFGVariableSummary, DFGFactorSummary}) = v._internalId


##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

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

#TODO data level2 for N
"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(node::N, solvable::Int)::Int where N <: DFGNode
  node._dfgNodeParams.solvable = solvable
  return solvable
end


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

Variables or factors may or may not be 'solvable', depending on a user definition.
returns true if `getSolvable` > 0
Related:
- `getSolvable`(@ref)
"""
isSolvable(node::Union{DFGVariable, DFGFactor}) = getSolvable(node) > 0


##------------------------------------------------------------------------------
## solveInProgress
##------------------------------------------------------------------------------

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

#TODO missing set solveInProgress and graph level accessor

isSolveInProgress(node::Union{DFGVariable, DFGFactor}, solvekey::Symbol=:default) = getSolveInProgress(node, solvekey) > 0


##==============================================================================
## Common Layer 2 CRUD and SET
##==============================================================================

##==============================================================================
## TAGS as a set, list, merge, remove, empty
##==============================================================================
"""
$SIGNATURES

Return the tags for a variable or factor.
"""
function listTags(dfg::AbstractDFG, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  getTags(getFnc(dfg, sym))
end
#alias for completeness
listTags(f::DataLevel0) = getTags(f)

"""
    $SIGNATURES

Merge add tags to a variable or factor (union)
"""
function mergeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  union!(getTags(getFnc(dfg, sym)), tags)
end
mergeTags!(f::DataLevel0, tags::Vector{Symbol}) = union!(f.tags, tags)


"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
function removeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  setdiff!(getTags(getFnc(dfg, sym)), tags)
end
removeTags!(f::DataLevel0, tags::Vector{Symbol}) = setdiff!(f.tags, tags)

"""
$SIGNATURES

Empty all tags from the node (empty)
"""
function emptyTags!(dfg::InMemoryDFGTypes, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  empty!(getTags(getFnc(dfg, sym)))
end
emptyTags!(f::DataLevel0) = empty!(f.tags)
