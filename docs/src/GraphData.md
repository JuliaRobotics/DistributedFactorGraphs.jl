# Using Graph Elements

Variables and factors in DistributedFactorGraphs are used for a variety of
different applications. We have tried to compartmentalize the data as much as
possible so that users do not need to dig around to find what they need (it's a work in progress).

There are three fundamental types of data in DFG:
- Variable and factor data (stored in the nodes themselves)
- Offloaded big data elements (keyed in a variable or factor, but stored in another location)
- Graph data (data that is related to the graph itself)

The following is a guideline to using these parameters.

**NOTE**: Some functions are direct accessors to the internal parameters, others are derived functions (e.g. getLabel(v) = v.label). In other cases the accessors are simplified ways to interact with the structures. We recommend using the accessors as the internal structure may change over time.

**NOTE**: Adds in general throw an error if the element already exists. Update will update the element if it exists, otherwise it will add it.

**NOTE**: In general these functions will return an error if the respective element is not found. This is to avoid returning, say, nothing, which will be horribly confusing if you tried `getVariableSolverData(dfg, :a, :b)` and it returned nothing - which was missing, :a or :b, or was there a communication issue? We recommend coding defensively and trapping errors in critical portions of your user code.

**NOTE**: All data is passed by reference, so if you update the returned structure it will update in the graph. The database driver is an exception, and once the variable or factor is updated you need to call update* to persist the changes to the graph.

The following examples make use this data:

```julia
using IncrementalInference
# Create a DFG with default solver parameters using the LightGraphs.jl driver.
dfg = LightDFG{SolverParams}(params=SolverParams())

x0 = addVariable!(dfg, :x0, ContinuousScalar, labels = [:POSE], solvable=1)
x1 = addVariable!(dfg, :x1, ContinuousScalar, labels = [:POSE], solvable=1)
f1 = addFactor!(dfg, [:x0; :x1], LinearConditional(Normal(50.0,2.0)), solvable=1)
```

## Variable and Factor Elements

### Common Elements

#### Labels

Labels are the principle identifier of a variable or factor.

```@docs
getLabel
```

#### Timestamps

Each variable or factor can have a timestamp associated with it.

```@docs
getTimestamp
setTimestamp
```

#### Tags

Tags are a set of symbols that contain identifiers for the variable or factor.

```@docs
listTags
mergeTags!
removeTags!
emptyTags!
```

### Solvable

The solvable flag indicates whether the solver should make use of the variable or factor while solving the graph. This can be used to construct graphs in chunks while solving asynchronously, or for selectively solving portions of the graph.

```@docs
getSolvable
setSolvable!
```

### Variables

#### Soft Type

The soft type is the underlying inference variable type, such as a Pose2.

```@docs
getSofttype
```

#### Packed Parametric Estimates

Solved graphs contain packed parametric estimates for the variables, which are keyed by the solution (the default is saved as :default).

For each PPE structure, there are accessors for getting individual values:

```@docs
getMaxPPE
getMeanPPE
getSuggestedPPE
```

Related functions for getting, adding/updating, and deleting PPE structures:

```@docs
listPPE
getPPE
addPPE!
updatePPE!
deletePPE!
mergePPEs!
```

Example of PPE operations:

```julia
# Add a new PPE of type MeanMaxPPE to :x0
ppe = MeanMaxPPE(:default, [0.0], [0.0], [0.0])
addPPE!(dfg, :x0, ppe)
@show listPPE(dfg, :x0)
# Get the data back - note that this is a reference to above.
v = getPPE(dfg, :x0, :default)
# Delete it
deletePPE!(dfg, :x0, :default)
# Update add it
updatePPE!(dfg, :x0, ppe, :default)
# Update update it
updatePPE!(dfg, :x0, ppe, :default)
# Bulk copy PPE's for x0 and x1
updatePPE!(dfg, [x0], :default)
```

#### Solver Data

Solver data is used by IncrementalInference/RoME/Caesar solver to produce the above PPEs.

Related functions:

```@docs
listVariableSolverData
getVariableSolverData
addVariableSolverData!
updateVariableSolverData!
deleteVariableSolverData!
mergeVariableSolverData!
```

Example of solver data operations:

```julia
# Add new VND of type ContinuousScalar to :x0
# Could also do VariableNodeData(ContinuousScalar())
vnd = VariableNodeData{ContinuousScalar}()
addVariableSolverData!(dfg, :x0, vnd, :parametric)
@show listVariableSolverData(dfg, :x0)
# Get the data back - note that this is a reference to above.
vndBack = getVariableSolverData(dfg, :x0, :parametric)
# Delete it
deleteVariableSolverData!(dfg, :x0, :parametric)
```

#### Small Data

Small data allows you to assign a dictionary to variables. It is a useful way to
keep small amounts of string data in a variable. As it is stored in the graph
itself, large entries will slow the graph down, so if data should exceed a
few bytes/kb, it should rather be saved in bigData.

```@docs
getSmallData
setSmallData!
```

Example:

```julia
setSmallData!(x0, Dict("entry"=>"entry value"))
getSmallData(x0)
```

#### Big Data

### Factors

## Graph-Related Data

DFG can store data in the graph itself (as opposed to inside graph elements).
When you retrieve graphs from a database, this information is carried along. If
you are working with an in-memory graph, the structure is flattened into the
graph itself as `userData`, `robotData`, and `sessionData`.

Graphs reside inside a hierarchy made up in the following way:
- User1
  - Robot1
    - Session1 (the graph itself)
- User2
  - Robot2
  - Robot3
    - Session2
    - Session3

This data can be retrieved with the follow functions:

```@docs
getUserData
getRobotData
getSessionData
```

It can be set using the following functions:

```@docs
setUserData!
setRobotData!
setSessionData!
```

Example of using graph-level data:

```julia
setUserData!(dfg, Dict(:a => "Hello"))
getUserData(dfg)
```
