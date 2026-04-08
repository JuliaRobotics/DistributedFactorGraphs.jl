"""
    $(SIGNATURES)
Plots the structure of the factor graph. GraphMakie must be imported before DistributedFactorGraphs for these functions to be available.
Returns the plot context.

E.g.
```
using GraphMakie
using DistributedFactorGraphs
# ... Make graph...
plotDFG(fg)
```
More information at [GraphMakie.jl](https://github.com/MakieOrg/GraphMakie.jl)
"""
function plotDFG end
