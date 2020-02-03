# Drawing Graphs

Graphs can be visualized by using either `GraphPlot` or rendering to .dot files (which can be viewed using xdot).

## GraphPlot  

`GraphPlot` plotting is available if `GraphPlot` is imported before DFG is imported. Install `GraphPlot` using the following command:

```julia
using Pkg
Pkg.install("GraphPlot")
```

Then bring `GraphPlot` in before DFG:

```julia
using GraphPlot
using DistributedFactorGraphs
```

Any factor graph can then be drawn by calling `dfgPlot`:

```julia
# Construct graph using IIF
using IncrementalInference
# Create graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())
v1 = addVariable!(dfg, :x0, ContinuousScalar, labels = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, labels = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, labels = [:LANDMARK], solvable=1)
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearConditional(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearConditional(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearConditional(Normal(-10.0,5.0)), solvable=1)

# Plot graph
dfgplot(dfg)
```

![imgs/initialgraph.jpg](imgs/initialgraph.jpg)

```@docs
dfgplot
```

### Rendering GraphPlot to PDF

The graph can be rendered to PDF or JPG in the following way:

```julia
# Save to PDF
using Compose
draw(PDF("/tmp/graph.pdf", 16cm, 16cm), dfgplot(dfg))
```

### More Information

More information at [GraphPlot.jl](https://github.com/JuliaGraphs/GraphPlot.jl)

## Dot Files

Dot files are a standard format for visualizing graphs and applications such as
xdot are available to view the files. Dot plotting does not require `GraphPlot`
and can be drawn by either:
- Calling `toDot` on any graph to produce a string of the graph
- Calling `toDotFile` on any graph to save it directly to a dotfile

```julia
using DistributedFactorGraphs
# Construct graph using IIF
using IncrementalInference
# Create graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())
v1 = addVariable!(dfg, :x0, ContinuousScalar, labels = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, labels = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, labels = [:LANDMARK], solvable=1)
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearConditional(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearConditional(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearConditional(Normal(-10.0,5.0)), solvable=1)
# Save to dot file
toDotFile(dfg, "/tmp/test.dot")
# Open with xdot
run(`xdot /tmp/test.dot`)
```

```@docs
toDot
toDotFile
```
