using DistributedFactorGraphs
using Test
using Dates

# TODO, dink meer aan: Trait based softtypes or hard type for VariableNodeData
# Test InferenceVariable Types
struct TestSofttype1 <: InferenceVariable
    dims::Int
    manifolds::Tuple{Symbol}
    TestSofttype1() = new(1,(:Euclid,))
end

struct TestSofttype2 <: InferenceVariable
    dims::Int
    manifolds::Tuple{Symbol, Symbol}
    TestSofttype2() = new(2,(:Euclid,:Circular,))
end

# Test Factor Types TODO same with factor type if I can figure out what it is and how it works
struct TestFunctorInferenceType1 <: FunctorInferenceType end
struct TestFunctorInferenceType2 <: FunctorInferenceType end

struct TestFunctorSingleton <: FunctorSingleton end
struct TestFunctorPairwise <: FunctorPairwise end
struct TestFunctorPairwiseMinimize <: FunctorPairwiseMinimize end

struct TestCCW{T} <: ConvolutionObject where {T<:FunctorInferenceType}
    usrfnc!::T
end
Base.:(==)(a::TestCCW, b::TestCCW) = a.usrfnc! == b.usrfnc!


global testDFGAPI = LightDFG
global testDFGAPI = GraphsDFG

#test Specific definitions
# struct TestInferenceVariable1 <: InferenceVariable end
# struct TestInferenceVariable2 <: InferenceVariable end
# struct TestFunctorInferenceType1 <: FunctorInferenceType end

# TODO see note in AbstractDFG.jl setSolverParams!
struct GeenSolverParams <: AbstractParams
end

T = testDFGAPI
solparams=NoSolverParams()
# DFG Accessors
function DFGStructureAndAccessors(::Type{T}, solparams::AbstractParams=NoSolverParams()) where T <: AbstractDFG
    # "DFG Structure and Accessors"
    # Constructors
    # Constructors to be implemented
    fg = T(params=solparams)
    #TODO test something better
    @test isa(fg, T)

    des = "description"
    uId = "userId"
    rId = "robotId"
    sId = "sessionId"
    ud = :ud=>"udEntry"
    rd = :rd=>"rdEntry"
    sd = :sd=>"sdEntry"
    fg = T(des, uId,  rId,  sId,  Dict{Symbol, String}(ud),  Dict{Symbol, String}(rd),  Dict{Symbol, String}(sd),  solparams)

    # accesssors
    # get
    @test getDescription(fg) == des
    @test getUserId(fg) == uId
    @test getRobotId(fg) == rId
    @test getSessionId(fg) == sId
    @test getAddHistory(fg) === fg.addHistory

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


    @test setSolverParams!(fg, typeof(solparams)()) == typeof(solparams)()

    @test setDescription!(fg, des*"_1") == des*"_1"

    #TODO I don't like, so not exporting, and not recommended to use
    #     Technically if you set Ids its a new object
    @test DistributedFactorGraphs.setUserId!(fg, uId*"_1") == uId*"_1"
    @test DistributedFactorGraphs.setRobotId!(fg, rId*"_1") == rId*"_1"
    @test DistributedFactorGraphs.setSessionId!(fg, sId*"_1") == sId*"_1"


    #deprecated
    @test_throws ErrorException getLabelDict(fg)


    #TODO
    # duplicateEmptyDFG
    # copyEmptyDFG
    # emptyDFG ?
    # _getDuplicatedEmptyDFG
    # copyEmptyDFG(::Type{T}, sourceDFG) where T <: AbstractDFG = T(getDFGInfo(sourceDFG))
    # copyEmptyDFG(sourceDFG::T) where T <: AbstractDFG = copyEmptyDFG(T, sourceDFG)

    return fg

end

# User, Robot, Session Data
function  UserRobotSessionData!(fg::AbstractDFG)
    # "User, Robot, Session Data"
    # User Data
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

function DFGVariableSCA()
    # "DFG Variable"

    v1_lbl = :a
    v1_tags = Set([:VARIABLE, :POSE])
    small = Dict("small"=>"data")
    testTimestamp = now()
    # Constructors
    v1 = DFGVariable(v1_lbl, TestSofttype1(), tags=v1_tags, solvable=0, solverDataDict=Dict(:default=>VariableNodeData{TestSofttype1}()))
    v2 = DFGVariable(:b, VariableNodeData{TestSofttype2}(), tags=Set([:VARIABLE, :LANDMARK]))
    v3 = DFGVariable(:c, VariableNodeData{TestSofttype2}())


    getSolverData(v1).solveInProgress = 1

    @test getLabel(v1) == v1_lbl
    @test getTags(v1) == v1_tags

    @test getTimestamp(v1) == v1.timestamp

    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1

    # TODO direct use is not recommended, use accessors, maybe not export or deprecate
    @test getSolverDataDict(v1) == v1.solverDataDict

    @test getPPEDict(v1) == v1.ppeDict

    @test getSmallData(v1) == Dict{String,String}()

    @test getSofttype(v1) == TestSofttype1()


    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(v3, testTags) == Set(testTags)
    @test setTags!(v3, Set(testTags)) == Set(testTags)

    #NOTE  a variable's timestamp is considered similar to its label.  setTimestamp! (not implemented) would create a new variable and call updateVariable!
    v1ts = setTimestamp(v1, testTimestamp)
    @test getTimestamp(v1ts) == testTimestamp
    #follow with updateVariable!(fg, v1ts)

    @test_throws MethodError setTimestamp!(v1, testTimestamp)

    @test setSolvable!(v1, 1) == 1
    @test getSolvable(v1) == 1
    @test setSolvable!(v1, 0) == 0

    @test setSmallData!(v1, small) == small
    @test getSmallData(v1) == small

    #no accessors on BigData, only CRUD

    #deprecated
    # @test @test_deprecated solverData(v1, :default) === v1.solverDataDict[:default]


    # #TODO sort out
    # getPPEs
    # getSolverData
    # setSolverData
    # getVariablePPEs
    # getVariablePPE
    # getSolvedCount
    # isSolved
    # setSolvedCount

    return (v1=v1, v2=v2, v3=v3, v1_tags=v1_tags)

end



function  DFGFactorSCA()
    # "DFG Factor"

    # Constructors
    #DFGVariable solvable default to 1, but Factor to 0, is that correct
    f1_lbl = :abf1
    f1_tags = Set([:FACTOR])
    testTimestamp = now()

    gfnd_prior = GenericFunctionNodeData(Symbol[], false, false, Int[], :DistributedFactorGraphs, TestCCW(TestFunctorSingleton()))

    gfnd = GenericFunctionNodeData(Symbol[], false, false, Int[], :DistributedFactorGraphs, TestCCW(TestFunctorInferenceType1()))

    f1 = DFGFactor{TestCCW{TestFunctorInferenceType1}, Symbol}(f1_lbl)
    f1 = DFGFactor(f1_lbl, [:a,:b], gfnd, tags = f1_tags, solvable=0)

    f2 = DFGFactor{TestFunctorInferenceType1, Symbol}(:bcf1)

    @test getLabel(f1) == f1_lbl
    @test getTags(f1) == f1_tags

    @test getTimestamp(f1) == f1.timestamp

    @test getInternalId(f1) == f1._dfgNodeParams._internalId

    @test getSolvable(f1) == 0


    @test getSolverData(f1) === f1.solverData

    @test getVariableOrder(f1) == [:a,:b]

    getSolverData(f1).solveInProgress = 1
    @test setSolvable!(f1, 1) == 1

    #TODO These 2 function are equivelent
    @test typeof(getFactorType(f1)) == TestFunctorInferenceType1
    @test typeof(getFactorFunction(f1)) == TestFunctorInferenceType1


    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(f1, testTags) == Set(testTags)
    @test setTags!(f1, Set(testTags)) == Set(testTags)

    #TODO Handle same way as variable
    f1ts = setTimestamp(f1, testTimestamp)
    @test !(f1ts === f1)
    @test getTimestamp(f1ts) == testTimestamp
    #follow with updateFactor!(fg, v1ts)
    @test setTimestamp!(f1, testTimestamp) == testTimestamp
    #/TODO

    @test setSolvable!(f1, 1) == 1
    @test getSolvable(f1) == 1

    #TODO don't know if this should be used, added for completeness, it just wastes the gc's time
    @test setSolverData!(f1, deepcopy(gfnd)) == gfnd

    # create f0 here for a later timestamp
    f0 = DFGFactor(:af1, [:a], gfnd_prior, tags = Set([:PRIOR]))

    return  (f0=f0, f1=f1, f2=f2)
end

function  VariablesandFactorsCRUD_SET!(fg, v1, v2, v3, f0, f1, f2)
    # "Variables and Factors CRUD an SET"

    #TODO dont throw ErrorException
    #TODO test remaining add signitures
    # global fg
    # fg = GraphsDFG(params=NoSolverParams())
    # fg = LightDFG(params=NoSolverParams())
    # add update delete
    @test addVariable!(fg, v1) == v1
    @test addVariable!(fg, v2) == v2

    #TODO standardize this error and res also for that matter
    @test_throws Exception addFactor!(fg, [:a, :nope], f1)
    @test_throws Exception addFactor!(fg, [v1, v2, v3], f1)

    @test addFactor!(fg, [v1, v2], f1) === f1
    @test_throws ErrorException addFactor!(fg, [v1, v2], f1)

    @test @test_logs (:warn, r"does not exist") updateVariable!(fg, v3) == v3
    @test updateVariable!(fg, v3) == v3
    @test_throws ErrorException addVariable!(fg, v3)

    @test @test_logs (:warn, r"does not exist") updateFactor!(fg, f2) === f2
    @test updateFactor!(fg, f2) === f2
    @test_throws ErrorException addFactor!(fg, [:b, :c], f2)
    #TODO Graphs.jl, but look at refactoring absract @test_throws ErrorException addFactor!(fg, f2)

    @test getAddHistory(fg) == [:a, :b, :c]

    # Extra timestamp functions https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/315
    if !(v1 isa SkeletonDFGVariable)
        newtimestamp = now()
        @test !(setTimestamp!(fg, :c, newtimestamp) === v3)
        @test getVariable(fg, :c) |> getTimestamp == newtimestamp

        @test !(setTimestamp!(fg, :bcf1, newtimestamp) === f2)
        @test getFactor(fg, :bcf1) |> getTimestamp == newtimestamp
    end
    #deletions
    @test getVariable(fg, :c) === deleteVariable!(fg, v3)
    @test_throws ErrorException deleteVariable!(fg, v3)
    @test setdiff(ls(fg),[:a,:b]) == []
    @test getFactor(fg, :bcf1) === deleteFactor!(fg, f2)
    @test_throws ErrorException deleteFactor!(fg, f2)
    @test lsf(fg) == [:abf1]


    @test getVariable(fg, :a) == v1
    @test getVariable(fg, :a, :default) == v1

    @test addFactor!(fg, f0) == f0

    if isa(v1, DFGVariable)
        #TODO decide if this should be @error or other type
        @test_throws ErrorException getVariable(fg, :a, :missingfoo)
    else
        @test_logs (:warn, r"supported for type DFGVariable") getVariable(fg, :a, :missingfoo)
    end

    @test getFactor(fg, :abf1) === f1

    @test_throws ErrorException getVariable(fg, :c)
    @test_throws ErrorException getFactor(fg, :bcf1)

    #test issue #375
    @test_skip @test_throws ErrorException getVariable(fg, :abf1)
    @test_skip @test_throws ErrorException getFactor(fg, :a)

    # Existence
    @test exists(fg, :a)
    @test !exists(fg, :c)
    @test exists(fg, :abf1)
    @test !exists(fg, :bcf1)

    @test exists(fg, v1)
    @test !exists(fg, v3)
    @test exists(fg, f1)
    @test !exists(fg, f2)

    # check types
    @test isVariable(fg, :a)
    @test !isVariable(fg, :abf1)

    @test isFactor(fg, :abf1)
    @test !isFactor(fg, :a)

    if f0 isa DFGFactor
        @test isPrior(fg, :af1)
        @test !isPrior(fg, :abf1)
    end

    #list
    @test length(getVariables(fg)) == 2
    @test issetequal(getLabel.(getFactors(fg)), [:af1, :abf1])

    @test issetequal([:a,:b], listVariables(fg))
    @test issetequal([:af1,:abf1], listFactors(fg))

    @test ls(fg) == listVariables(fg)
    @test lsf(fg) == listFactors(fg)

    @test @test_deprecated getVariableIds(fg) == listVariables(fg)
    @test @test_deprecated getFactorIds(fg) == listFactors(fg)

end


function  tagsTestBlock!(fg, v1, v1_tags)
# "tags"
#
    v1Tags = deepcopy(getTags(v1))
    @test issetequal(v1Tags, v1_tags)
    @test issetequal(listTags(fg, :a), v1Tags)
    @test issetequal(mergeTags!(fg, :a, [:TAG]), v1Tags ∪ [:TAG])
    @test issetequal(removeTags!(fg, :a, [:TAG]), v1Tags)
    @test emptyTags!(fg, :a) == Set{Symbol}()


    v2Tags = [listTags(fg, :b)...]
    @test hasTags(fg, :b, [v2Tags...])
    @test hasTags(fg, :b, [:LANDMARK, :TAG], matchAll=false)

    @test hasTagsNeighbors(fg, :abf1, [:LANDMARK])
    @test !hasTagsNeighbors(fg, :abf1, [:LANDMARK, :TAG])

end


function  PPETestBlock!(fg, v1)
    # "Parametric Point Estimates"

    #  - `getPPEs`
    # **Set**
    # > - `emptyPPE!`
    # > - `mergePPE!`

    # Add a new PPE of type MeanMaxPPE to :x0
    ppe = MeanMaxPPE(:default, [0.0], [0.0], [0.0])

    @test getMaxPPE(ppe) === ppe.max
    @test getMeanPPE(ppe) === ppe.mean
    @test getSuggestedPPE(ppe) === ppe.suggested
    @test getLastUpdatedTimestamp(ppe) === ppe.lastUpdatedTimestamp

    @test addPPE!(fg, :a, ppe) == ppe
    @test_throws ErrorException addPPE!(fg, :a, ppe)


    @test listPPEs(fg, :a) == [:default]
    # Get the data back - note that this is a reference to above.
    @test getPPE(fg, :a, :default) == ppe

    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    @test_throws ErrorException getPPE(fg, :a, :default)
    # Update add it
    @test @test_logs (:warn, r"does not exist") updatePPE!(fg, :a, ppe, :default) == ppe
    # Update update it
    @test updatePPE!(fg, :a, ppe, :default) == ppe
    # Bulk copy PPE's for x0 and x1
    @test updatePPE!(fg, [v1], :default) == nothing
    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    #FIXME copied from lower
    # @test @test_deprecated getVariablePPEs(v1) == v1.ppeDict
    @test_throws KeyError getPPE(v1, :notfound)
    #TODO
    # @test_deprecated getVariablePPE(v1)

    # Add a new PPE of type MeanMaxPPE to :x0
    ppe = MeanMaxPPE(:default, [0.0], [0.0], [0.0])
    addPPE!(fg, :a, ppe)
    @test listPPEs(fg, :a) == [:default]
    # Get the data back - note that this is a reference to above.
    @test getPPE(fg, :a, :default) == ppe

    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe
    # Update add it
    updatePPE!(fg, :a, ppe, :default)
    # Update update it
    updatePPE!(fg, :a, ppe, :default)
    # Bulk copy PPE's for x0 and x1
    updatePPE!(fg, [v1], :default)
    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    #TODO DEPRECATE
    # getEstimates
    # estimates
    # getVariablePPEs
    # getVariablePPE

    # newvar = deepcopy(v1)
    # getPPEDict(newvar)[:default] = MeanMaxPPE(:default, [150.0], [100.0], [50.0])
    # @test !(getPPEDict(newvar) == getPPEDict(v1))
    # delete!(getVariablePPEs(newvar), :default)
    # getVariablePPEs(newvar)[:second] = MeanMaxPPE(:second, [15.0], [10.0], [5.0])
    # @test symdiff(collect(keys(getVariablePPEs(v1))), [:default, :second]) == Symbol[]
    # @test symdiff(collect(keys(getVariablePPEs(newvar))), [:second]) == Symbol[]
    # # Get the source too.
    # @test symdiff(collect(keys(getVariablePPEs(getVariable(dfg, :a)))), [:default, :second]) == Symbol[]
    #update


    ## TODO make sure these are covered
            # global dfg
            # #get the variable
            # var1 = getVariable(dfg, :a)
            # #make a copy and simulate external changes
            # newvar = deepcopy(var1)
            # getVariablePPEs(newvar)[:default] = MeanMaxPPE(:default, [150.0], [100.0], [50.0])
            # #update
            # mergeUpdateVariableSolverData!(dfg, newvar)
            # #For now spot check
            # # @test solverDataDict(newvar) == solverDataDict(var1)
            # @test getVariablePPEs(newvar) == getVariablePPEs(var1)
            #
            # # Delete :default and replace to see if new ones can be added
            # delete!(getVariablePPEs(newvar), :default)
            # getVariablePPEs(newvar)[:second] = MeanMaxPPE(:second, [15.0], [10.0], [5.0])
            #
            # # Persist to the original variable.
            # mergeUpdateVariableSolverData!(dfg, newvar)
            # # At this point newvar will have only :second, and var1 should have both (it is the reference)
            # @test symdiff(collect(keys(getVariablePPEs(var1))), [:default, :second]) == Symbol[]
            # @test symdiff(collect(keys(getVariablePPEs(newvar))), [:second]) == Symbol[]
            # # Get the source too.
            # @test symdiff(collect(keys(getVariablePPEs(getVariable(dfg, :a)))), [:default, :second]) == Symbol[]
    ##
end

function  VSDTestBlock!(fg, v1)
    # "Variable Solver Data"
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

    vnd = VariableNodeData{TestSofttype1}()
    @test addVariableSolverData!(fg, :a, vnd, :parametric) == vnd

    @test_throws ErrorException addVariableSolverData!(fg, :a, vnd, :parametric)

    @test issetequal(listVariableSolverData(fg, :a), [:default, :parametric])

    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(fg, :a, :parametric)
    @test vndBack == vnd


    # Delete it
    @test deleteVariableSolverData!(fg, :a, :parametric) == vndBack
    # Update add it
    @test @test_logs (:warn, r"does not exist") updateVariableSolverData!(fg, :a, vnd, :parametric) == vnd

    # Update update it
    @test updateVariableSolverData!(fg, :a, vnd, :parametric) == vnd
    # test without deepcopy
    @test updateVariableSolverData!(fg, :a, vnd, :parametric, false) == vnd
    # Bulk copy update x0
    @test updateVariableSolverData!(fg, [v1], :default) == nothing

    altVnd = vnd |> deepcopy
    keepVnd = getSolverData(getVariable(fg, :a), :parametric) |> deepcopy
    altVnd.inferdim = -99.0
    retVnd = updateVariableSolverData!(fg, :a, altVnd, :parametric, false, [:inferdim;])
    @test retVnd == altVnd

    fill!(altVnd.bw, -1.0)
    retVnd = updateVariableSolverData!(fg, :a, altVnd, :parametric, false, [:bw;])
    @test retVnd == altVnd

    altVnd.inferdim = -98.0
    @test retVnd != altVnd

    # restore without copy
    # @show vnd.inferdim
    @test updateVariableSolverData!(fg, :a, keepVnd, :parametric, false, [:inferdim;:bw]) == vnd
    @test getSolverData(getVariable(fg, :a), :parametric).inferdim !=  altVnd.inferdim
    @test getSolverData(getVariable(fg, :a), :parametric).bw !=  altVnd.bw

    # Delete parametric from v1
    @test deleteVariableSolverData!(fg, :a, :parametric) == vnd

    @test_throws ErrorException getVariableSolverData(fg, :a, :parametric)

    #FIXME copied from lower
    @test getSolverData(v1) === v1.solverDataDict[:default]

    # Add new VND of type ContinuousScalar to :x0
    # Could also do VariableNodeData(ContinuousScalar())

    vnd = VariableNodeData{TestSofttype1}()
    addVariableSolverData!(fg, :a, vnd, :parametric)
    @test setdiff(listVariableSolverData(fg, :a), [:default, :parametric]) == []
    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(fg, :a, :parametric)
    @test vndBack == vnd
    # Delete it
    @test deleteVariableSolverData!(fg, :a, :parametric) == vndBack
    # Update add it
    updateVariableSolverData!(fg, :a, vnd, :parametric)
    # Update update it
    updateVariableSolverData!(fg, :a, vnd, :parametric)
    # Bulk copy update x0
    updateVariableSolverData!(fg, [v1], :default)
    # Delete parametric from v1
    deleteVariableSolverData!(fg, :a, :parametric)

    #TODO
    # mergeVariableSolverData!(...)

    #TODO solverDataDict() not deprecated
    # @test getSolverDataDict(newvar) == getSolverDataDict(v1)

    # @test @test_deprecated mergeUpdateVariableSolverData!(fg, newvar)
    # TODO
    # mergeVariableSolverData!
    # mergePPEs!
    # mergeVariableData!
    # mergeGraphVariableData!

end

function  BigDataEntriesTestBlock!(fg, v2)
    # "BigData Entries"

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


function testGroup!(fg, v1, v2, f0, f1)
    # "TODO Sorteer groep"

    @testset "Listing Variables and Factors with filters" begin

        @test issetequal([:a,:b], listVariables(fg))
        @test issetequal([:af1,:abf1], listFactors(fg))

        @test @test_deprecated getVariableIds(fg) == listVariables(fg)
        @test @test_deprecated getFactorIds(fg) == listFactors(fg)

        # TODO Mabye implement IIF type here
        # Requires IIF or a type in IIF
        @test getFactorType(f1.solverData) === f1.solverData.fnc.usrfnc!
        @test getFactorType(f1) === f1.solverData.fnc.usrfnc!
        @test getFactorType(fg, :abf1) === f1.solverData.fnc.usrfnc!

        @test isPrior(fg, :af1) # if f1 is prior
        @test lsfPriors(fg) == [:af1]

        #TODO add test, don't know what we want from this
        # desire is to list all factor types present a graph.
        @test_broken lsfTypes(fg)

        @test ls(fg, TestFunctorInferenceType1) == [:abf1]
        @test lsf(fg, TestFunctorSingleton) == [:af1]
        @test lsfWho(fg, :TestFunctorInferenceType1) == [:abf1]

        @test getSofttype(v1) == TestSofttype1()
        @test getSofttype(fg,:a) == TestSofttype1()

        @test getVariableType(v1) == TestSofttype1()
        @test getVariableType(fg,:a) == TestSofttype1()


        #TODO what is lsTypes supposed to return?
        @test_broken lsTypes(fg)

        @test ls(fg, TestSofttype1) == [:a]

        @test lsWho(fg, :TestSofttype1) == [:a]

        # FIXME return: Symbol[:b, :b] == Symbol[:b]
        varNearTs = findVariableNearTimestamp(fg, now())
        @test_skip varNearTs[1][1] == [:b]

        ## SORT copied from CRUD
        @test all(getVariables(fg, r"a") .== [v1])
        @test all(getVariables(fg, solvable=1) .== [v2])
        @test getVariables(fg, r"a", solvable=1) == []
        @test getVariables(fg, tags=[:LANDMARK])[1] == v2

        @test getFactors(fg, r"nope") == []
        @test issetequal(getLabel.(getFactors(fg, solvable=1)), [:af1, :abf1])
        @test getFactors(fg, solvable=2) == []
        @test getFactors(fg, tags=[:tag1])[1] == f1
        @test getFactors(fg, tags=[:PRIOR])[1] == f0
        ##/SORT

        # Additional testing for https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/201
        # list solvable
        @test symdiff([:a, :b], listVariables(fg, solvable=0)) == []
        @test listVariables(fg, solvable=1) == [:b]

        @test issetequal(listFactors(fg, solvable=1), [:af1, :abf1])
        @test issetequal(listFactors(fg, solvable=0), [:af1, :abf1])
        @test all([f in [f0, f1] for f in getFactors(fg, solvable=1)])

        @test lsf(fg, :b) == [f1.label]

        # Tags
        @test ls(fg, tags=[:POSE]) == []
        @test issetequal(ls(fg, tags=[:POSE, :LANDMARK]), ls(fg, tags=[:VARIABLE]))

        # Regexes
        @test ls(fg, r"a") == [v1.label]
        @test lsf(fg, r"abf*") == [f1.label]


        #TODO test filters and options
        # regexFilter::Union{Nothing, Regex}=nothing;
        # tags::Vector{Symbol}=Symbol[],
        # solvable::Int=0,
        # warnDuplicate::Bool=true,
        # number::Int=1

    end

    @testset "Sorting" begin
        unsorted = [:x1_3;:x1_6;:l1;:april1] #this will not work for :x1x2f1
        @test sort([:x1x2f1, :x1l1f1], lt=natural_lt) == [:x1l1f1, :x1x2f1]

        # NOTE Some of what is possible with sort and the wrappers
        l = [:a1, :X1, :b1c2, :x2_2, :c, :x1, :x10, :x1_1, :x10_10,:a, :x2_1, :xy3, :l1, :x1_2, :x1l1f1, Symbol("1a1"), :x1x2f1]
        @test sortDFG(l) == [Symbol("1a1"), :X1, :a, :a1, :b1c2, :c, :l1, :x1, :x1_1, :x1_2, :x1l1f1, :x1x2f1, :x2_1, :x2_2, :x10, :x10_10, :xy3]
        @test sort(l, lt=natural_lt) == [Symbol("1a1"), :X1, :a, :a1, :b1c2, :c, :l1, :x1, :x1_1, :x1_2, :x1l1f1, :x1x2f1, :x2_1, :x2_2, :x10, :x10_10, :xy3]

        @test getLabel.(sortDFG(getVariables(fg), lt=natural_lt, by=getLabel)) == [:a, :b]
        @test getLabel.(sort(getVariables(fg), lt=natural_lt, by=getLabel)) == [:a, :b]

        @test getLabel.(sortDFG(getFactors(fg))) == [:abf1, :af1]
        @test getLabel.(sort(getFactors(fg), by=getTimestamp)) == [:abf1, :af1]

        @test getLabel.(sortDFG(vcat(getVariables(fg),getFactors(fg)), lt=natural_lt, by=getLabel)) == [:a,:abf1, :af1, :b]
    end

    @testset "Some more helpers to sort out" begin
        # TODO
        #solver data is initialized
        @test !isInitialized(fg, :a)
        @test !isInitialized(v2)
        @test @test_logs (:error, r"Variable does not have solver data") !isInitialized(v2, :second)

        # solvables
        @test getSolvable(v1) == 0
        @test getSolvable(v2) == 1
        @test getSolvable(f1) == 1

        @test !isSolvable(v1)
        @test isSolvable(v2)

        #solves in progress
        @test getSolveInProgress(v1) == 1
        @test getSolveInProgress(f1) == 1
        @test !isSolveInProgress(v2) && v2.solverDataDict[:default].solveInProgress == 0
        @test isSolveInProgress(v1) && v1.solverDataDict[:default].solveInProgress > 0

        @test setSolvable!(v1, 1) == 1
        @test getSolvable(v1) == 1
        @test setSolvable!(fg, v1.label, 0) == 0
        @test getSolvable(v1) == 0
        @test setSolvable!(f1, 1) == 1
        @test getSolvable(fg, f1.label) == 1
        @test setSolvable!(fg, f1.label, 0) == 0
        @test getSolvable(f1) == 0

        # isFactor and isVariable
        @test isFactor(fg, f1.label)
        @test !isFactor(fg, v1.label)
        @test isVariable(fg, v1.label)
        @test !isVariable(fg, f1.label)
        @test !isVariable(fg, :doesntexist)
        @test !isFactor(fg, :doesntexist)

        # test solveCount for variable
        @test !isSolved(v1)
        @test getSolvedCount(v1) == 0
        setSolvedCount!(v1, 1)
        @test getSolvedCount(v1) == 1
        @test isSolved(v1)
        setSolvedCount!(fg, getLabel(v1), 2)
        @test getSolvedCount(fg, getLabel(v1)) == 2
    end
end


# Feed with graph a b solvable orphan not factor on a b
# fg = testDFGAPI()
# addVariable!(fg, DFGVariable(:a, TestSofttype1()))
# addVariable!(fg, DFGVariable(:b, TestSofttype1()))
# addFactor!(fg, DFGFactor(:abf1, [:a,:b], GenericFunctionNodeData{TestFunctorInferenceType1, Symbol}()))
# addVariable!(fg, DFGVariable(:orphan, TestSofttype1(), solvable = 0))
function AdjacencyMatricesTestBlock(fg)
    # Normal
    #deprecated
    @test_throws ErrorException getAdjacencyMatrix(fg)
    adjMat = DistributedFactorGraphs.getAdjacencyMatrixSymbols(fg)
    @test size(adjMat) == (2,4)
    @test symdiff(adjMat[1, :], [nothing, :a, :b, :orphan]) == Symbol[]
    @test symdiff(adjMat[2, :], [:abf1, :abf1, :abf1, nothing]) == Symbol[]
    #
    #sparse
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg)
    @test size(adjMat) == (1,3)

    # Checking the elements of adjacency, its not sorted so need indexing function
    indexOf = (arr, el1) -> findfirst(el2->el2==el1, arr)
    @test adjMat[1, indexOf(v_ll, :orphan)] == 0
    @test adjMat[1, indexOf(v_ll, :a)] == 1
    @test adjMat[1, indexOf(v_ll, :b)] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:abf1]) == Symbol[]

    # Only do solvable tests on DFGVariable
    if isa(getVariable(fg, :a), DFGVariable)
        # Filtered - REF DFG #201
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg, solvable=0)
        @test size(adjMat) == (1,3)
        @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
        @test symdiff(f_ll, [:abf1]) == Symbol[]

        # sparse
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg, solvable=1)
        @test size(adjMat) == (1,2)
        @test issetequal(v_ll, [:a, :b])
        @test f_ll == [:abf1]
    end
end

# Now make a complex graph for connectivity tests
function connectivityTestGraph(::Type{T}; VARTYPE=DFGVariable, FACTYPE=DFGFactor) where T <: InMemoryDFGTypes
    #settings
    numNodesType1 = 5
    numNodesType2 = 5

    dfg = T()

    vars = vcat(map(n -> VARTYPE(Symbol("x$n"), VariableNodeData{TestSofttype1}()), 1:numNodesType1),
                map(n -> VARTYPE(Symbol("x$(numNodesType1+n)"), VariableNodeData{TestSofttype2}()), 1:numNodesType2))

    foreach(v -> addVariable!(dfg, v), vars)


    if FACTYPE == DFGFactor
        #change ready and solveInProgress for x7,x8 for improved tests on x7x8f1
        #NOTE because defaults changed
        setSolvable!(dfg, :x8, 0)
        setSolvable!(dfg, :x9, 0)
        facs = map(n -> addFactor!(dfg, [vars[n], vars[n+1]], DFGFactor{Int, :Symbol}(Symbol("x$(n)x$(n+1)f1"))), 1:length(vars)-1)
        setSolvable!(dfg, :x7x8f1, 0)

    else
        facs = map(n -> addFactor!(dfg, [vars[n], vars[n+1]], FACTYPE(Symbol("x$(n)x$(n+1)f1"))), 1:length(vars)-1)
    end

    return (dfg=dfg, variables=vars, factors=facs)

end

# dfg, verts, facs = connectivityTestGraph(testDFGAPI)

function  GettingNeighbors(testDFGAPI; VARTYPE=DFGVariable, FACTYPE=DFGFactor)
    # "Getting Neighbors"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
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
    #TODO if not a LightDFG with and summary or skeleton
    if VARTYPE == DFGVariable
        @test getNeighbors(dfg, :x5, solvable=2) == Symbol[]
        @test getNeighbors(dfg, :x5, solvable=0) == [:x4x5f1,:x5x6f1]
        @test getNeighbors(dfg, :x5) == [:x4x5f1,:x5x6f1]
        @test getNeighbors(dfg, :x7x8f1, solvable=0) == [:x7, :x8]
        @test getNeighbors(dfg, :x7x8f1, solvable=1) == [:x7]
        @test getNeighbors(dfg, verts[1], solvable=0) == [:x1x2f1]
        @test getNeighbors(dfg, verts[1], solvable=2) == Symbol[]
        @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
    end

end

function  GettingSubgraphs(testDFGAPI; VARTYPE=DFGVariable, FACTYPE=DFGFactor)

    # "Getting Subgraphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
    # Subgraphs
    dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    # Test include orphan factors
    @test_broken begin
        dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
        @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
        # Test adding to the dfg
        dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
        @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    end
    #
    dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []

    #TODO if not a LightDFG with and summary or skeleton
    if VARTYPE == DFGVariable
        # DFG issue #201 Test include orphan factors with filtering - should only return x7 with solvable=1
        @test_broken begin
            dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=0)
            @test symdiff([:x7, :x8, :x7x8f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
            # Filter - always returns the node you start at but filters around that.
            dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=1)
            @test symdiff([:x7x8f1, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
            end
        # Test for distance = 2, should return orphans
        setSolvable!(dfg, :x8x9f1, 0)
        dfgSubgraph = getSubgraphAroundNode(dfg, getVariable(dfg, :x8), 2, true, solvable=1)
        @test issetequal([:x8, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
        #end if not a LightDFG with and summary or skeleton
    end
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


function  BuildingSubgraphs(testDFGAPI; VARTYPE=DFGVariable, FACTYPE=DFGFactor)

        # "Getting Subgraphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
    # Subgraphs
    dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [verts[1].label], 2)
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
    #
    dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [:x1, :x2, :x1x2f1])
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []

    dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [:x1x2f1], 1)
    # Only returns x1 and x2
    @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []

    #TODO if not a LightDFG with and summary or skeleton
    if VARTYPE == DFGVariable
        dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [:x8], 2, solvable=1)
        @test issetequal([:x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
        #end if not a LightDFG with and summary or skeleton
    end
    # DFG issue #95 - confirming that getSubgraphAroundNode retains order
    # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
    for fId in listVariables(dfg)
        # Get a subgraph of this and it's related factors+variables
        dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [fId], 2)
        # For each factor check that the order the copied graph == original
        for fact in getFactors(dfgSubgraph)
            @test fact._variableOrderSymbols == getFactor(dfg, fact.label)._variableOrderSymbols
        end
    end

end

#TODO Summaries and Summary Graphs
function  Summaries(testDFGAPI)
    # "Summaries and Summary Graphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI)
    #TODO for summary
    # if VARTYPE == DFGVariableSummary
        # factorFields = fieldnames(FACTYPE)
        # variableFields = fieldnames(VARTYPE)
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
                @test Symbol(typeof(getSofttype(getVariable(dfg, v)))) == getSofttypename(getVariable(summaryGraph, v))
                @test getSofttype(getVariable(dfg, v)) == getSofttype(getVariable(summaryGraph, v))
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            @test getproperty(getFactor(dfg, f), field) == getproperty(getFactor(summaryGraph, f), field)
        end
    end
end

function ProducingDotFiles(testDFGAPI; VARTYPE=DFGVariable, FACTYPE=DFGFactor)
    # "Producing Dot Files"
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI()
    v1 = VARTYPE(:a, VariableNodeData{TestSofttype1}())
    v2 = VARTYPE(:b, VariableNodeData{TestSofttype1}())
    if FACTYPE==DFGFactor
        f1 = DFGFactor{Int, :Symbol}(:abf1)
    else
        f1 = FACTYPE(:abf1)
    end
    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    addFactor!(dotdfg, [v1, v2], f1)
    #NOTE hardcoded toDot will have different results so test LightGraphs seperately
    if testDFGAPI <: LightDFG
        @test toDot(dotdfg) == "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box];\na -- abf1\nb -- abf1\n}\n"
    else
        @test toDot(dotdfg) == "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
    end
    @test toDotFile(dotdfg, "something.dot") == nothing
    Base.rm("something.dot")

end

function ConnectivityTest(testDFGAPI; kwargs...)
    dfg, verts, facs = connectivityTestGraph(testDFGAPI; kwargs...)
    @test isFullyConnected(dfg) == true
    @test hasOrphans(dfg) == false

    deleteFactor!(dfg, :x9x10f1)
    @test isFullyConnected(dfg) == false
    @test hasOrphans(dfg) == true

    deleteVariable!(dfg, :x5)
    if testDFGAPI == GraphsDFG
        @error "FIXME: isFullyConnected is partially broken for GraphsDFG see #286"
        @test_broken isFullyConnected(dfg) == false
        @test_broken hasOrphans(dfg) == true
    else
        @test isFullyConnected(dfg) == false
        @test hasOrphans(dfg) == true
    end
end


function CopyFunctionsTest(testDFGAPI; kwargs...)

    # testDFGAPI = LightDFG
    # kwargs = ()

    dfg, verts, facs = connectivityTestGraph(testDFGAPI; kwargs...)

    varlbls = ls(dfg)
    faclbls = lsf(dfg)

    dcdfg = deepcopyGraph(LightDFG, dfg)

    @test issetequal(ls(dcdfg), varlbls)
    @test issetequal(lsf(dcdfg), faclbls)

    vlbls = [:x2, :x3]
    flbls = [:x2x3f1]
    dcdfg_part = deepcopyGraph(LightDFG, dfg, vlbls, flbls)

    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)

    # deepcopy subgraph ignoring orphans
    @test_logs (:warn, r"orphan") dcdfg_part = deepcopyGraph(LightDFG, dfg, vlbls, union(flbls, [:x1x2f1]))
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)

    # deepcopy subgraph with 2 parts
    vlbls = [:x2, :x3, :x5, :x6, :x10]
    flbls = [:x2x3f1, :x5x6f1]
    dcdfg_part = deepcopyGraph(LightDFG, dfg, vlbls, flbls)
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)
    @test !isFullyConnected(dcdfg_part)
    # dfgplot(dcdfg_part)


    vlbls = [:x2, :x3]
    dcdfg_part =  deepcopyGraph(LightDFG, dfg, vlbls; verbose=false)
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), [:x2x3f1])

    # not found errors
    @test_throws ErrorException deepcopyGraph(LightDFG, dfg, [:x1, :a])
    @test_throws ErrorException deepcopyGraph(LightDFG, dfg, [:x1], [:f1])

    # already exists errors
    dcdfg_part = deepcopyGraph(LightDFG, dfg, [:x1, :x2, :x3], [:x1x2f1, :x2x3f1])
    @test_throws ErrorException deepcopyGraph!(dcdfg_part, dfg, [:x4, :x2, :x3], [:x1x2f1, :x2x3f1])
    @test_skip @test_throws ErrorException deepcopyGraph!(dcdfg_part, dfg, [:x1x2f1])

    # same but overwrite destination
    deepcopyGraph!(dcdfg_part, dfg, [:x4, :x2, :x3], [:x1x2f1, :x2x3f1]; overwriteDest = true)

    deepcopyGraph!(dcdfg_part, dfg, Symbol[], [:x1x2f1]; overwriteDest=true)


    # convert to...
    # condfg = convert(GraphsDFG, dfg)
    # @test condfg isa GraphsDFG
    # @test issetequal(ls(condfg), varlbls)
    # @test issetequal(lsf(condfg), faclbls)
    #
    # condfg = convert(LightDFG, dfg)
    # @test condfg isa LightDFG
    # @test issetequal(ls(condfg), varlbls)
    # @test issetequal(lsf(condfg), faclbls)

    # GraphsDFG(dfg::AbstractDFG) = convert(GraphsDFG,dfg)
    # GraphsDFG(dfg)

end
