# ==============================================================================
# Agent Blobentries
# ==============================================================================

function DFG.addAgentBlobentry!(fg::GraphsDFG, agentlabel::Symbol, entry::Blobentry)
    if haskey(fg.agents[agentlabel].blobentries, entry.label)
        throw(LabelExistsError("Blobentry", entry.label))
    end
    push!(fg.agents[agentlabel].blobentries, entry.label => entry)
    return entry
end

function DFG.addAgentBlobentries!(
    fg::GraphsDFG,
    agentlabel::Symbol,
    entries::Vector{Blobentry},
)
    return map(entries) do entry
        return DFG.addAgentBlobentry!(fg, agentlabel, entry)
    end
end

function DFG.getAgentBlobentry(fg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    if !haskey(fg.agents[agentlabel].blobentries, label)
        throw(LabelNotFoundError("Blobentry", label))
    end
    return fg.agents[agentlabel].blobentries[label]
end

function DFG.getAgentBlobentries(
    fg::GraphsDFG,
    agentlabel::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
)
    entries = collect(values(fg.agents[agentlabel].blobentries))
    filterDFG!(entries, whereLabel, getLabel)
    return entries
end

function DFG.mergeAgentBlobentry!(dfg::GraphsDFG, agentlabel::Symbol, entry::Blobentry)
    DFG.refBlobentries(dfg.agents[agentlabel])[getLabel(entry)] = entry
    return 1
end

function DFG.mergeAgentBlobentries!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    entries::Vector{Blobentry},
)
    cnts = map(entries) do entry
        return DFG.mergeAgentBlobentry!(dfg, agentlabel, entry)
    end
    return sum(cnts)
end

function DFG.deleteAgentBlobentry!(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    !haskey(dfg.agents[agentlabel].blobentries, label) && return 0
    delete!(dfg.agents[agentlabel].blobentries, label)
    return 1
end

function DFG.deleteAgentBlobentries!(
    dfg::GraphsDFG,
    agentlabel::Symbol,
    labels::Vector{Symbol},
)
    cnts = map(labels) do label
        return deleteAgentBlobentry!(dfg, agentlabel, label)
    end
    return sum(cnts)
end

function DFG.listAgentBlobentries(fg::GraphsDFG, agentlabel::Symbol)
    return collect(keys(fg.agents[agentlabel].blobentries))
end

function DFG.hasAgentBlobentry(dfg::GraphsDFG, agentlabel::Symbol, label::Symbol)
    return haskey(dfg.agents[agentlabel].blobentries, label)
end

# ==============================================================================
# Graph Blobentries
# ==============================================================================
function DFG.addGraphBlobentry!(fg::GraphsDFG, entry::Blobentry)
    if haskey(fg.graph.blobentries, entry.label)
        throw(LabelExistsError("Blobentry", entry.label))
    end
    push!(fg.graph.blobentries, entry.label => entry)
    return entry
end

function DFG.addGraphBlobentries!(fg::GraphsDFG, entries::Vector{Blobentry})
    return map(entries) do entry
        return DFG.addGraphBlobentry!(fg, entry)
    end
end

function DFG.getGraphBlobentry(fg::GraphsDFG, label::Symbol)
    if !haskey(fg.graph.blobentries, label)
        throw(LabelNotFoundError("GraphBlobentry", label))
    end
    return fg.graph.blobentries[label]
end

function DFG.getGraphBlobentries(
    fg::GraphsDFG;
    whereLabel::Union{Nothing, Function} = nothing,
)
    entries = collect(values(fg.graph.blobentries))
    filterDFG!(entries, whereLabel, getLabel)
    return entries
end

function DFG.mergeGraphBlobentry!(dfg::GraphsDFG, entry::Blobentry)
    DFG.refBlobentries(dfg.graph)[getLabel(entry)] = entry
    return 1
end

function DFG.mergeGraphBlobentries!(dfg::GraphsDFG, entries::Vector{Blobentry})
    cnts = map(entries) do entry
        return DFG.mergeGraphBlobentry!(dfg, entry)
    end
    return sum(cnts)
end

function DFG.deleteGraphBlobentry!(dfg::GraphsDFG, label::Symbol)
    !haskey(dfg.graph.blobentries, label) && return 0
    delete!(dfg.graph.blobentries, label)
    return 1
end

function DFG.deleteGraphBlobentries!(dfg::GraphsDFG, labels::Vector{Symbol})
    cnts = map(labels) do label
        return deleteGraphBlobentry!(dfg, label)
    end
    return sum(cnts)
end

function DFG.listGraphBlobentries(
    fg::GraphsDFG;
    whereLabel::Union{Nothing, Function} = nothing,
)
    labels = collect(keys(fg.graph.blobentries))
    filterDFG!(labels, whereLabel, string)
    return labels
end

function DFG.hasGraphBlobentry(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.graph.blobentries, label)
end

# ==============================================================================
# Variable Blobentries
# ==============================================================================

function DFG.addVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    variable = getVariable(dfg, label)
    DFG.addBlobentry!(variable, entry)
    return entry
end

function DFG.addVariableBlobentries!(
    dfg::GraphsDFG,
    vLbl::Symbol,
    entries::Vector{Blobentry},
)
    addVariableBlobentry!.(dfg, vLbl, entries)
    return entries
end

function DFG.getVariableBlobentry(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return DFG.getBlobentry(getVariable(dfg, variableLabel), label)
end

function DFG.getVariableBlobentries(
    dfg::GraphsDFG,
    variableLabel::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
    whereMultihash::Union{Nothing, Function} = nothing,
)
    return DFG.getBlobentries(getVariable(dfg, variableLabel); whereLabel, whereMultihash)
end

function DFG.mergeVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    return DFG.mergeBlobentry!(getVariable(dfg, label), entry)
end

function DFG.mergeVariableBlobentries!(
    dfg::GraphsDFG,
    vLbl::Symbol,
    entries::Vector{Blobentry},
)
    cnts = map(entries) do entry
        return DFG.mergeVariableBlobentry!(dfg, vLbl, entry)
    end
    return sum(cnts)
end

function DFG.deleteVariableBlobentry!(dfg::GraphsDFG, label::Symbol, entryLabel::Symbol)
    return DFG.deleteBlobentry!(getVariable(dfg, label), entryLabel)
end

function DFG.deleteVariableBlobentries!(
    dfg::GraphsDFG,
    varLabel::Symbol,
    labels::Vector{Symbol},
)
    cnts = map(labels) do label
        return deleteVariableBlobentry!(dfg, varLabel, label)
    end
    return sum(cnts)
end

function DFG.listVariableBlobentries(dfg::GraphsDFG, variableLabel::Symbol)
    return DFG.listBlobentries(getVariable(dfg, variableLabel))
end

function DFG.hasVariableBlobentry(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return DFG.hasBlobentry(getVariable(dfg, variableLabel), label)
end

# ==============================================================================
# Factor Blobentries
# ==============================================================================

function DFG.addFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    factor = getFactor(dfg, label)
    DFG.addBlobentry!(factor, entry)
    return entry
end

function DFG.addFactorBlobentries!(dfg::GraphsDFG, fLbl::Symbol, entries::Vector{Blobentry})
    DFG.addFactorBlobentry!.(dfg, fLbl, entries)
    return entries
end

function DFG.getFactorBlobentry(dfg::GraphsDFG, factorLabel::Symbol, label::Symbol)
    return getBlobentry(getFactor(dfg, factorLabel), label)
end

function DFG.getFactorBlobentries(
    dfg::GraphsDFG,
    factorLabel::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
    whereMultihash::Union{Nothing, Function} = nothing,
)
    return getBlobentries(getFactor(dfg, factorLabel); whereLabel, whereMultihash)
end

function DFG.mergeFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entry::Blobentry)
    return DFG.mergeBlobentry!(getFactor(dfg, label), entry)
end

function DFG.mergeFactorBlobentries!(
    dfg::GraphsDFG,
    fLbl::Symbol,
    entries::Vector{Blobentry},
)
    cnts = map(entries) do entry
        return DFG.mergeFactorBlobentry!(dfg, fLbl, entry)
    end
    return sum(cnts)
end

function DFG.deleteFactorBlobentry!(dfg::GraphsDFG, label::Symbol, entryLabel::Symbol)
    return DFG.deleteBlobentry!(getFactor(dfg, label), entryLabel)
end

function DFG.deleteFactorBlobentries!(
    dfg::GraphsDFG,
    facLabel::Symbol,
    labels::Vector{Symbol},
)
    cnts = map(labels) do label
        return DFG.deleteFactorBlobentry!(dfg, facLabel, label)
    end
    return sum(cnts)
end

function DFG.listFactorBlobentries(dfg::GraphsDFG, factorLabel::Symbol)
    return listBlobentries(getFactor(dfg, factorLabel))
end

function DFG.hasFactorBlobentry(dfg::GraphsDFG, factorLabel::Symbol, label::Symbol)
    return hasBlobentry(getFactor(dfg, factorLabel), label)
end
