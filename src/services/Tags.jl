# from CommonAccessors.jl
##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------

"""
$SIGNATURES

Return the tags for a Node.
"""
getTags(node) = node.tags

"""
$SIGNATURES

Set the tags for a Node.
"""
function setTags!(node, tags::Union{Vector{Symbol}, Set{Symbol}})
    node.tags !== tags && empty!(node.tags)
    return union!(node.tags, tags)
end

##==============================================================================
## TAGS as a set, list, merge, remove, empty
##==============================================================================

listTags(node) = node.tags
"""
    $SIGNATURES

Merge add tags to a variable or factor (union)
"""
mergeTags!(node, tags::Vector{Symbol}) = union!(node.tags, tags)
"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
removeTags!(node, tags::Vector{Symbol}) = setdiff!(node.tags, tags)
"""
$SIGNATURES

Empty all tags from the node (empty)
"""
emptyTags!(node) = empty!(node.tags)

"""
$SIGNATURES

Return the tags for a variable or factor.
"""

#alias for completeness #TODO keep or remove getTags?
const getTags = listTags

function listVariableTags(dfg::AbstractDFG, sym::Symbol)
    return listTags(getVariable(dfg, sym))
end

function listFactorTags(dfg::AbstractDFG, sym::Symbol)
    return listTags(getFactor(dfg, sym))
end

function listGraphTags(dfg::InMemoryDFGTypes)
    return listTags(dfg.graph)
end

function listAgentTags(dfg::InMemoryDFGTypes)
    return listTags(dfg.agent)
end

function mergeVariableTags!(dfg::AbstractDFG, sym::Symbol, tags)
    v = getVariable(dfg, sym)
    mergeTags!(v, tags)
    mergeVariable!(dfg, v)
    return length(tags)
end

function mergeFactorTags!(dfg::AbstractDFG, sym::Symbol, tags)
    f = getFactor(dfg, sym)
    mergeTags!(f, tags)
    mergeFactor!(dfg, f)
    return length(tags)
end

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

function mergeAgentTags!(dfg::InMemoryDFGTypes, tags)
    mergeTags!(dfg.agent, tags)
    return length(tags)
end

##

function listTags(dfg::AbstractDFG, sym::Symbol)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return getTags(getFnc(dfg, sym))
end

function mergeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return union!(getTags(getFnc(dfg, sym)), tags)
end

function removeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return setdiff!(getTags(getFnc(dfg, sym)), tags)
end

function emptyTags!(dfg::InMemoryDFGTypes, sym::Symbol)
    getFnc = isVariable(dfg, sym) ? getVariable : getFactor
    return empty!(getTags(getFnc(dfg, sym)))
end

##------------------------------------------------------------------------------
## TODO
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTags(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol}; matchAll::Bool = true)
    #
    alltags = listTags(dfg, sym)
    return length(filter(x -> x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTagsNeighbors(
    dfg::AbstractDFG,
    sym::Symbol,
    tags::Vector{Symbol};
    matchAll::Bool = true,
)
    #
    # assume only variables or factors are neighbors
    getNeiFnc = isVariable(dfg, sym) ? getFactor : getVariable
    alltags = union((ls(dfg, sym) .|> x -> getTags(getNeiFnc(dfg, x)))...)
    return length(filter(x -> x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end
