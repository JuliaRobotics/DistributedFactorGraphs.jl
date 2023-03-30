# Drawing Graphs

Graphs can be visualized by using either `GraphPlot` or rendering to .dot files (which can be viewed using xdot).

## GraphPlot  

`GraphPlot` plotting is available if `GraphPlot` is imported before DFG is imported. Install `GraphPlot` using the following command:

```julia
using Pkg
Pkg.add("GraphPlot")
```

Then bring `GraphPlot` in before DFG:

```@example plots; continued = true
using GraphPlot
using DistributedFactorGraphs
```

Any factor graph can then be drawn by calling [`plotDFG`](@ref):

```@example plots
using Cairo # hide
# Construct graph using IIF
using IncrementalInference
# Create graph
dfg = GraphsDFG{SolverParams}(solverParams=SolverParams())
v1 = addVariable!(dfg, :x0, ContinuousScalar, tags = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, tags = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, tags = [:LANDMARK], solvable=1)
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearRelative(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearRelative(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearRelative(Normal(-10.0,5.0)), solvable=1)

# Plot graph
plotDFG(dfg)
```

### Rendering GraphPlot to PDF

The graph can be rendered to PDF, SVG or JPG in the following way by including compose:

```@example plots
using Compose
# lets add another variable and factor and plot it
dfg.solverParams.graphinit = false # hide
addVariable!(dfg, :x2, ContinuousScalar);
addFactor!(dfg, [:x1; :x2], LinearRelative(Normal(50.0,2.0)));
# Save to SVG
draw(SVG("graph.svg", 10cm, 10cm), plotDFG(dfg));
nothing # hide
```
![](graph.svg)


### More Information

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)

## Dot Files

Dot files are a standard format for visualizing graphs and applications such as
xdot are available to view the files. Dot plotting does not require `GraphPlot`
and can be drawn by either:
- Calling [`toDot`](@ref) on any graph to produce a string of the graph
- Calling [`toDotFile`](@ref) on any graph to save it directly to a dotfile

```@example
using DistributedFactorGraphs
# Construct graph using IIF
using IncrementalInference
# Create graph
dfg = GraphsDFG{SolverParams}(solverParams=SolverParams())
v1 = addVariable!(dfg, :x0, ContinuousScalar, tags = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, tags = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, tags = [:LANDMARK], solvable=1)
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearRelative(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearRelative(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearRelative(Normal(-10.0,5.0)), solvable=1)
# Save to dot file
toDotFile(dfg, "/tmp/test.dot")
# Open with xdot
# run(`xdot /tmp/test.dot`)
# nothing # hide
```
