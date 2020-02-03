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

Set the tags for a node.
"""
function setTags!(f::DataLevel0, tags::Vector{Symbol})
  empty!(f.tags)
  union!(f.tags, tags)
end

"""
$SIGNATURES

Get the timestamp from a DFGFactor object.
"""
getTimestamp(v::DataLevel1) = v.timestamp

"""
$SIGNATURES

Set the timestamp of a DFGFactor object.
Dev note:
Since it is not mutable it has to return a new variable with the updated timestamp.
Use `updateVariable!` to update it in the factor graph.
TODO either this or we should make the field/variable mutable
"""
function setTimestamp(v::DFGVariable, ts::DateTime)
    return DFGVariable(v.label, ts, v.tags, v.ppeDict, v.solverDataDict, v.smallData, v.bigData, v._dfgNodeParams)
end

function setTimestamp(v::DFGVariableSummary, ts::DateTime)
    return DFGVariableSummary(v.label, ts, v.tags, v.estimateDict, v.softtypename, v.bigData, v._internalId)
end

setTimestamp!(f::FactorDataLevel1, ts::DateTime) = f.timestamp = ts

"""
$SIGNATURES

Return the internal ID for a variable.
"""
getInternalId(v::DataLevel2) = v._dfgNodeParams._internalId

getInternalId(v::Union{DFGVariableSummary, DFGFactorSummary}) = v._internalId
