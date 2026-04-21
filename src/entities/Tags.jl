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
    n_before = length(refTags(node))
    union!(refTags(node), tags)
    return length(refTags(node)) - n_before
end
"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
function deleteTags!(node, tags)
    n_before = length(refTags(node))
    setdiff!(refTags(node), tags)
    return n_before - length(refTags(node))
end

"""
$SIGNATURES

Empty all tags from the node (empty)
"""
emptyTags!(node) = empty!(refTags(node))

"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags::Vector{Symbol}``.
"""
function hasTags(node, tags::Vector{Symbol})
    return tags ⊆ listTags(node)
end
