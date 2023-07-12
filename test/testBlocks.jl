using DistributedFactorGraphs
using Test
using Dates
using Manifolds

import Base: convert
import DistributedFactorGraphs: reconstFactorData
# import DistributedFactorGraphs: getData, addData!, updateData!, deleteData!

# Test InferenceVariable Types
# struct TestVariableType1 <: InferenceVariable
#     dims::Int
#     manifolds::Tuple{Symbol}
#     TestVariableType1() = new(1,(:Euclid,))
# end


Base.convert(::Type{<:Tuple}, ::typeof(Euclidean(1))) = (:Euclid,)
Base.convert(::Type{<:Tuple}, ::typeof(Euclidean(2))) = (:Euclid, :Euclid)

@defVariable TestVariableType1 Euclidean(1) [0.0;]
@defVariable TestVariableType2 Euclidean(2) [0;0.0]

# struct TestVariableType2 <: InferenceVariable
#     dims::Int
#     manifolds::Tuple{Symbol, Symbol}
#     TestVariableType2() = new(2,(:Euclid,:Circular,))
# end


struct TestFunctorInferenceType1 <: AbstractRelative end
struct TestFunctorInferenceType2 <: AbstractRelative end

struct TestAbstractPrior <: AbstractPrior end
# struct TestAbstractRelativeFactor <: AbstractRelativeRoots end
struct TestAbstractRelativeFactorMinimize <: AbstractRelativeMinimize end

Base.@kwdef struct PackedTestFunctorInferenceType1 <: AbstractPackedFactor
    s::String = ""
end
# PackedTestFunctorInferenceType1() = PackedTestFunctorInferenceType1("")

function Base.convert(::Type{PackedTestFunctorInferenceType1}, d::TestFunctorInferenceType1)
    # @info "convert(::Type{PackedTestFunctorInferenceType1}, d::TestFunctorInferenceType1)"
    PackedTestFunctorInferenceType1()
end

function reconstFactorData(dfg::AbstractDFG, vo::AbstractVector, ::Type{TestFunctorInferenceType1}, d::PackedTestFunctorInferenceType1, ::String)
    TestFunctorInferenceType1()
end

# overly simplified test requires both reconstitute and convert
function Base.convert(::Type{TestFunctorInferenceType1}, d::PackedTestFunctorInferenceType1 )
    # @info "convert(::Type{TestFunctorInferenceType1}, d::PackedTestFunctorInferenceType1)"
    TestFunctorInferenceType1()
end


Base.@kwdef struct PackedTestAbstractPrior <: AbstractPackedFactor
    s::String = ""
end
# PackedTestAbstractPrior() = PackedTestAbstractPrior("")

function Base.convert(::Type{PackedTestAbstractPrior}, d::TestAbstractPrior)
    # @info "convert(::Type{PackedTestAbstractPrior}, d::TestAbstractPrior)"
    PackedTestAbstractPrior()
end

function Base.convert(::Type{TestAbstractPrior}, d::PackedTestAbstractPrior)
    # @info "onvert(::Type{TestAbstractPrior}, d::PackedTestAbstractPrior)"
    TestAbstractPrior()
end

struct TestCCW{T <: AbstractFactor} <: FactorOperationalMemory
    usrfnc!::T
end

TestCCW{T}() where T = TestCCW(T())

Base.:(==)(a::TestCCW, b::TestCCW) = a.usrfnc! == b.usrfnc!

DFG.getFactorOperationalMemoryType(par::NoSolverParams) = TestCCW
DFG.rebuildFactorMetadata!(dfg::AbstractDFG{NoSolverParams}, fac::DFGFactor) = fac

function reconstFactorData(dfg::AbstractDFG,
                                vo::AbstractVector,
                                ::Type{<:DFG.FunctionNodeData{TestCCW{F}}},
                                d::DFG.PackedFunctionNodeData{<:AbstractPackedFactor} ) where {F <: DFG.AbstractFactor}
    nF = convert(F, d.fnc)
    return DFG.FunctionNodeData(d.eliminated,
                                d.potentialused,
                                d.edgeIDs,
                                TestCCW(nF),
                                d.multihypo,
                                d.certainhypo,
                                d.nullhypo,
                                d.solveInProgress,
                                d.inflation)
end

function Base.convert(::Type{DFG.PackedFunctionNodeData{P}}, d::DFG.FunctionNodeData{<:FactorOperationalMemory}) where P <: AbstractPackedFactor
  return DFG.PackedFunctionNodeData(d.eliminated,
                                    d.potentialused,
                                    d.edgeIDs,
                                    convert(P, d.fnc.usrfnc!),
                                    d.multihypo,
                                    d.certainhypo,
                                    d.nullhypo,
                                    d.solveInProgress,
                                    d.inflation)
end



##
# global testDFGAPI = GraphsDFG
# T = testDFGAPI

#test Specific definitions
# struct TestInferenceVariable1 <: InferenceVariable end
# struct TestInferenceVariable2 <: InferenceVariable end
# struct TestFunctorInferenceType1 <: AbstractFactor end

# NOTE see note in AbstractDFG.jl setSolverParams!
struct GeenSolverParams <: AbstractParams
end

solparams=NoSolverParams()
# DFG Accessors
function DFGStructureAndAccessors(::Type{T}, solparams::AbstractParams=NoSolverParams()) where T <: AbstractDFG
    # "DFG Structure and Accessors"
    # Constructors
    # Constructors to be implemented
    fg = T(solverParams=solparams, userLabel="test@navability.io")
    #TODO test something better
    @test isa(fg, T)
    @test getUserLabel(fg)=="test@navability.io"
    @test getRobotLabel(fg)=="DefaultRobot"
    @test getSessionLabel(fg)[1:8] == "Session_"

    # Test the validation of the robot, session, and user IDs.
    notAllowedList = ["!notValid", "1notValid", "_notValid", "USER", "ROBOT", "SESSION",
                      "VARIABLE", "FACTOR", "ENVIRONMENT", "PPE", "DATA_ENTRY", "FACTORGRAPH"]

    for s in notAllowedList
        @test_throws ErrorException T(solverParams=solparams, sessionLabel=s)
        @test_throws ErrorException T(solverParams=solparams, robotLabel=s)
        @test_throws ErrorException T(solverParams=solparams, userLabel=s)
    end

    des = "description for runtest"
    uId = "test@navability.io"
    rId = "testRobotId"
    sId = "testSessionId"
    ud = Dict{Symbol,SmallDataTypes}(:ud=>"udEntry")
    rd = Dict{Symbol,SmallDataTypes}(:rd=>"rdEntry")
    sd = Dict{Symbol,SmallDataTypes}(:sd=>"sdEntry")
    fg = T(des, uId,  rId,  sId,  ud,  rd,  sd,  solparams)

    # accesssors
    # get
    @test getDescription(fg) == des
    @test getUserLabel(fg) == uId
    @test getRobotLabel(fg) == rId
    @test getSessionLabel(fg) == sId
    @test getAddHistory(fg) === fg.addHistory

    @test setUserData!(fg, ud) == ud
    @test setRobotData!(fg, rd) == rd
    @test setSessionData!(fg, sd) == sd
    @test getUserData(fg) == ud
    @test getRobotData(fg) == rd
    @test getSessionData(fg) == sd

    @test getSolverParams(fg) == NoSolverParams()

    smallUserData = Dict{Symbol, SmallDataTypes}(:a => "42", :b => "Hello")
    smallRobotData = Dict{Symbol, SmallDataTypes}(:a => "43", :b => "Hello")
    smallSessionData = Dict{Symbol, SmallDataTypes}(:a => "44", :b => "Hello")

    #TODO CRUD vs set
    @test setUserData!(fg, deepcopy(smallUserData)) == smallUserData
    @test setRobotData!(fg, deepcopy(smallRobotData)) == smallRobotData
    @test setSessionData!(fg, deepcopy(smallSessionData)) == smallSessionData

    @test getUserData(fg) == smallUserData
    @test getRobotData(fg) == smallRobotData
    @test getSessionData(fg) == smallSessionData


    # NOTE see note in AbstractDFG.jl setSolverParams!
    @test_throws MethodError setSolverParams!(fg, GeenSolverParams()) == GeenSolverParams()


    @test setSolverParams!(fg, typeof(solparams)()) == typeof(solparams)()

    @test setDescription!(fg, des*"_1") == des*"_1"


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
    @test updateSessionData!(fg, :b=>"3") == getSessionData(fg)
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

# User, Robot, Session Data Blob Entries
function  UserRobotSessionBlobEntries!(fg::AbstractDFG)

    be = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :key1, 
        blobstore = :b, 
        hash = "",
        origin = "",
        description = "",
        mimeType = "", 
        metadata = ""
    )

    # User Blob Entries
    #TODO

    # Robot Blob Entries
    #TODO

    # Session Blob Entries
    ae = addSessionBlobEntry!(fg, be)
    @test ae == be
    ge = getSessionBlobEntry(fg, :key1)
    @test ge == be
    
    #TODO


end

function DFGVariableSCA()
    # "DFG Variable"

    v1_lbl = :a
    v1_tags = Set([:VARIABLE, :POSE])
    small = Dict{Symbol, SmallDataTypes}(:small=>"data")
    testTimestamp = now(localzone())
    # Constructors
    v1 = DFGVariable(v1_lbl, TestVariableType1(), tags=v1_tags, solvable=0, solverDataDict=Dict(:default=>VariableNodeData{TestVariableType1}()))
    v2 = DFGVariable(:b, VariableNodeData{TestVariableType2}(), tags=Set([:VARIABLE, :LANDMARK]))
    v3 = DFGVariable(:c, VariableNodeData{TestVariableType2}(), timestamp=ZonedDateTime("2020-08-11T00:12:03.000-05:00"))

    vorphan = DFGVariable(:orphan, TestVariableType1(), tags=v1_tags, solvable=0, solverDataDict=Dict(:default=>VariableNodeData{TestVariableType1}()))

    # v1.solverDataDict[:default].val[1] = [0.0;]
    # v1.solverDataDict[:default].bw[1] = [1.0;]
    # v2.solverDataDict[:default].val[1] = [0.0;0.0]
    # v2.solverDataDict[:default].bw[1] = [1.0;1.0]
    # v3.solverDataDict[:default].val[1] = [0.0;0.0]
    # v3.solverDataDict[:default].bw[1] = [1.0;1.0]


    getSolverData(v1).solveInProgress = 1

    @test getLabel(v1) == v1_lbl
    @test getTags(v1) == v1_tags

    @test getTimestamp(v1) == v1.timestamp

    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1

    # TODO direct use is not recommended, use accessors, maybe not export or deprecate
    @test getSolverDataDict(v1) == v1.solverDataDict

    @test getPPEDict(v1) == v1.ppeDict

    @test getSmallData(v1) == Dict{Symbol,SmallDataTypes}()

    @test getVariableType(v1) == TestVariableType1()


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

    #no accessors on dataDict, only CRUD

    #variableType functions
    testvar = TestVariableType1()
    @test getDimension(testvar) == 1
    @test getManifold(testvar) == Euclidean(1)

    # #TODO sort out
    # getPPEs
    # getSolverData
    # setSolverData
    # getVariablePPEs
    # getVariablePPE
    # getSolvedCount
    # isSolved
    # setSolvedCount

    return (v1=v1, v2=v2, v3=v3, vorphan = vorphan, v1_tags=v1_tags)

end



function  DFGFactorSCA()
    # "DFG Factor"

    # Constructors
    #DFGVariable solvable default to 1, but Factor to 0, is that correct
    f1_lbl = :abf1
    f1_tags = Set([:FACTOR])
    testTimestamp = now(localzone())

    gfnd_prior = GenericFunctionNodeData(fnc=TestCCW(TestAbstractPrior()))

    gfnd = GenericFunctionNodeData(fnc=TestCCW(TestFunctorInferenceType1()))

    f1 = DFGFactor{TestCCW{TestFunctorInferenceType1}}(f1_lbl, [:a,:b])
    f1 = DFGFactor(f1_lbl, [:a,:b], gfnd, tags = f1_tags, solvable=0)

    f2 = DFGFactor{TestCCW{TestFunctorInferenceType1}}(:bcf1, [:b, :c], ZonedDateTime("2020-08-11T00:12:03.000-05:00"))
    #TODO add tests for mutating vos in updateFactor and orphan related checks.
    # we should perhaps prevent an empty vos


    @test getLabel(f1) == f1_lbl
    @test getTags(f1) == f1_tags

    @test getTimestamp(f1) == f1.timestamp

    @test getSolvable(f1) == 0


    @test getSolverData(f1) === f1.solverData

    @test getVariableOrder(f1) == [:a,:b]

    getSolverData(f1).solveInProgress = 1
    @test setSolvable!(f1, 1) == 1

    #TODO These 2 function are equivelent
    @test typeof(getFactorType(f1)) == TestFunctorInferenceType1
    @test typeof(getFactorFunction(f1)) == TestFunctorInferenceType1


    #TODO here for now, don't recommend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(f1, testTags) == Set(testTags)
    @test setTags!(f1, Set(testTags)) == Set(testTags)

    #TODO Handle same way as variable
    f1ts = setTimestamp(f1, testTimestamp)
    @test !(f1ts === f1)
    @test getTimestamp(f1ts) == testTimestamp
    #follow with updateFactor!(fg, v1ts)

    #TODO Should throw method error
    # @test_throws MethodError setTimestamp!(f1, testTimestamp)
    # @test_throws ErrorException setTimestamp!(f1, testTimestamp)
    #/TODO

    @test setSolvable!(f1, 1) == 1
    @test getSolvable(f1) == 1

    #TODO don't know if this should be used, added for completeness, it just wastes the gc's time
    @test setSolverData!(f1, deepcopy(gfnd)) == gfnd

    # create f0 here for a later timestamp
    f0 = DFGFactor(:af1, [:a], gfnd_prior, tags = Set([:PRIOR]))

    #fill in undefined fields
    # f2.solverData.certainhypo = Int[]
    # f2.solverData.multihypo = Float64[]
    # f2.solverData.edgeIDs = Int64[]

    return  (f0=f0, f1=f1, f2=f2)
end

function  VariablesandFactorsCRUD_SET!(fg, v1, v2, v3, f0, f1, f2)
    # "Variables and Factors CRUD an SET"

    #TODO dont throw ErrorException
    #TODO test remaining add signitures
    # global fg
    # fg = GraphsDFG(solverParams=NoSolverParams())
    # fg = GraphsDFG(solverParams=NoSolverParams())
    # add update delete
@test addVariable!(fg, v1) == v1
@test addVariable!(fg, v2) == v2

# test getindex
@test getLabel(fg[getLabel(v1)]) == getLabel(v1)

#TODO standardize this error and res also for that matter
@test_throws Exception addFactor!(fg, [:a, :nope], f1)
@test_throws Exception addFactor!(fg, [v1, v2, v3], f1)

@test addFactor!(fg, [v1, v2], f1) == f1
@test_throws ErrorException addFactor!(fg, [v1, v2], f1)

@test getLabel(fg[getLabel(f1)]) == getLabel(f1)

@test @test_logs (:warn, Regex("'$(v3.label)' does not exist")) match_mode=:any updateVariable!(fg, v3) == v3
@test updateVariable!(fg, v3) == v3
@test_throws ErrorException addVariable!(fg, v3)

@test @test_logs (:warn, Regex("'$(f2.label)' does not exist")) match_mode=:any updateFactor!(fg, f2) === f2
@test updateFactor!(fg, f2) === f2
@test_throws ErrorException addFactor!(fg, [:b, :c], f2)
#TODO Graphs.jl, but look at refactoring absract @test_throws ErrorException addFactor!(fg, f2)


if f2 isa DFGFactor
    f2_mod = DFGFactor(f2.label, f2.timestamp, f2.nstime, f2.tags, f2.solverData, f2.solvable, (:a,))
else
    f2_mod =  deepcopy(f2)
    pop!(f2_mod._variableOrderSymbols)
end

@test_throws ErrorException updateFactor!(fg, f2_mod)
@test issetequal(lsf(fg), [:bcf1, :abf1])

@test getAddHistory(fg) == [:a, :b, :c]

# Extra timestamp functions https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/315
if !(v1 isa SkeletonDFGVariable)
    newtimestamp = now(localzone())
    @test !(setTimestamp!(fg, :c, newtimestamp) === v3)
    @test getVariable(fg, :c) |> getTimestamp == newtimestamp

    @test !(setTimestamp!(fg, :bcf1, newtimestamp) === f2)
    @test getFactor(fg, :bcf1) |> getTimestamp == newtimestamp
end
#deletions
delvarCompare = getVariable(fg, :c)
delfacCompare = getFactor(fg, :bcf1)
delvar, delfacs = deleteVariable!(fg, v3)
@test delvarCompare == delvar
@test delfacCompare == delfacs[1]
@test_throws ErrorException deleteVariable!(fg, v3)
@test setdiff(ls(fg),[:a,:b]) == []

@test addVariable!(fg, v3) === v3
@test addFactor!(fg, f2) === f2

@test getFactor(fg, :bcf1) == deleteFactor!(fg, f2)
@test_throws ErrorException deleteFactor!(fg, f2)
@test lsf(fg) == [:abf1]

delvarCompare = getVariable(fg, :c)
delfacCompare = []
delvar, delfacs = deleteVariable!(fg, v3)
@test delvarCompare == delvar
@test delfacCompare == []

@test getVariable(fg, :a) == v1
@test getVariable(fg, :a, :default) == v1

@test addFactor!(fg, f0) == f0

if isa(v1, DFGVariable)
    #TODO decide if this should be @error or other type
    @test_throws ErrorException getVariable(fg, :a, :missingfoo)
else
    @test_logs (:warn, r"supported for type DFGVariable") getVariable(fg, :a, :missingfoo)
end

@test getFactor(fg, :abf1) == f1

@test_throws ErrorException getVariable(fg, :c)
@test_throws ErrorException getFactor(fg, :bcf1)

#test issue #375
@test_throws ErrorException getVariable(fg, :abf1)
@test_throws ErrorException getFactor(fg, :a)

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

if getVariable(fg, ls(fg)[1]) isa DFGVariable
  @test :default in listSolveKeys(fg)
  @test :default in listSolveKeys(fg, r"a"; filterSolveKeys=r"default")
  @test :default in listSupersolves(fg)
end

# simple broadcast test
if f0 isa DFGFactor
    @test issetequal(getFactorType.(fg, lsf(fg)),  [TestFunctorInferenceType1(), TestAbstractPrior()])
end
@test getVariable.(fg, [:a]) == [getVariable(fg, :a)]
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

    @test getPPEMax(ppe) === ppe.max
    @test getPPEMean(ppe) === ppe.mean
    @test getPPESuggested(ppe) === ppe.suggested
    @test getLastUpdatedTimestamp(ppe) === ppe.lastUpdatedTimestamp

    @test addPPE!(fg, :a, ppe) == ppe
    @test_throws ErrorException addPPE!(fg, :a, ppe)

    @test listPPEs(fg, :a) == [:default]

    # Get the data back - note that this is a reference to above.
    @test getPPE(getVariable(fg, :a), :default) == ppe
    @test getPPE(fg, :a, :default) == ppe
    @test getPPEMean(fg, :a, :default) == ppe.mean
    @test getPPEMax(fg, :a, :default) == ppe.max
    @test getPPESuggested(fg, :a, :default) == ppe.suggested

    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    @test_throws KeyError getPPE(fg, :a, :default)
    # Update add it
    @test @test_logs (:warn, Regex("'$(ppe.solveKey)' does not exist")) match_mode=:any updatePPE!(fg, :a, ppe) == ppe
    # Update update it
    @test updatePPE!(fg, :a, ppe) == ppe
    @test deletePPE!(fg, :a, :default) == ppe

    # manually add ppe to v1 for tests
    v1.ppeDict[:default] = deepcopy(ppe)
    # Bulk copy PPE's for :x1
    @test updatePPE!(fg, [v1], :default) == nothing
    # Delete it
    @test deletePPE!(fg, :a, :default) == ppe

    # New interface
    @test addPPE!(fg, :a, ppe) == ppe
    # Update update it
    @test updatePPE!(fg, :a, ppe) == ppe
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
    updatePPE!(fg, :a, ppe) #, :default)
    # Update update it
    updatePPE!(fg, :a, ppe) #, :default)

    v1.ppeDict[:default] = deepcopy(ppe)
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
    # > - `getVariableSolverDataAll` #TODO Data is already plural so maybe Variables, All or Dict, or use Datum for singular
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

    vnd = VariableNodeData{TestVariableType1}(solveKey=:parametric)
    # vnd.val[1] = [0.0;]
    # vnd.bw[1] = [1.0;]
    @test addVariableSolverData!(fg, :a, vnd) == vnd

    @test_throws ErrorException addVariableSolverData!(fg, :a, vnd)

    @test issetequal(listVariableSolverData(fg, :a), [:default, :parametric])

    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(fg, :a, :parametric)
    @test vndBack == vnd


    # Delete it
    @test deleteVariableSolverData!(fg, :a, :parametric) == vndBack
    # Update add it
    @test @test_logs (:warn, r"does not exist") updateVariableSolverData!(fg, :a, vnd) == vnd

    # Update update it
    @test updateVariableSolverData!(fg, :a, vnd) == vnd
    # test without deepcopy
    @test updateVariableSolverData!(fg, :a, vnd, false) == vnd
    # Bulk copy update x0
    @test updateVariableSolverData!(fg, [v1], :default) == nothing

    altVnd = vnd |> deepcopy
    keepVnd = getSolverData(getVariable(fg, :a), :parametric) |> deepcopy
    altVnd.infoPerCoord .= [-99.0;]
    retVnd = updateVariableSolverData!(fg, :a, altVnd, false, [:infoPerCoord;])
    @test retVnd == altVnd

    altVnd.bw = -ones(1,1)
    retVnd = updateVariableSolverData!(fg, :a, altVnd, false, [:bw;])
    @test retVnd == altVnd

    altVnd.infoPerCoord[1] = -98.0
    @test retVnd != altVnd

    # restore without copy
    @test updateVariableSolverData!(fg, :a, keepVnd, false, [:infoPerCoord;:bw]) == vnd
    @test getSolverData(getVariable(fg, :a), :parametric).infoPerCoord[1] !=  altVnd.infoPerCoord[1]
    @test getSolverData(getVariable(fg, :a), :parametric).bw !=  altVnd.bw

    # Delete parametric from v1
    @test deleteVariableSolverData!(fg, :a, :parametric) == vnd

    @test_throws KeyError getVariableSolverData(fg, :a, :parametric)

    #FIXME copied from lower
    @test getSolverData(v1) === v1.solverDataDict[:default]

    # Add new VND of type ContinuousScalar to :x0
    # Could also do VariableNodeData(ContinuousScalar())

    vnd = VariableNodeData{TestVariableType1}(solveKey=:parametric)
    # vnd.val[1] = [0.0;]
    # vnd.bw[1] = [1.0;]
    
    addVariableSolverData!(fg, :a, vnd)
    @test setdiff(listVariableSolverData(fg, :a), [:default, :parametric]) == []
    # Get the data back - note that this is a reference to above.
    vndBack = getVariableSolverData(fg, :a, :parametric)
    @test vndBack == vnd
    # Delete it
    @test deleteVariableSolverData!(fg, :a, :parametric) == vndBack
    # Update add it
    updateVariableSolverData!(fg, :a, vnd)
    # Update update it
    updateVariableSolverData!(fg, :a, vnd)
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

function smallDataTestBlock!(fg)

    @test listSmallData(fg, :a) == Symbol[:small]
    @test listSmallData(fg, :b) == Symbol[]
    @test small = getSmallData(fg, :a, :small) == "data"

    @test addSmallData!(fg, :a, :a=>5) == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :b=>10.0) == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :c=>true) == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :d=>"yes") == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :e=>[1, 2, 3])  == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :f=>[1.4, 2.5, 3.6]) == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :g=>["yes", "maybe"]) == getVariable(fg, :a).smallData
    @test addSmallData!(fg, :a, :h=>[true, false]) == getVariable(fg, :a).smallData

    @test_throws ErrorException addSmallData!(fg, :a, :a=>3)
    @test updateSmallData!(fg, :a, :a=>3) == getVariable(fg, :a).smallData
    
    @test_throws MethodError addSmallData!(fg, :a, :no=>0x01)
    @test_throws MethodError addSmallData!(fg, :a, :no=>1f0)
    @test_throws MethodError addSmallData!(fg, :a, :no=>Nanosecond(3))
    @test_throws MethodError addSmallData!(fg, :a, :no=>[0x01])
    @test_throws MethodError addSmallData!(fg, :a, :no=>[1f0])
    @test_throws MethodError addSmallData!(fg, :a, :no=>[Nanosecond(3)])
    
    @test deleteSmallData!(fg, :a, :a) == 3
    @test updateSmallData!(fg, :a, :a=>3) == getVariable(fg, :a).smallData
    @test length(listSmallData(fg, :a)) == 9
    emptySmallData!(fg, :a)
    @test length(listSmallData(fg, :a)) == 0

end




function  DataEntriesTestBlock!(fg, v2)
    # "Data Entries"

    # getBlobEntry
    # addBlobEntry
    # updateBlobEntry
    # deleteBlobEntry
    # getBlobEntries
    # listBlobEntries
    # emptyDataEntries
    # mergeDataEntries
    storeEntry = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :a, 
        blobstore = :b, 
        hash = "",
        origin = "",
        description = "",
        mimeType = "", 
        metadata = "")
    @test getLabel(storeEntry) == storeEntry.label
    @test getId(storeEntry) == storeEntry.id
    @test getHash(storeEntry) == hex2bytes(storeEntry.hash)
    @test getTimestamp(storeEntry) == storeEntry.timestamp

    # oid = zeros(UInt8,12); oid[12] = 0x01
    # de1 = MongodbDataEntry(:key1, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de1 = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :key1, 
        blobstore = :b, 
        hash = "",
        origin = "",
        description = "",
        mimeType = "", 
        metadata = "")

    # oid = zeros(UInt8,12); oid[12] = 0x02
    # de2 = MongodbDataEntry(:key2, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de2 = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :key2, 
        blobstore = :b, 
        hash = "",
        origin = "",
        description = "",
        mimeType = "", 
        metadata = "")

    # oid = zeros(UInt8,12); oid[12] = 0x03
    # de2_update = MongodbDataEntry(:key2, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de2_update = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :key2, 
        blobstore = :b, 
        hash = "",
        origin = "",
        description = "Yay",
        mimeType = "", 
        metadata = "")

    #add
    v1 = getVariable(fg, :a)
    @test addBlobEntry!(v1, de1) == de1
    @test addBlobEntry!(fg, :a, de2) == de2
    @test_throws ErrorException addBlobEntry!(v1, de1)
    @test de2 in getBlobEntries(v1)

    #get
    @test deepcopy(de1) == getBlobEntry(v1, :key1)
    @test deepcopy(de2) == getBlobEntry(fg, :a, :key2)
    @test_throws KeyError getBlobEntry(v2, :key1)
    @test_throws KeyError getBlobEntry(fg, :b, :key1)

    #update
    @test updateBlobEntry!(fg, :a, de2_update) == de2_update
    @test deepcopy(de2_update) == getBlobEntry(fg, :a, :key2)
    @test @test_logs (:warn, r"does not exist") updateBlobEntry!(fg, :b, de2_update) == de2_update

    #list
    entries = getBlobEntries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e->e.label, entries), [:key1, :key2])
    @test length(getBlobEntries(fg, :b)) == 1

    @test issetequal(listBlobEntries(fg, :a), [:key1, :key2])
    @test listBlobEntries(fg, :b) == Symbol[:key2]

    #delete
    @test deleteBlobEntry!(v1, de1) == de1
    @test listBlobEntries(v1) == Symbol[:key2]
    #delete from dfg
    @test deleteBlobEntry!(fg, :a, :key2) == de2_update
    @test listBlobEntries(v1) == Symbol[]
    deleteBlobEntry!(fg, :b, :key2)

    # packed variable data entries
    pacv = packVariable(v1)
    @test addBlobEntry!(pacv, de1) == de1
    @test hasBlobEntry(pacv, :key1)
    @test deepcopy(de1) == getBlobEntry(pacv, :key1)
    @test getBlobEntries(pacv) == [deepcopy(de1)]
    @test issetequal(listBlobEntries(pacv), [:key1])
    # @test deleteBlobEntry!(pacv, de1) == de1

end

function blobsStoresTestBlock!(fg)
    de1 = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :label1, 
        blobstore = :store1, 
        hash = "AAAA",
        origin = "origin1",
        description = "description1",
        mimeType = "mimetype1", 
        metadata = "")
    de2 = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :label2, 
        blobstore = :store2, 
        hash = "FFFF",
        origin = "origin2",
        description = "description2",
        mimeType = "mimetype2", 
        metadata = "",
        timestamp = ZonedDateTime("2020-08-12T12:00:00.000+00:00"))
    de2_update = BlobEntry(
        id = uuid4(), 
        blobId = uuid4(),
        originId = uuid4(),
        label = :label2, 
        blobstore = :store2, 
        hash = "0123",
        origin = "origin2",
        description = "description2",
        mimeType = "mimetype2", 
        metadata = "",
        timestamp = ZonedDateTime("2020-08-12T12:00:00.000+00:00"))
    @test getLabel(de1) == de1.label
    @test getId(de1) == de1.id
    @test getHash(de1) == hex2bytes(de1.hash)
    @test getTimestamp(de1) == de1.timestamp

    #add
    var1 = getVariable(fg, :a)
    var2 = getVariable(fg, :b)
    @test addBlobEntry!(var1, de1) == de1
    updateVariable!(fg, var1)
    @test addBlobEntry!(fg, :a, de2) == de2
    @test_throws ErrorException addBlobEntry!(var1, de1)
    @test de2 in getBlobEntries(fg, var1.label)

    #get
    @test deepcopy(de1) == getBlobEntry(var1, :label1)
    @test deepcopy(de2) == getBlobEntry(fg, :a, :label2)
    @test_throws KeyError getBlobEntry(var2, :label1)
    @test_throws KeyError getBlobEntry(fg, :b, :label1)

    #update
    @test updateBlobEntry!(fg, :a, de2_update) == de2_update
    @test deepcopy(de2_update) == getBlobEntry(fg, :a, :label2)
    @test @test_logs (:warn, r"does not exist") updateBlobEntry!(fg, :b, de2_update) == de2_update

    #list
    entries = getBlobEntries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e->e.label, entries), [:label1, :label2])
    @test length(getBlobEntries(fg, :b)) == 1

    @test issetequal(listBlobEntries(fg, :a), [:label1, :label2])
    @test listBlobEntries(fg, :b) == Symbol[:label2]

    #delete
    @test deleteBlobEntry!(fg, var1.label, de1.label) == de1
    @test listBlobEntries(fg, var1.label) == Symbol[:label2]
    #delete from dfg
    @test deleteBlobEntry!(fg, :a, :label2) == de2_update
    var1 = getVariable(fg, :a)
    @test listBlobEntries(var1) == Symbol[]

    # Blobstore functions
    fs = FolderStore("/tmp/$(string(uuid4())[1:8])")
    # Adding
    addBlobStore!(fg, fs)
    # Listing
    @test listBlobStores(fg) == [fs.key]
    # Getting
    @test getBlobStore(fg, fs.key) == fs
    # Deleting
    @test deleteBlobStore!(fg, fs.key) == fs
    # Updating
    updateBlobStore!(fg, fs)
    @test listBlobStores(fg) == [fs.key]
    # Emptying
    emptyBlobStore!(fg)
    @test listBlobStores(fg) == []
    # Add it back
    addBlobStore!(fg, fs)

    # Data functions
    testData = rand(UInt8, 50)
    # Adding 
    newData = addData!(fg, fs.key, :a, :testing, testData) # convenience wrapper over addBlob!
    # Listing
    @test :testing in listBlobEntries(fg, :a)
    # Getting
    data = getData(fg, fs, :a, :testing) # convenience wrapper over getBlob
    @test data[1].hash == newData.hash #[1]
    # @test data[2] == newData[2]
    # Updating
    updateData = updateData!(fg, fs, :a, newData, rand(UInt8, 50)) # convenience wrapper around updateBlob!
    @test updateData[1].hash != data[1].hash
    @test updateData[2] != data[2]
    # Deleting
    retData = deleteData!(fg, :a, :testing) # convenience wrapper around deleteBlob!

end


function testGroup!(fg, v1, v2, f0, f1)
    # "TODO Sorteer groep"

    @testset "Listing Variables and Factors with filters" begin

        @test issetequal([:a,:b], listVariables(fg))
        @test issetequal([:af1,:abf1], listFactors(fg))

        # @test @test_deprecated getVariableIds(fg) == listVariables(fg)
        # @test @test_deprecated getFactorIds(fg) == listFactors(fg)

        # TODO Mabye implement IIF type here
        # Requires IIF or a type in IIF
        @test getFactorType(f1.solverData) === f1.solverData.fnc.usrfnc!
        @test getFactorType(f1) === f1.solverData.fnc.usrfnc!
        @test getFactorType(fg, :abf1) === f1.solverData.fnc.usrfnc!

        @test isPrior(fg, :af1) # if f1 is prior
        @test lsfPriors(fg) == [:af1]

        @test issetequal([:TestFunctorInferenceType1, :TestAbstractPrior], lsfTypes(fg))

        facTypesDict = lsfTypesDict(fg)
        @test issetequal(collect(keys(facTypesDict)), lsfTypes(fg))
        @test issetequal(facTypesDict[:TestFunctorInferenceType1], [:abf1])
        @test issetequal(facTypesDict[:TestAbstractPrior], [:af1])

        @test ls(fg, TestFunctorInferenceType1) == [:abf1]
        @test lsf(fg, TestAbstractPrior) == [:af1]
        @test lsfWho(fg, :TestFunctorInferenceType1) == [:abf1]

        @test getVariableType(v1) == TestVariableType1()
        @test getVariableType(fg,:a) == TestVariableType1()

        @test getVariableType(v1) == TestVariableType1()
        @test getVariableType(fg,:a) == TestVariableType1()

        @test ls2(fg, :a) == [:b]

        @test issetequal([:TestVariableType1, :TestVariableType2], lsTypes(fg))

        varTypesDict = lsTypesDict(fg)
        @test issetequal(collect(keys(varTypesDict)), lsTypes(fg))
        @test issetequal(varTypesDict[:TestVariableType1], [:a])
        @test issetequal(varTypesDict[:TestVariableType2], [:b])

        @test ls(fg, TestVariableType1) == [:a]

        @test lsWho(fg, :TestVariableType1) == [:a]

        # FIXME return: Symbol[:b, :b] == Symbol[:b]
        varNearTs = findVariableNearTimestamp(fg, now())
        @test_skip varNearTs[1][1] == [:b]

        ## SORT copied from CRUD
        @test all(getVariables(fg, r"a") .== [getVariable(fg,v1.label)])
        @test all(getVariables(fg, solvable=1) .== [getVariable(fg,v2.label)])
        @test getVariables(fg, r"a", solvable=1) == []
        @test getVariables(fg, tags=[:LANDMARK])[1] == getVariable(fg, v2.label)

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

        @test lsf(fg, tags=[:NONE]) == []
        @test lsf(fg, tags=[:PRIOR]) == [:af1]

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
        @test @test_logs (:error, r"does not have solver data") !isInitialized(v2, :second)

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
        @test getSolvable(fg, f1.label) == 0

        #TODO follow up on why f1 is no longer referenced, and remove next line
        @test_broken getSolvable(f1) == 0


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
# addVariable!(fg, DFGVariable(:a, TestVariableType1()))
# addVariable!(fg, DFGVariable(:b, TestVariableType1()))
# addFactor!(fg, DFGFactor(:abf1, [:a,:b], GenericFunctionNodeData{TestFunctorInferenceType1, Symbol}()))
# addVariable!(fg, DFGVariable(:orphan, TestVariableType1(), solvable = 0))
function AdjacencyMatricesTestBlock(fg)
    # Normal
    #deprecated
    # @test_throws ErrorException getAdjacencyMatrix(fg)
    adjMat = DistributedFactorGraphs.getAdjacencyMatrixSymbols(fg)
    @test size(adjMat) == (2,4)
    @test issetequal(adjMat[1, :], [nothing, :a, :b, :orphan])
    @test issetequal(adjMat[2, :], [:abf1, :abf1, :abf1, nothing])
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
function connectivityTestGraph(::Type{T}; VARTYPE=DFGVariable, FACTYPE=DFGFactor) where T <: AbstractDFG#InMemoryDFGTypes
    #settings
    numNodesType1 = 5
    numNodesType2 = 5

    dfg = T(userLabel="test@navability.io")

    vars = vcat(map(n -> VARTYPE(Symbol("x$n"), VariableNodeData{TestVariableType1}()), 1:numNodesType1),
                map(n -> VARTYPE(Symbol("x$(numNodesType1+n)"), VariableNodeData{TestVariableType2}()), 1:numNodesType2))

    foreach(v -> addVariable!(dfg, v), vars)


    if FACTYPE == DFGFactor
        #change ready and solveInProgress for x7,x8 for improved tests on x7x8f1
        #NOTE because defaults changed
        setSolvable!(dfg, :x8, 0)
        setSolvable!(dfg, :x9, 0)

        gfnd = GenericFunctionNodeData(eliminated=true, potentialused=true, fnc=TestCCW(TestFunctorInferenceType1()), multihypo=Float64[], certainhypo=Int[], solveInProgress=0, inflation=1.0)
        f_tags = Set([:FACTOR])
        # f1 = DFGFactor(f1_lbl, [:a,:b], gfnd, tags = f_tags)

        facs = map(n -> addFactor!(dfg, DFGFactor(Symbol("x$(n)x$(n+1)f1"),
                                                  [vars[n].label, vars[n+1].label],
                                                  deepcopy(gfnd),
                                                  tags=deepcopy(f_tags))),
                                                   1:length(vars)-1)
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
    #TODO if not a GraphsDFG with and summary or skeleton
    if VARTYPE == DFGVariable
        @test getNeighbors(dfg, :x5, solvable=2) == Symbol[]
        @test issetequal(getNeighbors(dfg, :x5, solvable=0), [:x4x5f1,:x5x6f1])
        @test issetequal(getNeighbors(dfg, :x5), [:x4x5f1,:x5x6f1])
        @test getNeighbors(dfg, :x7x8f1, solvable=0) == [:x7, :x8]
        @test getNeighbors(dfg, :x7x8f1, solvable=1) == [:x7]
        @test getNeighbors(dfg, verts[1], solvable=0) == [:x1x2f1]
        @test getNeighbors(dfg, verts[1], solvable=2) == Symbol[]
        @test getNeighbors(dfg, verts[1]) == [:x1x2f1]
    end

end

#TODO confirm these tests are covered somewhere then delete
# function  GettingSubgraphs(testDFGAPI; VARTYPE=DFGVariable, FACTYPE=DFGFactor)
#
#     # "Getting Subgraphs"
#     dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE=VARTYPE, FACTYPE=FACTYPE)
#     # Subgraphs
#     dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     # Test include orphan factors
#     @test_broken begin
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 1, true)
#         @test symdiff([:x1, :x1x2f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#         # Test adding to the dfg
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2, true, dfgSubgraph)
#         @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#     end
#     #
#     dfgSubgraph = getSubgraph(dfg,[:x1, :x2, :x1x2f1])
#     # Only returns x1 and x2
#     @test symdiff([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#
#     #TODO if not a GraphsDFG with and summary or skeleton
#     if VARTYPE == DFGVariable
#         # DFG issue #201 Test include orphan factors with filtering - should only return x7 with solvable=1
#         @test_broken begin
#             dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=0)
#             @test symdiff([:x7, :x8, :x7x8f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#             # Filter - always returns the node you start at but filters around that.
#             dfgSubgraph = getSubgraphAroundNode(dfg, getFactor(dfg, :x7x8f1), 1, true, solvable=1)
#             @test symdiff([:x7x8f1, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...]) == []
#             end
#         # Test for distance = 2, should return orphans
#         setSolvable!(dfg, :x8x9f1, 0)
#         dfgSubgraph = getSubgraphAroundNode(dfg, getVariable(dfg, :x8), 2, true, solvable=1)
#         @test issetequal([:x8, :x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
#         #end if not a GraphsDFG with and summary or skeleton
#     end
#     # DFG issue #95 - confirming that getSubgraphAroundNode retains order
#     # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
#     for fId in listVariables(dfg)
#         # Get a subgraph of this and it's related factors+variables
#         dfgSubgraph = getSubgraphAroundNode(dfg, verts[1], 2)
#         # For each factor check that the order the copied graph == original
#         for fact in getFactors(dfgSubgraph)
#             @test fact._variableOrderSymbols == getFactor(dfg, fact.label)._variableOrderSymbols
#         end
#     end
#
# end


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

    #TODO if not a GraphsDFG with and summary or skeleton
    if VARTYPE == DFGVariable
        dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [:x8], 2, solvable=1)
        @test issetequal([:x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
        #end if not a GraphsDFG with and summary or skeleton
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

    #TODO buildSubgraph default constructors for skeleton and summary
    if VARTYPE == DFGVariable
        dfgSubgraph = buildSubgraph(dfg, [:x1, :x2, :x1x2f1])
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

        dfgSubgraph = buildSubgraph(dfg, [:x2, :x3], 2)
        @test issetequal([:x2, :x3, :x1, :x4, :x3x4f1, :x1x2f1, :x2x3f1], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

        dfgSubgraph = buildSubgraph(dfg, [:x1x2f1], 1)
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
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
            if field != :variableTypeName
                @test getproperty(getVariable(dfg, v), field) == getproperty(getVariable(summaryGraph, v), field)
            else
                # Special case to check the symbol variableType is equal to the full variableType.
                @test Symbol(typeof(getVariableType(getVariable(dfg, v)))) == getVariableTypeName(getVariable(summaryGraph, v))
                @test getVariableType(getVariable(dfg, v)) == getVariableType(getVariable(summaryGraph, v))
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            @test getproperty(getFactor(dfg, f), field) == getproperty(getFactor(summaryGraph, f), field)
        end
    end
end

function ProducingDotFiles(testDFGAPI,
                           v1 = nothing,
                           v2 = nothing,
                           f1 = nothing;
                           VARTYPE=DFGVariable,
                           FACTYPE=DFGFactor)
    # "Producing Dot Files"
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI(userLabel="test@navability.io")

    if v1 === nothing
        v1 = VARTYPE(:a, VariableNodeData{TestVariableType1}())
    end
    if v2 === nothing
        v2 = VARTYPE(:b, VariableNodeData{TestVariableType1}())
    end
    if f1 === nothing
        f1 = (FACTYPE==DFGFactor) ? DFGFactor{TestFunctorInferenceType1}(:abf1, [:a, :b]) : FACTYPE(:abf1)
    end

    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    # FIXME, fix deprecation
    # ┌ Warning: addFactor!(dfg, variables, factor) is deprecated, use addFactor!(dfg, factor)
    # │   caller = ProducingDotFiles(testDFGAPI::Type{GraphsDFG}, v1::Nothing, v2::Nothing, f1::Nothing; VARTYPE::Type{DFGVariable}, FACTYPE::Type{DFGFactor}) at testBlocks.jl:1440
    # └ @ Main ~/.julia/dev/DistributedFactorGraphs/test/testBlocks.jl:1440
    addFactor!(dotdfg, [v1, v2], f1)
    #NOTE hardcoded toDot will have different results so test Graphs seperately
    if testDFGAPI <: GraphsDFG || testDFGAPI <: GraphsDFG
        todotstr = toDot(dotdfg)
        todota = todotstr == "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\na -- abf1\nb -- abf1\n}\n"
        todotb = todotstr == "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\nb -- abf1\na -- abf1\n}\n"
        @test (todota || todotb)
    else
        @test toDot(dotdfg) == "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
    end
    @test toDotFile(dotdfg, "something.dot") == nothing
    Base.rm("something.dot")

end

function ConnectivityTest(testDFGAPI; kwargs...)
    dfg, verts, facs = connectivityTestGraph(testDFGAPI; kwargs...)
    @test isConnected(dfg) == true
    # @test @test_deprecated isFullyConnected(dfg) == true
    # @test @test_deprecated hasOrphans(dfg) == false

    deleteFactor!(dfg, :x9x10f1)
    @test isConnected(dfg) == false

    deleteVariable!(dfg, :x5)
    @test isConnected(dfg) == false

end


function CopyFunctionsTest(testDFGAPI; kwargs...)

    # testDFGAPI = GraphsDFG
    # kwargs = ()

    dfg, verts, facs = connectivityTestGraph(testDFGAPI; kwargs...)

    varlbls = ls(dfg)
    faclbls = lsf(dfg)

    dcdfg = deepcopyGraph(GraphsDFG, dfg)

    @test issetequal(ls(dcdfg), varlbls)
    @test issetequal(lsf(dcdfg), faclbls)

    vlbls = [:x2, :x3]
    flbls = [:x2x3f1]
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, vlbls, flbls)

    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)

    # deepcopy subgraph ignoring orphans
    # @test_logs (:warn, r"orphan") # orphan warning has been suppressed given overwhelming printouts
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, vlbls, union(flbls, [:x1x2f1]))
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)

    # deepcopy subgraph with 2 parts
    vlbls = [:x2, :x3, :x5, :x6, :x10]
    flbls = [:x2x3f1, :x5x6f1]
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, vlbls, flbls)
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), flbls)
    @test !isConnected(dcdfg_part)
    # plotDFG(dcdfg_part)


    vlbls = [:x2, :x3]
    dcdfg_part =  deepcopyGraph(GraphsDFG, dfg, vlbls; verbose=false)
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), [:x2x3f1])

    # not found errors
    @test_throws ErrorException deepcopyGraph(GraphsDFG, dfg, [:x1, :a])
    @test_throws ErrorException deepcopyGraph(GraphsDFG, dfg, [:x1], [:f1])

    # already exists errors
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, [:x1, :x2, :x3], [:x1x2f1, :x2x3f1])
    @test_throws ErrorException deepcopyGraph!(dcdfg_part, dfg, [:x4, :x2, :x3], [:x1x2f1, :x2x3f1])
    @test_throws ErrorException deepcopyGraph!(dcdfg_part, dfg, [:x1x2f1])

    # same but overwrite destination
    deepcopyGraph!(dcdfg_part, dfg, [:x4, :x2, :x3], [:x1x2f1, :x2x3f1]; overwriteDest = true)

    deepcopyGraph!(dcdfg_part, dfg, Symbol[], [:x1x2f1]; overwriteDest=true)

    vlbls1 = [:x1, :x2, :x3]
    vlbls2 = [:x4, :x5, :x6]
    dcdfg_part1 = deepcopyGraph(GraphsDFG, dfg, vlbls1)
    dcdfg_part2 = deepcopyGraph(GraphsDFG, dfg, vlbls2)

    mergedGraph = testDFGAPI(userLabel="test@navability.io")
    mergeGraph!(mergedGraph, dcdfg_part1)
    mergeGraph!(mergedGraph, dcdfg_part2)

    @test issetequal(ls(mergedGraph), union(vlbls1, vlbls2))
    @test issetequal(lsf(mergedGraph), union(lsf(dcdfg_part1), lsf(dcdfg_part2)))
    # convert to...
    # condfg = convert(GraphsDFG, dfg)
    # @test condfg isa GraphsDFG
    # @test issetequal(ls(condfg), varlbls)
    # @test issetequal(lsf(condfg), faclbls)
    #
    # condfg = convert(GraphsDFG, dfg)
    # @test condfg isa GraphsDFG
    # @test issetequal(ls(condfg), varlbls)
    # @test issetequal(lsf(condfg), faclbls)

    # GraphsDFG(dfg::AbstractDFG) = convert(GraphsDFG,dfg)
    # GraphsDFG(dfg)

end

function FileDFGTestBlock(testDFGAPI; kwargs...)

    # testDFGAPI = GraphsDFG
    # kwargs = ()
    # filename = "/tmp/fileDFG"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI; kwargs...)

    for filename in ["/tmp/fileDFG", "/tmp/FileDFGExtension.tar.gz"]

        v4 = getVariable(dfg, :x4)
        vnd = getSolverData(v4)
        # set everything
        vnd.BayesNetVertID = :outid
        push!(vnd.BayesNetOutVertIDs, :id)
        # vnd.bw[1] = [1.0;]
        push!(vnd.dimIDs, 1)
        vnd.dims = 1
        vnd.dontmargin = true
        vnd.eliminated = true
        vnd.infoPerCoord .= Float64[1.5;]
        vnd.initialized = true
        vnd.ismargin = true
        push!(vnd.separator, :sep)
        vnd.solveInProgress = 1
        vnd.solvedCount = 2
        # vnd.val[1] = [2.0;]
        #update
        updateVariable!(dfg, v4)

        f45 = getFactor(dfg, :x4x5f1)
        fsd = f45.solverData
        # set some factor solver data
        push!(fsd.certainhypo, 2)
        push!(fsd.edgeIDs, 3)
        fsd.eliminated = true
        push!(fsd.multihypo, 4.0)
        fsd.nullhypo = 5.0
        fsd.potentialused = true
        fsd.solveInProgress = true
        #update factor
        updateFactor!(dfg, f45)

        # Save and load the graph to test.
        saveDFG(dfg, filename)

        retDFG = testDFGAPI(userLabel="test@navability.io")
        @info "Going to load $filename"

        @test_throws AssertionError loadDFG!(retDFG,"badfilename")

        loadDFG!(retDFG, filename)

        @test issetequal(ls(dfg), ls(retDFG))
        @test issetequal(lsf(dfg), lsf(retDFG))
        for var in ls(dfg)
            @test getVariable(dfg, var) == getVariable(retDFG, var)
        end
        for fact in lsf(dfg)
            @test getFactor(dfg, fact) == getFactor(retDFG, fact)
        end

        # @test length(getBlobEntries(getVariable(retDFG, :x1))) == 1
        # @test typeof(getBlobEntry(getVariable(retDFG, :x1),:testing)) == GeneralDataEntry
        # @test length(getBlobEntries(getVariable(retDFG, :x2))) == 1
        # @test typeof(getBlobEntry(getVariable(retDFG, :x2),:testing2)) == FileDataEntry
    end

end
