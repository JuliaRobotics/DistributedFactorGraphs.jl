module DFGPlots

using Colors
using Graphs
using GraphPlot
using DocStringExtensions
import GraphPlot: gplot

using DistributedFactorGraphs

import DistributedFactorGraphs.plotDFG

export plotDFG, DFGPlotProps

struct DFGPlotProps
    nodefillc::NamedTuple{(:var, :fac), Tuple{RGB, RGB}}
    nodesize::NamedTuple{(:var, :fac), Tuple{Float64, Float64}}
    shape::NamedTuple{(:var, :fac), Tuple{Symbol, Symbol}} #not upported yet

    layout::Function #spring_layout, spectral_layout
    drawlabels::Bool
end

function DFGPlotProps()
    return DFGPlotProps(
        (var = colorant"seagreen", fac = colorant"cyan3"),
        (var = 1.0, fac = 0.3),
        (var = :box, fac = :elipse),
        spring_layout,
        true,
    )
end

function plotDFG(dfg::GraphsDFG, p::DFGPlotProps = DFGPlotProps())
    nodetypes = [haskey(dfg.g.variables, s) for s in dfg.g.labels]

    nodesize = [isVar ? p.nodesize.var : p.nodesize.fac for isVar in nodetypes]
    # nodelabel = [isVar ? string(get_prop(dfg.g,i,:label)) : "" for (i,isVar) in enumerate(nodetypes)]
    if p.drawlabels
        nodelabel = [nodetypes[i] ? string(s) : "" for (i, s) in enumerate(dfg.g.labels)]
    else
        nodelabel = nothing
    end

    nodefillc = [isVar ? p.nodefillc.var : p.nodefillc.fac for isVar in nodetypes]

    return gplot(
        dfg.g;
        nodelabel = nodelabel,
        nodesize = nodesize,
        nodefillc = nodefillc,
        layout = p.layout,
    )
end

function plotDFG(dfg::AbstractDFG, p::DFGPlotProps = DFGPlotProps())
    # TODO implement convert functions
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg); copyGraphMetadata = false)
    return plotDFG(ldfg, p)
end

function gplot(dfg::GraphsDFG; keyargs...)
    return gplot(dfg.g; keyargs...)
end

end
