# Common get and set methods

# NOTE this could be reduced with macros and function generation to even less code.

export getLabel, label
export getTags, setTags!, tags
export getTimestamp, setTimestamp!, timestamp
export getInternalId, internalId


const DataLevel0 = Union{VariableDataLevel0, FactorDataLevel0}
const DataLevel1 = Union{VariableDataLevel1, FactorDataLevel1}
const DataLevel2 = Union{VariableDataLevel2, FactorDataLevel2}


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

Get the timestamp from a DFGFactor object.

DEPRECATED -> use getTimestamp instead.
"""
function timestamp(v::DataLevel1)
    @warn "timestamp deprecated, use getTimestamp instead"
    getTimestamp(v)
end

"""
$SIGNATURES

Set the timestamp of a DFGFactor object.
"""
setTimestamp!(v::DataLevel1, ts::DateTime) = v.timestamp = ts


"""
$SIGNATURES

Return the internal ID for a variable.
"""
getInternalId(v::DataLevel1) = v._internalId

"""
$SIGNATURES

Return the internal ID for a variable.

DEPRECATED, internalId -> getInternalId
"""
function internalId(v::DataLevel1)
    @warn "Deprecated interalId, use getInternalId instead."
    getInternalId(v)
end
