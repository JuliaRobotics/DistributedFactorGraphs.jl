dfg = Neo4jDFG{SolverParams}("localhost", 7474, "neo4j", "test",
                            "test@navability.io", "testRobot", "testSession",
                            "Description of test session",
                            solverParams=SolverParams())

# Nuke the user
clearUser!!(dfg)
@test lsSessions(dfg) == []
@test lsRobots(dfg) == []
@test !(Symbol(dfg.userId) in map(u -> u.id, lsUsers(dfg)))
# Create sentinel nodes using shortcut
createDfgSessionIfNotExist(dfg)
@test map(s -> s.id, lsSessions(dfg)) == [Symbol(dfg.sessionId)]
@test map(s -> s.id, lsRobots(dfg)) == [Symbol(dfg.robotId)]
@test Symbol(dfg.userId) in map(u -> u.id, lsUsers(dfg))
# Test that we can call it again.
createDfgSessionIfNotExist(dfg)

# User, robot, and session
# TODO: Make easier ways to initialize these.
user = User(Symbol(dfg.userId), "Bob Zack", "Description", Dict{Symbol, String}())
robot = Robot(Symbol(dfg.robotId), user.id, "Test robot", "Description", Dict{Symbol, String}())
session = Session(Symbol(dfg.sessionId), robot.id, user.id, "Test Session", "Description", Dict{Symbol, String}())

@test getUserData(dfg) == Dict{Symbol, String}()
@test getRobotData(dfg) == Dict{Symbol, String}()
@test getSessionData(dfg) == Dict{Symbol, String}()

# User/robot/session data
user.data = Dict{Symbol, String}(:a => "Hello", :b => "Goodbye")
robot.data = Dict{Symbol, String}(:c => "ABC", :d => "Goodbye")
session.data = Dict{Symbol, String}(:e => "ADG", :f => "Goodbye")

setUserData!(dfg, user.data)
setRobotData!(dfg, robot.data)
setSessionData!(dfg, session.data)
@test getUserData(dfg) == user.data
@test getRobotData(dfg) == robot.data
@test getSessionData(dfg) == session.data

# And nuke it so we can try the addVariable etc. functions to make sure they create the nodes.
clearUser!!(dfg)
createDfgSessionIfNotExist(dfg)
# Add some nodes.
v1 = addVariable!(dfg, :a, ContinuousScalar, tags = [:POSE])
v2 = addVariable!(dfg, :b, ContinuousScalar, tags = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, tags = [:LANDMARK])
addFactor!(dfg, [:a], Prior(Normal(0,1)))
f1 = addFactor!(dfg, [:a; :b], LinearRelative(Normal(50.0,2.0)) )
f2 = addFactor!(dfg, [:b; :c], LinearRelative(Normal(50.0,2.0)) )

sessions = lsSessions(dfg)
@test map(s -> s.id, sessions) == [session.id]

dfgLocal = buildSubgraph(LightDFG, dfg, union(ls(dfg), lsf(dfg)))
# Confirm that with sentinels we still have the same graph (doesn't pull in the sentinels)
@test symdiff(ls(dfgLocal), ls(dfg)) == []
@test symdiff(lsf(dfgLocal), lsf(dfg)) == []

# Test errors
dfgError = deepcopy(dfg)
# User/robot/session ID's can't start with numbers and can't have spaces.
dfgError.userId = "I want to fail"
@test_throws Exception createDfgSessionIfNotExist(dfgError)
