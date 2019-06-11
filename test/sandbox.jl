## Sandboxing for CloudgraphsDFG

## Requires local Neo4j with user/pass neo4j:test
# To run the Docker image
# Install: docker pull neo4j
# Run: sudo docker run --publish=7474:7474 --publish=7687:7687 --env NEO4J_AUTH=neo4j/test neo4j


using DistributedFactorGraphs
using IncrementalInference
using Test

# Create connection
cgDFG = CloudGraphsDFG("localhost", 7474, "neo4j", "test",
    "testUser", "testRobot", "testSession",
    IncrementalInference.encodePackedType,
    IncrementalInference.getpackedtype,
    IncrementalInference.decodePackedType)

using RoME
if exists(cgDFG, :x0)
    vExisting = deleteVariable!(cgDFG, :x0)
    @test vExisting.label == :x0
end
@test !exists(cgDFG, :x0)
@test addVariable!(cgDFG, :x0, Pose2) != nothing
@test_throws Exception addVariable!(cgDFG, :x0, Pose2)
@test exists(cgDFG, :x0)
@test getVariable(cgDFG, :x0) != nothing
variable = getVariable(cgDFG, :x0)
push!(variable.tags, :EXTRAEXTRA)
updateVariable!(cgDFG, variable)
variableBack = getVariable(cgDFG, :x0, true)
@test variableBack.tags == variable.tags
@test deleteVariable!(cgDFG, :x0).label == :x0


using JSON2
packed = JSON2.read(json, Dict{String, PackedVariableNodeData})
# IncrementalInference.decodePackedType(packed["default"], "VariableNodeData")
# unpack(cgDFG, packed["default"])
solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(cgDFG, p), values(packed)))

addFactor!(cgDFG, [:x0], PriorPose2(MvNormal(zeros(3), 0.01*eye(3))) )
