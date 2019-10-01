using Test
using GraphPlot # For plotting tests
using Neo4j
using DistributedFactorGraphs
using IncrementalInference

apis = [GraphsDFG, MetaGraphsDFG, SymbolDFG, LightDFG, CloudGraphsDFG]
for api in apis
    @testset "Testing Driver: $(api)" begin
        @info "Testing Driver: $(api)"
        global testDFGAPI = api
        include("iifInterfaceTests.jl")
    end
end

# Test each interface
# apis = [GraphsDFG, MetaGraphsDFG, SymbolDFG, LightDFG]
# for api in apis
#     @testset "Testing Driver: $(api)" begin
#         @info "Testing Driver: $(api)"
#         global testDFGAPI = api
#         include("interfaceTests.jl")
#     end
# end

# Test special cases

@testset "Plotting Tests" begin
    include("plottingTest.jl")
end

@testset "SummaryDFG test" begin
    @info "Testing LightDFG Variable and Factor Subtypes"
    include("LightDFGSummaryTypes.jl")
end
