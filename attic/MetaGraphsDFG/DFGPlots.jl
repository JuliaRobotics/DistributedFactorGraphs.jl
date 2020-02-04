"""
    $(SIGNATURES)
Plots the structure of the factor graph. GraphPlot must be imported before DistributedFactoGraphs for these functions to be available.
Returns the plot context.

E.g.
```
using GraphPlot
using DistributedFactorGraphs, DistributedFactorGraphs.DFGPlots
# ... Make graph...
# Using GraphViz plotting
dfgplot(fg)
# Save to PDFG
using Compose
draw(PDF("/tmp/graph.pdf", 16cm, 16cm), dfgplot(fg))
```

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)
"""
function dfgplot(dfg::DistributedFactorGraphs.MetaGraphsDFG, p::DFGPlotProps = DFGPlotProps())
    @info "Deprecated, please use GraphsDFG or LightDFG."
    nodesize = [has_prop(dfg.g,i,:factor) ?  p.nodesize.fac : p.nodesize.var for i=vertices(dfg.g)]
    if p.drawlabels
        nodelabel = [has_prop(dfg.g,i,:factor) ? "" : string(get_prop(dfg.g,i,:label)) for i=vertices(dfg.g)]
    else
        nodelabel = nothing
    end
    nodefillc = [has_prop(dfg.g,i,:factor) ? p.nodefillc.fac : p.nodefillc.var for i=vertices(dfg.g)]

    gplot(dfg.g, nodelabel=nodelabel, nodesize=nodesize, nodefillc=nodefillc, layout=p.layout)

end

function gplot(dfg::DistributedFactorGraphs.MetaGraphsDFG; keyargs...)
    @info "Deprecated, please use GraphsDFG or LightDFG."
    gplot(dfg.g; keyargs...)
end
