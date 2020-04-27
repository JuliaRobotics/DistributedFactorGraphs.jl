using Test
using GraphPlot # For plotting tests
using Neo4j
using DistributedFactorGraphs
using Pkg
using Dates

# using IncrementalInference

include("testBlocks.jl")

##
testDFGAPI = CloudGraphsDFG

# TODO maybe move to cloud graphs permanantly as standard easy to use functions
function DFG.CloudGraphsDFG(; params=NoSolverParams())
    cgfg = CloudGraphsDFG{typeof(params)}("localhost", 7474, "neo4j", "test",
                                  "testUser", "testRobot", "testSession",
                                  "description",
                                  nothing,
                                  nothing,
                                  (dfg,f)->f,#IncrementalInference.decodePackedType,#(dfg,f)->f,
                                  (dfg,f)->f,#ncrementalInference.rebuildFactorMetadata!,#(dfg,f)->f,
                                  solverParams=params)
    createDfgSessionIfNotExist(cgfg)
    return cgfg
end

function DFG.CloudGraphsDFG(description::String,
                            userId::String,
                            robotId::String,
                            sessionId::String,
                            userData::Dict{Symbol, String},
                            robotData::Dict{Symbol, String},
                            sessionData::Dict{Symbol, String},
                            solverParams::AbstractParams;
                            host::String = "localhost",
                            port::Int = 7474,
                            dbUser::String = "neo4j",
                            dbPassword::String = "test")

    cdfg = CloudGraphsDFG{typeof(solverParams)}(host,
                                                port,
                                                dbUser,
                                                dbPassword,
                                                userId,
                                                robotId,
                                                sessionId,
                                                description,
                                                nothing,
                                                nothing,
                                                (dfg,f)->f,#IncrementalInference.decodePackedType,#(dfg,f)->f,
                                                (dfg,f)->f,#IncrementalInference.rebuildFactorMetadata!,#(dfg,f)->f,
                                                solverParams=solverParams)

    createDfgSessionIfNotExist(cdfg)

    setUserData!(cdfg, userData)
    setRobotData!(cdfg, robotData)
    setSessionData!(cdfg, sessionData)
    setDescription!(cdfg, description)

    return cdfg
end


##==============================================================================
## NOTE to self, keep this the same as interface test to consolidate
## Split up to make smaller PRs
##==============================================================================

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

@testset "tags" begin
    tagsTestBlock!(fg1, var1, v1_tags)
end

# @testset "Parametric Point Estimates" begin
#     PPETestBlock!(fg1, var1)
# end

@testset "Variable Solver Data" begin
    VSDTestBlock!(fg1, var1)
end

@testset "BigData Entries" begin
    @test_skip BigDataEntriesTestBlock!(fg1, var2)
end

# @testset "TODO Sorteer groep" begin
#     testGroup!(fg1, var1, var2, fac0, fac1)
# end


@testset "Adjacency Matrices" begin
    fg = testDFGAPI()
    clearRobot!!(fg)

    DFGVariable(:a, TestSofttype1())
    addVariable!(fg, var1)
    setSolvable!(fg, :a, 1)
    addVariable!(fg, var2)
    addFactor!(fg, fac1)
    addVariable!(fg, vorphan)

    AdjacencyMatricesTestBlock(fg)
end


@testset "Getting Neighbors" begin
    GettingNeighbors(testDFGAPI)
end


@testset "Getting Subgraphs" begin
    GettingSubgraphs(testDFGAPI)
end

# @testset "Building Subgraphs" begin
#     BuildingSubgraphs(testDFGAPI)
# end
#
# #TODO Summaries and Summary Graphs
# @testset "Summaries and Summary Graphs" begin
#     Summaries(testDFGAPI)
# end
#
# @testset "Producing Dot Files" begin
#     ProducingDotFiles(testDFGAPI)
# end
#
# @testset "Connectivity Test" begin
#      ConnectivityTest(testDFGAPI)
# end


#
#
# fg = fg1
# v1 = var1
# v2 = var2
# v3 = var3
# f0 = fac0
# f1 = fac1
# f2 = fac2
