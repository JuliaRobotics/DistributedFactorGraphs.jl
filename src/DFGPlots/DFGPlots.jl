module DFGPlots

using Colors
using LightGraphs
using MetaGraphs
using GraphPlot
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


function dfgplot(dfg::LightGraphsDFG)

    nodesize = [has_prop(dfg.g,i,:factor) ? 0.3 : 1.0 for i=vertices(dfg.g)]
    nodelabel = [has_prop(dfg.g,i,:factor) ? "" : string(get_prop(dfg.g,i,:label)) for i=vertices(dfg.g)]
    nodefillc = [has_prop(dfg.g,i,:factor) ? colorant"seagreen" : colorant"cyan3" for i=vertices(dfg.g)]

    gplot(dfg.g, nodelabel=nodelabel, nodesize=nodesize, nodefillc=nodefillc, layout=spectral_layout)

end

function gplot(dfg::LightGraphsDFG; keyargs...)
    gplot(dfg.g; keyargs...)
end

function dfgplot(dfg::AbstractDFG)
    # TODO implement convert functions
    @warn "TODO Implement convert"
    ldfg = LightGraphsDFG{AbstractParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, ldfg, union(getVariableIds(dfg), getFactorIds(dfg)), true)

    nodesize = [has_prop(ldfg.g,i,:factor) ? 0.3 : 1.0 for i=vertices(ldfg.g)]
    nodelabel = [has_prop(ldfg.g,i,:factor) ? "" : string(get_prop(ldfg.g,i,:label)) for i=vertices(ldfg.g)]
    nodefillc = [has_prop(ldfg.g,i,:factor) ? colorant"seagreen" : colorant"cyan3" for i=vertices(ldfg.g)]

    gplot(ldfg.g, nodelabel=nodelabel, nodesize=nodesize, nodefillc=nodefillc, layout=spectral_layout)

end

end
