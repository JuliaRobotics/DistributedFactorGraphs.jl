# DistributedFactorGraphs.jl

Click on badges to follow links:

Release v0.9 | Release v0.10 | Dev | Coverage | Documentation |
---------|---------|-----|------------|------------|
[![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=release/v0.9)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) | [![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=release/v0.10)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) |  [![Build Status](https://api.travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/DistributedFactorGraphs.jl) <br> [![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/JuliaRobotics/DistributedFactorGraphs.jl.svg)](https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues) | [![Codecov Status](https://codecov.io/gh/JuliaRobotics/DistributedFactorGraphs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaRobotics/DistributedFactorGraphs.jl) <br> [![Percentage of issues still open](https://isitmaintained.com/badge/open/JuliaRobotics/DistributedFactorGraphs.jl.svg)](https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues) | [![docs](https://img.shields.io/badge/DFGDocs-latest-blue.svg)](http://juliarobotics.github.io/DistributedFactorGraphs.jl/latest/) <br> [![docs](https://img.shields.io/badge/CaesarDocs-latest-blue.svg)](http://juliarobotics.github.io/Caesar.jl/latest/)


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

It is recommended to use `IncrementalInference` to create factor graphs as they will be solvable. 
```julia
using DistributedFactorGraphs
using IncrementalInference
```

Both drivers support the same functions, so choose which you want to use when creating your initial DFG. For example:

```julia
# In-memory DFG
# Initialize the default in-memory factor graph with default solver parameters.
dfg = initfg()
# add 2 ContinuousScalar variable types to the new factor graph
addVariable!(dfg, :a, ContinuousScalar)
addVariable!(dfg, :b, ContinuousScalar)
# add a LinearConditional factor
addFactor!(dfg, [:a, :b], LinearConditional(Normal(10.0,1.0)))
```

