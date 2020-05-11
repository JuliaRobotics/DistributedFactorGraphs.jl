
# DFG Accessors
@testset "DFG Structure and Accessors" begin
    # Constructors
    # Constructors to be implemented
    global fg1 = DFGStructureAndAccessors(testDFGAPI)
end

# User, Robot, Session Data
@testset "User, Robot, Session Data" begin
    UserRobotSessionData!(fg1)
end

# DFGVariable structure construction and accessors
@testset "DFG Variable" begin
    global var1, var2, var3, v1_tags
    var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
end

# DFGFactor structure construction and accessors
@testset "DFG Factor" begin
    global fac0, fac1, fac2 = DFGFactorSCA()
end


@testset "Variables and Factors CRUD and SET" begin
    VariablesandFactorsCRUD_SET!(fg1, var1, var2, var3, fac0, fac1, fac2)
end


@testset "Custom Printing" begin

    iobuf = IOBuffer()
    # for now just test the interface and a bit of output
    @test printVariable(var1) == nothing
    @test printFactor(fac1) == nothing

    @test printVariable(iobuf, var1, skipfields=[:timestamp, :solver, :ppe]) == nothing
    @test String(take!(iobuf)) == "DFGVariable{TestSofttype1}\nlabel:\n:a\ntags:\nSet([:VARIABLE, :POSE])\nsmallData:\nDict(\"small\"=>\"data\")\nbigData:\nDict{Symbol,AbstractBigDataEntry}()\n_dfgNodeParams:\nDFGNodeParams(0)\n"

    @test printVariable(iobuf, var1, short=true) == nothing
    @test String(take!(iobuf)) == "DFGVariable{TestSofttype1}\nlabel: a\ntags: Set([:VARIABLE, :POSE])\nsize marginal samples: (1, 1)\nkde bandwidths: [0.0]\nNo PPEs\n"


    @test printFactor(iobuf, fac1, skipfields=[:timestamp, :solver]) == nothing
    @test occursin(r"DFGFactor.*\nlabel:\n:abf1", String(take!(iobuf)))

    String(take!(iobuf)) == "DFGFactor{TestCCW{TestFunctorInferenceType1}}\nlabel:\n:abf1\ntags:\nSet([:tag1, :tag2])\nsolvable:\n0\n_dfgNodeParams:\nDFGNodeParams(1)\n_variableOrderSymbols:\n[:a, :b]\n"

    @test printFactor(iobuf, fac1, short=true) == nothing
    @test occursin(r"DFGFactor.*\nlabel.*\ntimestamp.*\ntags.*\nsolvable", String(take!(iobuf)))

    # s = String(take!(iobuf))

    @test show(var1) == nothing
    @test show(fac1) == nothing

    @test show(iobuf, MIME("text/plain"), var1) == nothing
    isapprox(length(take!(iobuf)), 452, atol=10)
    @test show(iobuf, MIME("text/plain"), fac1) == nothing
    isapprox(length(take!(iobuf)), 301, atol=10)

    @test printVariable(fg1, :a) == nothing
    @test printFactor(fg1, :abf1) == nothing

    @test printNode(fg1, :a) == nothing
    @test printNode(fg1, :abf1) == nothing

    show(stdout, MIME("application/prs.juno.inline"), var1) == var1
    show(stdout, MIME("application/prs.juno.inline"), fac1) == fac1
end

@testset "tags" begin
    tagsTestBlock!(fg1, var1, v1_tags)
end


@testset "Parametric Point Estimates" begin
    PPETestBlock!(fg1, var1)
end

@testset "Variable Solver Data" begin
    VSDTestBlock!(fg1, var1)
end

@testset "BigData Entries" begin
    BigDataEntriesTestBlock!(fg1, var2)
end

# fg = fg1
# v1 = var1
# v2 = var2
# v3 = var3
# f0 = fac0
# f1 = fac1
# f2 = fac2
@testset "TODO Sorteer groep" begin
    testGroup!(fg1, var1, var2, fac0, fac1)
end

# order up to here is important, TODO maybe make independant
##
@testset "Adjacency Matrices" begin

    fg = testDFGAPI()
    addVariable!(fg, DFGVariable(:a, TestSofttype1()))
    addVariable!(fg, DFGVariable(:b, TestSofttype1()))
    addFactor!(fg, DFGFactor(:abf1, [:a,:b], GenericFunctionNodeData{TestFunctorInferenceType1}()))
    addVariable!(fg, DFGVariable(:orphan, TestSofttype1(), solvable = 0))

    AdjacencyMatricesTestBlock(fg)

end

@testset "Getting Neighbors" begin
    GettingNeighbors(testDFGAPI)
end

# @testset "Getting Subgraphs" begin
#     GettingSubgraphs(testDFGAPI)
# end

@testset "Building Subgraphs" begin
    BuildingSubgraphs(testDFGAPI)
end

#TODO Summaries and Summary Graphs
@testset "Summaries and Summary Graphs" begin
    Summaries(testDFGAPI)
end

@testset "Producing Dot Files" begin
    ProducingDotFiles(testDFGAPI)
end

@testset "Connectivity Test" begin
     ConnectivityTest(testDFGAPI)
end


@testset "Copy Functions" begin

    fg = testDFGAPI()
    addVariable!(fg, DFGVariable(:a, TestSofttype1()))
    addVariable!(fg, DFGVariable(:b, TestSofttype1()))
    addVariable!(fg, DFGVariable(:c, TestSofttype1()))
    addFactor!(fg, DFGFactor(:f1, [:a,:b,:c], GenericFunctionNodeData{TestFunctorInferenceType1}()))

    # fgcopy = testDFGAPI()
    # DFG._copyIntoGraph!(fg, fgcopy, union(ls(fg), lsf(fg)))
    # @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    #test copyGraph, deepcopyGraph[!]
    fgcopy = testDFGAPI()
    DFG.deepcopyGraph!(fgcopy, fg)
    @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    CopyFunctionsTest(testDFGAPI)

end
