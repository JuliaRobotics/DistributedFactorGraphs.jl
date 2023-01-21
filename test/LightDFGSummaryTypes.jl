
# VARTYPE = DFGVariableSummary
# FACTYPE = DFGFactorSummary

dfg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
DistributedFactorGraphs.DFGVariableSummary(label::Symbol) = DFGVariableSummary(label, DistributedFactorGraphs.now(localzone()), Set{Symbol}(), Dict{Symbol, MeanMaxPPE}(), :Pose2, Dict{Symbol,AbstractDataEntry}())
DistributedFactorGraphs.DFGFactorSummary(label::Symbol) = DFGFactorSummary(label, DistributedFactorGraphs.now(localzone()), Set{Symbol}(), Symbol[])

DistributedFactorGraphs.DFGVariableSummary(label::Symbol, ::VariableNodeData{T}) where T = DFGVariableSummary(label, DistributedFactorGraphs.now(localzone()), Set{Symbol}(), Dict{Symbol, MeanMaxPPE}(), Symbol(T), Dict{Symbol,AbstractDataEntry}())
DistributedFactorGraphs.SkeletonDFGVariable(label::Symbol, args...) = SkeletonDFGVariable(label)


dfg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
v1 = VARTYPE(:a)
v2 = VARTYPE(:b)
v3 = VARTYPE(:c)
f0 = FACTYPE(:af1)
f1 = FACTYPE(:abf1)
f2 = FACTYPE(:bcf1)
append!(f2._variableOrderSymbols, [:b,:c])

union!(v1.tags, [:VARIABLE, :POSE])
union!(v2.tags, [:VARIABLE, :LANDMARK])
union!(f1.tags, [:FACTOR])


@testset "Variables and Factors CRUD and SET" begin
    VariablesandFactorsCRUD_SET!(dfg,v1,v2,v3,f0,f1,f2)
end


# Gets
@testset "Gets, Sets, and Accessors" begin
    global dfg,v1,v2,f1

    @test getLabel(v1) == v1.label
    @test getTags(v1) == v1.tags

    @test getLabel(f1) == f1.label
    @test getTags(f1) == f1.tags

    if VARTYPE == DFGVariableSummary
        @test getTimestamp(v1) == v1.timestamp
        @test getVariablePPEDict(v1) == v1.ppeDict
        @test_throws KeyError getVariablePPE(v1, :notfound)
        @test getVariableTypeName(v1) == :Pose2

        # FACTYPE == DFGFactorSummary
        testTimestamp = now(localzone())
        v1ts = setTimestamp(v1, testTimestamp)
        @test getTimestamp(v1ts) == testTimestamp
        #follow with updateVariable!(fg, v1ts)
        # setTimestamp!(v1, testTimestamp) not implemented, we can do an setTimestamp() updateVariable!() for a setTimestamp!(dfg, v1, testTimestamp)
        @test_throws MethodError setTimestamp!(v1, testTimestamp)

        f1ts = setTimestamp(f1, testTimestamp)
        @test !(f1ts === f1)
        @test getTimestamp(f1ts) == testTimestamp
        @test_throws MethodError setTimestamp!(v1, testTimestamp)
    end

end

@testset "Updating Nodes" begin
    VARTYPE == DFGVariableSummary && PPETestBlock!(dfg, v1)
end


@testset "Adjacency Matrices" begin
    fg = GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}()
    addVariable!(fg, VARTYPE(:a))
    addVariable!(fg, VARTYPE(:b))
    addFactor!(fg,  [:a,:b], FACTYPE(:abf1))
    addVariable!(fg, VARTYPE(:orphan))

    AdjacencyMatricesTestBlock(fg)
end

@testset "Getting Neighbors" begin
    GettingNeighbors(GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end

@testset "Building Subgraphs" begin
    BuildingSubgraphs(GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end

@testset "Producing Dot Files" begin
    ProducingDotFiles(GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end

@testset "Connectivity Test" begin
     ConnectivityTest(GraphsDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end
