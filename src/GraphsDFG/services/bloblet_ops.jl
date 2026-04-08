# TODO add whereLabel to get_Bloblets

# ==============================================================================
# Agent Bloblets
# ==============================================================================
function DFG.addAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, bloblet::Bloblet)
    return addBloblet!(getAgent(dfg, agentlabel), bloblet)
end

function DFG.addAgentBloblets!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    bloblets::Vector{Bloblet},
)
    return addBloblets!(getAgent(dfg, agentlabel), bloblets)
end

function DFG.getAgentBloblet(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return getBloblet(getAgent(dfg, agentlabel), label)
end

function DFG.getAgentBloblets(dfg::GraphsDFG, agentlabel::Symbol)
    return getBloblets(getAgent(dfg, agentlabel))
end

function DFG.mergeAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getAgent(dfg, agentlabel), bloblet)
end

function DFG.mergeAgentBloblets!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    bloblets::Vector{Bloblet},
)
    return mergeBloblets!(getAgent(dfg, agentlabel), bloblets)
end

function DFG.deleteAgentBloblet!(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return deleteBloblet!(getAgent(dfg, agentlabel), label)
end

function DFG.deleteAgentBloblets!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    labels::Vector{Symbol},
)
    return deleteBloblets!(getAgent(dfg, agentlabel), labels)
end

function DFG.listAgentBloblets(dfg::GraphsDFG, agentlabel::Symbol)
    return listBloblets(getAgent(dfg, agentlabel))
end

function DFG.hasAgentBloblet(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return hasBloblet(getAgent(dfg, agentlabel), label)
end

# ==============================================================================
# Graph Bloblets
# ==============================================================================

DFG.addGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = addBloblet!(dfg.graph, bloblet)

function DFG.addGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet})
    return addBloblets!(dfg.graph, bloblets)
end

DFG.getGraphBloblet(dfg::GraphsDFG, label::Symbol) = getBloblet(dfg.graph, label)

DFG.getGraphBloblets(dfg::GraphsDFG) = getBloblets(dfg.graph)

DFG.mergeGraphBloblet!(dfg::GraphsDFG, bloblet::Bloblet) = mergeBloblet!(dfg.graph, bloblet)

function DFG.mergeGraphBloblets!(dfg::GraphsDFG, bloblets::Vector{Bloblet})
    return mergeBloblets!(dfg.graph, bloblets)
end

DFG.deleteGraphBloblet!(dfg::GraphsDFG, label::Symbol) = deleteBloblet!(dfg.graph, label)

function DFG.deleteGraphBloblets!(dfg::GraphsDFG, labels::Vector{Symbol})
    return deleteBloblets!(dfg.graph, labels)
end

DFG.listGraphBloblets(dfg::GraphsDFG) = listBloblets(dfg.graph)

DFG.hasGraphBloblet(dfg::GraphsDFG, label::Symbol) = hasBloblet(dfg.graph, label)

# ==============================================================================
# Variable Bloblets
# ==============================================================================
function DFG.addVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getVariable(dfg, var_label), bloblet)
end

function DFG.addVariableBloblets!(
    dfg::GraphsDFG,
    var_label::Symbol,
    bloblets::Vector{Bloblet},
)
    return addBloblets!(getVariable(dfg, var_label), bloblets)
end

function DFG.getVariableBloblet(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return getBloblet(getVariable(dfg, var_label), label)
end

function DFG.getVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return getBloblets(getVariable(dfg, var_label))
end

function DFG.mergeVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getVariable(dfg, var_label), bloblet)
end

function DFG.mergeVariableBloblets!(
    dfg::GraphsDFG,
    var_label::Symbol,
    bloblets::Vector{Bloblet},
)
    return mergeBloblets!(getVariable(dfg, var_label), bloblets)
end

function DFG.deleteVariableBloblet!(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return deleteBloblet!(getVariable(dfg, var_label), label)
end

function DFG.deleteVariableBloblets!(
    dfg::GraphsDFG,
    var_label::Symbol,
    labels::Vector{Symbol},
)
    return deleteBloblets!(getVariable(dfg, var_label), labels)
end

function DFG.listVariableBloblets(dfg::GraphsDFG, var_label::Symbol)
    return listBloblets(getVariable(dfg, var_label))
end

function DFG.hasVariableBloblet(dfg::GraphsDFG, var_label::Symbol, label::Symbol)
    return hasBloblet(getVariable(dfg, var_label), label)
end

# ==============================================================================
# Factor Bloblets
# ==============================================================================
function DFG.addFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return addBloblet!(getFactor(dfg, fac_label), bloblet)
end

function DFG.addFactorBloblets!(
    dfg::GraphsDFG,
    fac_label::Symbol,
    bloblets::Vector{Bloblet},
)
    return addBloblets!(getFactor(dfg, fac_label), bloblets)
end

function DFG.getFactorBloblet(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return getBloblet(getFactor(dfg, fac_label), label)
end

function DFG.getFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return getBloblets(getFactor(dfg, fac_label))
end

function DFG.mergeFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, bloblet::Bloblet)
    return mergeBloblet!(getFactor(dfg, fac_label), bloblet)
end

function DFG.mergeFactorBloblets!(
    dfg::GraphsDFG,
    fac_label::Symbol,
    bloblets::Vector{Bloblet},
)
    return mergeBloblets!(getFactor(dfg, fac_label), bloblets)
end

function DFG.deleteFactorBloblet!(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return deleteBloblet!(getFactor(dfg, fac_label), label)
end

function DFG.deleteFactorBloblets!(
    dfg::GraphsDFG,
    fac_label::Symbol,
    labels::Vector{Symbol},
)
    return deleteBloblets!(getFactor(dfg, fac_label), labels)
end

function DFG.listFactorBloblets(dfg::GraphsDFG, fac_label::Symbol)
    return listBloblets(getFactor(dfg, fac_label))
end

function DFG.hasFactorBloblet(dfg::GraphsDFG, fac_label::Symbol, label::Symbol)
    return hasBloblet(getFactor(dfg, fac_label), label)
end
