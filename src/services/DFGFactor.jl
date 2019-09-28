import Base: convert

function convert(::Type{DFGFactorSummary}, f::DFGFactor)
    return DFGFactorSummary(f.label, deepcopy(f.tags), f._internalId, deepcopy(f._variableOrderSymbols))
end
