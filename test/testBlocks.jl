using DistributedFactorGraphs
using Test
using Dates
using LieGroups
using LieGroups: TranslationGroup

using DistributedFactorGraphs:
    LabelExistsError,
    LabelNotFoundError,
    NoSolverParams,
    AbstractGraphVariable,
    AbstractGraphFactor

import Base: convert

# Base.convert(::Type{<:Tuple}, ::typeof(TranslationGroup(1))) = (:Euclid,)
# Base.convert(::Type{<:Tuple}, ::typeof(TranslationGroup(2))) = (:Euclid, :Euclid)

# define a few varaible to use
@defStateType TestVariableType1 TranslationGroup(1) [0.0;]
DFG.@defStateTypeN TestVariableType{N} TranslationGroup(N) zeros(N)
const TestVariableType2 = TestVariableType{2}

# define a few factor types to use
DFG.@defObservationType TestFunctorInferenceType1 RelativeObservation TranslationGroup(1)
DFG.@defObservationType TestFunctorInferenceType2 RelativeObservation TranslationGroup(1)
DFG.@defObservationType TestAbstractPrior PriorObservation TranslationGroup(1)

@kwdef struct TestBelief
    a::Float64 = 1.0
    b::Float64 = 3.0
end

TestFunctorInferenceType1() = TestFunctorInferenceType1(TestBelief())
TestFunctorInferenceType2() = TestFunctorInferenceType2(TestBelief())
TestAbstractPrior() = TestAbstractPrior(TestBelief())

struct PackedNothingDistribution <: AbstractPackedBelief
    _type::Symbol
    function PackedNothingDistribution(; _type::String = "PackedNothingDistribution")
        return new(Symbol(_type))
    end
end

DFG.packDistribution(::Nothing) = PackedNothingDistribution()
DFG.unpackDistribution(::PackedNothingDistribution) = nothing

struct TestCCW{T <: AbstractObservation} <: FactorCache
    usrfnc!::T
end

TestCCW{T}() where {T} = TestCCW(T())

Base.:(==)(a::TestCCW, b::TestCCW) = a.usrfnc! == b.usrfnc!

##
# global testDFGAPI = GraphsDFG
# T = testDFGAPI

#test Specific definitions
# struct TestInferenceVariable1 <: StateType end
# struct TestInferenceVariable2 <: StateType end
# struct TestFunctorInferenceType1 <: AbstractObservation end

# NOTE see note in AbstractDFG.jl setSolverParams!
struct GeenSolverParams <: AbstractDFGParams end

solparams = NoSolverParams()
# DFG Accessors
function DFGStructureAndAccessors(
    ::Type{T},
    solparams::AbstractDFGParams = NoSolverParams(),
) where {T <: AbstractDFG}
    # "DFG Structure and Accessors"
    # Constructors
    # Constructors to be implemented
    fg = T(; solverParams = solparams)
    #TODO test something better
    @test isa(fg, T)
    @test getAgentLabel(fg) == :DefaultAgent
    @test string(getGraphLabel(fg))[1:6] == "graph_"

    # Test the validation of the robot, session, and user IDs.
    notAllowedList = [
        Symbol("!notValid"),
        Symbol("1notValid"),
        :_notValid,
        :AGENT,
        :VARIABLE,
        :FACTOR,
        :BLOB_ENTRY,
        :FACTORGRAPH,
    ]

    for s in notAllowedList
        @test_throws ArgumentError T(solverParams = solparams, graphLabel = s)
        @test_throws ArgumentError T(solverParams = solparams, agentLabel = s)
    end

    des = "description for runtest"
    rId = :testRobotId
    sId = :testSessionId
    rd = DFG.Bloblets(:rd=>DFG.Bloblet(:rd, "rdEntry"))
    sd = DFG.Bloblets(:sd=>DFG.Bloblet(:sd, "sdEntry"))
    fg = T(;
        graphDescription = des,
        agentLabel = rId,
        graphLabel = sId,
        agentBloblets = rd,
        graphBloblets = sd,
        solverParams = solparams,
    )

    # accesssors
    # get
    @test getDescription(fg) == des
    @test getAgentLabel(fg) == rId
    @test getGraphLabel(fg) == sId
    @test getAddHistory(fg) === fg.addHistory

    @test getSolverParams(fg) == NoSolverParams()

    #FIXME test bloblets
    # @test setAgentMetadata!(fg, rd) == rd
    # @test setGraphMetadata!(fg, sd) == sd
    # @test getAgentMetadata(fg) == rd
    # @test getGraphMetadata(fg) == sd

    # smallUserData = Dict{Symbol, MetadataTypes}(:a => "42", :b => "Hello")
    # smallRobotData = Dict{Symbol, MetadataTypes}(:a => "43", :b => "Hello")
    # smallSessionData = Dict{Symbol, MetadataTypes}(:a => "44", :b => "Hello")

    #TODO CRUD vs set
    # @test setAgentMetadata!(fg, deepcopy(smallRobotData)) == smallRobotData
    # @test setGraphMetadata!(fg, deepcopy(smallSessionData)) == smallSessionData

    # @test getAgentMetadata(fg) == smallRobotData
    # @test getGraphMetadata(fg) == smallSessionData

    # NOTE see note in AbstractDFG.jl setSolverParams!
    @test_throws Exception setSolverParams!(fg, GeenSolverParams()) == GeenSolverParams()

    @test setSolverParams!(fg, typeof(solparams)()) == typeof(solparams)()

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
function GraphAgentMetadata!(fg::AbstractDFG)
    # "User, Robot, Session Data"

    # Robot Data
    @test getAgentMetadata(fg, :a) == "43"
    #TODO
    @test_broken addAgentMetadata!
    @test DFG.updateAgentMetadata!(fg, :b => "2") == getAgentMetadata(fg)
    @test DFG.deleteAgentMetadata!(fg, :b) == 1
    @test DFG.emptyAgentMetadata!(fg) == Dict{Symbol, String}()

    # SessionData
    @test getGraphMetadata(fg, :a) == "44"
    #TODO
    @test_broken addGraphMetadata!
    @test DFG.updateGraphMetadata!(fg, :b => "3") == getGraphMetadata(fg)
    @test DFG.deleteGraphMetadata!(fg, :b) == 1
    @test DFG.emptyGraphMetadata!(fg) == Dict{Symbol, String}()

    # TODO Set-like if we want eg. list, merge, etc
    # listAgentMetadata
    # listGraphMetadata
    # mergeAgentData
    # mergeGraphData

end

# User, Robot, Session Data Blob Entries
function GraphAgentBlobentries!(fg::AbstractDFG)
    be = Blobentry(; label = :key1, blobstore = :b)

    # Agent Blob Entries
    ae = addAgentBlobentry!(fg, be)
    @test ae == be
    @test_throws DFG.LabelExistsError addAgentBlobentry!(fg, be)
    ge = getAgentBlobentry(fg, :key1)
    @test ge == be
    @test hasAgentBlobentry(fg, :key1)
    me = mergeAgentBlobentry!(fg, be)
    @test me == 1
    de = deleteAgentBlobentry!(fg, :key1)
    @test de == 1
    @test hasAgentBlobentry(fg, :key1) == false
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, :key1)
    @test_throws DFG.LabelNotFoundError deleteAgentBlobentry!(fg, :key1)

    # Graph Blob Entries
    ae = addGraphBlobentry!(fg, be)
    @test ae == be
    @test_throws DFG.LabelExistsError addGraphBlobentry!(fg, be)
    ge = getGraphBlobentry(fg, :key1)
    @test ge == be
    @test hasGraphBlobentry(fg, :key1)
    me = mergeGraphBlobentry!(fg, be)
    @test me == 1
    de = deleteGraphBlobentry!(fg, :key1)
    @test de == 1
    @test hasGraphBlobentry(fg, :key1) == false
    @test_throws DFG.LabelNotFoundError getGraphBlobentry(fg, :key1)
    @test_throws DFG.LabelNotFoundError deleteGraphBlobentry!(fg, :key1)

    be2 = Blobentry(; blobid = uuid4(), label = :key2, blobstore = :b)

    bes = [be, be2]

    ae = addAgentBlobentries!(fg, bes)
    @test length(ae) == 2
    @test_throws DFG.LabelExistsError addAgentBlobentries!(fg, bes)
    besr = getAgentBlobentries(fg)
    @test length(besr) == 2
    me = mergeAgentBlobentries!(fg, bes)
    @test me == 2
    de = deleteAgentBlobentries!(fg, [:key1, :key2])
    @test de == 2
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, :key1)
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, :key2)

    ae = addGraphBlobentries!(fg, bes)
    @test length(ae) == 2
    @test_throws DFG.LabelExistsError addGraphBlobentries!(fg, bes)
    besr = getGraphBlobentries(fg)
    @test length(besr) == 2
    me = mergeGraphBlobentries!(fg, bes)
    @test me == 2
    de = deleteGraphBlobentries!(fg, [:key1, :key2])
    @test de == 2
    @test_throws DFG.LabelNotFoundError getGraphBlobentry(fg, :key1)
    @test_throws DFG.LabelNotFoundError getGraphBlobentry(fg, :key2)
end

function DFGVariableSCA()
    # "DFG Variable"

    v1_lbl = :a
    v1_tags = Set([:VARIABLE, :POSE])
    small = Dict{Symbol, MetadataTypes}(:small => "data")
    testTimestamp = now(localzone())
    # Constructors
    v1 = VariableCompute(
        v1_lbl,
        TestVariableType1();
        tags = v1_tags,
        solvable = 0,
        solverDataDict = Dict(:default => State{TestVariableType1}()),
    )
    v2 = VariableCompute(:b, State{TestVariableType2}(); tags = Set([:VARIABLE, :LANDMARK]))
    v3 = VariableCompute(
        :c,
        State{TestVariableType2}();
        timestamp = ZonedDateTime("2020-08-11T00:12:03.000-05:00"),
    )

    vorphan = VariableCompute(
        :orphan,
        TestVariableType1();
        tags = v1_tags,
        solvable = 0,
        solverDataDict = Dict(:default => State{TestVariableType1}()),
    )

    # v1.states[:default].val[1] = [0.0;]
    # v1.states[:default].bw[1] = [1.0;]
    # v2.states[:default].val[1] = [0.0;0.0]
    # v2.states[:default].bw[1] = [1.0;1.0]
    # v3.states[:default].val[1] = [0.0;0.0]
    # v3.states[:default].bw[1] = [1.0;1.0]

    @test getLabel(v1) == v1_lbl
    @test getTags(v1) == v1_tags

    @test getTimestamp(v1) == v1.timestamp

    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1

    # TODO direct use is not recommended, use accessors, maybe not export or deprecate
    @test refStates(v1) == v1.states

    # @test getMetadata(v1) == Dict{Symbol, MetadataTypes}()

    @test getVariableType(v1) == TestVariableType1()

    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(v3, testTags) == Set(testTags)
    @test setTags!(v3, Set(testTags)) == Set(testTags)

    #NOTE  a variable's timestamp is considered similar to its label.  setTimestamp! (not implemented) would create a new variable and call mergeVariable!
    # @test getTimestamp(v1ts) == testTimestamp
    #follow with mergeVariable!(fg, v1ts)

    @test setSolvable!(v1, 1) == 1
    @test getSolvable(v1) == 1
    @test setSolvable!(v1, 0) == 0

    #no accessors on dataDict, only CRUD

    #variableType functions
    testvar = TestVariableType1()
    @test getDimension(testvar) == 1
    @test getManifold(testvar) == TranslationGroup(1)

    # #TODO sort out
    # getState
    # getSolvedCount
    # isSolved
    # setSolvedCount

    return (v1 = v1, v2 = v2, v3 = v3, vorphan = vorphan, v1_tags = v1_tags)
end

function DFGFactorSCA()
    # "DFG Factor"

    # Constructors
    #VariableCompute solvable default to 1, but Factor to 0, is that correct
    f1_lbl = :abf1
    f1_tags = Set([:FACTOR])
    testTimestamp = now(localzone())

    obs_prior = TestAbstractPrior()

    obs = TestFunctorInferenceType1()

    f1 = FactorCompute(f1_lbl, [:a, :b], obs; tags = f1_tags, solvable = 0)

    f2 = FactorCompute(
        :bcf1,
        [:b, :c],
        TestFunctorInferenceType1();
        timestamp = ZonedDateTime("2020-08-11T00:12:03.000-05:00"),
    )
    #TODO add tests for mutating vos in updateFactor and orphan related checks.
    # we should perhaps prevent an empty vos

    @test getLabel(f1) == f1_lbl
    @test getTags(f1) == f1_tags

    @test getTimestamp(f1) == f1.timestamp

    @test getSolvable(f1) == 0

    @test getObservation(f1) === f1.observation

    @test getVariableOrder(f1) == (:a, :b)

    @test setSolvable!(f1, 1) == 1

    @test typeof(getObservation(f1)) == TestFunctorInferenceType1{TestBelief}

    #TODO here for now, don't recommend usage.
    testTags = [:tag1, :tag2]
    @test setTags!(f1, testTags) == Set(testTags)
    @test setTags!(f1, Set(testTags)) == Set(testTags)

    #follow with mergeFactor!(fg, v1ts)

    #TODO Should throw method error
    # @test_throws MethodError setTimestamp!(f1, testTimestamp)
    # @test_throws ErrorException setTimestamp!(f1, testTimestamp)
    #/TODO

    @test setSolvable!(f1, 1) == 1
    @test getSolvable(f1) == 1

    # create f0 here for a later timestamp
    f0 = FactorCompute(:af1, [:a], obs_prior; tags = Set([:PRIOR]))

    #fill in undefined fields
    # f2.solverData.certainhypo = Int[]
    # f2.solverData.multihypo = Float64[]
    # f2.solverData.edgeIDs = Int64[]

    return (f0 = f0, f1 = f1, f2 = f2)
end

function VariablesandFactorsCRUD_SET!(fg, v1, v2, v3, f0, f1, f2)
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

    fnope = FactorCompute(:broken, [:a, :nope], TestFunctorInferenceType1())
    @test_throws LabelNotFoundError addFactor!(fg, fnope)

    @test addFactor!(fg, f1) == f1
    @test_throws LabelExistsError addFactor!(fg, f1)

    @test getLabel(fg[getLabel(f1)]) == getLabel(f1)

    @test mergeVariable!(fg, v3) == 1
    @test mergeVariables!(fg, [v3]) == 1
    @test_throws LabelExistsError addVariable!(fg, v3)

    @test mergeFactor!(fg, f2) == 1
    @test mergeFactors!(fg, [f2]) == 1
    @test_throws LabelExistsError addFactor!(fg, f2)
    #TODO Graphs.jl, but look at refactoring absract @test_throws LabelExistsError addFactor!(fg, f2)

    if f2 isa FactorCompute
        f2_mod = FactorCompute(
            f2.label,
            (:a,),
            f2.observation,
            f2.state;
            timestamp = f2.timestamp,
            tags = f2.tags,
            solvable = f2.solvable[],
        )
    else
        f2_mod = typeof(f2)(f2.label, (:a,))
    end

    @test_throws ErrorException mergeFactor!(fg, f2_mod)
    @test issetequal(lsf(fg), [:bcf1, :abf1])

    @test getAddHistory(fg) == [:a, :b, :c]

    # Extra timestamp functions https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/315

    #deletions
    delvarCompare = getVariable(fg, :c)
    delfacCompare = getFactor(fg, :bcf1)
    ndel = deleteVariable!(fg, v3)
    @test ndel == 2
    @test_throws LabelNotFoundError deleteVariable!(fg, v3)
    @test setdiff(ls(fg), [:a, :b]) == []

    @test addVariable!(fg, v3) === v3
    @test addFactor!(fg, f2) === f2

    @test deleteFactor!(fg, f2) == 1
    @test_throws LabelNotFoundError deleteFactor!(fg, f2)
    @test lsf(fg) == [:abf1]

    delvarCompare = getVariable(fg, :c)
    delfacCompare = []
    ndel = deleteVariable!(fg, v3)
    @test ndel == 1

    @test getVariable(fg, :a) == v1
    @test getVariable(fg, :a, :default) == v1

    @test addFactor!(fg, f0) == f0

    if isa(v1, VariableCompute)
        #TODO decide if this should be @error or other type
        @test_throws LabelNotFoundError getVariable(fg, :a, :missingfoo)
    else
        @test_logs (:warn, r"supported for type VariableCompute") getVariable(
            fg,
            :a,
            :missingfoo,
        )
    end

    @test getFactor(fg, :abf1) == f1

    @test_throws LabelNotFoundError getVariable(fg, :c)
    @test_throws LabelNotFoundError getFactor(fg, :bcf1)

    #test issue #375
    @test_throws LabelNotFoundError getVariable(fg, :abf1)
    @test_throws LabelNotFoundError getFactor(fg, :a)

    # Existence
    @test hasVariable(fg, :a)
    @test !hasVariable(fg, :c)
    @test exists(fg, :a)
    @test !exists(fg, :c)
    @test hasFactor(fg, :abf1)
    @test !hasFactor(fg, :bcf1)
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

    if f0 isa FactorCompute
        @test isPrior(fg, :af1)
        @test !isPrior(fg, :abf1)
    end

    #list
    @test length(getVariables(fg)) == 2
    @test issetequal(getLabel.(getFactors(fg)), [:af1, :abf1])

    @test issetequal([:a, :b], listVariables(fg))
    @test issetequal([:af1, :abf1], listFactors(fg))

    @test ls(fg) == listVariables(fg)
    @test lsf(fg) == listFactors(fg)

    if getVariable(fg, ls(fg)[1]) isa VariableCompute
        @test :default in DFG.listStates(fg)
        @test :default in DFG.listStates(fg; labelFilter = contains("default") ∘ string)
        @test :default in DFG.listStates(fg)
    end

    # simple broadcast test
    if f0 isa FactorCompute
        @test issetequal(
            getObservation.(fg, lsf(fg)),
            [TestFunctorInferenceType1(), TestAbstractPrior()],
        )
    end
    @test getVariable.(fg, [:a]) == [getVariable(fg, :a)]
end

function tagsTestBlock!(fg, v1, v1_tags)
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
    @test hasTags(fg, :b, [:LANDMARK, :TAG], matchAll = false)

    @test hasTagsNeighbors(fg, :abf1, [:LANDMARK])
    @test !hasTagsNeighbors(fg, :abf1, [:LANDMARK, :TAG])
end

function VSDTestBlock!(fg, v1)
    # "Variable Solver Data"
    # #### Variable Solver Data
    # **CRUD**
    #  - `getState`
    #  - `addState!`
    #  - `updateVariableSolverData!`
    #  - `deleteState!`
    #
    # > - `getStates` #TODO Data is already plural so maybe Variables, All or Dict, or use Datum for singular
    # > - `getVariablesSolverData`
    #
    # **Set like**
    #  - `listStates`
    #
    #
    # **State**
    #  - `getSolveInProgress`

    vnd = State{TestVariableType1}(; solveKey = :parametric)
    # vnd.val[1] = [0.0;]
    # vnd.bw[1] = [1.0;]
    @test addState!(fg, :a, vnd) == vnd

    @test_throws LabelExistsError addState!(fg, :a, vnd)

    @test issetequal(listStates(fg, :a), [:default, :parametric])

    # Get the data back - note that this is a reference to above.
    vndBack = getState(fg, :a, :parametric)
    @test vndBack == vnd

    # Delete it
    @test deleteState!(fg, :a, :parametric) == 1
    # Update add it
    @test mergeState!(fg, :a, vnd) == 1

    # Bulk copy update x0
    @test DFG.copytoState!(fg, v1.label, :default, getState(fg, v1.label, :default)) == 1

    @test DFG.mergeStates!(fg, Vector{Pair{Symbol, State}}([:a => vnd])) == 1
    @test DFG.mergeStates!(fg, [:a => vnd]) == 1
    @test DFG.mergeStates!(fg, :a, [vnd]) == 1
    altVnd = vnd |> deepcopy
    keepVnd = getState(getVariable(fg, :a), :parametric) |> deepcopy

    # Delete parametric from v1
    @test deleteState!(fg, :a, :parametric) == 1

    @test_throws LabelNotFoundError getState(fg, :a, :parametric)

    #FIXME copied from lower
    @test getState(v1, :default) === v1.states[:default]

    # Add new VND of type ContinuousScalar to :x0
    # Could also do State(ContinuousScalar())

    vnd = State{TestVariableType1}(; solveKey = :parametric)
    # vnd.val[1] = [0.0;]
    # vnd.bw[1] = [1.0;]

    addState!(fg, :a, vnd)
    @test setdiff(listStates(fg, :a), [:default, :parametric]) == []
    # Get the data back - note that this is a reference to above.
    vndBack = getState(fg, :a, :parametric)
    @test vndBack == vnd
    # Delete it
    @test deleteState!(fg, :a, :parametric) == 1
    # Update add it
    mergeState!(fg, :a, vnd)
    # Update update it
    mergeState!(fg, :a, vnd)
    # Delete parametric from v1
    deleteState!(fg, :a, :parametric)

    return nothing

    #TODO solverDataDict() not deprecated
    # @test refStates(newvar) == refStates(v1)

    # @test @test_deprecated mergeUpdateVariableSolverData!(fg, newvar)

end

function smallDataTestBlock!(fg)
    @test listMetadata(fg, :a) == Symbol[:small]
    @test listMetadata(fg, :b) == Symbol[]
    @test small = getMetadata(fg, :a, :small) == "data"

    @test addMetadata!(fg, :a, :a => 5) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :b => 10.0) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :c => true) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :d => "yes") == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :e => [1, 2, 3]) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :f => [1.4, 2.5, 3.6]) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :g => ["yes", "maybe"]) == getVariable(fg, :a).smallData
    @test addMetadata!(fg, :a, :h => [true, false]) == getVariable(fg, :a).smallData

    @test_throws LabelExistsError addMetadata!(fg, :a, :a => 3)
    @test updateMetadata!(fg, :a, :a => 3) == getVariable(fg, :a).smallData

    @test_throws MethodError addMetadata!(fg, :a, :no => 0x01)
    @test_throws MethodError addMetadata!(fg, :a, :no => 1.0f0)
    @test_throws MethodError addMetadata!(fg, :a, :no => Nanosecond(3))
    @test_throws MethodError addMetadata!(fg, :a, :no => [0x01])
    @test_throws MethodError addMetadata!(fg, :a, :no => [1.0f0])
    @test_throws MethodError addMetadata!(fg, :a, :no => [Nanosecond(3)])

    @test deleteMetadata!(fg, :a, :a) == 1
    @test updateMetadata!(fg, :a, :a => 3) == getVariable(fg, :a).smallData
    @test length(listMetadata(fg, :a)) == 9
    emptyMetadata!(fg, :a)
    @test length(listMetadata(fg, :a)) == 0
end

function DataEntriesTestBlock!(fg, v2)
    # "Data Entries"

    # getBlobentry
    # addBlobentry
    # updateBlobentry
    # deleteBlobentry
    # getBlobentries
    # listBlobentries
    # emptyDataEntries
    # mergeDataEntries
    storeEntry = Blobentry(; blobid = uuid4(), label = :a, blobstore = :b)
    @test getLabel(storeEntry) == storeEntry.label
    @test getTimestamp(storeEntry) == storeEntry.timestamp

    # oid = zeros(UInt8,12); oid[12] = 0x01
    # de1 = MongodbDataEntry(:key1, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de1 = Blobentry(; blobid = uuid4(), label = :key1, blobstore = :b)

    # oid = zeros(UInt8,12); oid[12] = 0x02
    # de2 = MongodbDataEntry(:key2, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de2 = Blobentry(; blobid = uuid4(), label = :key2, blobstore = :b)

    # oid = zeros(UInt8,12); oid[12] = 0x03
    # de2_update = MongodbDataEntry(:key2, uuid4(), NTuple{12,UInt8}(oid), "", now(localzone()))
    de2_update =
        Blobentry(; blobid = uuid4(), label = :key2, blobstore = :b, description = "Yay")

    #add
    v1 = getVariable(fg, :a)
    @test addBlobentry!(v1, de1) == de1
    @test addBlobentry!(fg, :a, de2) == de2
    @test_throws LabelExistsError addBlobentry!(v1, de1)
    @test de2 in getBlobentries(v1)

    #get
    @test deepcopy(de1) == getBlobentry(v1, :key1)
    @test deepcopy(de2) == getBlobentry(fg, :a, :key2)
    @test_throws LabelNotFoundError getBlobentry(v2, :key1)
    @test_throws LabelNotFoundError getBlobentry(fg, :b, :key1)

    #update
    @test mergeBlobentry!(fg, :a, de2_update) == 1
    @test deepcopy(de2_update) == getBlobentry(fg, :a, :key2)
    @test mergeBlobentry!(fg, :b, de2_update) == 1

    #list
    entries = getBlobentries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e -> e.label, entries), [:key1, :key2])
    @test length(getBlobentries(fg, :b)) == 1

    @test issetequal(listBlobentries(fg, :a), [:key1, :key2])
    @test listBlobentries(fg, :b) == Symbol[:key2]

    #delete
    @test deleteBlobentry!(v1, de1) == 1
    @test listBlobentries(v1) == Symbol[:key2]
    #delete from dfg
    @test deleteBlobentry!(fg, :a, :key2) == 1
    @test listBlobentries(v1) == Symbol[]
    deleteBlobentry!(fg, :b, :key2)

    # packed variable data entries
    pacv = packVariable(v1)
    @test addBlobentry!(pacv, de1) == de1
    @test hasBlobentry(pacv, :key1)
    @test deepcopy(de1) == getBlobentry(pacv, :key1)
    @test getBlobentries(pacv) == [deepcopy(de1)]
    @test issetequal(listBlobentries(pacv), [:key1])
    # @test deleteBlobentry!(pacv, de1) == de1

end

function blobsStoresTestBlock!(fg)
    de1 = Blobentry(;
        blobid = uuid4(),
        label = :label1,
        blobstore = :store1,
        crchash = 0xAAAA,
        origin = "origin1",
        description = "description1",
        mimetype = "mimetype1",
    )
    de2 = Blobentry(;
        blobid = uuid4(),
        label = :label2,
        blobstore = :store2,
        crchash = 0xFFFF,
        origin = "origin2",
        description = "description2",
        mimetype = "mimetype2",
        timestamp = DFG.TimeDateZone("2020-08-12T12:00:00.000Z"),
    )
    de2_update = Blobentry(;
        blobid = uuid4(),
        label = :label2,
        blobstore = :store2,
        crchash = 0x0123,
        origin = "origin2",
        description = "description2",
        mimetype = "mimetype2",
        timestamp = DFG.TimeDateZone("2020-08-12T12:00:00.000Z"),
    )
    @test getLabel(de1) == de1.label
    @test getTimestamp(de1) == de1.timestamp

    #add
    var1 = getVariable(fg, :a)
    var2 = getVariable(fg, :b)
    @test addBlobentry!(var1, de1) == de1
    mergeVariable!(fg, var1)
    @test addBlobentry!(fg, :a, de2) == de2
    @test_throws LabelExistsError addBlobentry!(var1, de1)
    @test de2 in getBlobentries(fg, var1.label)

    #get
    @test deepcopy(de1) == getBlobentry(var1, :label1)
    @test deepcopy(de2) == getBlobentry(fg, :a, :label2)
    @test_throws LabelNotFoundError getBlobentry(var2, :label1)
    @test_throws LabelNotFoundError getBlobentry(fg, :b, :label1)

    #update
    @test mergeBlobentry!(fg, :a, de2_update) == 1
    @test deepcopy(de2_update) == getBlobentry(fg, :a, :label2)
    @test mergeBlobentry!(fg, :b, de2_update) == 1

    #list
    entries = getBlobentries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e -> e.label, entries), [:label1, :label2])
    @test length(getBlobentries(fg, :b)) == 1

    @test issetequal(listBlobentries(fg, :a), [:label1, :label2])
    @test listBlobentries(fg, :b) == Symbol[:label2]

    # test collecting blobentries with filters
    gathered = DFG.gatherBlobentries(
        fg;
        variableLabelFilter = contains("a"),
        labelFilter = contains("1"),
    )
    @test first(gathered[1]) == :a
    @test last(gathered[1])[1] == getBlobentry(fg, :a, :label1)

    #delete
    @test deleteBlobentry!(fg, var1.label, de1.label) == 1
    @test listBlobentries(fg, var1.label) == Symbol[:label2]
    #delete from dfg
    @test deleteBlobentry!(fg, :a, :label2) == 1
    var1 = getVariable(fg, :a)
    @test listBlobentries(var1) == Symbol[]

    # Blobstore functions
    fs = FolderStore("/tmp/$(string(uuid4())[1:8])")
    # Adding
    addBlobstore!(fg, fs)
    # Listing
    @test listBlobstores(fg) == [fs.label]
    # Getting
    @test getBlobstore(fg, fs.label) == fs
    @test_throws LabelNotFoundError getBlobstore(fg, :notfound)
    # Deleting
    @test deleteBlobstore!(fg, fs.label) == 1
    # Updating
    updateBlobstore!(fg, fs)
    @test listBlobstores(fg) == [fs.label]
    # Emptying
    emptyBlobstore!(fg)
    @test listBlobstores(fg) == []
    # Add it back
    addBlobstore!(fg, fs)

    # Blob 
    testData = rand(UInt8, 50)
    blobid = addBlob!(fs, testData)
    @test blobid isa UUID
    @test hasBlob(fs, blobid)
    @test_throws DFG.IdExistsError addBlob!(fs, blobid, testData)
    @test getBlob(fs, blobid) == testData
    @test_throws DFG.IdNotFoundError getBlob(fs, uuid4())
    @test_throws DFG.IdNotFoundError deleteBlob!(fs, uuid4())
    @test deleteBlob!(fs, blobid) == 1
    @test_throws DFG.IdNotFoundError getBlob(fs, blobid)

    # Blob Wrappers
    # on Variable
    newentry = DFG.saveBlob_Variable!(fg, :a, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveBlob_Variable!(fg, :a, testData, :testing)
    @test :testing in listBlobentries(fg, :a)
    be, blob = DFG.loadBlob_Variable(fg, :a, :testing)
    @test newentry == be
    @test blob == testData
    @test DFG.deleteBlob_Variable!(fg, :a, :testing) == 2
    @test_throws DFG.LabelNotFoundError DFG.loadBlob_Variable(fg, :a, :testing)

    # on Graph
    newentry = DFG.saveBlob_Graph!(fg, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveBlob_Graph!(fg, testData, :testing, fs.label)
    @test :testing in listGraphBlobentries(fg)
    be, blob = DFG.loadBlob_Graph(fg, :testing)
    @test newentry == be
    @test blob == testData
    @test DFG.deleteBlob_Graph!(fg, :testing) == 2
    @test_throws DFG.LabelNotFoundError DFG.loadBlob_Graph(fg, :testing)

    # on Agent
    newentry = DFG.saveBlob_Agent!(fg, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveBlob_Agent!(fg, testData, :testing, fs.label)
    @test :testing in listAgentBlobentries(fg)
    be, blob = DFG.loadBlob_Agent(fg, :testing)
    @test newentry == be
    @test blob == testData
    @test DFG.deleteBlob_Agent!(fg, :testing) == 2
    @test_throws DFG.LabelNotFoundError DFG.loadBlob_Agent(fg, :testing)
    return nothing
end

function testGroup!(fg, v1, v2, f0, f1)
    # "TODO Sorteer groep"

    @testset "Listing Variables and Factors with filters" begin
        @test issetequal([:a, :b], listVariables(fg))
        @test issetequal([:af1, :abf1], listFactors(fg))

        # @test @test_deprecated getVariableIds(fg) == listVariables(fg)
        # @test @test_deprecated getFactorIds(fg) == listFactors(fg)

        @test getObservation(f1) === f1.observation
        @test getObservation(fg, :abf1) === f1.observation

        @test isPrior(fg, :af1) # if f1 is prior
        @test lsfPriors(fg) == [:af1]

        @test issetequal(
            [TestFunctorInferenceType1{TestBelief}, TestAbstractPrior{TestBelief}],
            DFG.lsfTypes(fg),
        )

        facTypesDict = DFG.lsfTypesDict(fg)
        @test issetequal(collect(keys(facTypesDict)), DFG.lsfTypes(fg))
        @test issetequal(facTypesDict[TestFunctorInferenceType1{TestBelief}], [:abf1])
        @test issetequal(facTypesDict[TestAbstractPrior{TestBelief}], [:af1])

        @test ls(fg, TestFunctorInferenceType1) == [:abf1]
        @test lsf(fg, TestAbstractPrior) == [:af1]

        @test getVariableType(v1) == TestVariableType1()
        @test getVariableType(fg, :a) == TestVariableType1()

        @test getVariableType(v1) == TestVariableType1()
        @test getVariableType(fg, :a) == TestVariableType1()

        @test ls2(fg, :a) == [:b]

        @test issetequal([TestVariableType1, TestVariableType2], DFG.lsTypes(fg))

        varTypesDict = DFG.lsTypesDict(fg)
        @test issetequal(collect(keys(varTypesDict)), DFG.lsTypes(fg))
        @test issetequal(varTypesDict[TestVariableType1], [:a])
        @test issetequal(varTypesDict[TestVariableType2], [:b])

        @test ls(fg, TestVariableType1) == [:a]

        # FIXME return: Symbol[:b, :b] == Symbol[:b]
        varNearTs = findVariableNearTimestamp(fg, now())
        @test_skip varNearTs[1][1] == [:b]

        ## SORT copied from CRUD
        @test all(getVariables(fg, r"a") .== [getVariable(fg, v1.label)])
        @test all(getVariables(fg; solvable = 1) .== [getVariable(fg, v2.label)])
        @test getVariables(fg, r"a"; solvable = 1) == []
        @test getVariables(fg; tags = [:LANDMARK])[1] == getVariable(fg, v2.label)

        @test getFactors(fg, r"nope") == []
        @test issetequal(getLabel.(getFactors(fg; solvable = 1)), [:af1, :abf1])
        @test getFactors(fg; solvable = 2) == []
        @test getFactors(fg; tags = [:tag1])[1] == f1
        @test getFactors(fg; tags = [:PRIOR])[1] == f0
        ##/SORT

        # Additional testing for https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/201
        # list solvable
        @test symdiff([:a, :b], listVariables(fg; solvable = 0)) == []
        @test listVariables(fg; solvable = 1) == [:b]

        @test issetequal(listFactors(fg; solvable = 1), [:af1, :abf1])
        @test issetequal(listFactors(fg; solvable = 0), [:af1, :abf1])
        @test all([f in [f0, f1] for f in getFactors(fg; solvable = 1)])

        @test lsf(fg, :b) == [f1.label]

        # Tags
        @test ls(fg; tags = [:POSE]) == []
        @test issetequal(ls(fg; tags = [:POSE, :LANDMARK]), ls(fg; tags = [:VARIABLE]))

        @test lsf(fg; tags = [:NONE]) == []
        @test lsf(fg; tags = [:PRIOR]) == [:af1]

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
        unsorted = [:x1_3; :x1_6; :l1; :april1] #this will not work for :x1x2f1
        @test sort([:x1x2f1, :x1l1f1]; lt = natural_lt) == [:x1l1f1, :x1x2f1]

        # NOTE Some of what is possible with sort and the wrappers
        l = [
            :a1,
            :X1,
            :b1c2,
            :x2_2,
            :c,
            :x1,
            :x10,
            :x1_1,
            :x10_10,
            :a,
            :x2_1,
            :xy3,
            :l1,
            :x1_2,
            :x1l1f1,
            Symbol("1a1"),
            :x1x2f1,
        ]
        @test sortDFG(l) == [
            Symbol("1a1"),
            :X1,
            :a,
            :a1,
            :b1c2,
            :c,
            :l1,
            :x1,
            :x1_1,
            :x1_2,
            :x1l1f1,
            :x1x2f1,
            :x2_1,
            :x2_2,
            :x10,
            :x10_10,
            :xy3,
        ]
        @test sort(l; lt = natural_lt) == [
            Symbol("1a1"),
            :X1,
            :a,
            :a1,
            :b1c2,
            :c,
            :l1,
            :x1,
            :x1_1,
            :x1_2,
            :x1l1f1,
            :x1x2f1,
            :x2_1,
            :x2_2,
            :x10,
            :x10_10,
            :xy3,
        ]

        @test getLabel.(sortDFG(getVariables(fg); lt = natural_lt, by = getLabel)) ==
              [:a, :b]
        @test getLabel.(sort(getVariables(fg); lt = natural_lt, by = getLabel)) == [:a, :b]

        @test getLabel.(sortDFG(getFactors(fg))) == [:abf1, :af1]
        @test getLabel.(sort(getFactors(fg); by = getTimestamp)) == [:abf1, :af1]

        @test getLabel.(
            sortDFG(vcat(getVariables(fg), getFactors(fg)); lt = natural_lt, by = getLabel),
        ) == [:a, :abf1, :af1, :b]
    end

    @testset "Some more helpers to sort out" begin
        # TODO
        #solver data is initialized
        @test !isInitialized(fg, :a)
        @test !isInitialized(v2)
        @test_throws LabelNotFoundError isInitialized(v2, :second)

        # solvables
        @test getSolvable(v1) == 0
        @test getSolvable(v2) == 1
        @test getSolvable(f1) == 1

        @test !isSolvable(v1)
        @test isSolvable(v2)

        @test setSolvable!(v1, 1) == 1
        @test getSolvable(v1) == 1
        @test setSolvable!(fg, v1.label, 0) == 0
        @test getSolvable(v1) == 0
        @test setSolvable!(f1, 1) == 1
        @test getSolvable(fg, f1.label) == 1
        @test setSolvable!(fg, f1.label, 0) == 0
        @test getSolvable(fg, f1.label) == 0

        @test getSolvable(f1) == 0
        setSolvable!(f1, 1)

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

function AdjacencyMatricesTestBlock(fg)
    # Normal
    #deprecated
    # @test_throws ErrorException getAdjacencyMatrix(fg)
    adjMat = DistributedFactorGraphs.getAdjacencyMatrixSymbols(fg)
    @test size(adjMat) == (2, 4)
    @test issetequal(adjMat[1, :], [nothing, :a, :b, :orphan])
    @test issetequal(adjMat[2, :], [:abf1, :abf1, :abf1, nothing])
    #
    #sparse
    adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg)
    @test size(adjMat) == (1, 3)

    # Checking the elements of adjacency, its not sorted so need indexing function
    indexOf = (arr, el1) -> findfirst(el2 -> el2 == el1, arr)
    @test adjMat[1, indexOf(v_ll, :orphan)] == 0
    @test adjMat[1, indexOf(v_ll, :a)] == 1
    @test adjMat[1, indexOf(v_ll, :b)] == 1
    @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
    @test symdiff(f_ll, [:abf1]) == Symbol[]

    # Only do solvable tests on VariableCompute
    if isa(getVariable(fg, :a), VariableCompute)
        # Filtered - REF DFG #201
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg; solvable = 0)
        @test size(adjMat) == (1, 3)
        @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
        @test symdiff(f_ll, [:abf1]) == Symbol[]

        # sparse
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg; solvable = 1)
        @test size(adjMat) == (1, 2)
        @test issetequal(v_ll, [:a, :b])
        @test f_ll == [:abf1]
    end
end

# Now make a complex graph for connectivity tests
function connectivityTestGraph(
    ::Type{T};
    VARTYPE = VariableCompute,
    FACTYPE = FactorCompute,
) where {T <: AbstractDFG}#InMemoryDFGTypes
    #settings
    numNodesType1 = 5
    numNodesType2 = 5

    dfg = T(; graphLabel = :testGraph)

    vars = vcat(
        map(n -> VARTYPE(Symbol("x$n"), State{TestVariableType1}()), 1:numNodesType1),
        map(
            n -> VARTYPE(Symbol("x$(numNodesType1+n)"), State{TestVariableType2}()),
            1:numNodesType2,
        ),
    )

    addVariables!(dfg, vars)

    if FACTYPE == FactorCompute
        #change ready and solveInProgress for x7,x8 for improved tests on x7x8f1
        #NOTE because defaults changed
        setSolvable!(dfg, :x8, 0)
        setSolvable!(dfg, :x9, 0)

        facstate = DFG.FactorState(;
            eliminated = true,
            potentialused = true,
            multihypo = Float64[],
            certainhypo = Int[],
            inflation = 1.0,
        )
        f_tags = Set([:FACTOR])

        facs = map(
            n -> addFactor!(
                dfg,
                FactorCompute(
                    Symbol("x$(n)x$(n+1)f1"),
                    [vars[n].label, vars[n + 1].label],
                    TestFunctorInferenceType1(),
                    facstate;
                    tags = deepcopy(f_tags),
                ),
            ),
            1:(length(vars) - 1),
        )
        setSolvable!(dfg, :x7x8f1, 0)

    else
        facs = map(
            n -> addFactor!(
                dfg,
                FACTYPE(Symbol("x$(n)x$(n+1)f1"), [vars[n].label, vars[n + 1].label]),
            ),
            1:(length(vars) - 1),
        )
    end

    return (dfg = dfg, variables = vars, factors = facs)
end

# dfg, verts, facs = connectivityTestGraph(testDFGAPI)

function GettingNeighbors(testDFGAPI; VARTYPE = VariableCompute, FACTYPE = FactorCompute)
    # "Getting Neighbors"
    dfg, verts, facs =
        connectivityTestGraph(testDFGAPI; VARTYPE = VARTYPE, FACTYPE = FACTYPE)
    # Trivial test to validate that intersect([], []) returns order of first parameter
    @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
    # Get neighbors tests
    @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = listNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test neighbors == [:x1, :x2]
    # Testing aliases
    @test listNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test listNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

    # Solvable
    #TODO if not a GraphsDFG with and summary or skeleton
    if VARTYPE == VariableCompute
        @test listNeighbors(dfg, :x5; solvable = 2) == Symbol[]
        @test issetequal(listNeighbors(dfg, :x5; solvable = 0), [:x4x5f1, :x5x6f1])
        @test issetequal(listNeighbors(dfg, :x5), [:x4x5f1, :x5x6f1])
        @test listNeighbors(dfg, :x7x8f1; solvable = 0) == [:x7, :x8]
        @test listNeighbors(dfg, :x7x8f1; solvable = 1) == [:x7]
        @test listNeighbors(dfg, verts[1]; solvable = 0) == [:x1x2f1]
        @test listNeighbors(dfg, verts[1]; solvable = 2) == Symbol[]
        @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
    end
end

#TODO confirm these tests are covered somewhere then delete
# function  GettingSubgraphs(testDFGAPI; VARTYPE=VariableCompute, FACTYPE=FactorCompute)
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
#     if VARTYPE == VariableCompute
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
#             @test fact.variableorder == getFactor(dfg, fact.label).variableorder
#         end
#     end
#
# end

function BuildingSubgraphs(testDFGAPI; VARTYPE = VariableCompute, FACTYPE = FactorCompute)

    # "Getting Subgraphs"
    dfg, verts, facs =
        connectivityTestGraph(testDFGAPI; VARTYPE = VARTYPE, FACTYPE = FACTYPE)
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
    if VARTYPE == VariableCompute
        dfgSubgraph = buildSubgraph(testDFGAPI, dfg, [:x8], 2; solvable = 1)
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
            @test fact.variableorder == getFactor(dfg, fact.label).variableorder
        end
    end

    #TODO buildSubgraph default constructors for skeleton and summary
    if VARTYPE == VariableCompute
        dfgSubgraph = buildSubgraph(dfg, [:x1, :x2, :x1x2f1])
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

        dfgSubgraph = buildSubgraph(dfg, [:x2, :x3], 2)
        @test issetequal(
            [:x2, :x3, :x1, :x4, :x3x4f1, :x1x2f1, :x2x3f1],
            [ls(dfgSubgraph)..., lsf(dfgSubgraph)...],
        )

        dfgSubgraph = buildSubgraph(dfg, [:x1x2f1], 1)
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
    end
end

#TODO Summaries and Summary Graphs
function Summaries(testDFGAPI)
    # "Summaries and Summary Graphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI)
    #TODO for summary
    # if VARTYPE == VariableSummary
    # factorFields = fieldnames(FACTYPE)
    # variableFields = fieldnames(VARTYPE)
    factorFields = fieldnames(FactorSummary)
    variableFields = fieldnames(VariableSummary)

    summaryGraph = getSummaryGraph(dfg)
    @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
    @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
    # Check all fields are equal for all variables
    for v in ls(summaryGraph)
        for field in variableFields
            if field != :variableTypeName
                @test getproperty(getVariable(dfg, v), field) ==
                      getproperty(getVariable(summaryGraph, v), field)
            else
                # Special case to check the symbol variableType is equal to the full variableType.
                @test Symbol(typeof(getVariableType(getVariable(dfg, v)))) ==
                      getVariableTypeName(getVariable(summaryGraph, v))
                @test getVariableType(getVariable(dfg, v)) ==
                      getVariableType(getVariable(summaryGraph, v))
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            @test getproperty(getFactor(dfg, f), field) ==
                  getproperty(getFactor(summaryGraph, f), field)
        end
    end
end

function ProducingDotFiles(
    testDFGAPI,
    v1 = nothing,
    v2 = nothing,
    f1 = nothing;
    VARTYPE = VariableCompute,
    FACTYPE = FactorCompute,
)
    # "Producing Dot Files"
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI(; graphLabel = :testGraph)

    if v1 === nothing
        v1 = VARTYPE(:a, State{TestVariableType1}())
    end
    if v2 === nothing
        v2 = VARTYPE(:b, State{TestVariableType1}())
    end
    if f1 === nothing
        if (FACTYPE == FactorCompute)
            f1 = FactorCompute(:abf1, [:a, :b], TestFunctorInferenceType1())
        else
            f1 = FACTYPE(:abf1, [:a, :b])
        end
    end

    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    # FIXME, fix deprecation
    # ┌ Warning: addFactor!(dfg, variables, factor) is deprecated, use addFactor!(dfg, factor)
    # │   caller = ProducingDotFiles(testDFGAPI::Type{GraphsDFG}, v1::Nothing, v2::Nothing, f1::Nothing; VARTYPE::Type{VariableCompute}, FACTYPE::Type{FactorCompute}) at testBlocks.jl:1440
    # └ @ Main ~/.julia/dev/DistributedFactorGraphs/test/testBlocks.jl:1440
    addFactor!(dotdfg, f1)
    #NOTE hardcoded toDot will have different results so test Graphs seperately
    if testDFGAPI <: GraphsDFG || testDFGAPI <: GraphsDFG
        todotstr = DFG.toDot(dotdfg)
        todota =
            todotstr ==
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\na -- abf1\nb -- abf1\n}\n"
        todotb =
            todotstr ==
            "graph G {\na [color=red, shape=ellipse];\nb [color=red, shape=ellipse];\nabf1 [color=blue, shape=box, fontsize=8, fixedsize=false, height=0.1, width=0.1];\nb -- abf1\na -- abf1\n}\n"
        @test (todota || todotb)
    else
        @test DFG.toDot(dotdfg) ==
              "graph graphname {\n2 [\"label\"=\"b\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n2 -- 3\n3 [\"label\"=\"abf1\",\"shape\"=\"box\",\"fillcolor\"=\"blue\",\"color\"=\"blue\"]\n1 [\"label\"=\"a\",\"shape\"=\"ellipse\",\"fillcolor\"=\"red\",\"color\"=\"red\"]\n1 -- 3\n}\n"
    end
    @test DFG.toDotFile(dotdfg, "something.dot") === nothing
    return Base.rm("something.dot")
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
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, vlbls; verbose = false)
    @test issetequal(ls(dcdfg_part), vlbls)
    @test issetequal(lsf(dcdfg_part), [:x2x3f1])

    # not found errors
    @test_throws LabelNotFoundError deepcopyGraph(GraphsDFG, dfg, [:x1, :a])
    @test_throws LabelNotFoundError deepcopyGraph(GraphsDFG, dfg, [:x1], [:f1])

    # already exists errors
    dcdfg_part = deepcopyGraph(GraphsDFG, dfg, [:x1, :x2, :x3], [:x1x2f1, :x2x3f1])
    @test_throws LabelExistsError deepcopyGraph!(
        dcdfg_part,
        dfg,
        [:x4, :x2, :x3],
        [:x1x2f1, :x2x3f1],
    )
    @test_throws LabelNotFoundError deepcopyGraph!(dcdfg_part, dfg, [:x1x2f1])

    # same but overwrite destination
    deepcopyGraph!(
        dcdfg_part,
        dfg,
        [:x4, :x2, :x3],
        [:x1x2f1, :x2x3f1];
        overwriteDest = true,
    )

    deepcopyGraph!(dcdfg_part, dfg, Symbol[], [:x1x2f1]; overwriteDest = true)

    vlbls1 = [:x1, :x2, :x3]
    vlbls2 = [:x4, :x5, :x6]
    dcdfg_part1 = deepcopyGraph(GraphsDFG, dfg, vlbls1)
    dcdfg_part2 = deepcopyGraph(GraphsDFG, dfg, vlbls2)

    mergedGraph = testDFGAPI(; graphLabel = :testGraph)
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
        vnd = getState(v4, :default)
        # set everything
        # vnd.BayesNetVertID = :outid
        # push!(vnd.BayesNetOutVertIDs, :id)
        # vnd.bw[1] = [1.0;]
        # vnd.dontmargin = true
        # vnd.eliminated = true
        vnd.observability .= Float64[1.5;]
        vnd.initialized = true
        vnd.marginalized = true
        push!(vnd.separator, :sep)
        vnd.solves = 2
        # vnd.val[1] = [2.0;]
        #update
        mergeVariable!(dfg, v4)

        f45 = getFactor(dfg, :x4x5f1)
        fsd = getFactorState(f45)
        # set some factor solver data
        push!(fsd.certainhypo, 2)
        fsd.eliminated = true
        push!(fsd.multihypo, 4.0)
        fsd.nullhypo = 5.0
        fsd.potentialused = true
        #update factor
        mergeFactor!(dfg, f45)

        # Save and load the graph to test.
        saveDFG(dfg, filename)

        retDFG = testDFGAPI(; graphLabel = :testGraph)
        @info "Going to load $filename"

        @test_throws AssertionError loadDFG!(retDFG, "badfilename")

        loadDFG!(retDFG, filename)

        @test issetequal(ls(dfg), ls(retDFG))
        @test issetequal(lsf(dfg), lsf(retDFG))
        for var in ls(dfg)
            @test getVariable(dfg, var) == getVariable(retDFG, var)
        end
        for fact in lsf(dfg)
            @test getFactor(dfg, fact) == getFactor(retDFG, fact)
        end

        # @test length(getBlobentries(getVariable(retDFG, :x1))) == 1
        # @test typeof(getBlobentry(getVariable(retDFG, :x1),:testing)) == GeneralDataEntry
        # @test length(getBlobentries(getVariable(retDFG, :x2))) == 1
        # @test typeof(getBlobentry(getVariable(retDFG, :x2),:testing2)) == FileDataEntry
    end
end
