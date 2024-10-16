## ================================================================================
## Deprecated in v0.25
##=================================================================================
@deprecate getSessionBlobEntry(dfg::AbstractDFG, label::Symbol) getGraphBlobEntry(dfg, label)
@deprecate getSessionBlobEntries(args...) getGraphBlobEntries(args...)
@deprecate addSessionBlobEntry!(args...) addGraphBlobEntry!(args...)
@deprecate addSessionBlobEntries!(args...) addGraphBlobEntries!(args...)
@deprecate updateSessionBlobEntry!(args...) updateGraphBlobEntry!(args...)
@deprecate deleteSessionBlobEntry!(args...) deleteGraphBlobEntry!(args...)
@deprecate getRobotBlobEntry(args...) getAgentBlobEntry(args...)
@deprecate getRobotBlobEntries(args...) getAgentBlobEntries(args...)
@deprecate addRobotBlobEntry!(args...) addAgentBlobEntry!(args...)
@deprecate addRobotBlobEntries!(args...) addAgentBlobEntries!(args...)
@deprecate updateRobotBlobEntry!(args...) updateAgentBlobEntry!(args...)
@deprecate deleteRobotBlobEntry!(args...) deleteAgentBlobEntry!(args...)
@deprecate getUserBlobEntry(args...) getAgentBlobEntry(args...)
@deprecate getUserBlobEntries(args...) getAgentBlobEntries(args...)
@deprecate addUserBlobEntry!(args...) addAgentBlobEntry!(args...)
@deprecate addUserBlobEntries!(args...) addAgentBlobEntries!(args...)
@deprecate updateUserBlobEntry!(args...) updateAgentBlobEntry!(args...)
@deprecate deleteUserBlobEntry!(args...) deleteAgentBlobEntry!(args...)
@deprecate listSessionBlobEntries(args...) listGraphBlobEntries(args...)
@deprecate listRobotBlobEntries(args...) listAgentBlobEntries(args...)
@deprecate listUserBlobEntries(args...) listAgentBlobEntries(args...)

@deprecate getRobotData(dfg::AbstractDFG) getAgentMetadata(dfg)
@deprecate getSessionData(dfg::AbstractDFG) getGraphMetadata(dfg)

## ================================================================================
## Deprecated in v0.24
##=================================================================================
@deprecate getBlobEntry(var::AbstractDFGVariable, key::AbstractString) getBlobEntryFirst(
    var,
    Regex(key),
)

@deprecate lsfWho(dfg::AbstractDFG, type::Symbol) lsf(dfg, getfield(Main, type))

## ================================================================================
## Deprecated in v0.23
##=================================================================================
#NOTE free up getNeighbors to return the variables or factors
@deprecate getNeighbors(args...; kwargs...) listNeighbors(args...; kwargs...)

