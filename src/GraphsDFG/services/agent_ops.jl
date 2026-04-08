## =============================================================================
## Agent in DFG CRUD
## =============================================================================

"""
    $(SIGNATURES)
"""
function DFG.addAgent!(dfg::GraphsDFG, agent::Agent)
    label = getLabel(agent)
    haskey(refAgents(dfg), label) && throw(LabelExistsError("Agent", label))
    push!(refAgents(dfg), label => agent)
    return agent
end

"""
    $(SIGNATURES)
"""
function DFG.getAgent(dfg::GraphsDFG, label::Symbol)
    agent = get(refAgents(dfg), label, nothing)
    if isnothing(agent)
        available = listAgents(dfg)
        isempty(available) &&
            @info "No agents in graph: `$(getGraphLabel(dfg))`. Use `addAgent!(dfg, Agent(; label=:myAgent))` to add one"
        throw(LabelNotFoundError("Agent", label, available))
    end
    return agent
end

function DFG.getAgents(dfg::GraphsDFG)
    return map(listAgents(dfg)) do label
        return getAgent(dfg, label)
    end
end

"""
    $(SIGNATURES)
"""
function DFG.mergeAgent!(dfg::GraphsDFG, agent::Agent)
    label = getLabel(agent)
    if hasAgent(dfg, label)
        mergeAgent!(refAgents(dfg)[label], agent)
    else
        addAgent!(dfg, agent)
    end
    return 1
end

function DFG.mergeAgents!(dfg::GraphsDFG, agents::Vector{Agent})
    count = 0
    for agent in agents
        count += mergeAgent!(dfg, agent)
    end
    return count
end

"""
    $(SIGNATURES)
"""
function DFG.deleteAgent!(dfg::GraphsDFG, label::Symbol)
    !haskey(refAgents(dfg), label) && return 0
    pop!(refAgents(dfg), label)
    return 1
end

"""
    $(SIGNATURES)
"""
function DFG.listAgents(dfg::GraphsDFG)
    return collect(keys(refAgents(dfg)))
end

"""
    $(SIGNATURES)
"""
function DFG.hasAgent(dfg::GraphsDFG, label::Symbol)
    return haskey(refAgents(dfg), label)
end
