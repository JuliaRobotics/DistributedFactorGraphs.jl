using Test
using DataFrames
using DistributedFactorGraphs

# Test each interface
apis = [GraphsDFG]
global testDFGAPI = nothing
for api in apis
    global testDFGAPI = api
    include("interfaceTests.jl")
end
# Test other interfaces
