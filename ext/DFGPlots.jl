module DFGPlots

using Colors
using Graphs
using DocStringExtensions
using GraphMakie

using DistributedFactorGraphs

import DistributedFactorGraphs: plotDFG
import GraphMakie: graphplot

export plotDFG, DFGPlotProps

struct DFGPlotProps
    nodefillc::NamedTuple{(:var, :fac), Tuple{RGB, RGB}}
    nodesize::NamedTuple{(:var, :fac), Tuple{Float64, Float64}}
    shape::NamedTuple{(:var, :fac), Tuple{Symbol, Symbol}} #not upported yet

    layout::Any #FIXME add layout type
    drawlabels::Bool
end

function DFGPlotProps()
    return DFGPlotProps(
        (var = colorant"lightgreen", fac = colorant"cyan3"),
        (var = 50.0, fac = 20.0),
        (var = :circle, fac = :rect),
        GraphMakie.Stress(),
        true,
    )
end

function plotDFG(dfg::GraphsDFG; p::DFGPlotProps = DFGPlotProps(), interactive::Bool = true)
    nodetypes = [haskey(dfg.g.variables, s) for s in dfg.g.labels]

    nodesize = [isVar ? p.nodesize.var : p.nodesize.fac for isVar in nodetypes]
    # nodelabel = [isVar ? string(get_prop(dfg.g,i,:label)) : "" for (i,isVar) in enumerate(nodetypes)]
    if p.drawlabels
        ilabels = [nodetypes[i] ? string(s) : "" for (i, s) in enumerate(dfg.g.labels)]
    else
        ilabels = nothing
    end

    node_color = [isVar ? p.nodefillc.var : p.nodefillc.fac for isVar in nodetypes]
    marker = [isVar ? p.shape.var : p.shape.fac for isVar in nodetypes]

    figaxpl = graphplot(
        dfg.g;
        ilabels,
        layout = p.layout,
        node_size = nodesize,
        node_color,
        node_attr = (marker = marker,),
    )

    (f, ax, p) = figaxpl

    label_text = GraphMakie.text!(
        ax,
        0,
        0;
        text = "",
        font = :bold,
        fontsize = 30,
        glowcolor = (:white, 1),
        glowwidth = 3,
    )

    ax.aspect = GraphMakie.DataAspect()
    if interactive
        function node_drag_action(state, idx, event, axis)
            p[:node_pos][][idx] = event.data
            return p[:node_pos][] = p[:node_pos][]
        end
        GraphMakie.hidedecorations!(ax)
        GraphMakie.hidespines!(ax)
        ndrag = NodeDragHandler(node_drag_action)
        GraphMakie.deregister_interaction!(ax, :rectanglezoom)
        GraphMakie.register_interaction!(ax, :ndrag, ndrag)

        function node_hover_action(state, idx, event, axis)
            label = dfg.g.labels[idx]
            label_text.text[] = state ? string(label) : ""
            return label_text.transformation.translation[] = (event.data..., 0)
        end
        nhover = NodeHoverHandler(node_hover_action)
        GraphMakie.register_interaction!(ax, :nhover, nhover)
    end
    return figaxpl
end

function plotDFG(dfg::AbstractDFG, p::DFGPlotProps = DFGPlotProps())
    # TODO implement convert functions
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg); copyGraphMetadata = false)
    return plotDFG(ldfg, p)
end

function graphplot(dfg::GraphsDFG; keyargs...)
    return graphplot(dfg.g; keyargs...)
end

end
