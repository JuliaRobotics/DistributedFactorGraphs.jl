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
DistributedFactorGraphs.jl has not been registered yet, and should be installed by cloning this repository:

```julia
Pkg.clone("https://github.com/JuliaRobotics/DistributedFactorGraphs.jl.git")
```

