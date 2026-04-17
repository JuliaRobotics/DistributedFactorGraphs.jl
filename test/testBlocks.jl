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

# struct PackedNothingDistribution <: AbstractPackedBelief
#     _type::Symbol
#     function PackedNothingDistribution(; _type::String = "PackedNothingDistribution")
#         return new(Symbol(_type))
#     end
# end

# DFG.packDistribution(::Nothing) = PackedNothingDistribution()
# DFG.unpackDistribution(::PackedNothingDistribution) = nothing

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
    @test isempty(listAgents(fg))
    @test getGraphLabel(fg) == :workspace

    # Test the validation of the robot, session, and user IDs.
    notAllowedList = [Symbol("!notValid"), Symbol("1notValid"), :_notValid]

    for s in notAllowedList
        @test_throws ArgumentError T(solverParams = solparams, graphLabel = s)
    end

    des = "description for runtest"
    rId = :testRobotId
    sId = :testSessionId
    rd = DFG.Bloblets(:rd => DFG.Bloblet(:rd, "rdEntry"))
    sd = DFG.Bloblets(:sd => DFG.Bloblet(:sd, "sdEntry"))
    fg = T(;
        graphDescription = des,
        graphLabel = sId,
        graphBloblets = sd,
        solverParams = solparams,
    )
    addAgent!(fg, Agent(; label = rId, bloblets = rd))

    # accesssors
    # get
    @test getDescription(fg) == des
    @test getGraphLabel(fg) == sId

    @test getSolverParams(fg) == NoSolverParams()

    #FIXME test bloblets
    @test DFG.getAgentBloblet(fg, rId, :rd) == rd[:rd]
    @test DFG.getGraphBloblet(fg, :sd) == sd[:sd]

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
    display(fg)
    return fg
end

# User, Robot, Session Data
function GraphAgentBloblets!(fg::AbstractDFG)
    # First add an agent to test with
    agentlabel = :testAgent
    addAgent!(fg, Agent(; label = agentlabel))

    # Agent-level bloblets
    agent_blob = Bloblet(:agent_blob, "ready")
    @test addAgentBloblet!(fg, agentlabel, agent_blob) == agent_blob
    @test getAgentBloblet(fg, agentlabel, agent_blob.label) == agent_blob
    updated_agent_blob = Bloblet(agent_blob.label, "updated")
    @test mergeAgentBloblet!(fg, agentlabel, updated_agent_blob) == 1
    @test getAgentBloblet(fg, agentlabel, agent_blob.label) == updated_agent_blob
    @test agent_blob.label in listAgentBloblets(fg, agentlabel)
    @test deleteAgentBloblet!(fg, agentlabel, agent_blob.label) == 1
    @test_throws DFG.LabelNotFoundError getAgentBloblet(fg, agentlabel, agent_blob.label)
    @test deleteAgentBloblet!(fg, agentlabel, agent_blob.label) == 0

    deleteAgent!(fg, agentlabel)

    # Graph-level bloblets
    graph_blob = Bloblet(:graph_blob, "running")
    @test addGraphBloblet!(fg, graph_blob) == graph_blob
    @test getGraphBloblet(fg, graph_blob.label) == graph_blob
    updated_graph_blob = Bloblet(graph_blob.label, "complete")
    @test mergeGraphBloblet!(fg, updated_graph_blob) == 1
    @test getGraphBloblet(fg, graph_blob.label) == updated_graph_blob
    @test graph_blob.label in listGraphBloblets(fg)
    @test deleteGraphBloblet!(fg, graph_blob.label) == 1
    @test_throws DFG.LabelNotFoundError getGraphBloblet(fg, graph_blob.label)
    @test deleteGraphBloblet!(fg, graph_blob.label) == 0
end

# User, Robot, Session Data Blob Entries
function GraphAgentBlobentries!(fg::AbstractDFG)
    be = Blobentry(:key1, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :b)

    # First add an agent to test with
    agentlabel = :testBlobentryAgent
    addAgent!(fg, Agent(; label = agentlabel))

    # Agent Blob Entries
    ae = addAgentBlobentry!(fg, agentlabel, be)
    @test ae == be
    @test_throws DFG.LabelExistsError addAgentBlobentry!(fg, agentlabel, be)
    ge = getAgentBlobentry(fg, agentlabel, :key1)
    @test ge == be
    @test hasAgentBlobentry(fg, agentlabel, :key1)
    me = mergeAgentBlobentry!(fg, agentlabel, be)
    @test me == 1
    de = deleteAgentBlobentry!(fg, agentlabel, :key1)
    @test de == 1
    @test hasAgentBlobentry(fg, agentlabel, :key1) == false
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, agentlabel, :key1)
    @test deleteAgentBlobentry!(fg, agentlabel, :key1) == 0
    @test addAgentBlobentries!(fg, agentlabel, [be]) == [be]
    @test deleteAgentBlobentries!(fg, agentlabel, [:key1]) == 1
    @test mergeAgentBlobentries!(fg, agentlabel, [be]) == 1
    @test deleteAgentBlobentries!(fg, agentlabel, [:key1]) == 1

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
    @test deleteGraphBlobentry!(fg, :key1) == 0
    @test addGraphBlobentries!(fg, [be]) == [be]
    @test deleteGraphBlobentries!(fg, [:key1]) == 1
    @test mergeGraphBlobentries!(fg, [be]) == 1
    @test deleteGraphBlobentries!(fg, [:key1]) == 1

    be2 = Blobentry(:key2, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :b)

    bes = [be, be2]

    ae = addAgentBlobentries!(fg, agentlabel, bes)
    @test length(ae) == 2
    @test_throws DFG.LabelExistsError addAgentBlobentries!(fg, agentlabel, bes)
    besr = getAgentBlobentries(fg, agentlabel)
    @test length(besr) == 2
    me = mergeAgentBlobentries!(fg, agentlabel, bes)
    @test me == 2
    de = deleteAgentBlobentries!(fg, agentlabel, [:key1, :key2])
    @test de == 2
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, agentlabel, :key1)
    @test_throws DFG.LabelNotFoundError getAgentBlobentry(fg, agentlabel, :key2)

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
    #test some Timestamp helpers
    ts1 = DFG.Timestamp(Nanosecond(1760700359563000064), localzone())
    ts2 = DFG.Timestamp(1760700359.563000064, localzone())
    @test ts1 == ts2
    ts3 = DFG.Timestamp("2020-08-11T00:12:03.000-05:00")
    ts4 = DFG.Timestamp(Val(:rata), 63732787923.0, FixedTimeZone("UTC-05:00"))
    @test ts3 == ts4
    # Constructors
    v1 = VariableDFG(
        v1_lbl,
        TestVariableType1();
        tags = v1_tags,
        solvable = 0,
        states = OrderedDict(:default => State{TestVariableType1}(; label = :default)),
        bloblets = DFG.Bloblets(:small => DFG.Bloblet(:small, "data")),
    )
    v2 = VariableDFG(
        :b,
        State{TestVariableType2}(; label = :default);
        tags = Set([:VARIABLE, :LANDMARK]),
    )
    v3 = VariableDFG(
        :c,
        State{TestVariableType2}(; label = :default);
        timestamp = DFG.Timestamp("2020-08-11T00:12:03.000-05:00"),
    )

    vorphan = VariableDFG(
        :orphan,
        TestVariableType1();
        tags = v1_tags,
        solvable = 0,
        states = OrderedDict(:default => State{TestVariableType1}(; label = :default)),
    )

    # v1.states[:default].val[1] = [0.0;]
    # v1.states[:default].bw[1] = [1.0;]
    # v2.states[:default].val[1] = [0.0;0.0]
    # v2.states[:default].bw[1] = [1.0;1.0]
    # v3.states[:default].val[1] = [0.0;0.0]
    # v3.states[:default].bw[1] = [1.0;1.0]

    @test getLabel(v1) == v1_lbl
    @test DFG.refTags(v1) === v1_tags

    @test getTimestamp(v1) == v1.timestamp

    @test getSolvable(v1) == 0
    @test getSolvable(v2) == 1

    # TODO direct use is not recommended, use accessors, maybe not export or deprecate
    @test DFG.refStates(v1) == v1.states

    # @test getMetadata(v1) == Dict{Symbol, MetadataTypes}()

    @test getStateKind(v1) == TestVariableType1()

    #TODO here for now, don't reccomend usage.
    testTags = [:tag1, :tag2]
    @test DFG.mergeTags!(v3, testTags) == 2
    @test DFG.mergeTags!(v3, Set(testTags)) == 2

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

    @test DFG.calcDeltatime(v1, v2) isa Real

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
    #VariableDFG solvable default to 1, but Factor to 0, is that correct
    f1_lbl = :abf1
    f1_tags = Set([:FACTOR])
    testTimestamp = now(localzone())

    obs_prior = TestAbstractPrior()

    obs = TestFunctorInferenceType1()

    f1 = FactorDFG(f1_lbl, [:a, :b], obs; tags = f1_tags, solvable = 0)

    f2 = FactorDFG(
        :bcf1,
        [:b, :c],
        TestFunctorInferenceType1();
        timestamp = ZonedDateTime("2020-08-11T00:12:03.000-05:00"),
    )

    #test IIF like constructor
    f3 = FactorDFG([:a, :b], TestFunctorInferenceType1())

    #TODO add tests for mutating vos in updateFactor and orphan related checks.
    # we should perhaps prevent an empty vos

    @test getLabel(f1) == f1_lbl
    @test DFG.refTags(f1) === f1_tags

    @test getTimestamp(f1) == f1.timestamp

    @test getSolvable(f1) == 0

    @test getObservation(f1) === f1.observation

    @test getVariableOrder(f1) == (:a, :b)

    @test setSolvable!(f1, 1) == 1

    @test typeof(getObservation(f1)) == TestFunctorInferenceType1{TestBelief}

    testTags = [:tag1, :tag2]
    @test DFG.mergeTags!(f1, testTags) == 2
    @test DFG.mergeTags!(f1, Set(testTags)) == 2

    #follow with mergeFactor!(fg, v1ts)

    #TODO Should throw method error
    # @test_throws MethodError setTimestamp!(f1, testTimestamp)
    # @test_throws ErrorException setTimestamp!(f1, testTimestamp)
    #/TODO

    @test setSolvable!(f1, 1) == 1
    @test getSolvable(f1) == 1

    # create f0 here for a later timestamp
    f0 = FactorDFG(:af1, [:a], obs_prior; tags = Set([:PRIOR]))

    @test DFG.calcDeltatime(f1, f2) isa Real
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

    fnope = FactorDFG(:broken, [:a, :nope], TestFunctorInferenceType1())
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

    if f2 isa FactorDFG
        f2_mod = FactorDFG(
            f2.label,
            (:a,),
            f2.observation,
            f2.hyper,
            f2.state;
            timestamp = f2.timestamp,
            tags = f2.tags,
            solvable = f2.solvable[],
        )
    else
        f2_mod = typeof(f2)(f2.label, (:a,))
    end

    @test_throws DFG.MergeConflictError mergeFactor!(fg, f2_mod)
    @test issetequal(lsf(fg), [:bcf1, :abf1])

    # Extra timestamp functions https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/315

    #deletions
    delvarCompare = getVariable(fg, :c)
    delfacCompare = getFactor(fg, :bcf1)
    ndel = deleteVariable!(fg, v3)
    @test ndel == 2
    @test deleteVariable!(fg, v3) == 0
    @test setdiff(ls(fg), [:a, :b]) == []

    @test addVariable!(fg, v3) === v3
    @test addFactor!(fg, f2) === f2

    @test deleteFactor!(fg, f2) == 1
    @test deleteFactor!(fg, f2) == 0
    @test lsf(fg) == [:abf1]

    delvarCompare = getVariable(fg, :c)
    delfacCompare = []
    ndel = deleteVariable!(fg, v3)
    @test ndel == 1

    @test getVariable(fg, :a) == v1

    @test addFactor!(fg, f0) == f0

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

    if f0 isa FactorDFG
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

    if getVariable(fg, ls(fg)[1]) isa VariableDFG
        @test :default in DFG.listStates(fg)
        @test :default in DFG.listStates(fg; whereLabel = contains("default") ∘ string)
        @test :default in DFG.listStates(fg)
    end

    # simple broadcast test
    if f0 isa FactorDFG
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
    v1Tags = deepcopy(DFG.refTags(v1))
    @test issetequal(v1Tags, v1_tags)
    @test issetequal(listVariableTags(fg, :a), v1Tags)
    @test mergeVariableTags!(fg, :a, [:TAG]) == 1
    @test issetequal(listVariableTags(fg, :a), v1Tags ∪ [:TAG])
    @test deleteVariableTags!(fg, :a, [:TAG]) == 1
    @test issetequal(listVariableTags(fg, :a), v1Tags)
    @test emptyTags!(getVariable(fg, :a)) == Set{Symbol}()

    v2Tags = listVariableTags(fg, :b)
    @test hasVariableTags(fg, :b, v2Tags)
    @test hasVariableTags(fg, :b, [:LANDMARK])
    @test !hasVariableTags(fg, :b, [:LANDMARK, :TAG])

    @test listNeighbors(fg, :abf1; whereTags = ⊇([:LANDMARK])) == [:b]
    @test isempty(listNeighbors(fg, :abf1; whereTags = ⊇([:LANDMARK, :TAG])))

    # Test specific type tag accessors
    @test issetequal(listVariableTags(fg, :a), listTags(getVariable(fg, :a)))
    @test issetequal(listFactorTags(fg, :abf1), listTags(getFactor(fg, :abf1)))

    # Test mergeVariableTags! and mergeFactorTags!
    @test mergeVariableTags!(fg, :a, [:NEW_VAR_TAG]) == 1
    @test :NEW_VAR_TAG ∈ listVariableTags(fg, :a)
    @test hasVariableTags(fg, :a, [:NEW_VAR_TAG])
    @test deleteVariableTags!(fg, :a, [:NEW_VAR_TAG]) == 1
    @test !hasVariableTags(fg, :a, [:NEW_VAR_TAG])

    @test mergeFactorTags!(fg, :abf1, [:NEW_FACTOR_TAG]) == 1
    @test :NEW_FACTOR_TAG ∈ listFactorTags(fg, :abf1)
    @test hasFactorTags(fg, :abf1, [:NEW_FACTOR_TAG])
    @test deleteFactorTags!(fg, :abf1, [:NEW_FACTOR_TAG]) == 1
    @test !hasFactorTags(fg, :abf1, [:NEW_FACTOR_TAG])

    @test mergeGraphTags!(fg, [:GRAPH_TAG]) == 1
    @test :GRAPH_TAG ∈ listGraphTags(fg)
    @test hasGraphTags(fg, [:GRAPH_TAG])
    @test deleteGraphTags!(fg, [:GRAPH_TAG]) == 1
    @test !hasGraphTags(fg, [:GRAPH_TAG])

    agentlabel = :testTagAgent
    addAgent!(fg, Agent(; label = agentlabel))
    @test mergeAgentTags!(fg, agentlabel, [:AGENT_TAG]) == 1
    @test :AGENT_TAG ∈ listAgentTags(fg, agentlabel)
    @test hasAgentTags(fg, agentlabel, [:AGENT_TAG])
    @test deleteAgentTags!(fg, agentlabel, [:AGENT_TAG]) == 1
    @test !hasAgentTags(fg, agentlabel, [:AGENT_TAG])

    @test listVariableTags(fg, :a) isa Vector{Symbol}
    @test listFactorTags(fg, :abf1) isa Vector{Symbol}
    @test listGraphTags(fg) isa Vector{Symbol}
    @test listAgentTags(fg, agentlabel) isa Vector{Symbol}
    deleteAgent!(fg, agentlabel)
    return nothing
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

    vnd = State{TestVariableType1}(; label = :parametric)
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

    vnd = State{TestVariableType1}(; label = :parametric)
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

    # @test refStates(newvar) == refStates(v1)

    # @test @test_deprecated mergeUpdateVariableSolverData!(fg, newvar)

end

function blobletTestBlock!(fg)
    @test listVariableBloblets(fg, :a) == Symbol[:small]
    @test listVariableBloblets(fg, :b) == Symbol[]
    @test getVariableBloblet(fg, :a, :small) == DFG.Bloblet(:small, "data")

    @test addVariableBloblet!(fg, :a, Bloblet(:a, 5)) == Bloblet(:a, 5)
    @test addVariableBloblet!(fg, :a, Bloblet(:b, 10.0)) == Bloblet(:b, 10.0)
    @test addVariableBloblet!(fg, :a, Bloblet(:c, true)) == Bloblet(:c, true)
    @test addVariableBloblet!(fg, :a, Bloblet(:d, "yes")) == Bloblet(:d, "yes")
    @test addVariableBloblet!(fg, :a, Bloblet(:e, [1, 2, 3])) == Bloblet(:e, [1, 2, 3])
    @test addVariableBloblet!(fg, :a, Bloblet(:f, [1.4, 2.5, 3.6])) ==
          Bloblet(:f, [1.4, 2.5, 3.6])
    @test addVariableBloblet!(fg, :a, Bloblet(:g, ["yes", "maybe"])) ==
          Bloblet(:g, ["yes", "maybe"])
    @test addVariableBloblet!(fg, :a, Bloblet(:h, [true, false])) ==
          Bloblet(:h, [true, false])

    @test_throws LabelExistsError addVariableBloblet!(fg, :a, Bloblet(:a, 3))
    @test mergeVariableBloblet!(fg, :a, Bloblet(:a, 3)) == 1

    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => 0x01))
    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => 1.0f0))
    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => Nanosecond(3)))
    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => [0x01]))
    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => [1.0f0]))
    @test_throws MethodError addVariableBloblet!(fg, :a, Bloblet(:no => [Nanosecond(3)]))

    @test deleteVariableBloblet!(fg, :a, :a) == 1
    @test mergeVariableBloblet!(fg, :a, Bloblet(:a, 3)) == 1
    @test length(listVariableBloblets(fg, :a)) == 9
    # emptyVariableBloblets!(fg, :a)
    # @test length(listVariableBloblets(fg, :a)) == 0

    # has bloblet
    @test hasVariableBloblet(fg, :a, :small)
    @test !hasVariableBloblet(fg, :a, :nonexistent)

    # delete non-existent returns 0
    @test deleteVariableBloblet!(fg, :a, :nonexistent) == 0

    # Bulk operations
    bulk_bloblets = [Bloblet(:bulk1, 1), Bloblet(:bulk2, 2)]
    @test addVariableBloblets!(fg, :a, bulk_bloblets) == bulk_bloblets
    @test hasVariableBloblet(fg, :a, :bulk1)
    @test hasVariableBloblet(fg, :a, :bulk2)
    @test mergeVariableBloblets!(fg, :a, [Bloblet(:bulk1, 10), Bloblet(:bulk2, 20)]) == 2
    @test deleteVariableBloblets!(fg, :a, [:bulk1, :bulk2]) == 2
    @test !hasVariableBloblet(fg, :a, :bulk1)

    # get non-existent throws
    @test_throws LabelNotFoundError getVariableBloblet(fg, :a, :nonexistent)
end

function factorBlobletTestBlock!(fg)
    # Factor bloblet CRUD
    @test listFactorBloblets(fg, :abf1) == Symbol[]
    @test addFactorBloblet!(fg, :abf1, Bloblet(:fbl1, "factor_data")) ==
          Bloblet(:fbl1, "factor_data")
    @test_throws LabelExistsError addFactorBloblet!(fg, :abf1, Bloblet(:fbl1, "dup"))
    @test hasFactorBloblet(fg, :abf1, :fbl1)
    @test !hasFactorBloblet(fg, :abf1, :nonexistent)
    @test getFactorBloblet(fg, :abf1, :fbl1) == Bloblet(:fbl1, "factor_data")
    @test_throws LabelNotFoundError getFactorBloblet(fg, :abf1, :nonexistent)
    @test mergeFactorBloblet!(fg, :abf1, Bloblet(:fbl1, "updated")) == 1
    @test getFactorBloblet(fg, :abf1, :fbl1) == Bloblet(:fbl1, "updated")
    @test :fbl1 in listFactorBloblets(fg, :abf1)

    # Bulk operations
    @test addFactorBloblets!(fg, :abf1, [Bloblet(:fbl2, 1), Bloblet(:fbl3, 2)]) ==
          [Bloblet(:fbl2, 1), Bloblet(:fbl3, 2)]
    @test length(getFactorBloblets(fg, :abf1)) == 3
    @test mergeFactorBloblets!(fg, :abf1, [Bloblet(:fbl2, 10), Bloblet(:fbl3, 20)]) == 2
    @test deleteFactorBloblets!(fg, :abf1, [:fbl2, :fbl3]) == 2
    @test deleteFactorBloblet!(fg, :abf1, :fbl1) == 1
    @test listFactorBloblets(fg, :abf1) == Symbol[]
end

function hasBlobletTestBlock!(fg)
    # Agent bloblets has
    agentlabel = :testHasBlobletAgent
    addAgent!(fg, Agent(; label = agentlabel))
    addAgentBloblet!(fg, agentlabel, Bloblet(:agent_has_test, "data"))
    @test hasAgentBloblet(fg, agentlabel, :agent_has_test)
    @test !hasAgentBloblet(fg, agentlabel, :nonexistent)
    deleteAgentBloblet!(fg, agentlabel, :agent_has_test)
    @test !hasAgentBloblet(fg, agentlabel, :agent_has_test)
    deleteAgent!(fg, agentlabel)

    # Graph bloblets has
    addGraphBloblet!(fg, Bloblet(:graph_has_test, "data"))
    @test hasGraphBloblet(fg, :graph_has_test)
    @test !hasGraphBloblet(fg, :nonexistent)
    deleteGraphBloblet!(fg, :graph_has_test)
    @test !hasGraphBloblet(fg, :graph_has_test)
end

function statesExtendedTestBlock!(fg)
    # hasState
    @test hasState(fg, :a, :default)
    @test !hasState(fg, :a, :nonexistent)

    # getStates returns Vector
    states = getStates(fg, :a)
    @test states isa Vector
    @test length(states) >= 1

    # addStates! bulk
    s1 = State{TestVariableType1}(; label = :bulk_s1)
    s2 = State{TestVariableType1}(; label = :bulk_s2)
    @test addStates!(fg, :a, [s1, s2]) == 2
    @test hasState(fg, :a, :bulk_s1)
    @test hasState(fg, :a, :bulk_s2)

    # addStates! with pair syntax
    s3 = State{TestVariableType2}(; label = :bulk_s3)
    @test addStates!(fg, [:b => s3]) == 1
    @test hasState(fg, :b, :bulk_s3)

    # deleteStates! bulk
    @test deleteStates!(fg, :a, [:bulk_s1, :bulk_s2]) == 2
    @test !hasState(fg, :a, :bulk_s1)
    @test !hasState(fg, :a, :bulk_s2)

    # deleteStates! with pair syntax
    @test deleteStates!(fg, [:b => :bulk_s3]) == 1
    @test !hasState(fg, :b, :bulk_s3)

    # deleteState! non-existent returns 0
    @test deleteState!(fg, :a, :nonexistent) == 0

    # listStates with filters
    @test :default in listStates(fg, :a)
    @test listStates(fg, :a; whereLabel = ==(Symbol("default")) ∘ identity) == [:default]

    # listStates across dfg returns Vector
    all_states = listStates(fg)
    @test all_states isa AbstractVector
    @test :default in all_states

    # LabelNotFoundError for getState on missing state
    @test_throws LabelNotFoundError getState(fg, :a, :nonexistent)

    # mergeStates! bulk
    s4 = State{TestVariableType1}(; label = :merge_bulk)
    @test mergeStates!(fg, :a, [s4]) == 1
    @test hasState(fg, :a, :merge_bulk)
    @test mergeStates!(fg, :a, [s4]) == 1  # idempotent
    deleteState!(fg, :a, :merge_bulk)
    return nothing
end

function blobstoreExtendedTestBlock!(fg)
    store = DFG.MemoryBlobprovider(; label = :mergestore)
    @test addBlobprovider!(fg, store) isa Any
    @test_throws LabelExistsError addBlobprovider!(fg, store)

    # mergeBlobproviders!
    store2 = DFG.MemoryBlobprovider(; label = :mergestore2)
    @test DFG.mergeBlobproviders!(fg, [store2]) == 1
    @test :mergestore2 in listBlobproviders(fg)
    # merge again is idempotent
    @test DFG.mergeBlobproviders!(fg, [store2]) == 0

    @test_throws LabelNotFoundError getBlobprovider(fg, :nonexistent)

    # cleanup
    @test DFG.deleteBlobprovider!(fg, :mergestore) == 1
    @test DFG.deleteBlobprovider!(fg, :mergestore2) == 1
    @test DFG.deleteBlobprovider!(fg, :nonexistent) == 0
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
    storeEntry = Blobentry(:a, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :b)
    @test getLabel(storeEntry) == storeEntry.label
    @test getTimestamp(storeEntry) == storeEntry.timestamp

    de1 = Blobentry(:key1, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :b)

    de2 = Blobentry(:key2, DFG.Multihash(sha2_256, rand(UInt8, 32)), UInt32(0), :b)

    de2_update = Blobentry(
        :key2,
        DFG.Multihash(sha2_256, rand(UInt8, 32)),
        UInt32(0),
        :b;
        description = "Yay",
    )

    #add
    v1 = getVariable(fg, :a)
    @test addBlobentry!(v1, de1) == de1
    @test addVariableBlobentry!(fg, :a, de2) == de2
    @test_throws LabelExistsError addBlobentry!(v1, de1)
    @test de2 in getBlobentries(v1)

    #get
    @test deepcopy(de1) == getBlobentry(v1, :key1)
    @test deepcopy(de2) == getVariableBlobentry(fg, :a, :key2)
    @test_throws LabelNotFoundError getBlobentry(v2, :key1)
    @test_throws LabelNotFoundError getVariableBlobentry(fg, :b, :key1)

    #merge
    @test mergeVariableBlobentry!(fg, :a, de2_update) == 1
    @test deepcopy(de2_update) == getVariableBlobentry(fg, :a, :key2)
    @test mergeVariableBlobentry!(fg, :b, de2_update) == 1

    #list
    entries = getVariableBlobentries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e -> e.label, entries), [:key1, :key2])
    @test length(getVariableBlobentries(fg, :b)) == 1

    @test issetequal(listVariableBlobentries(fg, :a), [:key1, :key2])
    @test listVariableBlobentries(fg, :b) == Symbol[:key2]

    @test hasVariableBlobentry(fg, :a, :key1)
    @test !hasVariableBlobentry(fg, :a, :nope)
    @test_throws LabelNotFoundError hasVariableBlobentry(fg, :nope, :nope)

    #delete
    @test deleteBlobentry!(v1, :key1) == 1
    @test listVariableBlobentries(fg, getLabel(v1)) == Symbol[:key2]
    #delete from dfg
    @test deleteVariableBlobentry!(fg, :a, :key2) == 1
    @test listVariableBlobentries(fg, :a) == Symbol[]
    deleteVariableBlobentry!(fg, :b, :key2)
    @test listVariableBlobentries(fg, :b) == Symbol[]

    @test getLabel.(addVariableBlobentries!(fg, :a, [de1, de2])) == [:key1, :key2]
    @test deleteVariableBlobentries!(fg, :a, [:key1, :key2]) == 2
    @test listVariableBlobentries(fg, :a) == Symbol[]
    @test mergeVariableBlobentries!(fg, :a, [de1, de2]) == 2
    @test getLabel.(getVariableBlobentries(fg, :a)) == [:key1, :key2]
    @test mergeVariableBlobentries!(fg, :a, [de1, de2]) == 2
    @test deleteVariableBlobentries!(fg, :a, [:key1]) == 1

    @test deleteVariableBlobentries!(fg, :a, [:key1]) == 0
    @test_throws LabelExistsError addVariableBlobentries!(fg, :a, [de2])
    @test deleteVariableBlobentries!(fg, :a, [:key2]) == 1

    #Factor blobentries
    @test addFactorBlobentry!(fg, :abf1, de1) == de1
    @test_throws LabelExistsError addFactorBlobentry!(fg, :abf1, de1)
    @test de1 == getFactorBlobentry(fg, :abf1, getLabel(de1))
    @test_throws LabelNotFoundError getFactorBlobentry(fg, :abf1, :nope)
    @test hasFactorBlobentry(fg, :abf1, getLabel(de1))
    @test !hasFactorBlobentry(fg, :abf1, :nope)
    @test mergeFactorBlobentry!(fg, :abf1, de2_update) == 1
    @test listFactorBlobentries(fg, :abf1) == [getLabel(de1), getLabel(de2_update)]
    @test deleteFactorBlobentry!(fg, :abf1, getLabel(de2_update)) == 1
    @test deleteFactorBlobentry!(fg, :abf1, getLabel(de2_update)) == 0
    @test getFactorBlobentries(fg, :abf1) == [de1]
    @test getLabel.(addFactorBlobentries!(fg, :abf1, [de2])) == [getLabel(de2)]
    @test mergeFactorBlobentries!(fg, :abf1, [de1, de2_update]) == 2
    @test deleteFactorBlobentries!(fg, :abf1, [getLabel(de1), getLabel(de2_update)]) == 2
    @test listFactorBlobentries(fg, :abf1) == Symbol[]

    #graph blobentries
    @test addGraphBlobentry!(fg, de1) == de1
    @test_throws LabelExistsError addGraphBlobentry!(fg, de1)
    @test de1 == getGraphBlobentry(fg, getLabel(de1))
    @test_throws LabelNotFoundError getGraphBlobentry(fg, :nope)
    @test mergeGraphBlobentry!(fg, de2_update) == 1
    @test listGraphBlobentries(fg) == [getLabel(de1), getLabel(de2_update)]
    @test deleteGraphBlobentry!(fg, getLabel(de2_update)) == 1
    @test deleteGraphBlobentry!(fg, getLabel(de2_update)) == 0
    @test getGraphBlobentries(fg) == [de1]
    @test addGraphBlobentries!(fg, [de2]) == [de2]
    @test mergeGraphBlobentries!(fg, [de1, de2_update]) == 2
    @test deleteGraphBlobentries!(fg, [getLabel(de1), getLabel(de2_update)]) == 2
    @test listGraphBlobentries(fg) == Symbol[]

    # agent blobentries
    agentlabel = :testBEAgent
    addAgent!(fg, Agent(; label = agentlabel))
    @test addAgentBlobentry!(fg, agentlabel, de1) == de1
    @test_throws LabelExistsError addAgentBlobentry!(fg, agentlabel, de1)
    @test de1 == getAgentBlobentry(fg, agentlabel, getLabel(de1))
    @test_throws LabelNotFoundError getAgentBlobentry(fg, agentlabel, :nope)
    @test mergeAgentBlobentry!(fg, agentlabel, de2_update) == 1
    @test listAgentBlobentries(fg, agentlabel) == [getLabel(de1), getLabel(de2_update)]
    @test deleteAgentBlobentry!(fg, agentlabel, getLabel(de2_update)) == 1
    @test deleteAgentBlobentry!(fg, agentlabel, getLabel(de2_update)) == 0
    @test getAgentBlobentries(fg, agentlabel) == [de1]
    @test addAgentBlobentries!(fg, agentlabel, [de2]) == [de2]
    @test mergeAgentBlobentries!(fg, agentlabel, [de1, de2_update]) == 2
    @test deleteAgentBlobentries!(fg, agentlabel, [getLabel(de1), getLabel(de2_update)]) ==
          2
    @test listAgentBlobentries(fg, agentlabel) == Symbol[]
    deleteAgent!(fg, agentlabel)
    return nothing
end

function blobsStoresTestBlock!(fg)
    de1 = Blobentry(
        :label1,
        DFG.Multihash(sha2_256, rand(UInt8, 32)),
        UInt32(0xAAAA),
        :store1;
        origin = "origin1",
        description = "description1",
        mimetype = MIME("mimetype1"),
    )
    de2 = Blobentry(
        :label2,
        DFG.Multihash(sha2_256, rand(UInt8, 32)),
        UInt32(0xFFFF),
        :store2;
        origin = "origin2",
        description = "description2",
        mimetype = MIME("mimetype2"),
        timestamp = DFG.TimeDateZone("2020-08-12T12:00:00.000Z"),
    )
    de2_update = Blobentry(
        :label2,
        DFG.Multihash(sha2_256, rand(UInt8, 32)),
        UInt32(0x0123),
        :store2;
        origin = "origin2",
        description = "description2",
        mimetype = MIME("mimetype2"),
        timestamp = DFG.TimeDateZone("2020-08-12T12:00:00.000Z"),
    )
    @test getLabel(de1) == de1.label
    @test getTimestamp(de1) == de1.timestamp

    #add
    var1 = getVariable(fg, :a)
    var2 = getVariable(fg, :b)
    @test addBlobentry!(var1, de1) == de1
    mergeVariable!(fg, var1)
    @test addVariableBlobentry!(fg, :a, de2) == de2
    @test_throws LabelExistsError addBlobentry!(var1, de1)
    @test de2 in getVariableBlobentries(fg, var1.label)

    #get
    @test deepcopy(de1) == getBlobentry(var1, :label1)
    @test deepcopy(de2) == getVariableBlobentry(fg, :a, :label2)
    @test_throws LabelNotFoundError getBlobentry(var2, :label1)
    @test_throws LabelNotFoundError getVariableBlobentry(fg, :b, :label1)

    #update
    @test mergeVariableBlobentry!(fg, :a, de2_update) == 1
    @test deepcopy(de2_update) == getVariableBlobentry(fg, :a, :label2)
    @test mergeVariableBlobentry!(fg, :b, de2_update) == 1

    #list
    entries = getVariableBlobentries(fg, :a)
    @test length(entries) == 2
    @test issetequal(map(e -> e.label, entries), [:label1, :label2])
    @test length(getVariableBlobentries(fg, :b)) == 1

    @test issetequal(listVariableBlobentries(fg, :a), [:label1, :label2])
    @test listVariableBlobentries(fg, :b) == Symbol[:label2]

    # test collecting blobentries with filters
    gathered = DFG.gatherBlobentries(
        fg;
        whereVariableLabel = contains("a"),
        whereLabel = contains("1"),
    )
    @test first(gathered[1]) == :a
    @test last(gathered[1])[1] == getVariableBlobentry(fg, :a, :label1)

    #delete
    @test deleteVariableBlobentry!(fg, var1.label, de1.label) == 1
    @test listVariableBlobentries(fg, var1.label) == Symbol[:label2]
    #delete from dfg
    @test deleteVariableBlobentry!(fg, :a, :label2) == 1
    var1 = getVariable(fg, :a)
    @test listBlobentries(var1) == Symbol[]

    # Blobprovider functions
    fs = DFG.FolderBlobprovider("/tmp/$(string(uuid4())[1:8])")
    # Adding
    addBlobprovider!(fg, fs)
    # Listing
    @test listBlobproviders(fg) == [fs.label]
    # Getting
    @test getBlobprovider(fg, fs.label) == fs
    @test_throws LabelNotFoundError getBlobprovider(fg, :notfound)
    # Deleting
    @test DFG.deleteBlobprovider!(fg, fs.label) == 1
    # Add it back
    addBlobprovider!(fg, fs)

    # Blob (CAS)
    testData = rand(UInt8, 50)
    mhash = putBlob!(fs, testData)
    @test mhash isa DFG.Multihash
    # show(io, MIME"text/plain"(), ::Multihash)
    iobuf = IOBuffer()
    show(iobuf, MIME"text/plain"(), mhash)
    showstr = String(take!(iobuf))
    @test startswith(showstr, "multihash:")
    @test length(showstr) > length("multihash:")
    # decode(::Multihash)
    code, digest = DFG.decode(mhash)
    @test code == 0x12  # sha2_256
    @test length(digest) == 32
    @test DFG.Multihash(code, digest) == mhash
    # verifyBlob(entry, blob)
    entry = Blobentry(:vb_test, mhash, crc32c(testData))
    @test DFG.verifyBlob(entry, testData) == true
    @test DFG.verifyBlob(entry, rand(UInt8, 50)) == false
    @test hasBlob(fs, mhash)
    @test listBlobs(fs) == [mhash]
    # putBlob! is idempotent
    @test putBlob!(fs, testData) == mhash
    @test fetchBlob(fs, mhash) == testData
    @test isnothing(fetchBlob(fs, DFG.Multihash(sha2_256, rand(UInt8, 32))))
    @test purgeBlob!(fs, DFG.Multihash(sha2_256, rand(UInt8, 32))) == 0
    @test purgeBlob!(fs, mhash) == 1
    @test isnothing(fetchBlob(fs, mhash))
    @test purgeBlob!(fs, mhash) == 0
    @test isempty(listBlobs(fs))

    # Blob Wrappers
    # on Variable
    newentry = DFG.saveVariableBlob!(fg, :a, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveVariableBlob!(fg, :a, testData, :testing)
    @test :testing in listVariableBlobentries(fg, :a)
    be, blob = DFG.loadVariableBlob(fg, :a, :testing)
    @test newentry == be
    @test blob == testData
    deleteVariableBlobentry!(fg, :a, :testing)
    @test_throws DFG.LabelNotFoundError DFG.loadVariableBlob(fg, :a, :testing)

    # on Graph
    newentry = DFG.saveGraphBlob!(fg, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveGraphBlob!(fg, testData, :testing, fs.label)
    @test :testing in listGraphBlobentries(fg)
    be, blob = DFG.loadGraphBlob(fg, :testing)
    @test newentry == be
    @test blob == testData
    deleteGraphBlobentry!(fg, :testing)
    @test_throws DFG.LabelNotFoundError DFG.loadGraphBlob(fg, :testing)

    # on Agent
    agentlabel = :testBlobWrapperAgent
    addAgent!(fg, Agent(; label = agentlabel))
    newentry = DFG.saveAgentBlob!(fg, agentlabel, testData, :testing, fs.label)
    @test_throws DFG.LabelExistsError DFG.saveAgentBlob!(
        fg,
        agentlabel,
        testData,
        :testing,
        fs.label,
    )
    @test :testing in listAgentBlobentries(fg, agentlabel)
    be, blob = DFG.loadAgentBlob(fg, agentlabel, :testing)
    @test newentry == be
    @test blob == testData
    deleteAgentBlobentry!(fg, agentlabel, :testing)
    @test_throws DFG.LabelNotFoundError DFG.loadAgentBlob(fg, agentlabel, :testing)
    deleteAgent!(fg, agentlabel)
    return nothing
end

function testGroup!(fg, v1, v2, f0, f1)
    # "TODO split and sort these tests"

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

        @test getStateKind(v1) == TestVariableType1()
        @test getStateKind(fg, :a) == TestVariableType1()

        @test getStateKind(v1) == TestVariableType1()
        @test getStateKind(fg, :a) == TestVariableType1()

        @test ls2(fg, :a) == [:b]

        @test issetequal([TestVariableType1, TestVariableType2], DFG.lsTypes(fg))

        varTypesDict = DFG.lsTypesDict(fg)
        @test issetequal(collect(keys(varTypesDict)), DFG.lsTypes(fg))
        @test issetequal(varTypesDict[TestVariableType1], [:a])
        @test issetequal(varTypesDict[TestVariableType2], [:b])

        @test ls(fg, TestVariableType1) == [:a]

        # FIXME return: Symbol[:b, :b] == Symbol[:b]
        varNearTs = findVariablesNearTimestamp(fg, now())
        @test varNearTs[1][1] == [:b]

        ## SORT copied from CRUD
        @test all(
            getVariables(fg; whereLabel = contains(r"a")) .== [getVariable(fg, v1.label)],
        )
        @test all(getVariables(fg; whereSolvable = >=(1)) .== [getVariable(fg, v2.label)])
        @test getVariables(fg; whereLabel = contains(r"a"), whereSolvable = >=(1)) == []
        @test getVariables(fg; whereTags = ⊇([:LANDMARK]))[1] == getVariable(fg, v2.label)

        @test getFactors(fg; whereLabel = contains(r"nope")) == []
        @test issetequal(getLabel.(getFactors(fg; whereSolvable = >=(1))), [:af1, :abf1])
        @test getFactors(fg; whereSolvable = >=(2)) == []
        @test getFactors(fg; whereTags = ⊇([:tag1]))[1] == f1
        @test getFactors(fg; whereTags = ⊇([:PRIOR]))[1] == f0
        ##/SORT

        # Additional testing for https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/201
        # list solvable
        @test symdiff([:a, :b], listVariables(fg; whereSolvable = >=(0))) == []
        @test listVariables(fg; whereSolvable = >=(1)) == [:b]

        @test issetequal(listFactors(fg; whereSolvable = >=(1)), [:af1, :abf1])
        @test issetequal(listFactors(fg; whereSolvable = >=(0)), [:af1, :abf1])
        @test all([f in [f0, f1] for f in getFactors(fg; whereSolvable = >=(1))])

        @test lsf(fg, :b) == [f1.label]

        # Tags
        @test ls(fg; whereTags = ⊇([:POSE])) == []
        @test issetequal(
            ls(fg; whereTags = !isdisjoint([:POSE, :LANDMARK])),
            ls(fg; whereTags = ⊇([:VARIABLE])),
        )

        @test lsf(fg; whereTags = !isdisjoint([:NONE])) == []
        @test lsf(fg; whereTags = ⊇([:NONE])) == []
        @test lsf(fg; whereTags = ⊇([:PRIOR])) == [:af1]

        # Regexes
        @test ls(fg; whereLabel = contains(r"a")) == [v1.label]
        @test lsf(fg; whereLabel = contains(r"abf*")) == [f1.label]

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

    # Only do solvable tests on VariableDFG
    if isa(getVariable(fg, :a), VariableDFG)
        # Filtered - REF DFG #201
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg; whereSolvable = >=(0))
        @test size(adjMat) == (1, 3)
        @test symdiff(v_ll, [:a, :b, :orphan]) == Symbol[]
        @test symdiff(f_ll, [:abf1]) == Symbol[]

        # sparse
        adjMat, v_ll, f_ll = getBiadjacencyMatrix(fg; whereSolvable = >=(1))
        @test size(adjMat) == (1, 2)
        @test issetequal(v_ll, [:a, :b])
        @test f_ll == [:abf1]
    end
end

# Now make a complex graph for connectivity tests
function connectivityTestGraph(
    ::Type{T},
    ::Type{<:VariableDFG},
    ::Type{<:FactorDFG},
) where {T <: AbstractDFG}#InMemoryDFGTypes
    #settings
    numNodesType1 = 5
    numNodesType2 = 5

    dfg = T(; graphLabel = :testGraph)

    vars = vcat(
        map(
            n -> VariableDFG(Symbol("x$n"), State{TestVariableType1}(; label = :default)),
            1:numNodesType1,
        ),
        map(
            n -> VariableDFG(
                Symbol("x$(numNodesType1+n)"),
                State{TestVariableType2}(; label = :default),
            ),
            1:numNodesType2,
        ),
    )

    addVariables!(dfg, vars)

    #change ready and solveInProgress for x7,x8 for improved tests on x7x8f1
    #NOTE because defaults changed
    setSolvable!(dfg, :x8, 0)
    setSolvable!(dfg, :x9, 0)

    state = DFG.Recipestate(; eliminated = true, potentialused = true)
    hyper = DFG.Recipehyper(; multihypo = Float64[], inflation = 1.0)
    f_tags = Set([:FACTOR])

    facs = map(
        n -> addFactor!(
            dfg,
            FactorDFG(
                Symbol("x$(n)x$(n+1)f1"),
                [vars[n].label, vars[n + 1].label],
                TestFunctorInferenceType1(),
                deepcopy(hyper),
                deepcopy(state);
                tags = copy(f_tags),
            ),
        ),
        1:(length(vars) - 1),
    )
    setSolvable!(dfg, :x7x8f1, 0)

    return (dfg = dfg, variables = vars, factors = facs)
end

function connectivityTestGraph(
    ::Type{T},
    ::Type{<:GraphVariable},
    ::Type{<:GraphFactor},
) where {T <: AbstractDFG}#InMemoryDFGTypes
    (; dfg, variables, factors) = connectivityTestGraph(T, VariableDFG, FactorDFG)
    sfg = T()
    addVariables!(sfg, variables)
    addFactors!(sfg, factors)
    return (dfg = dfg, variables = getVariables(sfg), factors = getFactors(sfg))
end

# dfg, verts, facs = connectivityTestGraph(testDFGAPI)

function GettingNeighbors(testDFGAPI; VARTYPE = VariableDFG, FACTYPE = FactorDFG)
    # "Getting Neighbors"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE, FACTYPE)
    # Trivial test to validate that intersect([], []) returns order of first parameter
    @test intersect([:x3, :x2, :x1], [:x1, :x2]) == [:x2, :x1]
    # Get neighbors tests
    @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
    neighbors = listNeighbors(dfg, getFactor(dfg, :x1x2f1))
    @test neighbors == [:x1, :x2]
    # Testing aliases
    @test listNeighbors(dfg, getFactor(dfg, :x1x2f1)) == ls(dfg, getFactor(dfg, :x1x2f1))
    @test listNeighbors(dfg, :x1x2f1) == ls(dfg, :x1x2f1)

    varneighls, facneighls = listNeighborhood(dfg, [:x1, :x3], 2)
    @test issetequal(varneighls, [:x1, :x2, :x3, :x4])
    @test issetequal(facneighls, [:x1x2f1, :x2x3f1, :x3x4f1])

    # Solvable
    #TODO if not a GraphsDFG with and summary or skeleton
    if VARTYPE == VariableDFG
        @test listNeighbors(dfg, :x5; whereSolvable = >=(2)) == Symbol[]
        @test issetequal(listNeighbors(dfg, :x5; whereSolvable = >=(0)), [:x4x5f1, :x5x6f1])
        @test issetequal(listNeighbors(dfg, :x5), [:x4x5f1, :x5x6f1])
        @test listNeighbors(dfg, :x7x8f1; whereSolvable = >=(0)) == [:x7, :x8]
        @test listNeighbors(dfg, :x7x8f1; whereSolvable = >=(1)) == [:x7]
        @test listNeighbors(dfg, verts[1]; whereSolvable = >=(0)) == [:x1x2f1]
        @test listNeighbors(dfg, verts[1]; whereSolvable = >=(2)) == Symbol[]
        @test listNeighbors(dfg, verts[1]) == [:x1x2f1]
    end
end

#TODO confirm these tests are covered somewhere then delete
# function  GettingSubgraphs(testDFGAPI; VARTYPE=VariableDFG, FACTYPE=FactorDFG)
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
#     if VARTYPE == VariableDFG
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

function BuildingSubgraphs(testDFGAPI; VARTYPE = VariableDFG, FACTYPE = FactorDFG)

    # "Getting Subgraphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE, FACTYPE)
    # Subgraphs
    dfgSubgraph = getSubgraph(testDFGAPI, dfg, [verts[1].label], 2)
    # Only returns x1 and x2
    @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
    #
    dfgSubgraph = getSubgraph(testDFGAPI, dfg, [:x1, :x2, :x1x2f1])
    # Only returns x1 and x2
    @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

    dfgSubgraph = getSubgraph(testDFGAPI, dfg, [:x1x2f1], 1)
    # Only returns x1 and x2
    @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

    #TODO if not a GraphsDFG with and summary or skeleton
    if VARTYPE == VariableDFG
        dfgSubgraph = getSubgraph(testDFGAPI, dfg, [:x8], 2; whereSolvable = >=(1))
        @test issetequal([:x7], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
        #end if not a GraphsDFG with and summary or skeleton
    end
    # DFG issue #95 - confirming that getSubgraphAroundNode retains order
    # REF: https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/95
    for fId in listVariables(dfg)
        # Get a subgraph of this and it's related factors+variables
        dfgSubgraph = getSubgraph(testDFGAPI, dfg, [fId], 2)
        # For each factor check that the order the copied graph == original
        for fact in getFactors(dfgSubgraph)
            @test fact.variableorder == getFactor(dfg, fact.label).variableorder
        end
    end

    #TODO getSubgraph default constructors for skeleton and summary
    if VARTYPE == VariableDFG
        dfgSubgraph = getSubgraph(dfg, [:x1, :x2, :x1x2f1])
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])

        dfgSubgraph = getSubgraph(dfg, [:x2, :x3], 2)
        @test issetequal(
            [:x2, :x3, :x1, :x4, :x3x4f1, :x1x2f1, :x2x3f1],
            [ls(dfgSubgraph)..., lsf(dfgSubgraph)...],
        )

        dfgSubgraph = getSubgraph(dfg, [:x1x2f1], 1)
        @test issetequal([:x1, :x1x2f1, :x2], [ls(dfgSubgraph)..., lsf(dfgSubgraph)...])
    end
end

#TODO Summaries and Summary Graphs
function Summaries(testDFGAPI)
    # "Summaries and Summary Graphs"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)
    #TODO for summary
    # if VARTYPE == VariableSummary
    # factorFields = fieldnames(FACTYPE)
    # variableFields = fieldnames(VARTYPE)
    factorFields = fieldnames(DFG.FactorSummary)
    variableFields = fieldnames(DFG.VariableSummary)

    summaryGraph = getSummaryGraph(dfg)
    @test symdiff(ls(summaryGraph), ls(dfg)) == Symbol[]
    @test symdiff(lsf(summaryGraph), lsf(dfg)) == Symbol[]
    # Check all fields are equal for all variables
    for v in ls(summaryGraph)
        for field in variableFields
            a = getproperty(getVariable(dfg, v), field)
            b = getproperty(getVariable(summaryGraph, v), field)
            if field == :solvable
                @test a[] == b[]
            else
                @test a == b
            end
        end
    end
    for f in lsf(summaryGraph)
        for field in factorFields
            a = getproperty(getFactor(dfg, f), field)
            b = getproperty(getFactor(summaryGraph, f), field)
            if field == :solvable
                @test a[] == b[]
            else
                @test a == b
            end
        end
    end
end

function ProducingDotFiles(
    testDFGAPI,
    v1 = nothing,
    v2 = nothing,
    f1 = nothing;
    VARTYPE = VariableDFG,
    FACTYPE = FactorDFG,
)
    # "Producing Dot Files"
    # create a simpler graph for dot testing
    dotdfg = testDFGAPI(; graphLabel = :testGraph)

    if v1 === nothing
        v1 = VARTYPE(:a, State{TestVariableType1}(; label = :default))
    end
    if v2 === nothing
        v2 = VARTYPE(:b, State{TestVariableType1}(; label = :default))
    end
    if f1 === nothing
        if (FACTYPE == FactorDFG)
            f1 = FactorDFG(:abf1, [:a, :b], TestFunctorInferenceType1())
        else
            f1 = FACTYPE(:abf1, [:a, :b])
        end
    end

    addVariable!(dotdfg, v1)
    addVariable!(dotdfg, v2)
    # FIXME, fix deprecation
    # ┌ Warning: addFactor!(dfg, variables, factor) is deprecated, use addFactor!(dfg, factor)
    # │   caller = ProducingDotFiles(testDFGAPI::Type{GraphsDFG}, v1::Nothing, v2::Nothing, f1::Nothing; VARTYPE::Type{VariableDFG}, FACTYPE::Type{FactorDFG}) at testBlocks.jl:1440
    # └ @ Main ~/.julia/dev/DistributedFactorGraphs/test/testBlocks.jl:1440
    addFactor!(dotdfg, f1)
    #NOTE hardcoded toDot will have different results so test Graphs separately
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

function ConnectivityTest(testDFGAPI; VARTYPE = VariableDFG, FACTYPE = FactorDFG)
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE, FACTYPE)
    @test isConnected(dfg) == true
    # @test @test_deprecated isFullyConnected(dfg) == true
    # @test @test_deprecated hasOrphans(dfg) == false

    deleteFactor!(dfg, :x9x10f1)
    @test isConnected(dfg) == false

    deleteVariable!(dfg, :x5)
    @test isConnected(dfg) == false
end

function CopyFunctionsTest(testDFGAPI; VARTYPE = VariableDFG, FACTYPE = FactorDFG)

    # testDFGAPI = GraphsDFG
    # kwargs = ()

    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE, FACTYPE)

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

function FileDFGTestBlock(testDFGAPI; VARTYPE = VariableDFG, FACTYPE = FactorDFG)

    # testDFGAPI = GraphsDFG
    # kwargs = ()
    # filename = "/tmp/fileDFG"
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VARTYPE, FACTYPE)
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
    # set some factor solver data
    f45.state.eliminated = true
    push!(f45.hyper.multihypo, 4.0)
    f45.hyper.nullhypo = 5.0
    f45.state.potentialused = true
    #update factor
    mergeFactor!(dfg, f45)

    for filename in ["/tmp/fileDFG", "/tmp/FileDFGExtension.tar.gz"]
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

        dfg2 = loadDFG(filename)

        @test issetequal(ls(dfg), ls(dfg2))
        @test issetequal(lsf(dfg), lsf(dfg2))
        for var in ls(dfg)
            @test getVariable(dfg, var) == getVariable(dfg2, var)
        end
        for fact in lsf(dfg)
            @test getFactor(dfg, fact) == getFactor(dfg2, fact)
        end
        #TODO test graph, agent, blob stores, solverdata.

        # @test length(getBlobentries(getVariable(retDFG, :x1))) == 1
        # @test typeof(getBlobentry(getVariable(retDFG, :x1),:testing)) == GeneralDataEntry
        # @test length(getBlobentries(getVariable(retDFG, :x2))) == 1
        # @test typeof(getBlobentry(getVariable(retDFG, :x2),:testing2)) == FileDataEntry
    end

    filename = "/tmp/fileDFG"
    summarydfg = testDFGAPI{NoSolverParams, VariableSummary, FactorSummary}(;
        graphLabel = :testGraph,
    )
    loadDFG!(summarydfg, filename)

    @test issetequal(ls(dfg), ls(summarydfg))
    @test issetequal(lsf(dfg), lsf(summarydfg))

    skeletondfg = testDFGAPI{NoSolverParams, VariableSkeleton, FactorSkeleton}(;
        graphLabel = :testGraph,
    )
    loadDFG!(skeletondfg, filename)

    @test issetequal(ls(dfg), ls(skeletondfg))
    @test issetequal(lsf(dfg), lsf(skeletondfg))
end

function PathFindingTests(testDFGAPI)
    # Graph layout (connectivityTestGraph):
    # x1 - x1x2f1 - x2 - x2x3f1 - x3 - x3x4f1 - x4 - x4x5f1 - x5
    #   - x5x6f1 - x6 - x6x7f1 - x7 - x7x8f1 - x8 - x8x9f1 - x9 - x9x10f1 - x10
    # Variable types: x1..x5 = TestVariableType1, x6..x10 = TestVariableType2
    # Solvable defaults: x8=0, x9=0, x7x8f1=0; rest = 1
    dfg, verts, facs = connectivityTestGraph(testDFGAPI, VariableDFG, FactorDFG)

    # Add cross-link factors to create loops for multi-path testing
    # x1 -- x1x3f1 -- x3  (shortcut bypassing x2)
    # x2 -- x2x4f1 -- x4  (shortcut bypassing x3)
    addFactor!(dfg, FactorDFG(:x1x3f1, [:x1, :x3], TestFunctorInferenceType1()))
    addFactor!(dfg, FactorDFG(:x2x4f1, [:x2, :x4], TestFunctorInferenceType1()))

    # --- Basic findPaths / findPath (no restrictions) ---
    result = findPath(dfg, :x1, :x3)
    # shortest path should be via the direct link x1-x1x3f1-x3 (dist=2) not via x2 (dist=4)
    @test result.path == [:x1, :x1x3f1, :x3]
    @test result.dist == 2

    # Multiple paths from x1 to x4:
    # 1) x1-x1x2f1-x2-x2x4f1-x4  (dist=4)
    # 2) x1-x1x3f1-x3-x3x4f1-x4  (dist=4)
    # 3) x1-x1x2f1-x2-x2x3f1-x3-x3x4f1-x4  (dist=6)
    # 4) x1-x1x3f1-x3-x2x3f1-x2-x2x4f1-x4  (dist=6)
    results = findPaths(dfg, :x1, :x4, 4)
    @test length(results) >= 2
    @test results[1].dist <= results[end].dist  # sorted by distance

    # path across the whole graph
    full_path = findPath(dfg, :x1, :x10)
    @test :x1 == first(full_path.path)
    @test :x10 == last(full_path.path)

    # --- Restrict with variableLabels only (all factors kept) ---
    # Restrict to x1..x5 variables.  Factors connecting only those vars are auto-included.
    vars_subset = listVariables(dfg; whereType = ==(TestVariableType1()))
    result_restricted = findPath(dfg, :x1, :x5; variableLabels = vars_subset)
    @test first(result_restricted.path) == :x1
    @test last(result_restricted.path) == :x5
    # x6..x10 should NOT appear on the path
    @test isempty(intersect(result_restricted.path, [:x6, :x7, :x8, :x9, :x10]))

    # --- Restrict with factorLabels only (all variables kept) ---
    # Only allow the first 4 factors, path x1→x5 should still work
    facs_first4 = listFactors(dfg; whereLabel = contains(r"x[1-4](?!\d)"))
    result_fac = findPath(dfg, :x1, :x5; factorLabels = facs_first4)
    @test first(result_fac.path) == :x1
    @test last(result_fac.path) == :x5

    # --- Restrict with both variableLabels and factorLabels ---
    vars_1to5 = listVariables(dfg; whereType = ==(TestVariableType1()))
    facs_1to4 = listFactors(dfg; whereLabel = contains(r"x[1-4](?!\d)"))
    result_both =
        findPath(dfg, :x1, :x5; variableLabels = vars_1to5, factorLabels = facs_1to4)
    @test first(result_both.path) == :x1
    @test last(result_both.path) == :x5

    # --- With whereSolvable ---
    # Only solvable >= 1 variables (excludes x8, x9)
    solvable_vars = listVariables(dfg; whereSolvable = >=(1))
    solvable_facs = listFactors(dfg; whereSolvable = >=(1))
    # Path from x1 to x7 should work (all solvable)
    result_solvable = findPath(
        dfg,
        :x1,
        :x7;
        variableLabels = solvable_vars,
        factorLabels = solvable_facs,
    )
    @test first(result_solvable.path) == :x1
    @test last(result_solvable.path) == :x7
    # x8 and x9 (unsolvable) should not appear
    @test :x8 ∉ result_solvable.path
    @test :x9 ∉ result_solvable.path

    # Path from x1 to x10 with solvable filter should fail (x8, x9, x7x8f1 block the way)
    paths_blocked = findPaths(
        dfg,
        :x1,
        :x10,
        1;
        variableLabels = solvable_vars,
        factorLabels = solvable_facs,
    )
    @test isempty(paths_blocked)

    # And the singular findPath should return nothing
    @test isnothing(
        findPath(
            dfg,
            :x1,
            :x10;
            variableLabels = solvable_vars,
            factorLabels = solvable_facs,
        ),
    )

    # --- With whereTags ---
    # By default all variables have :VARIABLE tag. Tag some for testing.
    mergeVariableTags!(dfg, :x3, Set([:LANDMARK]))
    mergeVariableTags!(dfg, :x4, Set([:LANDMARK]))
    landmark_vars = listVariables(dfg; whereTags = ⊇([:LANDMARK]))
    @test :x3 ∈ landmark_vars
    @test :x4 ∈ landmark_vars
    # Restrict to only LANDMARK variables - x1 is not a LANDMARK, so include it to enable the path
    vars_with_x1 = union([:x1, :x2], landmark_vars)
    result_tags = findPath(dfg, :x1, :x4; variableLabels = vars_with_x1)
    @test first(result_tags.path) == :x1
    @test last(result_tags.path) == :x4
    # x5..x10 should not be on this path
    @test isempty(intersect(result_tags.path, [:x5, :x6, :x7, :x8, :x9, :x10]))

    # --- findPaths with k > 1 on looped graph ---
    # With cross-links x1x3f1 and x2x4f1. Multiple paths exist from x1 to x4.
    results_multi = findPaths(dfg, :x1, :x4, 5)
    @test length(results_multi) >= 2
    # All paths should start at x1 and end at x4
    for r in results_multi
        @test first(r.path) == :x1
        @test last(r.path) == :x4
    end
    # Distances should be non-decreasing
    @test issorted([r.dist for r in results_multi])

    # --- Error: no path exists ---
    # Disconnect x10 by removing the factor
    deleteFactor!(dfg, :x9x10f1)
    @test isnothing(findPath(dfg, :x1, :x10))
    empty_paths = findPaths(dfg, :x1, :x10, 1)
    @test isempty(empty_paths)
end
