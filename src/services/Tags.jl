# from CommonAccessors.jl
##==============================================================================
## TAGS as a set -- list, merge, delete, (empty?)
##==============================================================================
# Node level functions (in-memory)
"""
$SIGNATURES
"""
listTags(node) = collect(refTags(node))

"""
    $SIGNATURES

Merge add tags to a variable or factor (union)
"""
function mergeTags!(node, tags)
    union!(refTags(node), tags)
    return length(tags)
end
"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
function deleteTags!(node, tags)
    setdiff!(refTags(node), tags)
    return length(tags)
end

"""
$SIGNATURES

Empty all tags from the node (empty)
"""
emptyTags!(node) = empty!(refTags(node))

# DFG level functions
##==============================================================================

"""
$SIGNATURES

List the tags for a variable.
"""
function listVariableTags(dfg::AbstractDFG, sym::Symbol)
    return listTags(getVariable(dfg, sym))
end

function listFactorTags(dfg::AbstractDFG, sym::Symbol)
    return listTags(getFactor(dfg, sym))
end

function listGraphTags(dfg::InMemoryDFGTypes)
    return listTags(dfg.graph)
end

function listAgentTags(dfg::InMemoryDFGTypes, agentlabel::Symbol)
    return listTags(getAgent(dfg, agentlabel))
end

# function mergeVariableTags!(dfg::AbstractDFG, sym::Symbol, tags)
#     v = getVariable(dfg, sym)
#     mergeTags!(v, tags)
#     mergeVariable!(dfg, v)
#     return length(tags)
# end

# function mergeFactorTags!(dfg::AbstractDFG, sym::Symbol, tags)
#     f = getFactor(dfg, sym)
#     mergeTags!(f, tags)
#     mergeFactor!(dfg, f)
#     return length(tags)
# end

function mergeVariableTags!(dfg::InMemoryDFGTypes, label::Symbol, tags)
    return mergeTags!(getVariable(dfg, label), tags)
end

function mergeFactorTags!(dfg::InMemoryDFGTypes, label::Symbol, tags)
    return mergeTags!(getFactor(dfg, label), tags)
end

function mergeGraphTags!(dfg::InMemoryDFGTypes, tags)
    mergeTags!(dfg.graph, tags)
    return length(tags)
end

function mergeAgentTags!(dfg::InMemoryDFGTypes, agentlabel::Symbol, tags)
    mergeTags!(getAgent(dfg, agentlabel), tags)
    return length(tags)
end

##------------------------------------------------------------------------------

function deleteVariableTags!(dfg::InMemoryDFGTypes, label::Symbol, tags)
    return deleteTags!(getVariable(dfg, label), tags)
end

function deleteFactorTags!(dfg::InMemoryDFGTypes, label::Symbol, tags)
    return deleteTags!(getFactor(dfg, label), tags)
end

function deleteGraphTags!(dfg::InMemoryDFGTypes, tags)
    deleteTags!(dfg.graph, tags)
    return length(tags)
end

function deleteAgentTags!(dfg::InMemoryDFGTypes, agentlabel::Symbol, tags)
    deleteTags!(getAgent(dfg, agentlabel), tags)
    return length(tags)
end

##------------------------------------------------------------------------------

function hasVariableTags(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol})
    return tags ⊆ listVariableTags(dfg, sym)
end

function hasFactorTags(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol})
    return tags ⊆ listFactorTags(dfg, sym)
end

function hasGraphTags(dfg::AbstractDFG, tags::Vector{Symbol})
    return tags ⊆ listGraphTags(dfg)
end

function hasAgentTags(dfg::AbstractDFG, agentlabel::Symbol, tags::Vector{Symbol})
    return tags ⊆ listAgentTags(dfg, agentlabel)
end

##
function listTags(dfg::AbstractDFG, sym::Symbol)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return listTags(getFnc(dfg, sym))
end

function mergeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    union!(refTags(getFnc(dfg, sym)), tags)
    return length(tags)
end

function deleteTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    setdiff!(refTags(getFnc(dfg, sym)), tags)
    return length(tags)
end

function emptyTags!(dfg::InMemoryDFGTypes, sym::Symbol)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return empty!(refTags(getFnc(dfg, sym)))
end

##------------------------------------------------------------------------------
## TODO
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags::Vector{Symbol}``.
"""
function hasTags(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol})
    return tags ⊆ listTags(dfg, sym)
end
