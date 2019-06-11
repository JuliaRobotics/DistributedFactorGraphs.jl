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
# DANGER: Clear everything from session
clearSession!(cgDFG)

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
@test getVariableIds(cgDFG) == [:x0]
@test getVariableIds(cgDFG, r"x.*") == [:x0]
@test getVariableIds(cgDFG, r"y.*") == []
variable = getVariable(cgDFG, :x0)
push!(variable.tags, :EXTRAEXTRA)
updateVariable!(cgDFG, variable)
variableBack = getVariable(cgDFG, :x0, true)
@test variableBack.tags == variable.tags
@test deleteVariable!(cgDFG, :x0).label == :x0

# Things that should pass
helloVariable = addVariable!(cgDFG, :hellothisIsALabel_Something, Pose2)
@test helloVariable != nothing
@test getVariableIds(cgDFG, r".*thisIsALabel.*") == [:hellothisIsALabel_Something]
@test deleteVariable!(cgDFG, helloVariable).label == helloVariable.label

# TODO: Comparisons
# Comparisons

# Factors
x0 = addVariable!(cgDFG, :x0, Pose2)
x1 = addVariable!(cgDFG, :x1, Pose2)
l1 = addVariable!(cgDFG, :l1, Pose2)
prior = PriorPose2( MvNormal([10; 10; pi/6.0], Matrix(Diagonal([0.1;0.1;0.05].^2))))
addFactor!(cgDFG, [:x0], prior )

pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
p2br = Pose2Point2BearingRange(Normal(0,0.1),Normal(20.0,1.0))


using JSON2
packed = JSON2.read(json, Dict{String, PackedVariableNodeData})
# IncrementalInference.decodePackedType(packed["default"], "VariableNodeData")
# unpack(cgDFG, packed["default"])
solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(cgDFG, p), values(packed)))

addFactor!(cgDFG, [:x0], PriorPose2(MvNormal(zeros(3), 0.01*eye(3))) )
