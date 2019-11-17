dfg = CloudGraphsDFG{NoSolverParams}("localhost", 7474, "neo4j", "test",
                            "testUser", "testRobot", "testSession",
                            nothing,
                            nothing,
                            IncrementalInference.decodePackedType,
                            IncrementalInference.rebuildFactorMetadata!,
                            solverParams=NoSolverParams())

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
# And nuke it so we can try the longer functions.
clearUser!!(dfg)

# User, robot, and session
# TODO: Make easier ways to initialize these.
user = User(Symbol(dfg.userId), "Bob Zack", "Description", Dict{Symbol, String}())
robot = Robot(Symbol(dfg.robotId), user.id, "Test robot", "Description", Dict{Symbol, String}())
session = Session(Symbol(dfg.sessionId), robot.id, user.id, "Test Session", "Description", Dict{Symbol, String}())

@test createUser(dfg, user) == user
@test createRobot(dfg, robot) == robot
@test createSession(dfg, session) == session
@test map(s -> s.id, lsSessions(dfg)) == [Symbol(dfg.sessionId)]
@test map(s -> s.id, lsRobots(dfg)) == [Symbol(dfg.robotId)]
@test Symbol(dfg.userId) in map(u -> u.id, lsUsers(dfg))

# Test errors
dfgError = deepcopy(dfg)
# User/robot/session ID's can't start with numbers and can't have spaces.
dfgError.userId = "1testNope"
user = User(Symbol(dfgError.userId), "Bob Zack", "Description", Dict{Symbol, String}())
@test_throws Exception createUser(dfgError, user)

@test getUserData(dfg) == Dict{Symbol, String}()
@test getRobotData(dfg) == Dict{Symbol, String}()
@test getSessionData(dfg) == Dict{Symbol, String}()

# User/robot/session data
user.data = Dict{Symbol, String}(:a => "Hello", :b => "Goodbye")
robot.data = Dict{Symbol, String}(:c => "Hello", :d => "Goodbye")
session.data = Dict{Symbol, String}(:e => "Hello", :f => "Goodbye")

setUserData(dfg, user.data)
setRobotData(dfg, robot.data)
setSessionData(dfg, session.data)
@test getUserData(dfg) == user.data
@test getRobotData(dfg) == robot.data
@test getSessionData(dfg) == session.data

# Add some nodes.
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE])
v2 = addVariable!(dfg, :b, ContinuousScalar, labels = [:POSE])
v3 = addVariable!(dfg, :c, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfg, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(dfg, [:b; :c], LinearConditional(Normal(50.0,2.0)) )

sessions = lsSessions(dfg)
@test map(s -> s.id, sessions) == [session.id]

# Pull and solve this graph
dfgLocal = GraphsDFG{SolverParams}(params=SolverParams())
DistributedFactorGraphs.getSubgraph(dfg, union(ls(dfg), lsf(dfg)), true, dfgLocal)

# Confirm that with sentinels we still have the same graph (doesn't pull in the sentinels)
@test symdiff(ls(dfgLocal), ls(dfg)) == []
@test symdiff(lsf(dfgLocal), lsf(dfg)) == []

# Solve it
tree, smtasks = solveTree!(dfgLocal)


# Make sure we can copy and solve normal orphaned sessions.
dfgOrphaned = deepcopy(dfg)
dfgOrphaned.sessionId = "doesntexist"
# Don't create a session
# Add some nodes.
v1 = addVariable!(dfgOrphaned, :a, ContinuousScalar, labels = [:POSE])
v2 = addVariable!(dfgOrphaned, :b, ContinuousScalar, labels = [:POSE])
v3 = addVariable!(dfgOrphaned, :c, ContinuousScalar, labels = [:LANDMARK])
f1 = addFactor!(dfgOrphaned, [:a; :b], LinearConditional(Normal(50.0,2.0)) )
f2 = addFactor!(dfgOrphaned, [:b; :c], LinearConditional(Normal(50.0,2.0)) )
# Solve it
dfgLocal = GraphsDFG{SolverParams}(params=SolverParams())
DistributedFactorGraphs.getSubgraph(dfgOrphaned, union(ls(dfgOrphaned), lsf(dfgOrphaned)), true, dfgLocal)
tree, smtasks = solveTree!(dfgLocal)

# If this passes without errors and we solve the graph, then all good.
