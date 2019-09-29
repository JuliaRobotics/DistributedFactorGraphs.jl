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
dfg
dfg.g.inclist
fieldnames(typeof(dfg.g))
dfg.g.vertices
summ = getSummary(dfg)
summaryGraph = getSummaryGraph(dfg)
ls(summaryGraph)
lsf(summaryGraph)
getVariable(summaryGraph, :a)
getFactor(summaryGraph, :f1)
