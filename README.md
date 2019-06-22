# DistributedFactorGraphs.jl

[![Build Status](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl)
[![Coverage Status](https://img.shields.io/coveralls/JuliaRobotics/DistributedFactorGraphs.jl.svg)](https://coveralls.io/r/JuliaRobotics/DistributedFactorGraphs.jl?branch=master)
[![docs](https://img.shields.io/badge/docs-latest-blue.svg)](http://juliarobotics.github.io/DistributedFactorGraphs.jl/latest/)

DistributedFactorGraphs.jl provides a flexible factor graph API for use in the [Caesar.jl](https://github.com/JuliaRobotics/Caesar.jl) ecosystem. The package supplies:
* A standardized API for interacting with factor graphs
* Implementations of the API for in-memory and database-driven operation
* Visualization extensions to validate the underlying graph

**Note** this package is still under initial development, and will adopt parts of the functionality currently contained in [IncrementalInference.jl](http://www.github.com/JuliaRobotics/IncrementalInference.jl).

# Documentation
Please see the [documentation](http://juliarobotics.github.io/DistributedFactorGraphs.jl/latest/) and the [unit tests](https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/tree/master/test) for examples on using DistributedFactorGraphs.jl.

# Installation
DistributedFactorGraphs can be installed from Julia packages using:
```julia
add DistributedFactorGraphs
```

# Usage
DistributedFactorGraphs (DFG) currently supports two implementations:
* An in-memory factor graph based on Graphs.jl
* A Neo4j-based factor graph based on Neo4j.jl

The in-memory implementation is the default. The Neo4j driver can be enabled by importing Neo4j before DFG:

```julia
# To enable the Neo4j driver, import Neo4j.jl first
using Neo4j
using DistributedFactorGraphs
```

Both drivers support the same functions, so choose which you want to use when creating your initial DFG. For example:

```julia
# In-memory DFG
dfg = GraphsDFG{NoSolverParams}()
addVariable!(dfg, DFGVariable(:a))
addVariable!(dfg, DFGVariable(:b))
addFactor!(dfg, [v1, v2], DFGFactor{Int, :Symbol}(:f1)) # Rather use a RoME-type factor here (e.g. Pose2Pose2) rather than an Int, this is just for demonstrative purposes.
```

```julia
# Neo4j-based DFG
dfg = CloudGraphsDFG{NoSolverParams}("localhost", 7474, "neo4j", "test",
      "testUser", "testRobot", "testSession",
      nothing,
      nothing,
      IncrementalInference.decodePackedType)
addVariable!(dfg, DFGVariable(:a))
addVariable!(dfg, DFGVariable(:b))
addFactor!(dfg, [v1, v2], DFGFactor{Int, :Symbol}(:f1)) # Rather use a RoME-type factor here (e.g. Pose2Pose2) rather than an Int, this is just for demonstrative purposes.
```

Please see the documentation for more information on interacting with the factor graph.

## Setting up a Quick Neo4j Database
The simplest way to set up a test database is with Docker.

To pull the Neo4j image:
```bash
docker pull neo4j
```

To run the image with user `neo4j` and password `test`:

```bash
docker run --publish=7474:7474 --publish=7687:7687 --env NEO4J_AUTH=neo4j/test neo4j
```
