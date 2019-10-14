module DFGPlots

using Colors
using LightGraphs
using MetaGraphs
using GraphPlot
using DocStringExtensions
import GraphPlot: gplot

using ...DistributedFactorGraphs

export
    dfgplot,
    DFGPlotProps

struct DFGPlotProps
    nodefillc::NamedTuple{(:var,:fac),Tuple{RGB,RGB}}
    nodesize::NamedTuple{(:var,:fac),Tuple{Float64,Float64}}
    shape::NamedTuple{(:var,:fac),Tuple{Symbol,Symbol}} #not upported yet

    layout::Function #spring_layout, spectral_layout
    drawlabels::Bool
end

DFGPlotProps() = DFGPlotProps(  (var=colorant"seagreen", fac=colorant"cyan3"),
                                (var=1.0, fac=0.3),
                                (var=:box, fac=:elipse),
                                spectral_layout,
                                true)



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
dfgplot(fg)
# Save to PDFG
using Compose
draw(PDF("/tmp/graph.pdf", 16cm, 16cm), dfgplot(fg))
```

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)
"""
function dfgplot(dfg::LightDFG, p::DFGPlotProps = DFGPlotProps())

    nodetypes = [haskey(dfg.g.variables, s) for s in dfg.g.labels]

    nodesize = [isVar ? p.nodesize.var : p.nodesize.fac for isVar in nodetypes]
    # nodelabel = [isVar ? string(get_prop(dfg.g,i,:label)) : "" for (i,isVar) in enumerate(nodetypes)]
    if p.drawlabels
        nodelabel = [nodetypes[i] ? string(s) : "" for (i,s) in enumerate(dfg.g.labels)]
    else
        nodelabel = nothing
    end

    nodefillc = [isVar ? p.nodefillc.var : p.nodefillc.fac for isVar in nodetypes]

    gplot(dfg.g, nodelabel=nodelabel, nodesize=nodesize, nodefillc=nodefillc, layout=p.layout)

end

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
function dfgplot(dfg::AbstractDFG, p::DFGPlotProps = DFGPlotProps())
    # TODO implement convert functions
    @warn "TODO Implement convert"
    ldfg = LightDFG{AbstractParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, ldfg, union(getVariableIds(dfg), getFactorIds(dfg)), true)

    dfgplot(ldfg, p)
end

function gplot(dfg::DistributedFactorGraphs.MetaGraphsDFG; keyargs...)
    @info "Deprecated, please use GraphsDFG or LightDFG."
    gplot(dfg.g; keyargs...)
end

function gplot(dfg::LightDFG; keyargs...)
    gplot(dfg.g; keyargs...)
end

end
