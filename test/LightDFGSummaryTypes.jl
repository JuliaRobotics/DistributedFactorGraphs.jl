
# VARTYPE = DFGVariableSummary
# FACTYPE = DFGFactorSummary

dfg = LightDFG{NoSolverParams, VARTYPE, FACTYPE}()
DistributedFactorGraphs.DFGVariableSummary(label::Symbol) = DFGVariableSummary(label, DistributedFactorGraphs.now(), Set{Symbol}(), Dict{Symbol, MeanMaxPPE}(), :Pose2, Dict{Symbol,AbstractBigDataEntry}(), 0)
DistributedFactorGraphs.DFGFactorSummary(label::Symbol) = DFGFactorSummary(label, DistributedFactorGraphs.now(), Set{Symbol}(), 0, Symbol[])

DistributedFactorGraphs.DFGVariableSummary(label::Symbol, soft::InferenceVariable) = DFGVariableSummary(label, DistributedFactorGraphs.now(), Set{Symbol}(), Dict{Symbol, MeanMaxPPE}(), Symbol(typeof(soft)), Dict{Symbol,AbstractBigDataEntry}(), 0)
DistributedFactorGraphs.SkeletonDFGVariable(label::Symbol, soft::InferenceVariable) = SkeletonDFGVariable(label)


dfg = LightDFG{NoSolverParams, VARTYPE, FACTYPE}()
v1 = VARTYPE(:a)
v2 = VARTYPE(:b)
v3 = VARTYPE(:c)
f0 = FACTYPE(:af1)
f1 = FACTYPE(:abf1)
f2 = FACTYPE(:bcf1)

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
        @test getVariablePPEs(v1) == v1.ppeDict
        @test_throws KeyError getVariablePPE(v1, :notfound)
        @test getSofttype(v1) == :Pose2
        @test getInternalId(v1) == v1._internalId

        # FACTYPE == DFGFactorSummary
        @test getInternalId(f1) == f1._internalId

        testTimestamp = now()
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
    fg = LightDFG{NoSolverParams, VARTYPE, FACTYPE}()
    addVariable!(fg, VARTYPE(:a, TestSofttype1()))
    addVariable!(fg, VARTYPE(:b, TestSofttype1()))
    addFactor!(fg,  [:a,:b], FACTYPE(:abf1))
    addVariable!(fg, VARTYPE(:orphan, TestSofttype1()))

    AdjacencyMatricesTestBlock(fg)
end

@testset "Getting Neighbors" begin
    GettingNeighbors(LightDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end

@testset "Getting Subgraphs" begin
    GettingSubgraphs(LightDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end


@testset "Producing Dot Files" begin
    ProducingDotFiles(LightDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end

@testset "Connectivity Test" begin
     ConnectivityTest(LightDFG{NoSolverParams, VARTYPE, FACTYPE}, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
end
