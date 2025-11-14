
# VARTYPE = VariableSummary
# FACTYPE = FactorSummary

dfg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
function DistributedFactorGraphs.VariableSummary(label::Symbol)
    return VariableSummary(
        label,
        TimeDateZone("2025-11-13T15:21:57.474125421+01:00"),
        Set{Symbol}(),
        :Pose2,
        Dict{Symbol, Blobentry}(),
    )
end

function DistributedFactorGraphs.VariableSummary(label::Symbol, ::State{T}) where {T}
    return VariableSummary(
        label,
        TimeDateZone("2025-11-13T15:21:57.474125421+01:00"),
        Set{Symbol}(),
        Symbol(T),
        Dict{Symbol, Blobentry}(),
    )
end

function DistributedFactorGraphs.VariableSkeleton(label::Symbol, args...)
    return VariableSkeleton(label)
end

function DistributedFactorGraphs.VariableSkeleton(label::Symbol, ::State{T}) where {T}
    return VariableSkeleton(label, Set{Symbol}())
end

dfg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
v1 = VARTYPE(:a)
v2 = VARTYPE(:b)
v3 = VARTYPE(:c)
f0 = FACTYPE(:af1, [:a])
f1 = FACTYPE(:abf1, [:a, :b])
f2 = FACTYPE(:bcf1, [:b, :c])

union!(v1.tags, [:VARIABLE, :POSE])
union!(v2.tags, [:VARIABLE, :LANDMARK])
union!(f1.tags, [:FACTOR])

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
        nstime = 0,
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
        nstime = 0,
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
        nstime = 0,
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
    @test getTags(v1) == v1.tags

    @test getLabel(f1) == f1.label
    @test getTags(f1) == f1.tags

    if VARTYPE == VariableSummary
        @test getTimestamp(v1) == v1.timestamp
    end
end

@testset "Adjacency Matrices" begin
    fg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
    addVariable!(fg, VARTYPE(:a))
    addVariable!(fg, VARTYPE(:b))
    addFactor!(fg, FACTYPE(:abf1, [:a, :b]))
    addVariable!(fg, VARTYPE(:orphan))

    AdjacencyMatricesTestBlock(fg)
end

@testset "Getting Neighbors" begin
    GettingNeighbors(
        GraphsDFG{NoSolverParams, VARTYPE, FACTYPE};
        VARTYPE = VARTYPE,
        FACTYPE = FACTYPE,
    )
end

@testset "Building Subgraphs" begin
    BuildingSubgraphs(
        GraphsDFG{NoSolverParams, VARTYPE, FACTYPE};
        VARTYPE = VARTYPE,
        FACTYPE = FACTYPE,
    )
end

@testset "Producing Dot Files" begin
    ProducingDotFiles(
        GraphsDFG{NoSolverParams, VARTYPE, FACTYPE};
        VARTYPE = VARTYPE,
        FACTYPE = FACTYPE,
    )
end

@testset "Connectivity Test" begin
    ConnectivityTest(
        GraphsDFG{NoSolverParams, VARTYPE, FACTYPE};
        VARTYPE = VARTYPE,
        FACTYPE = FACTYPE,
    )
end
