##==============================================================================
## Common Accessors
##==============================================================================

##------------------------------------------------------------------------------
## References to containers
##------------------------------------------------------------------------------

refTags(node) = node.tags
refBlobentries(node) = node.blobentries
refBloblets(node) = node.bloblets

##------------------------------------------------------------------------------
## By value accessors
##------------------------------------------------------------------------------

# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

"""
    $(SIGNATURES)
Get the label of the node.
"""
getLabel(node) = node.label


"""
$SIGNATURES

Get the timestamp of a AbstractGraphNode.
"""
getTimestamp(node) = node.timestamp

"""
    $(SIGNATURES)
"""
getDescription(node) = node.description

##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.  Useful for ensuring atomic transactions.

Related:
- isSolveInProgress
"""
getSolvable(node::Union{VariableDFG, FactorDFG}) = node.solvable[]

"""
    $SIGNATURES

Get 'solvable' parameter for either a variable or factor.
"""
function getSolvable(dfg::AbstractDFG, sym::Symbol)
    if isVariable(dfg, sym)
        return getVariable(dfg, sym).solvable[]
    elseif isFactor(dfg, sym)
        return getFactor(dfg, sym).solvable[]
    end
end

"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(node::Union{VariableDFG, FactorDFG}, solvable::Int)
    node.solvable[] = solvable
    return solvable
end

#FIXME this is only for in memory DFGs
function setSolvable!(dfg::AbstractDFG, sym::Symbol, solvable::Int)
    if isVariable(dfg, sym)
        getVariable(dfg, sym).solvable[] = solvable
    elseif isFactor(dfg, sym)
        getFactor(dfg, sym).solvable[] = solvable
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
isSolvable(node::Union{VariableDFG, FactorDFG}) = getSolvable(node) > 0
