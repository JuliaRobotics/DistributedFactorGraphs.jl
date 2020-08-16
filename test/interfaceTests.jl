if false
using Test
using GraphPlot
using Neo4j
using DistributedFactorGraphs
using Pkg
using Dates
using UUIDs
using TimeZones

include("testBlocks.jl")

testDFGAPI = CloudGraphsDFG
testDFGAPI = LightDFG

# Enable debug logging
using Logging
logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)
end

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
    global var1, var2, var3, v1_tags, vorphan
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

    @test printVariable(iobuf, var1, skipfields=[:timestamp, :solver, :ppe, :nstime]) == nothing
    @test String(take!(iobuf)) == "DFGVariable{TestSofttype1}\nlabel:\n:a\ntags:\nSet([:VARIABLE, :POSE])\nsmallData:\nDict{Symbol,Union{Bool, Float64, Int64, Array{Bool,1}, Array{Float64,1}, Array{Int64,1}, Array{String,1}, String}}(:small=>\"data\")\ndataDict:\nDict{Symbol,AbstractDataEntry}()\nsolvable:\n0\n"

    @test printVariable(iobuf, var1, short=true) == nothing
    @test String(take!(iobuf)) == "DFGVariable{TestSofttype1}\nlabel: a\ntags: Set([:VARIABLE, :POSE])\nsize marginal samples: (1, 1)\nkde bandwidths: [0.0]\nNo PPEs\n"


    @test printFactor(iobuf, fac1, skipfields=[:timestamp, :solver, :nstime]) == nothing
    @test occursin(r"DFGFactor.*\nlabel:\n:abf1", String(take!(iobuf)))

    String(take!(iobuf)) == "DFGFactor{TestCCW{TestFunctorInferenceType1}}\nlabel:\n:abf1\ntags:\nSet([:tag1, :tag2])\nsolvable:\n0\nsolvable:\n1\n_variableOrderSymbols:\n[:a, :b]\n"

    @test printFactor(iobuf, fac1, short=true) == nothing
    @show teststr = String(take!(iobuf))
    @test occursin(r"DFGFactor", teststr)
    @test occursin(r"label", teststr)
    @test occursin(r"timestamp", teststr)
    @test occursin(r"tags", teststr)
    @test occursin(r"solvable", teststr)

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

@testset "SmallData CRUD" begin
    smallDataTestBlock!(fg1)
end

@testset "Data Entries and Blobs" begin
    if typeof(fg1) <: InMemoryDFGTypes
        DataEntriesTestBlock!(fg1, var2)
    end
    @testset "Data blob tests" begin
        blobsStoresTestBlock!(fg1)
    end
end

@testset "TODO Sorteer groep" begin
    if typeof(fg1)  <: InMemoryDFGTypes
        testGroup!(fg1, var1, var2, fac0, fac1)
    else
        @test_skip testGroup!(fg1, var1, var2, fac0, fac1)
    end
end

# order up to here is important, TODO maybe make independant
##
@testset "Adjacency Matrices" begin

    fg = testDFGAPI(userId="testUserId")
    addVariable!(fg, var1)
    setSolvable!(fg, :a, 1)
    addVariable!(fg, var2)
    addFactor!(fg, fac1)
    addVariable!(fg, vorphan)

    AdjacencyMatricesTestBlock(fg)

end

@testset "Getting Neighbors" begin
    rand(1)
    GettingNeighbors(testDFGAPI)
end

@testset "Building Subgraphs" begin
    rand(2)
    BuildingSubgraphs(testDFGAPI)
end

#TODO Summaries and Summary Graphs
@testset "Summaries and Summary Graphs" begin
    rand(3)
    Summaries(testDFGAPI)
end

@testset "Producing Dot Files" begin
    rand(4)
    if testDFGAPI <: InMemoryDFGTypes
        ProducingDotFiles(testDFGAPI)
    else
        ProducingDotFiles(testDFGAPI, var1, var2, fac1)
    end
end

@testset "Connectivity Test" begin
    if testDFGAPI != CloudGraphsDFG
        rand(5)
        ConnectivityTest(testDFGAPI)
    else
        @warn "CloudGraphsDFG is currently failing with the connectivity test."
    end
end


@testset "Copy Functions" begin
    rand(6)
    fg = testDFGAPI(userId="testUserId")
    addVariable!(fg, var1)
    addVariable!(fg, var2)
    addVariable!(fg, var3)
    addFactor!(fg, fac1)

    # fgcopy = testDFGAPI()
    # DFG._copyIntoGraph!(fg, fgcopy, union(ls(fg), lsf(fg)))
    # @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    #test copyGraph, deepcopyGraph[!]
    fgcopy = testDFGAPI(userId="testUserId")
    DFG.deepcopyGraph!(fgcopy, fg)
    @test getVariableOrder(fg,:abf1) == getVariableOrder(fgcopy,:abf1)

    CopyFunctionsTest(testDFGAPI)

end

@testset "File Save Functions" begin
    rand(7)
    if testDFGAPI <: InMemoryDFGTypes
        FileDFGTestBlock(testDFGAPI)
    else
        @test_skip FileDFGTestBlock(testDFGAPI)
    end
end
#=
fg = fg1
v1 = var1
v2 = var2
v3 = var3
f0 = fac0
f1 = fac1
f2 = fac2
=#
