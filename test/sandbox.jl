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
exists(cgDFG, :x0)

addVariable!(cgDFG, :x0, Pose2) # , labels=["POSE"]
addFactor!(cgDFG, [:x0], PriorPose2(MvNormal(zeros(3), 0.01*eye(3))) )
