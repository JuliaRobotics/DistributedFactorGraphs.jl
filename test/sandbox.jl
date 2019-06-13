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

# DANGER: Clear everything from session + Neo4j database
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
x1 = addVariable!(cgDFG, :x1, Pose2)
x2 = addVariable!(cgDFG, :x2, Pose2)
x3 = addVariable!(cgDFG, :x3, Pose2)
l1 = addVariable!(cgDFG, :l1, Pose2)
l2 = addVariable!(cgDFG, :l2, Pose2)

prior = PriorPose2( MvNormal([10; 10; pi/6.0], Matrix(Diagonal([0.1;0.1;0.05].^2))))
addFactor!(cgDFG, [:x0], prior )

pp = Pose2Pose2(MvNormal([10.0;0;pi/3], Matrix(Diagonal([0.1;0.1;0.1].^2))))
p2br = Pose2Point2BearingRange(Normal(0,0.1),Normal(20.0,1.0))

# FYI deep copies not required, since no per factor specific data in pp
addFactor!(cgDFG, [:x1, :x2], pp, autoinit=false)
addFactor!(cgDFG, [:x2, :x3], pp, autoinit=false)
addFactor!(cgDFG, [:x1, :l1], p2br, autoinit=false)
addFactor!(cgDFG, [:x2, :l1], p2br, autoinit=false)
addFactor!(cgDFG, [:x3, :l2], p2br, autoinit=false)

@test setdiff(getNeighbors(cgDFG, :x2), [:x2l1f1, :x2x3f1, :x1x2f1]) == []

# Show it
DFG.toDotFile(dfg, "/tmp/testRmMarg.dot")


# ##### Testing
# newFactor = DFGFactor{CommonConvWrapper{typeof(prior)}, Symbol}(Symbol("x0f0"))
# # newFactor.tags = union([:abc], [:FACTOR]) # TODO: And session info
# # addNewFncVertInGraph!(fgl, newvert, currid, namestring, ready)
# ccw = IncrementalInference.prepgenericconvolution([x0], prior, multihypo=nothing, threadmodel=SingleThreaded)
# data_ccw = FunctionNodeData{CommonConvWrapper{typeof(prior)}}(Int[], false, false, Int[], Symbol(:test), ccw)
# newData = IncrementalInference.setDefaultFactorNode!(cgDFG, newFactor, [x0], deepcopy(prior), multihypo=nothing, threadmodel=SingleThreaded)
# # packedType = encodePackedType(newData)
# #Testing
# fnctype = newData.fnc.usrfnc!
# fnc = getfield(IncrementalInference.getmodule(fnctype), Symbol("Packed$(IncrementalInference.getname(fnctype))"))
# packed = convert(PackedFunctionNodeData{fnc}, newData)
# using JSON2
# j = JSON2.write(packed)
# retPacked = JSON2.read(j, GenericFunctionNodeData{PackedPriorPose2,String})
# retUnpacked = convert(GenericFunctionNodeData{IncrementalInference.getname(fnctype)}, retPacked)
# # TODO: Need to remove this...
# for vert in Xi
#   push!(newData.fncargvID, vert.label) # vert._internalId # YUCK :/ -- Yup, this is a problem
# end
#
#
