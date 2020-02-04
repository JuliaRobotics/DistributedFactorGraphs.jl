# global testDFGAPI = LightDFG
# global testDFGAPI = GraphsDFG

#test Specific definitions
struct TestInferenceVariable1 <: InferenceVariable end
struct TestInferenceVariable2 <: InferenceVariable end

struct TestFunctorInferenceType1 <: FunctorInferenceType end

# TODO see note in AbstractDFG.jl setSolverParams!
struct GeenSolverParams <: AbstractParams
end

# DFG Accessors
@testset "DFG Structure and Accessors" begin
    # Constructors
    # Constructors to be implemented
    global fg = testDFGAPI(params=NoSolverParams())
    #TODO test something better
    @test isa(fg, testDFGAPI)

    des = "description"
    uId = "userId"
    rId = "robotId"
    sId = "sessionId"
    ud = :ud=>"udEntry"
    rd = :rd=>"rdEntry"
    sd = :sd=>"sdEntry"
    fg = testDFGAPI(des, uId,  rId,  sId,  Dict{Symbol, String}(ud),  Dict{Symbol, String}(rd),  Dict{Symbol, String}(sd),  NoSolverParams())

    # accesssors
    # get
    @test getDescription(fg) == des
    @test getUserId(fg) == uId
    @test getRobotId(fg) == rId
    @test getSessionId(fg) == sId
    @test getAddHistory(fg) == []

    @test getUserData(fg) == Dict(ud)
    @test getRobotData(fg) == Dict(rd)
    @test getSessionData(fg) == Dict(sd)

    @test getSolverParams(fg) == NoSolverParams()

    smallUserData = Dict{Symbol, String}(:a => "42", :b => "Hello")
    smallRobotData = Dict{Symbol, String}(:a => "43", :b => "Hello")
    smallSessionData = Dict{Symbol, String}(:a => "44", :b => "Hello")

    #TODO CRUD vs set
    @test setUserData!(fg, deepcopy(smallUserData)) == smallUserData
    @test setRobotData!(fg, deepcopy(smallRobotData)) == smallRobotData
    @test setSessionData!(fg, deepcopy(smallSessionData)) == smallSessionData

    @test getUserData(fg) == smallUserData
    @test getRobotData(fg) == smallRobotData
    @test getSessionData(fg) == smallSessionData


    # TODO see note in AbstractDFG.jl setSolverParams!
    @test_throws MethodError setSolverParams!(fg, GeenSolverParams()) == GeenSolverParams()


    @test setSolverParams!(fg, NoSolverParams()) == NoSolverParams()

    @test setDescription!(fg, des*"_1") == des*"_1"

    #TODO I don't like, so not exporting, and not recommended to use
    #     Technically if you set Ids its a new object
    @test DistributedFactorGraphs.setUserId!(fg, uId*"_1") == uId*"_1"
    @test DistributedFactorGraphs.setRobotId!(fg, rId*"_1") == rId*"_1"
    @test DistributedFactorGraphs.setSessionId!(fg, sId*"_1") == sId*"_1"


    #deprecated
    @test_throws ErrorException getLabelDict(fg)
    @test @test_deprecated setDescription(fg, des) == des


    #TODO
    # duplicateEmptyDFG
    # copyEmptyDFG
    # emptyDFG ?
    # _getDuplicatedEmptyDFG
end

# User, Robot, Session Data
@testset "User, Robot, Session Data" begin
    # User Data
    global fg
    @test getUserData(fg, :a) == "42"
    #TODO
    @test_broken addUserData!
    @test updateUserData!(fg, :b=>"1") == getUserData(fg)
    @test getUserData(fg, :b) == deleteUserData!(fg, :b)
    @test emptyUserData!(fg) == Dict{Symbol,String}()

    # Robot Data
    @test getRobotData(fg, :a) == "43"
    #TODO
    @test_broken addRobotData!
    @test updateRobotData!(fg, :b=>"2") == getRobotData(fg)
    @test getRobotData(fg, :b) == deleteRobotData!(fg, :b)
    @test emptyRobotData!(fg) == Dict{Symbol,String}()

    # SessionData
    @test getSessionData(fg, :a) == "44"
    #TODO
    @test_broken addSessionData!
    updateSessionData!(fg, :b=>"3") == getSessionData(fg)
    @test getSessionData(fg, :b) == deleteSessionData!(fg, :b)
    @test emptySessionData!(fg) == Dict{Symbol,String}()

    # TODO Set-like if we want eg. list, merge, etc
    # listUserData
    # listRobotData
    # listSessionData
    # mergeUserData
    # mergeRobotData
    # mergeSessionData

end

@testset "DFG Variable" begin

    global v1, v2, v3

    v1_lbl = :a
    global v1_tags = Set([:VARIABLE, :POSE])
    small = Dict("small"=>"data")
    testTimestamp = now()
    # Constructors
    v1 = DFGVariable(v1_lbl, TestInferenceVariable1(), tags=v1_tags, solvable=0)
    v2 = DFGVariable(:b, TestInferenceVariable2(), tags=Set([:VARIABLE, :LANDMARK]))
    v3 = DFGVariable(:c, TestInferenceVariable2())


    getSolverData(v1).solveInProgress = 1

    @test getLabel(v1) == v1_lbl
    @test getTags(v1) == v1_tags

    @test getTimestamp(v1) == v1.timestamp

    @test getInternalId(v1) == v1._internalId
    @test getInternalId(v1) == v1._dfgNodeParams._internalId

    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1

    # TODO direct use is not recommended, use accessors, maybe not export or deprecate
    @test getSolverDataDict(v1) == v1.solverDataDict
    # TODO implement name
    @test getPPEDict(v1) == v1.ppeDict

    @test getSmallData(v1) == Dict{String,String}()

    @test getSofttype(v1) == TestInferenceVariable1()


    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(v3, testTags) == Set(testTags)
    @test setTags!(v3, Set(testTags)) == Set(testTags)

    #TODO Document
    #NOTE there does not exist a thing like setTimestamp!, a variable's timestamp is considered similar to its label.
    v1ts = setTimestamp(v1, testTimestamp)
    @test getTimestamp(v1ts) == testTimestamp
    #follow with updateVariable!(fg, v1ts)
    @test_throws MethodError setTimestamp!(v1, testTimestamp)

    @test setSolvable!(v1, 1) == 1
    @test getSolvable(v1) == 1

    @test setSmallData!(v1, small) == small
    @test getSmallData(v1) == small

    #no accessors on BigData, only CRUD

    # #TODO sort out
    # getPPEs
    # getSolverData
    # setSolverData
    # getVariablePPEs
    # getVariablePPE
    # getSolvedCount
    # isSolved
    # setSolvedCount

end

@testset "DFG Factor" begin

    global f1, f2
    # Constructors
    #DFGVariable solvable default to 1, but Factor to 0, is that correct
    f1_lbl = :f1
    f1_tags = Set([:FACTOR])
    testTimestamp = now()

    f1 = DFGFactor{TestFunctorInferenceType1, Symbol}(f1_lbl)
    f1 = DFGFactor(f1_lbl, [:a,:b], GenericFunctionNodeData{TestFunctorInferenceType1,Symbol}(), tags = f1_tags, solvable=0)

    f2 = DFGFactor{TestFunctorInferenceType1, Symbol}(:f2)

    @test getLabel(f1) == f1_lbl
    @test getTags(f1) == f1_tags

    @test getTimestamp(f1) == f1.timestamp

    @test getInternalId(f1) == f1._internalId
    @test getInternalId(f1) == f1._dfgNodeParams._internalId

    @test getSolvable(f1) == 0


    @test getSolverData(f1) == f1.solverData

    @test getVariableOrder(f1) == [:a,:b]

    getSolverData(f1).solveInProgress = 1
    @test setSolvable!(f1, 1) == 1


    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(f1, testTags) == Set(testTags)
    @test setTags!(f1, Set(testTags)) == Set(testTags)

    #TODO Handle same way as variable
    f1ts = setTimestamp(f1, testTimestamp)
    @test !(f1ts === f1)
    @test getTimestamp(f1ts) == testTimestamp
    #follow with updateVariable!(fg, v1ts)
    @test setTimestamp!(f1, testTimestamp) == testTimestamp
    #/TODO

    @test setSolvable!(f1, 1) == 1
    @test getSolvable(f1) == 1

    #TODO setSolverData!(f1,...)????

    #TODO
    # getFactorFunction
    # getFactorType
    # isPrior

end

@testset "Variables and Factors CRUD" begin

    #TODO dont throw ErrorException
    #TODO test remaining add signitures
    # global fg
    # fg = GraphsDFG(params=NoSolverParams())
    # fg = LightDFG(params=NoSolverParams())
    # add update delete
    @test addVariable!(fg, v1) == v1
    @test addVariable!(fg, v2) == v2
    @test @test_logs (:warn, r"does not exist") updateVariable!(fg, v3) == v3
    @test_throws ErrorException addVariable!(fg, v3)

    @test addFactor!(fg, [v1, v2], f1) == f1
    @test_throws ErrorException addFactor!(fg, [v1, v2], f1)
    @test @test_logs (:warn, r"does not exist") updateFactor!(fg, f2) == f2
    @test_throws ErrorException addFactor!(fg, [:b, :c], f2)

    #deletions
    @test deleteVariable!(fg, v3) == v3
    @test_throws ErrorException deleteVariable!(fg, v3)
    @test setdiff(ls(fg),[:a,:b]) == []
    @test deleteFactor!(fg, f2) == f2
    @test_throws ErrorException deleteFactor!(fg, f2)
    @test lsf(fg) == [:f1]


    @test getVariable(fg, :a) == v1
    @test getFactor(fg, :f1) == f1

    @test_throws ErrorException getVariable(fg, :c)
    @test_throws ErrorException getFactor(fg, :f2)


    # TODO move
    #list
    @test issetequal([:a,:b], listVariables(fg))
    @test issetequal([:f1], listFactors(fg))

    @test @test_deprecated getVariableIds(fg) == listVariables(fg)
    @test @test_deprecated getFactorIds(fg) == listFactors(fg)


end


#
@testset "tags" begin
    #
    # LOTS TODO

    @test issetequal(getTags(fg, :a), v1_tags)

    # TODO do we error on duplicates
    @test issetequal(addTags!(fg, :a, [:TAG]), v1_tags ∪ [:TAG])

    @test_broken emptyTags!(fg, :a)

    @test_broken updateTags!
    @test_broken deleteTags!
    @test_broken listTags
    @test_broken mergeTags!

end


@testset "Parametric Point Estimates" begin

    #  - `getPPEs`
    # **Set**
    # > - `emptyPPE!`
    # > - `mergePPE!`

    # Add a new PPE of type MeanMaxPPE to :x0
    ppe = MeanMaxPPE(:default, [0.0], [0.0], [0.0])

    @test addPPE!(fg, :a, ppe) == ppe
    @test_throws ErrorException addPPE!(fg, :a, ppe)


    @test listPPE(fg, :a) == [:default]
    # Get the data back - note that this is a reference to above.
    @test getPPE(fg, :a, :default) == ppe

    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    @test_throws ErrorException getPPE(fg, :a, :default)
    # Update add it
    #TODO warn key not exist
    @test @test_logs (:warn, r"does not exist") updatePPE!(fg, :a, ppe, :default) == ppe
    # Update update it
    @test updatePPE!(fg, :a, ppe, :default) == ppe
    # Bulk copy PPE's for x0 and x1
    @test updatePPE!(fg, [v1], :default) == nothing
    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

end

@testset "Variable Solver Data" begin
# #### Variable Solver Data
# **CRUD**
#  - `getVariableSolverData`
#  - `addVariableSolverData!`
#  - `updateVariableSolverData!`
#  - `deleteVariableSolverData!`
#
# > - `getVariableSolverDataAll` #TODO Data is already plural so maybe Variables, All or Dict
# > - `getVariablesSolverData`
#
# **Set like**
#  - `listVariableSolverData`
#
# > - `emptyVariableSolverData!` #TODO ?
# > - `mergeVariableSolverData!` #TODO ?
#
# **VariableNodeData**
#  - `getSolveInProgress`

    vnd = VariableNodeData{TestInferenceVariable1}()
    @test addVariableSolverData!(fg, :a, vnd, :parametric) == vnd

    @test_throws ErrorException addVariableSolverData!(fg, :a, vnd, :parametric)

    @test issetequal(listVariableSolverData(fg, :a), [:default, :parametric])

    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(fg, :a, :parametric)
    @test vndBack == vnd


    # Delete it
    @test deleteVariableSolverData!(fg, :a, :parametric) == vndBack
    # Update add it
    #TODO warn key not exist
    @test @test_logs (:warn, r"does not exist") updateVariableSolverData!(fg, :a, vnd, :parametric) == vnd

    # Update update it
    @test updateVariableSolverData!(fg, :a, vnd, :parametric) == vnd
    # Bulk copy update x0
    @test updateVariableSolverData!(fg, [v1], :default) == nothing

    # Delete parametric from v1
    @test deleteVariableSolverData!(fg, :a, :parametric) == vnd

    @test_throws ErrorException getVariableSolverData(fg, :a, :parametric)

end

@testset "BigData Entries" begin

    # getBigDataEntry
    # addBigDataEntry
    # updateBigDataEntry
    # deleteBigDataEntry
    # getBigDataEntries
    # getBigDataKeys
    # listBigDataEntries
    # emptyBigDataEntries
    # mergeBigDataEntries

    oid = zeros(UInt8,12); oid[12] = 0x01
    de1 = MongodbBigDataEntry(:key1, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x02
    de2 = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x03
    de2_update = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    #add
    v1 = getVariable(fg, :a)
    @test addBigDataEntry!(v1, de1) == de1
    @test addBigDataEntry!(fg, :a, de2) == de2
    @test_throws ErrorException addBigDataEntry!(v1, de1)
    @test de2 in getBigDataEntries(v1)

    #get
    @test deepcopy(de1) == getBigDataEntry(v1, :key1)
    @test deepcopy(de2) == getBigDataEntry(fg, :a, :key2)
    @test_throws ErrorException getBigDataEntry(v2, :key1)
    @test_throws ErrorException getBigDataEntry(fg, :b, :key1)

    #update
    @test updateBigDataEntry!(fg, :a, de2_update) == de2_update
    @test deepcopy(de2_update) == getBigDataEntry(fg, :a, :key2)
    @test @test_logs (:warn, r"does not exist") updateBigDataEntry!(fg, :b, de2_update) == de2_update

    #list
    entries = getBigDataEntries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e->e.key, entries), [:key1, :key2])
    @test length(getBigDataEntries(fg, :b)) == 1

    @test issetequal(getBigDataKeys(fg, :a), [:key1, :key2])
    @test getBigDataKeys(fg, :b) == Symbol[:key2]

    #delete
    @test deleteBigDataEntry!(v1, :key1) == v1
    @test getBigDataKeys(v1) == Symbol[:key2]
    #delete from dfg
    @test deleteBigDataEntry!(fg, :a, :key2) == v1
    @test getBigDataKeys(v1) == Symbol[]
end

## ========================================================================== ##

## ========================================================================== ##
#=
dfg = testDFGAPI{NoSolverParams}()

#add types for softtypes
struct TestInferenceVariable1 <: InferenceVariable end
struct TestInferenceVariable2 <: InferenceVariable end

v1 = DFGVariable(:a, TestInferenceVariable1())
v2 = DFGVariable(:b, TestInferenceVariable2())
f1 = DFGFactor{Int, :Symbol}(:f1)

#add tags for filters
union!(v1.tags, [:VARIABLE, :POSE])
union!(v2.tags, [:VARIABLE, :LANDMARK])
union!(f1.tags, [:FACTOR])

st1 = TestInferenceVariable1()
st2 = TestInferenceVariable2()

getSolverData(v1).softtype = deepcopy(st1)
getSolverData(v2).softtype = deepcopy(st2)

# set v1 to solvable=0
setSolvable!(v1, 0)
# set v1 and f1 solveInProgress
getSolverData(v1).solveInProgress = 1
getSolverData(f1).solveInProgress = 1


# NOTE: Just for testing
# Override compareAllSpecial for testing our DFGFactor{Int, :Symbol}
# as we don't have IIF which overloads with the proper compareSpecial(::CommonConvWrapper)
import DistributedFactorGraphs: compareAllSpecial
function compareAllSpecial(A::T1, B::T2;
                    skip=Symbol[], show::Bool=true) where {T1 <: Int, T2 <: Int}
  #
  T1 != T2 && return false
  return compareAll(A, B, skip=skip, show=show)
end

# @testset "Creating Graphs" begin
global dfg,v1,v2,f1
addVariable!(dfg, v1)
addVariable!(dfg, v2)
addFactor!(dfg, [v1, v2], f1)
@test_throws Exception addFactor!(dfg, DFGFactor{Int, :Symbol}("f2"), [v1, DFGVariable("Nope")])
# end
##
@testset "Adding Removing Nodes" begin
    dfg2 = testDFGAPI{NoSolverParams}()
    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    v3 = DFGVariable(:c, TestInferenceVariable1())
    f1 = DFGFactor{Int, :Symbol}(:f1)
    f2 = DFGFactor{Int, :Symbol}(:f2)
    # @testset "Creating Graphs" begin
    @test addVariable!(dfg2, v1)
    @test addVariable!(dfg2, v2)
    @test_throws ErrorException updateVariable!(dfg2, v3)
    @test addVariable!(dfg2, v3)
    @test_throws ErrorException addVariable!(dfg2, v3)
    @test addFactor!(dfg2, [v1, v2], f1)
    @test_throws ErrorException addFactor!(dfg2, [v1, v2], f1)
    @test_throws ErrorException updateFactor!(dfg2, f2)
    @test addFactor!(dfg2, [:b, :c], f2)
    @test deleteVariable!(dfg2, v3) == v3
    @test symdiff(ls(dfg2),[:a,:b]) == []
    @test deleteFactor!(dfg2, f2) == f2
    @test lsf(dfg2) == [:f1]
end

@testset "Listing Nodes" begin
    global dfg,v1,v2,f1
    @test length(ls(dfg)) == 2
    @test length(lsf(dfg)) == 1
    @test symdiff([:a, :b], listVariables(dfg)) == []
    # Additional testing for https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/201
    @test symdiff([:a, :b], listVariables(dfg, solvable=0)) == []
    @test listVariables(dfg, solvable=1) == [:b]
      # WHAT -- still does not work?
      # v2b = deepcopy(v2)
      # setTags!(v2b, [:VARIABLE; :LANDMARK])
      # setSolvable!(v2b, 1)
      # setTimestamp!(v2b, getTimestamp(getVariables(dfg, solvable=1)[1]))
    @test getVariables(dfg, solvable=1) == [v2]
    @test listFactors(dfg) == [:f1]
    @test listFactors(dfg, solvable=1) == []
    @test listFactors(dfg, solvable=0) == [:f1]
    @test getFactors(dfg, solvable=0) == [f1]
    #
    @test lsf(dfg, :a) == [f1.label]
    # Tags
    @test ls(dfg, tags=[:POSE]) == [:a]
    @test symdiff(ls(dfg, tags=[:POSE, :LANDMARK]), ls(dfg, tags=[:VARIABLE])) == []
    # Regexes
    @test ls(dfg, r"a") == [v1.label]
    @test lsf(dfg, r"f*") == [f1.label]
    # Accessors
    @test getAddHistory(dfg) == [:a, :b] #, :f1
    @test getDescription(dfg) != nothing
    @test_throws ErrorException getLabelDict(dfg)
    # Existence
    @test exists(dfg, :a) == true
    @test exists(dfg, v1) == true
    @test exists(dfg, :nope) == false
    # Sorting of results
    # TODO - this function needs to be cleaned up
    unsorted = [:x1_3;:x1_6;:l1;:april1] #this will not work for :x1x2f1
    @test sortDFG(unsorted) == sortVarNested(unsorted)
    @test sort([:x1x2f1, :x1l1f1], lt=DistributedFactorGraphs.natural_lt) == [:x1l1f1, :x1x2f1]
    l = [:a1, :X1, :b1c2, :x2_2, :c, :x1, :x10, :x1_1, :x10_10,:a, :x2_1, :xy3, :l1, :x1_2, :x1l1f1, Symbol("1a1"), :x1x2f1]
    @test sort(l, lt=DistributedFactorGraphs.natural_lt) == [Symbol("1a1"), :X1, :a, :a1, :b1c2, :c, :l1, :x1, :x1_1, :x1_2, :x1l1f1, :x1x2f1, :x2_1, :x2_2, :x10, :x10_10, :xy3]
end

# Gets
@testset "Gets, Sets, and Accessors" begin
    global dfg,v1,v2,f1
    #TODO compare variable and factor
    @test getVariable(dfg, v1.label) == v1
    @test_broken getVariable(dfg, v2.label) != v1
    @test getFactor(dfg, f1.label) == f1
    f2 = deepcopy(f1)
    f2.label = :something
    @test f2 != f1
    #TODO we should really finish defining error behaviour
    @test_throws Exception getVariable(dfg, :nope)
    # @test getVariable(dfg, :nope) == nothing
    @test_throws Exception getVariable(dfg, "nope")
    @test_throws Exception getFactor(dfg, :nope)
    @test_throws Exception getFactor(dfg, "nope")

    # Sets
    v1Prime = deepcopy(v1)
    #updateVariable! returns the variable updated, so should be equal
    @test_broken updateVariable!(dfg, v1Prime) == v1
    f1Prime = deepcopy(f1)
    #updateFactor! returns the factor updated, so should be equal
    @test_broken updateFactor!(dfg, f1Prime) == f1
    # Revert
    v1 = getVariable(dfg, v1.label)
    f1 = getFactor(dfg, f1.label)

    # Accessors
    @test getLabel(v1) == v1.label
    @test getTags(v1) == v1.tags
    testTags = [:ha, :ha23]
    @test setTags!(v1, testTags) == Set(testTags)
    @test getTags(v1) == Set(testTags)

    @test getTimestamp(v1) == v1.timestamp
    testTimestamp = now()
    #TODO set timestamp immutable, confirm behaviour
    v1ts = setTimestamp(v1, testTimestamp)
    updateVariable!(dfg, v1ts)
    @test getVariable(dfg, v1ts.label) == v1ts
    @test v1ts != v1
    v1 = getVariable(dfg, v1ts.label)
    @test getTimestamp(v1) == testTimestamp

    @test getTimestamp(f1) == f1.timestamp
    testTimestamp = now()
    @test setTimestamp!(f1, testTimestamp) == testTimestamp
    @test getTimestamp(f1) == f1.timestamp

    @test getVariablePPEs(v1) == v1.ppeDict
    @test getVariablePPE(v1, :notfound) == nothing
    @test getSolverData(v1) === v1.solverDataDict[:default]
    @test @test_logs (:warn, r"[Dd]eprecate") getData(v1) === v1.solverDataDict[:default]
    @test @test_logs (:warn, r"[Dd]eprecate") solverData(v1, :default) === v1.solverDataDict[:default]
    @test getSolverDataDict(v1) == v1.solverDataDict
    @test getInternalId(v1) == v1._internalId

    #TODO: Finish
    # Add new VND of type ContinuousScalar to :x0
    # Could also do VariableNodeData(ContinuousScalar())
    vnd = VariableNodeData{TestInferenceVariable1}()
    addVariableSolverData!(dfg, :a, vnd, :parametric)
    @test setdiff(listVariableSolverData(dfg, :a), [:default, :parametric]) == []
    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(dfg, :a, :parametric)
    @test vndBack == vnd
    # Delete it
    @test deleteVariableSolverData!(dfg, :a, :parametric) == vndBack
    # Update add it
    updateVariableSolverData!(dfg, :a, vnd, :parametric)
    # Update update it
    updateVariableSolverData!(dfg, :a, vnd, :parametric)
    # Bulk copy update x0
    updateVariableSolverData!(dfg, [v1], :default)
    # Delete parametric from v1
    deleteVariableSolverData!(dfg, :a, :parametric)

    #TODO: Finish
    # Add a new PPE of type MeanMaxPPE to :x0
    ppe = MeanMaxPPE(:default, [0.0], [0.0], [0.0])
    addPPE!(dfg, :a, ppe)
    @test listPPE(dfg, :a) == [:default]
    # Get the data back - note that this is a reference to above.
    @test getPPE(dfg, :a, :default) == ppe

    # Delete it
    @test deletePPE!(dfg, :a, :default) == ppe
    # Update add it
    updatePPE!(dfg, :a, ppe, :default)
    # Update update it
    updatePPE!(dfg, :a, ppe, :default)
    # Bulk copy PPE's for x0 and x1
    updatePPE!(dfg, [v1], :default)
    # Delete it
    @test deletePPE!(dfg, :a, :default) == ppe

    #TODO I don't know what is supposed to happen to softtype
    @test getSofttype(v1) == st1
    @test getSofttype(v2) == st2

    @test getLabel(f1) == f1.label
    @test getTags(f1) == f1.tags
    @test setTags!(v1, testTags) == Set(testTags)
    @test getTags(v1) == Set(testTags)

    @test getSolverData(f1) == f1.solverData
    # Deprecated functions
    @test @test_logs (:warn, r"[Dd]eprecate") solverData(f1) == f1.solverData
    # REMOVED? @test getData(f1) == f1.data
    # Internal function
    @test getInternalId(f1) == f1._dfgNodeParams._internalId

    @test getSolverParams(dfg) != nothing
    @test setSolverParams!(dfg, getSolverParams(dfg)) == getSolverParams(dfg)

    #solver data is initialized
    @test !isInitialized(dfg, :a)
    @test !isInitialized(v2)
    @test @test_logs (:error, r"Variable does not have solver data") !isInitialized(v2, key=:second)
    # isSolvable and isSolveInProgress
    #TODO implement or deprecate isSolvable
    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1
    @test getSolvable(f1) == 0
    @test getSolvable(v1) == 0

    #TODO isSolveInProgress was not deprecated
    @test getSolveInProgress(v1) == 1
    @test getSolveInProgress(f1) == 1
    # setSolvable, getSolvable, and variants
    v1 = getVariable(dfg, v1.label)
    f1 = getFactor(dfg, f1.label)
    @test setSolvable!(v1, 1) == 1
    @test getSolvable(v1) == 1
    @test setSolvable!(dfg, v1.label, 0) == 0
    @test getSolvable(v1) == 0
    @test setSolvable!(f1, 1) == 1
    @test getSolvable(dfg, f1.label) == 1
    @test setSolvable!(dfg, f1.label, 0) == 0
    @test getSolvable(f1) == 0


    # isFactor and isVariable
    @test isFactor(dfg, f1.label)
    @test !isFactor(dfg, v1.label)
    @test isVariable(dfg, v1.label)
    @test !isVariable(dfg, f1.label)
    @test !isVariable(dfg, :doesntexist)
    @test !isFactor(dfg, :doesntexist)

    # test solveCount for variable
    @test !isSolved(v1)
    @test getSolvedCount(v1) == 0
    setSolvedCount!(v1, 1)
    @test getSolvedCount(v1) == 1
    @test isSolved(v1)
    setSolvedCount!(dfg, getLabel(v1), 2)
    @test getSolvedCount(dfg, getLabel(v1)) == 2

    # Session, robot, and user small data tests
    smallUserData = Dict{Symbol, String}(:a => "42", :b => "Hello")
    smallRobotData = Dict{Symbol, String}(:a => "43", :b => "Hello")
    smallSessionData = Dict{Symbol, String}(:a => "44", :b => "Hello")
    setUserData!(dfg, deepcopy(smallUserData))
    setRobotData!(dfg, deepcopy(smallRobotData))
    setSessionData!(dfg, deepcopy(smallSessionData))
    @test getUserData(dfg) == smallUserData
    @test getRobotData(dfg) == smallRobotData
    @test getSessionData(dfg) == smallSessionData

end

@testset "BigData Entries" begin
    oid = zeros(UInt8,12); oid[12] = 0x01
    de1 = MongodbBigDataEntry(:key1, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x02
    de2 = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    oid = zeros(UInt8,12); oid[12] = 0x03
    de2_update = MongodbBigDataEntry(:key2, NTuple{12,UInt8}(oid))

    #add
    v1 = getVariable(dfg, :a)
    @test addBigDataEntry!(v1, de1) == v1
    @test addBigDataEntry!(dfg, :a, de2) == v1
    @test_throws ErrorException addBigDataEntry!(v1, de1)
    @test de2 in getBigDataEntries(v1)

    #get
    @test deepcopy(de1) == getBigDataEntry(v1, :key1)
    @test deepcopy(de2) == getBigDataEntry(dfg, :a, :key2)
    @test getBigDataEntry(v2, :key1) == nothing
    @test getBigDataEntry(dfg, :b, :key1) == nothing

    #update
    @test updateBigDataEntry!(dfg, :a, de2_update) == v1
    @test deepcopy(de2_update) == getBigDataEntry(dfg, :a, :key2)
    @test @test_logs (:error, r"does not exist") updateBigDataEntry!(dfg, :b, de2_update) == nothing

    #list
    entries = getBigDataEntries(dfg, :a)
    @test length(entries) == 2
    @test symdiff(map(e->e.key, entries), [:key1, :key2]) == Symbol[]
    @test length(getBigDataEntries(dfg, :b)) == 0

    @test symdiff(getBigDataKeys(dfg, :a), [:key1, :key2]) == Symbol[]
    @test getBigDataKeys(dfg, :b) == Symbol[]

    #delete
    @test deleteBigDataEntry!(v1, :key1) == v1
    @test getBigDataKeys(v1) == Symbol[:key2]
    #delete from dfg
    @test deleteBigDataEntry!(dfg, :a, :key2) == v1
    @test getBigDataKeys(v1) == Symbol[]
end

@testset "Updating Nodes" begin
    global dfg
    #get the variable
    var = getVariable(dfg, :a)
    #make a copy and simulate external changes
    newvar = deepcopy(var)
    getVariablePPEs(newvar)[:default] = MeanMaxPPE(:default, [150.0], [100.0], [50.0])
    #update
    mergeUpdateVariableSolverData!(dfg, newvar)

    #For now spot check
    #TODO solverDataDict() not deprecated
    @test getSolverDataDict(newvar) == getSolverDataDict(var)
    @test getVariablePPEs(newvar) == getVariablePPEs(var)
    @test getMaxPPE(getVariablePPEs(newvar)[:default]) == getVariablePPEs(newvar)[:default].max
    @test getMeanPPE(getVariablePPEs(newvar)[:default]) == getVariablePPEs(newvar)[:default].mean
    @test getSuggestedPPE(getVariablePPEs(newvar)[:default]) == getVariablePPEs(newvar)[:default].suggested

    # Delete :default and replace to see if new ones can be added
    delete!(getVariablePPEs(newvar), :default)
    getVariablePPEs(newvar)[:second] = MeanMaxPPE(:second, [15.0], [10.0], [5.0])

    # Persist to the original variable.
    mergeUpdateVariableSolverData!(dfg, newvar)
    # At this point newvar will have only :second, and var should have both (it is the reference)
    @test symdiff(collect(keys(getVariablePPEs(var))), [:default, :second]) == Symbol[]
    @test symdiff(collect(keys(getVariablePPEs(newvar))), [:second]) == Symbol[]
    # Get the source too.
    @test symdiff(collect(keys(getVariablePPEs(getVariable(dfg, :a)))), [:default, :second]) == Symbol[]
end

# Connectivity test
@testset "Connectivity Test" begin
    global dfg,v1,v2,f1
    @test isFullyConnected(dfg) == true
    @test hasOrphans(dfg) == false
    addVariable!(dfg, DFGVariable(:orphan, TestInferenceVariable1()))
    @test isFullyConnected(dfg) == false
    @test hasOrphans(dfg) == true
end

# Adjacency matrices
@testset "Adjacency Matrices" begin
    global dfg,v1,v2,f1
    # Normal
    #deprecated
    @test_throws ErrorException getAdjacencyMatrix(dfg)
    adjMat = DistributedFactorGraphs.getAdjacencyMatrixSymbols(dfg)
    @test size(adjMat) == (2,4)
    @test symdiff(adjMat[1, :], [nothing, :a, :b, :orphan]) == Symbol[]
    @test symdiff(adjMat[2, :], [:f1, :f1, :f1, nothing]) == Symbol[]
    #
    #sparse
    #TODO this silly name thing has gone on too long
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg)
    @test size(adjMat) == (1,3)

    # Checking the elements of adjacency, its not sorted so need indexing function
    indexOf = (arr, el1) -> findfirst(el2->el2==el1, arr)
    @test adjMat[1, indexOf(v_ll, :orphan)] == 0
    @test adjMat[1, indexOf(v_ll, :a)] == 1
    @test adjMat[1, indexOf(v_ll, :b)] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:f1, :f1, :f1]) == Symbol[]

    # Filtered - REF DFG #201
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg, solvable=1)
    @test size(adjMat) == (0,2)

    # sparse
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(dfg, solvable=1)
    @test size(adjMat) == (0,2)
    @test v_ll == [:orphan, :b]
    @test f_ll == []

end

# Deletions
@testset "Deletions" begin
    deleteFactor!(dfg, :f1)
    @test listFactors(dfg) == []
    deleteVariable!(dfg, :b)
    @test symdiff([:a, :orphan], listVariables(dfg)) == []
    #delete last also for the LightGraphs implementation coverage
    deleteVariable!(dfg, :orphan)
    @test symdiff([:a], listVariables(dfg)) == []
    deleteVariable!(dfg, :a)
    @test listVariables(dfg) == []
end


# Now make a complex graph for connectivity tests
numNodes = 10
dfg = testDFGAPI{NoSolverParams}()
verts = map(n -> DFGVariable(Symbol("x$n"), TestInferenceVariable1()), 1:numNodes)
#change ready and solveInProgress for x7,x8 for improved tests on x7x8f1
#NOTE because defaults changed
verts[8]._dfgNodeParams.solvable = 0
verts[9]._dfgNodeParams.solvable = 0
# Can't change the softtypes now.
# #force softytypes to first 2 vertices.
# verts[1].solverDataDict[:default].softtype = deepcopy(st1)
# verts[2].solverDataDict[:default].softtype = deepcopy(st2)

map(v -> addVariable!(dfg, v), verts)
map(n -> addFactor!(dfg, [verts[n], verts[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:(numNodes-1))

getFactor(dfg, :x7x8f1)._dfgNodeParams.solvable = 0

@testset "Getting Neighbors" begin
    global dfg,verts
    # Trivial test to validate that intersect([], []) returns order of first parameter
    @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
    # Get neighbors tests
    @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = getNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test neighbors == [:x1, :x2]
    # Testing aliases
    @test getNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test getNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

    # Solvable
    @test getNeighbors(dfg, :x5, solvable=1) == Symbol[]
    @test getNeighbors(dfg, :x5, solvable=0) == [:x4x5f1,:x5x6f1]
    @test getNeighbors(dfg, :x5) == [:x4x5f1,:x5x6f1]
    @test getNeighbors(dfg, :x7x8f1, solvable=0) == [:x7, :x8]
    @test getNeighbors(dfg, :x7x8f1, solvable=1) == [:x7]
    @test getNeighbors(dfg, verts[1], solvable=0) == [:x1x2f1]
    @test getNeighbors(dfg, verts[1], solvable=1) == Symbol[]
    @test getNeighbors(dfg, verts[1]) == [:x1x2f1]

end

@testset "Getting Subgraphs" begin
    # Subgraphs
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test include orphan factors
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
    @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test adding to the dfg
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    #
    dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []

    # DFG issue #201 Test include orphan factors with filtering - should only return x7 with solvable=1
    dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=0)
    @test symdiff([:x7, :x8, :x7x8f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Filter - always returns the node you start at but filters around that.
    dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=1)
    @test symdiff([:x7x8f1, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test for distance = 2, should return orphans
    #:x7x8f1 is not solvable
    dfgSubgraph = getSubgraphAroundNode(dfg, getVariable(dfg, :x8), 2, true, solvable=1)
    @test symdiff([:x8, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []

    # DFG issue #95 - confirming that getSubgraphAroundNode retains order
    # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
    for fId in listVariables(dfg)
        # Get a subgraph of this and it's related factors+variables
        dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
        # For each factor check that the order the copied graph == original
        for fact in getFactors(dfgSubgraph)
            @test fact._variableOrderSymbols == getFactor(dfg, fact.label)._variableOrderSymbols
        end
    end
end

#TODO Summaries and Summary Graphs
@testset "Summaries and Summary Graphs" begin
    factorFields = fieldnames(DFGFactorSummary)
    variableFields = fieldnames(DFGVariableSummary)

    summary = getSummary(dfg)
    @test symdiff(collect(keys(summary.variables)), ls(dfg)) == Symbol[]
    @test symdiff(collect(keys(summary.factors)), lsf(dfg)) == Symbol[]

    summaryGraph = getSummaryGraph(dfg)
    @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
    @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
    # Check all fields are equal for all variables
    for v in ls(summaryGraph)
        for field in variableFields
            if field != :softtypename
                @test getproperty(getVariable(dfg, v), field) == getproperty(getVariable(summaryGraph, v), field)
            else
                # Special case to check the symbol softtype is equal to the full softtype.
                @test Symbol(typeof(getSofttype(getVariable(dfg, v)))) == getSofttype(getVariable(summaryGraph, v))
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            @test getproperty(getFactor(dfg, f), field) == getproperty(getFactor(summaryGraph, f), field)
        end
    end
end

@testset "Producing Dot Files" begin
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI{NoSolverParams}()
    v1 = DFGVariable(:a, TestInferenceVariable1())
    v2 = DFGVariable(:b, TestInferenceVariable1())
    f1 = DFGFactor{Int, :Symbol}(:f1)
    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    addFactor!(dotdfg, [v1, v2], f1)
    #NOTE hardcoded toDot will have different results so test LightGraphs seperately
    if testDFGAPI == LightDFG
        @test toDot(dotdfg) == "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nf1 [color=blue, shape=box];\na -- f1\nb -- f1\n}\n"
    else
        @test toDot(dotdfg) == "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"f1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
    end
    @test toDotFile(dotdfg, "something.dot") == nothing
    Base.rm("something.dot")

end

=#
