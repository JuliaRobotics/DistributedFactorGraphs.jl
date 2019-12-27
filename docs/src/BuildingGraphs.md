# Creating Graphs

In this section constructing DFG graphs will be discussed. To start, bring DistributedFactorGraphs into your workspace:

```julia
using DistributedFactorGraphs
```

We recommend using IncrementalInference (IIF) to populate DFG graphs. DFG provides the structure, but IIF overloads the provided `addVariable!` and `addFactor!` functions and creates solver-specific data that allows the graph to be solved. So although you can use DFG's `addVariable!` and `addFactor!`, it is better to start with IIF's functions so that the graph is solvable.

So for the following examples, IncrementalInference will be used to create the variables and factors. It should be added and imported to run the examples:

```julia
using Pkg
Pkg.add("IncrementalInference")
using IncrementalInference
```

## Initializing a Graph

DFG graphs can be built using various drivers (different representations of the underlying graph). At the moment DFG supports 3 drivers:
- GraphsDFG: An in-memory graph that uses Graphs.jl for representing the graph.
- LightDFG: An in-memory graph that uses LightGraphs.jl for representing the graph.
- CloudGraphs: A database-driven graph that uses Neo4j.jl for interacting with the graph.

In general the first two are used for building and solving graphs, and CloudGraphs is used for persisting in-memory graphs into a database. In the long term we recommend using the LightDFG driver for in-memory operation because Graphs.jl is not actively supported and over time that driver may be deprecated.

To continue the example, run one of the following to create a DFG driver:

### Creating a GraphsDFG Graph

```julia
# Create a DFG with default solver parameters using the Graphs.jl driver.
dfg = GraphsDFG{SolverParams}(params=SolverParams())
```

### Creating a LightDFG Graph

```julia
# Create a DFG with default solver parameters using the LightGraphs.jl driver.
dfg = LightDFG{SolverParams}(params=SolverParams())
```

### Creating a CloudGraphsDFG Graph

```julia
# Create a DFG with no solver parameters (just to demonstrate the difference) using the CloudGraphs driver, and connect it to a local Neo4j instance.
dfg = CloudGraphsDFG{NoSolverParams}("localhost", 7474, "neo4j", "test",
                                "testUser", "testRobot", "testSession",
                                nothing,
                                nothing,
                                IncrementalInference.decodePackedType,
                                IncrementalInference.rebuildFactorMetadata!)
```


## Creating Variables with IIF

Variables are added using IncrementalInference's `addVariable!` function. To create the variable, you provide the following parameters:
- The graph the variable is being added to
- The variable's label (e.g. :x1 or :a)
- The variable type (which is a subtype of InferenceVariable)

In addition, the following optional parameters are provided:
- Additional labels for the variable (in DFG these are referred to as tags)
- A `solvable` flag to indicate whether the variable is ready to be added to a solution

Three variables are added:

```julia
v1 = addVariable!(dfg, :x0, ContinuousScalar, labels = [:POSE], solvable=1)
v2 = addVariable!(dfg, :x1, ContinuousScalar, labels = [:POSE], solvable=1)
v3 = addVariable!(dfg, :l0, ContinuousScalar, labels = [:LANDMARK], solvable=1)
```

### Creating Factors with IIF

Similarly to variables, it is recommended that users start with the IIF implementation of the `addFactor!` functions to create factors. To create the factors, you provide the following parameters:
- The graph the variable is being added to
- The labels for the variables that the factor is linking
- The factor function (which is a subtype of )

Additionally, the solvable flag is also set to indicate that the factor can be used in solving graphs.

**NOTE:** Every graph requires a prior for it to be solvable, so it is a good practice to make sure one is added (generally by adding to the first variable in the graph).

Four factors are added: a prior, a linear conditional relationship with a normal distribution between x0 and x1, and a pair of linear conditional relationships between each pose and the landmark.

```julia
prior = addFactor!(dfg, [:x0], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:x0; :x1], LinearConditional(Normal(50.0,2.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x0], LinearConditional(Normal(40.0,5.0)), solvable=1)
f1 = addFactor!(dfg, [:l0; :x1], LinearConditional(Normal(-10.0,5.0)), solvable=1)
```
