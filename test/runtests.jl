using Test
using DataFrames
using DistributedFactorGraphs
using DistributedFactorGraphs.GraphsJl

# Test Graphs.jl interface
testDFGAPI = GraphsDFG
include("interfaceTests.jl")

# Test other interfaces
