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

**NOTE**: In general these functions will return an error if the respective element is not found. This is to avoid returning, say, nothing, which will be horribly confusing if you tried `getState(dfg, :a, :b)` and it returned nothing - which was missing, :a or :b, or was there a communication issue? We recommend coding defensively and trapping errors in critical portions of your user code.

**NOTE**: All data is passed by reference, so if you update the returned structure it will update in the graph. The database driver is an exception, and once the variable or factor is updated you need to call update* to persist the changes to the graph.

The following examples make use of this data:

```julia
using IncrementalInference
# Create a DFG with default solver parameters using the Graphs.jl driver.
dfg = GraphsDFG{SolverParams}(params=SolverParams())

x0 = addVariable!(dfg, :x0, ContinuousScalar, tags = [:POSE], solvable=1)
x1 = addVariable!(dfg, :x1, ContinuousScalar, tags = [:POSE], solvable=1)
f1 = addFactor!(dfg, [:x0; :x1], LinearRelative(Normal(50.0,2.0)), solvable=1)
```

## Variable and Factor Elements

### Common Elements

#### Labels

Labels are the principle identifier of a variable or factor.

- [`getLabel`](@ref)


#### Timestamps

Each variable or factor can have a timestamp associated with it representing when the physical event/observation occurred.

**Time Standard**: Timestamps use UTC-based time (Coordinated Universal Time) via the `TimeDateZone` type, not TAI (International Atomic Time). The key difference is that UTC includes leap seconds to keep synchronized with Earth's rotation, while TAI is a continuous monotonic time scale without leap seconds.

**Timezone Support**: While timestamps default to UTC (`tz"UTC"`), `TimeDateZone` supports any timezone (e.g., `tz"America/New_York"`, `tz"Europe/London"`). The timezone offset is preserved when stored and retrieved.

**Event Time vs Database Time**: The timestamp represents the physical event time (when a sensor measurement was taken, when a robot was at a pose, etc.), not when the variable was added to the database. Database metadata timestamps may be tracked separately by specific backend implementations.

**Temporal Uncertainty**: This single timestamp value is metadata and does not represent temporal uncertainty. For problems where time itself is a state variable requiring inference (e.g., using `SGal3` which includes temporal components), include time as part of your state type rather than relying on this metadata field.  Furthermore, the concept of "ClockPriors" is also at play for the API design changes relating to v2.

**Future**:  changing away from field name `timestamp` was deferred from v1.0 owing to resolution of older complexity of other fields being standardized; however, the desire for a better name exists and should be revisited in the v2 API.  At time of writing, the best summary of the naming debate is captured here: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/1087#issuecomment-3582252305.  In the lead up to a new long term release (a.k.a semver major), a deprecation cycle will be used via semver minors to ensure users have an easy and macro-aided transition in the API.

Related functions:

- [`getTimestamp`](@ref)


#### Tags

Tags are a set of symbols that contain identifiers for the variable or factor.

- [`listTags`](@ref)
- [`mergeTags!`](@ref)
- [`deleteTags!`](@ref)
- [`emptyTags!`](@ref)


### Solvable

The solvable flag indicates whether the solver should make use of the variable or factor while solving the graph. This can be used to construct graphs in chunks while solving asynchronously, or for selectively solving portions of the graph.


- [`getSolvable`](@ref)
- [`setSolvable!`](@ref)


### Variables

#### Variable Type

The `AbstractStateType` is the underlying inference variable type, such as a Pose2.

- [`getStateKind`](@ref)


#### Variable States (Solver Data)

Variable `State`s are used by the IncrementalInference/RoME/Caesar solver.

Related functions:


- [`listStates`](@ref)
- [`getState`](@ref)
- [`addState!`](@ref)
- [`mergeState!`](@ref)
- [`deleteState!`](@ref)
- [`mergeState!`](@ref)


Example of variable `State` operations:

```julia
# Add new VND of type ContinuousScalar to :x0
# Could also do State(ContinuousScalar())
state = State{ContinuousScalar}()
addState!(dfg, :x0, state, :parametric)
@show listStates(dfg, :x0)
# Get the data back - note that this is a reference to above.
stateBack = getState(dfg, :x0, :parametric)
# Delete it
deleteState!(dfg, :x0, :parametric)
```

#### Bloblets

Bloblets allow you to assign a dictionary of key-value [Symbol-String] pairs to nodes. It is a useful way to
keep small amounts of primitive (Strings, Integers, Floats, Bool) data that is stored as a string in a node. As it is stored in the graph
itself, large entries will slow the graph down, so if data should exceed a
few bytes/kb, it should rather be saved in Blobs.


- [`getVariableBloblet`](@ref)
- [`addVariableBloblet!`](@ref)


Example:

```julia
addVariableBloblet!(dfg, :x0, Bloblet(:bloblet_label,"bloblet value"))
getVariableBloblet(dfg, :x0)
```

#### Big Data

### Factors

## Graph-Related Data

DFG can store data in the graph itself (as opposed to inside graph elements).
When you retrieve distributed factor graphs from a database, this information is carried along. If
you are working with an in-memory graph, the DFG structure contains the graph itself as well as
`Agent` and `Graph` data.

Graphs reside inside a hierarchy made up in the following way:
- Agent
  - Bloblets
  - Blobentries
- Graph
  - Bloblets
  - Blobentries

Agent and Graph bloblets are useful for storing data that is related to the entire graph, and support CRUD operations:

- [`getAgentBloblet`](@ref)
- [`getGraphBloblet`](@ref)

- [`addAgentBloblet!`](@ref)
- [`addGraphBloblet!`](@ref)

- [`mergeAgentBloblet!`](@ref)
- [`mergeGraphBloblet!`](@ref)

- [`deleteAgentBloblet!`](@ref)
- [`deleteGraphBloblet!`](@ref)

Example of using graph-level data:

```julia
addAgentBloblet!(dfg, Bloblet(:status, "ready"))
getAgentBloblet(dfg, :status)
```
