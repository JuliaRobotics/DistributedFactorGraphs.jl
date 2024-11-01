"""
    $(SIGNATURES)
Plots the structure of the factor graph. GraphPlot must be imported before DistributedFactorGraphs for these functions to be available.
Returns the plot context.

E.g.
```
using GraphPlot
using DistributedFactorGraphs, DistributedFactorGraphs.DFGPlots
# ... Make graph...
# Using GraphViz plotting
plotDFG(fg)
# Save to PDF
using Compose
draw(PDF("/tmp/graph.pdf", 16cm, 16cm), plotDFG(fg))
```

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)
"""
function plotDFG end