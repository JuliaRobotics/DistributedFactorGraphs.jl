# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

"""
$SIGNATURES

Return the label for a variable or factor.
"""
getLabel(v::DataLevel0) = v.label

"""
$SIGNATURES

Return the tags for a variable.
"""
getTags(v::DataLevel0) = v.tags


"""
$SIGNATURES

Set the tags for a factor.
"""
function setTags!(f::DataLevel0, tags::Vector{Symbol})
  resize!(f.tags, length(tags))
  f.tags .= tags
end

"""
$SIGNATURES

Get the timestamp from a DFGFactor object.
"""
getTimestamp(v::DataLevel1) = v.timestamp

"""
$SIGNATURES

Set the timestamp of a DFGFactor object.
"""
setTimestamp!(v::DataLevel1, ts::DateTime) = v.timestamp = ts

"""
$SIGNATURES

Return the internal ID for a variable.
"""
getInternalId(v::DataLevel1) = v._dfgNodeParams._internalId
