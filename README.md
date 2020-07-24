# DistributedFactorGraphs.jl

Release v0.8 | Release v0.9 | Dev | Coverage | DFG Docs | Caesar Docs |
---------|---------|-----|----------|------|------------
[![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=release/v0.8)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) | [![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=release/v0.9)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) |  [![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) | [![Codecov Status](https://codecov.io/gh/JuliaRobotics/DistributedFactorGraphs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaRobotics/DistributedFactorGraphs.jl) | [![docs](https://img.shields.io/badge/docs-latest-blue.svg)](http://juliarobotics.github.io/DistributedFactorGraphs.jl/latest/) | [![docs](https://img.shields.io/badge/docs-latest-blue.svg)](http://juliarobotics.github.io/Caesar.jl/latest/)

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

The in-memory implementation is the default, using LightGraphs.jl.

```julia
using DistributedFactorGraphs
```

Both drivers support the same functions, so choose which you want to use when creating your initial DFG. For example:

```julia
# In-memory DFG
dfg = LightDFG{NoSolverParams}()
addVariable!(dfg, DFGVariable(:a))
addVariable!(dfg, DFGVariable(:b))
addFactor!(dfg, [v1, v2], DFGFactor{Int, :Symbol}(:f1)) # Rather use a RoME-type factor here (e.g. Pose2Pose2) rather than an Int, this is just for demonstrative purposes.
```

