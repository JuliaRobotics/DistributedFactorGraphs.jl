# DistributedFactorGraphs.jl

Click on badges to follow links:

| Release v0.16 | Dev | Coverage | Documentation |
|---------------|-----|----------|---------------|
| [![Build Status][dfg-ci-stb-img]][dfg-ci-stb-url] | [![CI][dfg-ci-dev-img]][dfg-ci-dev-url] <br> [![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/JuliaRobotics/DistributedFactorGraphs.jl.svg)](https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues) | [![codecov.io][dfg-cov-img]][dfg-cov-url] <br> [![Percentage of issues still open](https://isitmaintained.com/badge/open/JuliaRobotics/DistributedFactorGraphs.jl.svg)](https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues) | [![docs](https://img.shields.io/badge/DFGDocs-latest-blue.svg)](http://juliarobotics.github.io/DistributedFactorGraphs.jl/latest/) <br> [![docs](https://img.shields.io/badge/CaesarDocs-latest-blue.svg)](http://juliarobotics.github.io/Caesar.jl/latest/)


[dfg-ci-dev-img]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml/badge.svg
[dfg-ci-dev-url]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml
[dfg-ci-stb-img]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml/badge.svg?branch=release%2Fv0.16
[dfg-ci-stb-url]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml
[dfg-cov-img]: https://codecov.io/github/JuliaRobotics/DistributedFactorGraphs.jl/coverage.svg?branch=master
[dfg-cov-url]: https://codecov.io/github/JuliaRobotics/DistributedFactorGraphs.jl?branch=master
[dfg-build-img]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml/badge.svg
[dfg-build-url]: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/actions/workflows/ci.yml

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
# add a LinearRelative factor
addFactor!(dfg, [:a, :b], LinearRelative(Normal(10.0,1.0)))
```

