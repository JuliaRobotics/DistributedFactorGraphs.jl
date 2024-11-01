# Introduction

DistributedFactorGraphs.jl provides a flexible factor graph API for use in the [Caesar.jl](https://github.com/JuliaRobotics/Caesar.jl) ecosystem. The package supplies:
* A standardized API for interacting with factor graphs
* Implementations of the API for in-memory and database-driven operation
* Visualization extensions to validate the underlying graph

**Note** this package is still under initial development, and will adopt parts of the functionality currently contained in [IncrementalInference.jl](http://www.github.com/JuliaRobotics/IncrementalInference.jl).

## Installation

DistributedFactorGraphs can be installed from Julia packages using:
```julia
julia> ]add DistributedFactorGraphs
```

## Manual Outline
```@contents
Pages = [
    "index.md"
    "DataStructure.md"
    "BuildingGraphs.md"
    "GraphData.md"
    "DrawingGraphs.md"
    "ref_api.md"
    "func_ref.md"
    "services_ref.md"
    "blob_ref.md"
]
```
