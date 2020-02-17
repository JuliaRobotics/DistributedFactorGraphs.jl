using DistributedFactorGraphs
using IncrementalInference

numNodes = 10

# dfg = LightDFG{SolverParams}()
dfg = GraphsDFG{SolverParams}()


#change ready and solvable for x7,x8 for improved tests on x7x8f1
verts = map(n -> addVariable!(dfg, Symbol("x$n"), ContinuousScalar, labels = [:POSE]), 1:numNodes)
#TODO fix this to use accessors
verts[7].solvable = 1
verts[8].solvable = 0
getSolverData(verts[8]).solveInProgress = 1
setSolvedCount!(verts[1], 5)
#call update to set it on cloud
updateVariable!(dfg, verts[7])
updateVariable!(dfg, verts[8])

# Add some bigData to x1, x2
addBigDataEntry!(verts[1], GeneralBigDataEntry(:testing, :testing; mimeType="application/nuthin!"))
addBigDataEntry!(verts[2], FileBigDataEntry(:testing2, "/dev/null"))
#call update to set it on cloud
updateVariable!(dfg, verts[1])
updateVariable!(dfg, verts[2])

facts = map(n -> addFactor!(dfg, [verts[n], verts[n+1]], LinearConditional(Normal(50.0,2.0))), 1:(numNodes-1))

# Save and load the graph to test.
filename = "/tmp/test123.tar.gz"
saveDFG(dfg, filename)

filename = "/tmp/test123.tar.gz"
copyDfg = DistributedFactorGraphs._getDuplicatedEmptyDFG(dfg)
@info "Going to load $filename"
retDFG = loadDFG("/tmp/test1.tar.gz", Main, copyDfg)

x2 = getVariable(dfg, :x2)







x2ret = getVariable(retDFG, :x2)
setSolvable!(x2ret, 0)

x2 == x2ret


using Test
for var in ls(dfg)
    @test getVariable(dfg, var) == getVariable(retDFG, var)
end
for fact in lsf(dfg)
    @test getFactor(dfg, fact) == getFactor(retDFG, fact)
end
