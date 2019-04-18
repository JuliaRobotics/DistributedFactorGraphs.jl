using Test
using DataFrames
using DistributedFactorGraphs
using DistributedFactorGraphs.GraphsJl

# Test each interface
apis = [GraphsDFG]
global testDFGAPI = nothing
for api in apis
    global testDFGAPI = api
    include("interfaceTests.jl")
end
# Test other interfaces
