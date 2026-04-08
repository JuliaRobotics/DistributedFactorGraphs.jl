# ==============================================================================
# Agent CRUD
# ==============================================================================
"""
    $(SIGNATURES)
Get an agent by label.
"""
function getAgent end

"""
    $(SIGNATURES)
Get all agents in the DFG.
"""
function getAgents end

"""
    $(SIGNATURES)
Add an agent to the DFG.
"""
function addAgent! end

"""
    $(SIGNATURES)
Add multiple agents to the DFG.
"""
function addAgents! end

"""
    $(SIGNATURES)
Merge an agent into the DFG (add or update).
"""
function mergeAgent! end

"""
    $(SIGNATURES)
Merge multiple agents into the DFG.
"""
function mergeAgents! end

"""
    $(SIGNATURES)
Delete an agent by label.
"""
function deleteAgent! end

"""
    $(SIGNATURES)
Delete multiple agents by label.
"""
function deleteAgents! end

"""
    $(SIGNATURES)
List all agent labels in the DFG.
"""
function listAgents end

"""
    $(SIGNATURES)
Check whether an agent with the given label exists.
"""
function hasAgent end
