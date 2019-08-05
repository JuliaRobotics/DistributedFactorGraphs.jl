using Test
using DataFrames
using DistributedFactorGraphs

# Test each interface
apis = [GraphsDFG, LightGraphsDFG]
# apis = [graphsDFG, cgDFG]
for api in apis
    @testset "Testing Driver: $(api)" begin
        global testDFGAPI = api
        include("interfaceTests.jl")
    end
end

# Test other interfaces that are not yet compatible for the general tests.
# @testset "CloudGraphsDFG Drive: " begin
#     include("cloudGraphsDFGTests.jl")
# end

# function decodePackedType(packeddata::GenericFunctionNodeData{Symbol,<:AbstractString}, notused::String)
#   usrtyp = convert(FunctorInferenceType, packeddata.fnc)
#   fulltype = FunctionNodeData{Symbol}
#   return convert(fulltype, packeddata)
# end
#
# cgDFG = CloudGraphsDFG("localhost", 7474, "neo4j", "test",
#     "testUser", "testRobot", "testSession",
#     nothing,
#     nothing,
#     decodePackedType)
# if haskey(ENV, "TRAVIS")
#     cgDFG = CloudGraphsDFG("localhost", 7474, "neo4j", "neo4j",
#         "testUser", "testRobot", "testSession",
#         nothing,
#         nothing,
#         decodePackedType)
# end
# # Completely wipe out the graph before testing.
# clearRobot!!(cgDFG)
