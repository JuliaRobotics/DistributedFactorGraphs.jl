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
                                spectral_layout,
                                true)


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

function dfgplot(dfg::MetaGraphsDFG, p::DFGPlotProps = DFGPlotProps())

    nodesize = [has_prop(dfg.g,i,:factor) ?  p.nodesize.fac : p.nodesize.var for i=vertices(dfg.g)]
    if p.drawlabels
        nodelabel = [has_prop(dfg.g,i,:factor) ? "" : string(get_prop(dfg.g,i,:label)) for i=vertices(dfg.g)]
    else
        nodelabel = nothing
    end
    nodefillc = [has_prop(dfg.g,i,:factor) ? p.nodefillc.fac : p.nodefillc.var for i=vertices(dfg.g)]

    gplot(dfg.g, nodelabel=nodelabel, nodesize=nodesize, nodefillc=nodefillc, layout=p.layout)

end

function dfgplot(dfg::AbstractDFG, p::DFGPlotProps = DFGPlotProps())
    # TODO implement convert functions
    @warn "TODO Implement convert"
    ldfg = MetaGraphsDFG{AbstractParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, ldfg, union(getVariableIds(dfg), getFactorIds(dfg)), true)

    dfgplot(ldfg, p)

end

function gplot(dfg::MetaGraphsDFG; keyargs...)
    gplot(dfg.g; keyargs...)
end

function gplot(dfg::LightDFG; keyargs...)
    gplot(dfg.g; keyargs...)
end

end
