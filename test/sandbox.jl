using Revise
using DistributedFactorGraphs

dfg = GraphsDFG{NoSolverParams}()
v1 = DFGVariable(:a)
v2 = DFGVariable(:b)
v3 = DFGVariable(:c)
f1 = DFGFactor{Int, :Symbol}(:f1)
f2 = DFGFactor{Int, :Symbol}(:f2)
addVariable!(dfg, v1)
addVariable!(dfg, v2)
addVariable!(dfg, v3)
addFactor!(dfg, [v1, v2], f1)
addFactor!(dfg, [:b, :c], f2)

getSummary(dfg)
# getSummaryGraph(dfg)

import Base: convert
function convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.estimateDict), v._internalId)
end

function convert(::Type{DFGFactorSummary}, f::DFGFactor)
    return DFGFactorSummary(f.label, deepcopy(f.tags), f._internalId, deepcopy(f._variableOrderSymbols))
end


v = convert(DFGVariableSummary, v1)
convert(DFGFactorSummary, f1)
