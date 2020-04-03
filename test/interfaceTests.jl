
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
    var1, var2, var3, v1_tags = DFGVariableSCA()
end

# DFGFactor structure construction and accessors
@testset "DFG Factor" begin
    global fac0, fac1, fac2 = DFGFactorSCA()
end

@testset "Variables and Factors CRUD and SET" begin
    VariablesandFactorsCRUD_SET!(fg1, var1, var2, var3, fac0, fac1, fac2)
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

@testset "TODO Sorteer groep" begin
    testGroup!(fg1, var1, var2, fac0, fac1)
end

# order up to here is important, TODO maybe make independant
##
@testset "Adjacency Matrices" begin

    fg = testDFGAPI()
    addVariable!(fg, DFGVariable(:a, TestSofttype1()))
    addVariable!(fg, DFGVariable(:b, TestSofttype1()))
    addFactor!(fg, DFGFactor(:abf1, [:a,:b], GenericFunctionNodeData{TestFunctorInferenceType1, Symbol}()))
    addVariable!(fg, DFGVariable(:orphan, TestSofttype1(), solvable = 0))

    AdjacencyMatricesTestBlock(fg)

end

@testset "Getting Neighbors" begin
    GettingNeighbors(testDFGAPI)
end

@testset "Getting Subgraphs" begin
    GettingSubgraphs(testDFGAPI)
end

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
    addFactor!(fg, DFGFactor(:f1, [:a,:b,:c], GenericFunctionNodeData{TestFunctorInferenceType1, Symbol}()))

    fgcopy = testDFGAPI()
    DFG._copyIntoGraph!(fg, fgcopy, union(ls(fg), lsf(fg)))
    @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    #test copyGraph, deepcopyGraph[!]
    fgcopy = testDFGAPI()
    DFG.deepcopyGraph!(fgcopy, fg)
    @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    CopyFunctionsTest(testDFGAPI)

end
