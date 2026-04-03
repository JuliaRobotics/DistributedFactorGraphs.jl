# TODO add whereLabel to get_Bloblets
## ==============================================================================
## Variable Bloblets
## ==============================================================================
"""
    $(SIGNATURES)
"""
function getVariableBloblet(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return getBloblet(getVariable(dfg, var_label), label)
end

"""
    $(SIGNATURES)
"""
function getVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return getBloblets(getVariable(dfg, var_label))
end

"""
    $(SIGNATURES)
"""
function addVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getVariable(dfg, var_label), bloblet)
end

"""
    $(SIGNATURES)
"""
function addVariableBloblets!(dfg::GraphsDFG, var_label::Symbol, bloblets::Vector{Bloblet})
    return addBloblets!(getVariable(dfg, var_label), bloblets)
end

"""
    $(SIGNATURES)
"""
function mergeVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getVariable(dfg, var_label), bloblet)
end

"""
    $(SIGNATURES)
"""
function mergeVariableBloblets!(
    dfg::GraphsDFG,
    var_label::Symbol,
    bloblets::Vector{Bloblet},
)
    return mergeBloblets!(getVariable(dfg, var_label), bloblets)
end

"""
    $(SIGNATURES)
"""
function deleteVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return deleteBloblet!(getVariable(dfg, var_label), label)
end

"""
    $(SIGNATURES)
"""
function deleteVariableBloblets!(dfg::GraphsDFG, var_label::Symbol, labels::Vector{Symbol})
    return deleteBloblets!(getVariable(dfg, var_label), labels)
end

"""
    $(SIGNATURES)
"""
function listVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return listBloblets(getVariable(dfg, var_label))
end

"""
    $(SIGNATURES)
"""
function hasVariableBloblet(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return hasBloblet(getVariable(dfg, var_label), label)
end

## ==============================================================================
## Factor Bloblets
## ==============================================================================
"""
    $(SIGNATURES)
"""
function getFactorBloblet(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return getBloblet(getFactor(dfg, fac_label), label)
end

"""
    $(SIGNATURES)
"""
function getFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return getBloblets(getFactor(dfg, fac_label))
end

"""
    $(SIGNATURES)
"""
function addFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getFactor(dfg, fac_label), bloblet)
end

"""
    $(SIGNATURES)
"""
function addFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, bloblets::Vector{Bloblet})
    return addBloblets!(getFactor(dfg, fac_label), bloblets)
end

"""
    $(SIGNATURES)
"""
function mergeFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getFactor(dfg, fac_label), bloblet)
end

"""
    $(SIGNATURES)
"""
function mergeFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, bloblets::Vector{Bloblet})
    return mergeBloblets!(getFactor(dfg, fac_label), bloblets)
end

"""
    $(SIGNATURES)
"""
function deleteFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return deleteBloblet!(getFactor(dfg, fac_label), label)
end

"""
    $(SIGNATURES)
"""
function deleteFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, labels::Vector{Symbol})
    return deleteBloblets!(getFactor(dfg, fac_label), labels)
end

"""
    $(SIGNATURES)
"""
function listFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return listBloblets(getFactor(dfg, fac_label))
end

"""
    $(SIGNATURES)
"""
function hasFactorBloblet(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return hasBloblet(getFactor(dfg, fac_label), label)
end

##==============================================================================
## Agent Bloblets
##==============================================================================
"""
    $(SIGNATURES)
"""
function getAgentBloblet(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return getBloblet(getAgent(dfg, agentlabel), label)
end
"""
    $(SIGNATURES)
"""
function addAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, bloblet::Bloblet)
    return addBloblet!(getAgent(dfg, agentlabel), bloblet)
end
"""
    $(SIGNATURES)
"""
function mergeAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getAgent(dfg, agentlabel), bloblet)
end
"""
    $(SIGNATURES)
"""
function deleteAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return deleteBloblet!(getAgent(dfg, agentlabel), label)
end
"""
    $(SIGNATURES)
"""
function getAgentBloblets(dfg::GraphsDFG, agentlabel::Symbol)
    return getBloblets(getAgent(dfg, agentlabel))
end
"""
    $(SIGNATURES)
"""
function addAgentBloblets!(dfg::GraphsDFG, agentlabel::Symbol, bloblets::Vector{Bloblet})
    return addBloblets!(getAgent(dfg, agentlabel), bloblets)
end
"""
    $(SIGNATURES)
"""
function mergeAgentBloblets!(dfg::GraphsDFG, agentlabel::Symbol, bloblets::Vector{Bloblet})
    return mergeBloblets!(getAgent(dfg, agentlabel), bloblets)
end
"""
    $(SIGNATURES)
"""
function deleteAgentBloblets!(dfg::GraphsDFG, agentlabel::Symbol, labels::Vector{Symbol})
    return deleteBloblets!(getAgent(dfg, agentlabel), labels)
end
"""
    $(SIGNATURES)
"""
function listAgentBloblets(dfg::GraphsDFG, agentlabel::Symbol)
    return listBloblets(getAgent(dfg, agentlabel))
end
"""
    $(SIGNATURES)
"""
function hasAgentBloblet(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return hasBloblet(getAgent(dfg, agentlabel), label)
end

##==============================================================================
## Graph Bloblets
##==============================================================================
"""
    $(SIGNATURES)
"""
getGraphBloblet(dfg::GraphsDFG, label::Symbol) = getBloblet(dfg.graph, label)
"""
    $(SIGNATURES)
"""
addGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = addBloblet!(dfg.graph, bloblet)
"""
    $(SIGNATURES)
"""
mergeGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = mergeBloblet!(dfg.graph, bloblet)
"""
    $(SIGNATURES)
"""
deleteGraphBloblet!(dfg::GraphsDFG, label::Symbol) = deleteBloblet!(dfg.graph, label)
"""
    $(SIGNATURES)
"""
getGraphBloblets(dfg::GraphsDFG) = getBloblets(dfg.graph)
"""
    $(SIGNATURES)
"""
function addGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet})
    return addBloblets!(dfg.graph, bloblets)
end
"""
    $(SIGNATURES)
"""
function mergeGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet})
    return mergeBloblets!(dfg.graph, bloblets)
end
"""
    $(SIGNATURES)
"""
function deleteGraphBloblets!(dfg::GraphsDFG, labels::Vector{Symbol})
    return deleteBloblets!(dfg.graph, labels)
end
"""
    $(SIGNATURES)
"""
listGraphBloblets(dfg::GraphsDFG) = listBloblets(dfg.graph)
"""
    $(SIGNATURES)
"""
hasGraphBloblet(dfg::GraphsDFG, label::Symbol) = hasBloblet(dfg.graph, label)
