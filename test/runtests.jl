using Test
using DistributedFactorGraphs

# Test each interface
apis = [GraphsDFG, MetaGraphsDFG, SymbolDFG, LightDFG]
for api in apis
    @testset "Testing Driver: $(api)" begin
        global testDFGAPI = api
        include("interfaceTests.jl")
    end
end
