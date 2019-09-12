
function convert(::DFGFactorSummary, v::DFGFactor)
    return DFGFactorSummary(v.label, deepcopy(v.tags), v._internalId, deepcopy(_variableOrderSymbols))
end
