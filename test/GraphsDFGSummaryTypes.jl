
# VARTYPE = VariableSummary
# FACTYPE = FactorSummary

# generate variables and factors
var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
fac0, fac1, fac2 = DFGFactorSCA()

dfg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
v1 = VARTYPE(var1)
v2 = VARTYPE(var2)
v3 = VARTYPE(var3)
f0 = FACTYPE(fac0)
f1 = FACTYPE(fac1)
f2 = FACTYPE(fac2)

if false
    #TODO add to tests
    VARTYPE = VariableDFG
    FACTYPE = FactorDFG
    dfg = GraphsDFG{NoSolverParams, VariableDFG, FactorDFG}()
    v1 = VariableDFG(; label = :a, variableType = "Pose2", tags = [:VARIABLE, :POSE])
    v2 = VariableDFG(; label = :b, variableType = "Pose2", tags = [:VARIABLE, :LANDMARK])
    v3 = VariableDFG(; label = :c, variableType = "Pose2")
    orphan = VariableDFG(; label = :orphan, variableType = "Pose2")
    f0 = FactorDFG(;
        label = :af1,
        tags = [:FACTOR],
        variableorder = [:a],
        timestamp = DFG.Dates.now(DFG.tz"Z"),
        fnctype = "PriorPose2",
        solvable = 1,
        data = "",
        metadata = "",
    )
    f1 = FactorDFG(;
        label = :abf1,
        tags = [:FACTOR],
        variableorder = [:a, :b],
        timestamp = DFG.Dates.now(DFG.tz"Z"),
        fnctype = "Pose2Pose2",
        solvable = 1,
        data = "",
        metadata = "",
    )
    f2 = FactorDFG(;
        label = :bcf1,
        tags = [:FACTOR],
        variableorder = [:b, :c],
        timestamp = DFG.Dates.now(DFG.tz"Z"),
        fnctype = "Pose2Pose2",
        solvable = 1,
        data = "",
        metadata = "",
    )
end

@testset "Variables and Factors CRUD and SET" begin
    VariablesandFactorsCRUD_SET!(dfg, v1, v2, v3, f0, f1, f2)
end

# Gets
@testset "Gets, Sets, and Accessors" begin
    global dfg, v1, v2, f1

    @test getLabel(v1) == v1.label
    @test DFG.refTags(v1) === v1.tags

    @test getLabel(f1) == f1.label
    @test DFG.refTags(f1) === f1.tags

    if VARTYPE == VariableSummary
        @test getTimestamp(v1) == v1.timestamp
    end
end

@testset "Adjacency Matrices" begin
    fg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
    addVariable!(fg, VARTYPE(var1))
    addVariable!(fg, VARTYPE(var2))
    addFactor!(fg, FACTYPE(fac1))
    addVariable!(fg, VARTYPE(vorphan))

    AdjacencyMatricesTestBlock(fg)
end

@testset "Getting Neighbors" begin
    GettingNeighbors(GraphsDFG; VARTYPE = VARTYPE, FACTYPE = FACTYPE)
end

@testset "Building Subgraphs" begin
    BuildingSubgraphs(GraphsDFG; VARTYPE = VARTYPE, FACTYPE = FACTYPE)
end

@testset "Connectivity Test" begin
    ConnectivityTest(GraphsDFG; VARTYPE = VARTYPE, FACTYPE = FACTYPE)
end
