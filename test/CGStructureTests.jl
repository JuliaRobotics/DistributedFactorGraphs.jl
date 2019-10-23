using DistributedFactorGraphs
using IncrementalInference
using Test

blank() = return nothing
dfg = CloudGraphsDFG{NoSolverParams}("localhost", 7474, "neo4j", "test",
                            "Bob", "testRobot", "testSession",
                            nothing,
                            nothing,
                            blank,
                            blank,
                            solverParams=NoSolverParams())
# Nuke the user
clearUser!!(dfg)

# User, robot, and session
user = User(:Bob, "Bob Zack", "Description", Dict{String, String}())
robot = Robot(:testRobot, user.id, "Test robot", "Description", Dict{String, String}())
session = Session(:testSession, robot.id, user.id, "Test Session", "Description", Dict{String, String}())

# Test of the 'serializer' and 'deserializer'
dictUser = DistributedFactorGraphs._convertNodeToDict(user)

createUser(dfg, user)
createRobot(dfg, robot)
createSession(dfg, session)

# Add some nodes.
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE])
v2 = addVariable!(dfg, :b, ContinuousScalar, labels = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f1 = addFactor!(dfg, [:a; :b; :c], LinearConditional(Normal(50.0,2.0)) )

listSessions(dfg)
