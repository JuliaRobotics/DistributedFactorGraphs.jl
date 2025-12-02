if false
    using Test
    using GraphMakie
    using DistributedFactorGraphs
    using Pkg
    using Dates
    using UUIDs
    using TimeZones
    using TimesDates
    using DistributedFactorGraphs: OrderedDict

    include("testBlocks.jl")

    testDFGAPI = GraphsDFG

    # Enable debug logging
    using Logging
    logger = SimpleLogger(stdout, Logging.Debug)
    global_logger(logger)

    # or
    logger = ConsoleLogger(stdout, Logging.Debug)
    global_logger(logger)
end

# DFG.@usingDFG true
# include("testBlocks.jl")

# DFG Accessors
@testset "DFG Structure and Accessors" begin
    # Constructors
    # Constructors to be implemented
    global fg1 = DFGStructureAndAccessors(testDFGAPI)
end

# User, Robot, Session Data
@testset "User, Robot, Session Data" begin
    GraphAgentBloblets!(fg1)
end

@testset "User, Robot, Session Blob Entries" begin
    GraphAgentBlobentries!(fg1)
end

# VariableCompute structure construction and accessors
@testset "DFG Variable" begin
    global var1, var2, var3, v1_tags, vorphan
    var1, var2, var3, vorphan, v1_tags = DFGVariableSCA()
end

# FactorCompute structure construction and accessors
@testset "DFG Factor" begin
    global fac0, fac1, fac2 = DFGFactorSCA()
end

@testset "Variables and Factors CRUD and SET" begin
    VariablesandFactorsCRUD_SET!(fg1, var1, var2, var3, fac0, fac1, fac2)
end

@testset "Custom Printing" begin
    global var1, var2, var3, v1_tags, vorphan

    iobuf = IOBuffer()
    # for now just test the interface and a bit of output
    @test printVariable(var1) === nothing
    @test printFactor(fac1) === nothing

    @test printVariable(iobuf, var1; skipfields = [:timestamp]) === nothing

    varstr = String(take!(iobuf))
    @test occursin(r"VariableDFG", varstr)
    @test occursin(r"label", varstr)

    @test printVariable(iobuf, var1; short = true) === nothing
    varstr = String(take!(iobuf))
    @test occursin(r"VariableDFG", varstr)
    @test occursin(r"timestamp", varstr)
    @test occursin(r"label", varstr)
    @test occursin(r"bandwidths", varstr)
    #  == "VariableCompute{TestVariableType1}\nlabel: a\ntags: Set([:VARIABLE, :POSE])\nsize marginal samples: (1, 1)\nkde bandwidths: [0.0]\nNo PPEs\n"

    @test printFactor(iobuf, fac1; skipfields = [:timestamp]) === nothing
    @test occursin(r"FactorDFG.*\nlabel:\n:abf1", String(take!(iobuf)))

    @test printFactor(iobuf, fac1; short = true) === nothing
    @show teststr = String(take!(iobuf))
    @test occursin(r"FactorDFG", teststr)
    @test occursin(r"label", teststr)
    @test occursin(r"timestamp", teststr)
    @test occursin(r"tags", teststr)
    @test occursin(r"solvable", teststr)

    # s = String(take!(iobuf))

    @test show(var1) === nothing
    @test show(fac1) === nothing

    @test show(iobuf, MIME("text/plain"), var1) === nothing
    isapprox(length(take!(iobuf)), 452; atol = 10)
    @test show(iobuf, MIME("text/plain"), fac1) === nothing
    isapprox(length(take!(iobuf)), 301; atol = 10)

    @test printVariable(fg1, :a) === nothing
    @test printFactor(fg1, :abf1) === nothing

    @test printNode(fg1, :a) === nothing
    @test printNode(fg1, :abf1) === nothing

    #Blobentry
    be = DFG.Blobentry(:testbe; metadata = Dict("key1" => "value1", "key2" => 42))
    @test show(iobuf, MIME("text/plain"), be) === nothing
    disp_entry = String(take!(iobuf))
    @test occursin(r"Blobentry", disp_entry)
    @test occursin(r"testbe", disp_entry)
end

@testset "tags" begin
    tagsTestBlock!(fg1, var1, v1_tags)
end

@testset "Variable Solver Data" begin
    VSDTestBlock!(fg1, var1)
end

#FIXME replace with Bloblets tests
@testset "Bloblet CRUD" begin
    blobletTestBlock!(fg1)
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
    if typeof(fg1) <: InMemoryDFGTypes
        testGroup!(fg1, var1, var2, fac0, fac1)
    else
        @test_skip testGroup!(fg1, var1, var2, fac0, fac1)
    end
end

# order up to here is important, TODO maybe make independant
##
@testset "Adjacency Matrices" begin
    fg = testDFGAPI(; graphLabel = :testGraph)
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
    rand(5)
    ConnectivityTest(testDFGAPI)
end

@testset "Copy Functions" begin
    rand(6)
    fg = testDFGAPI(; graphLabel = :testGraph)
    addVariable!(fg, var1)
    addVariable!(fg, var2)
    addVariable!(fg, var3)
    addFactor!(fg, fac1)

    # fgcopy = testDFGAPI()
    # DFG._copyIntoGraph!(fg, fgcopy, union(ls(fg), lsf(fg)))
    # @test getVariableOrder(fg,:f1) == getVariableOrder(fgcopy,:f1)

    #test copyGraph, deepcopyGraph[!]
    fgcopy = testDFGAPI(; graphLabel = :testGraph)
    DFG.deepcopyGraph!(fgcopy, fg)
    @test getVariableOrder(fg, :abf1) == getVariableOrder(fgcopy, :abf1)

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

# FIXME this will likeley become obsolete with new pack/unpack system
# @testset "Mixing Compute and DFG graph nodes" begin
#     com_fg = testDFGAPI()
#     pac_fg = testDFGAPI{NoSolverParams, VariableDFG, FactorDFG}()

#     v = addVariable!(com_fg, var1)
#     @test v == var1
#     pv = addVariable!(pac_fg, v)
#     @test packVariable(v) == pv

#     pv = addVariable!(pac_fg, var2)
#     @test unpackVariable(pv) == var2
#     v = addVariable!(com_fg, pv)
#     @test v == var2

#     f = addFactor!(com_fg, fac0)
#     @test f == fac0
#     pf = addFactor!(pac_fg, f)
#     @test packFactor(f) == pf

#     pf = addFactor!(pac_fg, fac1)
#     @test unpackFactor(pf) == fac1
#     f = addFactor!(com_fg, pf)
#     @test f == fac1
# end
#=
fg = fg1
v1 = var1
v2 = var2
v3 = var3
f0 = fac0
f1 = fac1
f2 = fac2
=#
