## ================================================================================
## Deprecated in v0.25
##=================================================================================
@deprecate getSessionBlobEntry(args...) getGraphBlobEntry(args...)
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

@deprecate getUserData(args...) getAgentMetadata(args...)
@deprecate getRobotData(args...) getAgentMetadata(args...)
@deprecate getSessionData(args...) getGraphMetadata(args...)

@deprecate setUserData!(args...) setAgentMetadata!(args...)
@deprecate setRobotData!(args...) setAgentMetadata!(args...)
@deprecate setSessionData!(args...) setGraphMetadata!(args...)

#TODO 
# @deprecate getUserLabel(dfg) getAgentLabel(dfg)
# @deprecate getRobotLabel(dfg) getAgentLabel(dfg)
# @deprecate getSessionLabel(dfg) getGraphLabel(dfg)

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
