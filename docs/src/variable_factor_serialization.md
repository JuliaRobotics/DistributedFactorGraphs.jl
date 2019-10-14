# Serialization of Variables and Factors

If you are transferring variables and factors over a wire you need to serialize
and deserialize variables and factors.

## Packing and Unpacking

Packing is done with the exposed functions `packVariable()::Dict{String, Any}` and
`packFactor()::Dict{String, Any}`. You can then serialize this into a string or JSON
as you would normally.

> Note: When you deserialize a factor and want to use it for solving, you must call IncrementalInference.rebuildFactorMetadata!(dfgLoadInto, factor) to reinflate it completely. Please review [FileDFG service](src/FileDFG/services/FileDFG.jl) for an example.

For example:
```julia
using DistributedFactorGraphs
using IncrementalInference, RoME

# Make a variable and a factor:
# Make a simple graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())
# Add the first pose :x0
x0 = addVariable!(dfg, :x0, Pose2)
# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(dfg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Now serialize them:
pVariable = packVariable(dfg, x0)
pFactor = packFactor(dfg, prior)

# And we can deserialize them
upVariable = unpackVariable(dfg, pVariable)
# FYI: The graph is used in unpackFactor to find the variables that the factor links to.
upFactor = unpackFactor(dfg, pFactor, IncrementalInference)
# Note, you need to call IncrementalInference.rebuildFactorMetadata!(dfgLoadInto, factor)
# to make it useable. Please add an issue if this poses a problem or causes issues.
```

As a more complex example, we can use JSON2 to stringify the data and write it to a folder of files as FileDFG does:

```julia
using DistributedFactorGraphs
using IncrementalInference, RoME

# Make a variable and a factor:
# Make a simple graph
dfg = GraphsDFG{SolverParams}(params=SolverParams())
# Add the first pose :x0
x0 = addVariable!(dfg, :x0, Pose2)
# Add at a fixed location PriorPose2 to pin :x0 to a starting location (10,10, pi/4)
prior = addFactor!(dfg, [:x0], PriorPose2( MvNormal([10; 10; 1.0/8.0], Matrix(Diagonal([0.1;0.1;0.05].^2))) ) )

# Slightly fancier example: We can use JSON2, we can serialize to a string
varFolder = "/tmp"
for v in getVariables(dfg)
    vPacked = packVariable(dfg, v)
    io = open("$varFolder/$(v.label).json", "w")
    JSON2.write(io, vPacked)
    close(io)
end
# Factors
for f in getFactors(dfg)
    fPacked = packFactor(dfg, f)
    io = open("$folder/factors/$(f.label).json", "w")
    JSON2.write(io, fPacked)
    close(io)
end
```
