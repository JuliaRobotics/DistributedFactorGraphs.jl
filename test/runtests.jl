using Test
using GraphPlot # For plotting tests
using DistributedFactorGraphs

# Test each interface
apis = [GraphsDFG, MetaGraphsDFG, SymbolDFG, LightDFG]
for api in apis
    @testset "Testing Driver: $(api)" begin
        global testDFGAPI = api
        include("interfaceTests.jl")
    end
end

# Test special cases

@testset "Plotting Tests" begin
    include("plottingTest.jl")
end
