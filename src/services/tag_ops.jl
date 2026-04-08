# ==============================================================================
#  Tag CRUD — Agent
# ==============================================================================

"""
    $(SIGNATURES)
Merge `tags` into an agent's tag set (union).
"""
function mergeAgentTags! end

"""
    $(SIGNATURES)
Remove `tags` from an agent's tag set (setdiff).
"""
function deleteAgentTags! end

"""
    $(SIGNATURES)
List all tags on an agent.
"""
function listAgentTags end

"""
    $(SIGNATURES)
Check whether an agent has all of the given `tags`.
"""
function hasAgentTags end

# ==============================================================================
#  Tag CRUD — Graph
# ==============================================================================

"""
    $(SIGNATURES)
Merge `tags` into the graph-root tag set (union).
"""
function mergeGraphTags! end

"""
    $(SIGNATURES)
Remove `tags` from the graph-root tag set (setdiff).
"""
function deleteGraphTags! end

"""
    $(SIGNATURES)
List all tags on the graph root.
"""
function listGraphTags end

"""
    $(SIGNATURES)
Check whether the graph root has all of the given `tags`.
"""
function hasGraphTags end

# ==============================================================================
#  Tag CRUD — Variable
# ==============================================================================

"""
    $(SIGNATURES)
Merge `tags` into a variable's tag set (union).
"""
function mergeVariableTags! end

"""
    $(SIGNATURES)
Remove `tags` from a variable's tag set (setdiff).
"""
function deleteVariableTags! end

"""
    $(SIGNATURES)
List all tags on a variable.
"""
function listVariableTags end

"""
    $(SIGNATURES)
Check whether a variable has all of the given `tags`.
"""
function hasVariableTags end

# ==============================================================================
#  Tag CRUD — Factor
# ==============================================================================

"""
    $(SIGNATURES)
Merge `tags` into a factor's tag set (union).
"""
function mergeFactorTags! end

"""
    $(SIGNATURES)
Remove `tags` from a factor's tag set (setdiff).
"""
function deleteFactorTags! end

"""
    $(SIGNATURES)
List all tags on a factor.
"""
function listFactorTags end

"""
    $(SIGNATURES)
Check whether a factor has all of the given `tags`.
"""
function hasFactorTags end

# ==============================================================================
#  Generic
# ==============================================================================

# TODO deprecate in favor of explicit listVariableTags, and listFactorTags. 
# Only used in GraphsDFG listNeighborhood whereTags filter.
function listTags(dfg::AbstractDFG, sym::Symbol)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return listTags(getFnc(dfg, sym))
end
