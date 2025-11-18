## ==============================================================================
## Variable Bloblets
## ==============================================================================
function getVariableBloblet(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return getBloblet(getVariable(dfg, var_label), label)
end

function getVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return getBloblets(getVariable(dfg, var_label))
end

function addVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getVariable(dfg, var_label), bloblet)
end
function addVariableBloblets!(dfg::GraphsDFG, var_label::Symbol, bloblets::Vector{Bloblet})
    return addBloblets!(getVariable(dfg, var_label), bloblets)
end
function mergeVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getVariable(dfg, var_label), bloblet)
end
function mergeVariableBloblets!(dfg::GraphsDFG, var_label::Symbol, bloblets::Vector{Bloblet})
    return mergeBloblets!(getVariable(dfg, var_label), bloblets)
end
function deleteVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return deleteBloblet!(getVariable(dfg, var_label), label)
end
function deleteVariableBloblets!(dfg::GraphsDFG, var_label::Symbol, labels::Vector{Symbol})
    return deleteBloblets!(getVariable(dfg, var_label), labels)
end
function listVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return listBloblets(getVariable(dfg, var_label))
end

## ==============================================================================
## Factor Bloblets
## ==============================================================================
function getFactorBloblet(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return getBloblet(getFactor(dfg, fac_label), label)
end
function getFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return getBloblets(getFactor(dfg, fac_label))
end
function addFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getFactor(dfg, fac_label), bloblet)
end
function addFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, bloblets::Vector{Bloblet})
    return addBloblets!(getFactor(dfg, fac_label), bloblets)
end
function mergeFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getFactor(dfg, fac_label), bloblet)
end
function mergeFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, bloblets::Vector{Bloblet})
    return mergeBloblets!(getFactor(dfg, fac_label), bloblets)
end
function deleteFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return deleteBloblet!(getFactor(dfg, fac_label), label)
end
function deleteFactorBloblets!(dfg::GraphsDFG, fac_label::Symbol, labels::Vector{Symbol})
    return deleteBloblets!(getFactor(dfg, fac_label), labels)
end
function listFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return listBloblets(getFactor(dfg, fac_label))
end

##==============================================================================
## Agent Bloblets
##==============================================================================

getAgentBloblet(dfg::GraphsDFG, label::Symbol) = getBloblet(dfg.agent, label)
addAgentBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = addBloblet!(dfg.agent, bloblet)
mergeAgentBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = mergeBloblet!(dfg.agent, bloblet)
deleteAgentBloblet!(dfg::GraphsDFG, label::Symbol) = deleteBloblet!(dfg.agent, label)

getAgentBloblets(dfg::GraphsDFG) = getBloblets(dfg.agent)
addAgentBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet}) = addBloblets!(dfg.agent, bloblets)
mergeAgentBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet}) = mergeBloblets!(dfg.agent, bloblets)
deleteAgentBloblets!(dfg::GraphsDFG, labels::Vector{Symbol}) = deleteBloblets!(dfg.agent, labels)
listAgentBloblets(dfg::GraphsDFG) = listBloblets(dfg.agent)

##==============================================================================
## Graph Bloblets
##==============================================================================

getGraphBloblet(dfg::GraphsDFG, label::Symbol) = getBloblet(dfg.graph, label)
addGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = addBloblet!(dfg.graph, bloblet)
mergeGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = mergeBloblet!(dfg.graph, bloblet)
deleteGraphBloblet!(dfg::GraphsDFG, label::Symbol) = deleteBloblet!(dfg.graph, label)

getGraphBloblets(dfg::GraphsDFG) = getBloblets(dfg.graph)
addGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet}) = addBloblets!(dfg.graph, bloblets)
mergeGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet}) = mergeBloblets!(dfg.graph, bloblets)
deleteGraphBloblets!(dfg::GraphsDFG, labels::Vector{Symbol}) = deleteBloblets!(dfg.graph, labels)
listGraphBloblets(dfg::GraphsDFG) = listBloblets(dfg.graph)
