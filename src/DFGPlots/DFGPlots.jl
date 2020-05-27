module DFGPlots

using Colors
using LightGraphs
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
                                spring_layout,
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
# Save to PDF
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
# Save to PDF
using Compose
draw(PDF("/tmp/graph.pdf", 16cm, 16cm), dfgplot(fg))
```

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)
"""
function dfgplot(dfg::AbstractDFG, p::DFGPlotProps = DFGPlotProps())
    # TODO implement convert functions
    ldfg = LightDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg), copyGraphMetadata=false)
    dfgplot(ldfg, p)
end

function gplot(dfg::LightDFG; keyargs...)
    gplot(dfg.g; keyargs...)
end


#TODO decide if we want to overload show for display in juno, It's a bit annoying with development
# function Base.show(io::IO, ::MIME"application/prs.juno.plotpane+html", dfg::AbstractDFG)
function dfgplot(io::IO, ::MIME"application/prs.juno.plotpane+html", dfg::AbstractDFG)

    if length(ls(dfg)) != 0
        size = get(io, :juno_plotsize, [100, 100])

        plot_output = IOBuffer()
        GraphPlot.draw(GraphPlot.SVGJS(plot_output, GraphPlot.Compose.default_graphic_width,
                   GraphPlot.Compose.default_graphic_width, false), dfgplot(dfg))
        plotsvg = String(take!(plot_output))

        print(io,
            """
                <div style="
                background-color: #eee;
                color: #222;
                width: $(size[1]-40)px;
                height: $(size[2]-40)px;
                position: absolute;
                top: 0;
                left: 0;
                padding: 20px;
                margin: 0;
                ">
                $(typeof(dfg))
                <ul>
                    <li>$(dfg.userId)</li>
                    <li>$(dfg.robotId)</li>
                    <li>$(dfg.sessionId)</li>
                    <li>$(dfg.description)</li>
                </ul>
                <script charset="utf-8">
                    $(read(GraphPlot.Compose.snapsvgjs, String))
                </script>
                <script charset="utf-8">
                    $(read(GraphPlot.gadflyjs, String))
                </script>
                $(plotsvg)
                </div>
            """)
    else
         Base.show(io,  dfg)
    end

end


end
