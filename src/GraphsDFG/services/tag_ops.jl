# ==============================================================================
# Agent Tags
# ==============================================================================
function DFG.mergeAgentTags!(dfg::GraphsDFG, agentlabel::Symbol, tags)
    return mergeTags!(getAgent(dfg, agentlabel), tags)
end

function DFG.deleteAgentTags!(dfg::GraphsDFG, agentlabel::Symbol, tags)
    return deleteTags!(getAgent(dfg, agentlabel), tags)
end

function DFG.listAgentTags(dfg::GraphsDFG, agentlabel::Symbol)
    return listTags(getAgent(dfg, agentlabel))
end

function DFG.hasAgentTags(dfg::GraphsDFG, agentlabel::Symbol, tags::Vector{Symbol})
    return tags ⊆ listAgentTags(dfg, agentlabel)
end

# ==============================================================================
# Graph Tags
# ==============================================================================
function DFG.mergeGraphTags!(dfg::GraphsDFG, tags)
    return mergeTags!(dfg.graph, tags)
end

function DFG.deleteGraphTags!(dfg::GraphsDFG, tags)
    return deleteTags!(dfg.graph, tags)
end

function DFG.listGraphTags(dfg::GraphsDFG)
    return listTags(dfg.graph)
end

function DFG.hasGraphTags(dfg::GraphsDFG, tags::Vector{Symbol})
    return tags ⊆ listGraphTags(dfg)
end

# ==============================================================================
# Variable Tags
# ==============================================================================
function DFG.mergeVariableTags!(dfg::GraphsDFG, label::Symbol, tags)
    return mergeTags!(getVariable(dfg, label), tags)
end

function DFG.deleteVariableTags!(dfg::GraphsDFG, label::Symbol, tags)
    return deleteTags!(getVariable(dfg, label), tags)
end

function DFG.listVariableTags(dfg::GraphsDFG, sym::Symbol)
    return listTags(getVariable(dfg, sym))
end

function DFG.hasVariableTags(dfg::GraphsDFG, sym::Symbol, tags::Vector{Symbol})
    return tags ⊆ listVariableTags(dfg, sym)
end

# ==============================================================================
# Factor Tags
# ==============================================================================
function DFG.mergeFactorTags!(dfg::GraphsDFG, label::Symbol, tags)
    return mergeTags!(getFactor(dfg, label), tags)
end

function DFG.deleteFactorTags!(dfg::GraphsDFG, label::Symbol, tags)
    return deleteTags!(getFactor(dfg, label), tags)
end

function DFG.listFactorTags(dfg::GraphsDFG, sym::Symbol)
    return listTags(getFactor(dfg, sym))
end

function DFG.hasFactorTags(dfg::GraphsDFG, sym::Symbol, tags::Vector{Symbol})
    return tags ⊆ listFactorTags(dfg, sym)
end
