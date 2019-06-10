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
    getVariable(cgDFG, :x0)
    # deleteVariable!(cgDFG, :x0)
end
@test !exists(cgDFG, :x0)
addVariable!(cgDFG, :x0, Pose2)


@test addVariable!(cgDFG, :x0, Pose2) == true
@test exists(cgDFG, :x0)

json = "{\"default\":{\"vecval\":[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],\"dimval\":3,\"vecbw\":[0.0,0.0,0.0],\"dimbw\":3,\"BayesNetOutVertIDs\":[],\"dimIDs\":[0,1,2],\"dims\":3,\"eliminated\":false,\"BayesNetVertID\":\"_null\",\"separator\":[],\"softtype\":\"Pose2(3, String[], (:Euclid, :Euclid, :Circular))\",\"initialized\":false,\"partialinit\":false,\"ismargin\":false,\"dontmargin\":false}}"
using JSON2
packed = JSON2.read(json, Dict{String, PackedVariableNodeData})
# IncrementalInference.decodePackedType(packed["default"], "VariableNodeData")
# unpack(cgDFG, packed["default"])
solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(cgDFG, p), values(packed)))

addFactor!(cgDFG, [:x0], PriorPose2(MvNormal(zeros(3), 0.01*eye(3))) )
