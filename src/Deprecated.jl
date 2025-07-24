## ================================================================================
## Deprecated in v0.28
##=================================================================================
export AbstractRelativeMinimize,
    AbstractManifoldMinimize,
    AbstractPrior,
    AbstractRelative,
    InferenceVariable,
    InferenceType,
    PackedSamplableBelief

#TODO: maybe just remove these
export NoSolverParams

const AbstractPrior = PriorObservation
const AbstractRelative = RelativeObservation
const AbstractParams = AbstractDFGParams

abstract type AbstractRelativeMinimize <: RelativeObservation end
abstract type AbstractManifoldMinimize <: RelativeObservation end

const InferenceVariable = StateType{Any}
const InferenceType = AbstractPackedObservation

const PackedSamplableBelief = PackedBelief

export getVariableState
export addVariableState!
export mergeVariableState!
export deleteVariableState!
export listVariableStates
export VariableState
export VariableStateType
export copytoVariableState!
const getVariableState = getState
const addVariableState! = addState!
const mergeVariableState! = mergeState!
const deleteVariableState! = deleteState!
const listVariableStates = listStates
const VariableState = State
const VariableStateType = StateType
const copytoVariableState! = copytoState!

export setSolverData!
# """
#     $SIGNATURES
# Set solver data structure stored in a variable.
# """
function setSolverData!(v::VariableCompute, data::State, key::Symbol = :default)
    Base.depwarn(
        "setSolverData!(v::VariableCompute, data::State, key::Symbol = :default) is deprecated, use mergeState! instead.",
        :setSolverData!,
    )
    @assert key == data.solveKey "State.solveKey=:$(data.solveKey) does not match requested :$(key)"
    return v.solverDataDict[key] = data
end

@deprecate mergeVariableSolverData!(args...; kwargs...) mergeState!(args...; kwargs...)

export mergeVariableData!, mergeGraphVariableData!
function mergeVariableData!(args...)
    return error(
        "mergeVariableData! is obsolete, use mergeState! for state, PPEs are obsolete",
    )
end
function mergeGraphVariableData!(args...)
    return error(
        "mergeGraphVariableData! is obsolete, use mergeState! for state, PPEs are obsolete",
    )
end

# """
#     $(SIGNATURES)
# Gives back all factor labels that fit the bill:
#     lsWho(dfg, :Pose3)

# Notes
# - Returns `Vector{Symbol}`

# Dev Notes
# - Cloud versions will benefit from less data transfer
#  - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

# Related

# ls, lsf, lsfPriors
# """
function lsWho(dfg::AbstractDFG, type::Symbol)
    Base.depwarn("lsWho(dfg, type) is deprecated, use ls(dfg, type) instead.", :lsWho)
    vars = getVariables(dfg)
    labels = Symbol[]
    for v in vars
        varType = typeof(getVariableType(v)) |> nameof
        varType == type && push!(labels, v.label)
    end
    return labels
end

# solvekey is deprecated and sync!/copyto! is the better verb.
#TODO replace with syncStates! or similar
# """
#     $SIGNATURES
# Duplicate a `solveKey`` into a destination from a source.

# Notes
# - Can copy between graphs, or to different solveKeys within one graph.
# """
function cloneSolveKey!(
    dest_dfg::AbstractDFG,
    dest::Symbol,
    src_dfg::AbstractDFG,
    src::Symbol;
    solvable::Int = 0,
    labels = intersect(ls(dest_dfg; solvable = solvable), ls(src_dfg; solvable = solvable)),
    verbose::Bool = false,
)
    #
    for x in labels
        sd = deepcopy(getState(getVariable(src_dfg, x), src))
        copytoState!(dest_dfg, x, dest, sd)
    end

    return nothing
end

function cloneSolveKey!(dfg::AbstractDFG, dest::Symbol, src::Symbol; kw...)
    #
    @assert dest != src "Must copy to a different solveKey within the same graph, $dest."
    return cloneSolveKey!(dfg, dest, dfg, src; kw...)
end

export getData, addData!, updateData!, deleteData!

#TODO not a good function, as it's not complete.
# """
#     $(SIGNATURES)
# Convenience function to get all the metadata of a DFG
# """
# export getDFGInfo
function getDFGInfo(dfg::AbstractDFG)
    return (
        description = getDescription(dfg),
        agentLabel = getAgentLabel(dfg),
        graphLabel = getGraphLabel(dfg),
        agentMetadata = getAgentMetadata(dfg),
        graphMetadata = getGraphMetadata(dfg),
        solverParams = getSolverParams(dfg),
    )
end

export DFGVariable
const DFGVariable = VariableCompute

export listSolveKeys, listSupersolves
# """
#     $TYPEDSIGNATURES
# List all the solvekeys used amongst all variables in the distributed factor graph object.

# Related

# [`listSolveKeys`](@ref), [`getSolverDataDict`](@ref), [`listVariables`](@ref)
# """
function listSolveKeys(
    variable::VariableCompute,
    filterSolveKeys::Union{Regex, Nothing} = nothing,
    skeys = Set{Symbol}(),
)
    Base.depwarn("listSolveKeys is deprecated, use listStates instead.", :listSolveKeys)
    #
    for ky in keys(getSolverDataDict(variable))
        push!(skeys, ky)
    end

    #filter the solveKey set with filterSolveKeys regex
    !isnothing(filterSolveKeys) &&
        return filter!(k -> occursin(filterSolveKeys, string(k)), skeys)
    return skeys
end

function listSolveKeys(
    dfg::AbstractDFG,
    lbl::Symbol,
    filterSolveKeys::Union{Regex, Nothing} = nothing,
    skeys = Set{Symbol}(),
)
    return listSolveKeys(getVariable(dfg, lbl), filterSolveKeys, skeys)
end
#

function listSolveKeys(
    dfg::AbstractDFG,
    filterVariables::Union{Type{<:StateType}, Regex, Nothing} = nothing;
    filterSolveKeys::Union{Regex, Nothing} = nothing,
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
)
    #
    skeys = Set{Symbol}()
    varList = listVariables(dfg, filterVariables; tags = tags, solvable = solvable)
    for vs in varList  #, ky in keys(getSolverDataDict(getVariable(dfg, vs)))
        listSolveKeys(dfg, vs, filterSolveKeys, skeys)
    end

    # done inside the loop
    # #filter the solveKey set with filterSolveKeys regex
    # !isnothing(filterSolveKeys) && return filter!(k -> occursin(filterSolveKeys, string(k)), skeys)

    return skeys
end
const listSupersolves = listSolveKeys

#TODO mergeBlobentries! does not fit with merge definition, should probably be updated to copyto or sync.
# leaving here until it is done.

# """
#     $SIGNATURES

# Add a blob entry into the destination variable which already exists 
# in a source variable.

# See also: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`listBlobentries`](@ref), [`getBlob`](@ref)
# """
function mergeBlobentries!(
    dst::AbstractDFG,
    dlbl::Symbol,
    src::AbstractDFG,
    slbl::Symbol,
    bllb::Union{Symbol, UUID, <:AbstractString, Regex},
)
    #
    _makevec(s) = [s;]
    _makevec(s::AbstractVector) = s
    des_ = getBlobentry(src, slbl, bllb)
    des = _makevec(des_)
    # don't add data entries that already exist 
    dde = listBlobentries(dst, dlbl)
    # HACK, verb list should just return vector of Symbol. NCE36
    _getid(s) = s
    _getid(s::Blobentry) = s.id
    uids = _getid.(dde) # (s->s.id).(dde)
    filter!(s -> !(_getid(s) in uids), des)
    # add any data entries not already in the destination variable, by uuid
    return addBlobentry!.(dst, dlbl, des)
end

function mergeBlobentries!(
    dst::AbstractDFG,
    dlbl::Symbol,
    src::AbstractDFG,
    slbl::Symbol,
    ::Colon = :,
)
    des = listBlobentries(src, slbl)
    # don't add data entries that already exist 
    uids = listBlobentries(dst, dlbl)
    # verb list should just return vector of Symbol. NCE36
    filter!(s -> !(s in uids), des)
    if 0 < length(des)
        union(((s -> mergeBlobentries!(dst, dlbl, src, slbl, s)).(des))...)
    end
end

function mergeBlobentries!(
    dest::AbstractDFG,
    src::AbstractDFG,
    w...;
    varList::AbstractVector = listVariables(dest) |> sortDFG,
)
    @showprogress 1 "merging data entries" for vl in varList
        mergeBlobentries!(dest, vl, src, vl, w...)
    end
    return varList
end

## ================================================================================
## Deprecated in v0.27
##=================================================================================
export AbstractFactor
const AbstractFactor = AbstractObservation

export AbstractPackedFactor
const AbstractPackedFactor = AbstractPackedObservation

export FactorOperationalMemory
const FactorOperationalMemory = FactorCache

export VariableNodeData
const VariableNodeData = State

@deprecate getNeighborhood(args...; kwargs...) listNeighborhood(args...; kwargs...)
@deprecate addBlob!(store::AbstractBlobstore, blobId::UUID, data, ::String) addBlob!(
    store,
    blobId,
    data,
)
@deprecate addBlob!(store::AbstractBlobstore{T}, data::T, ::String) where {T} addBlob!(
    store,
    uuid4(),
    data,
)

@deprecate updateVariable!(args...) mergeVariable!(args...)
@deprecate updateFactor!(args...) mergeFactor!(args...)

@deprecate updateBlobEntry!(args...) mergeBlobentry!(args...)
@deprecate updateGraphBlobEntry!(args...) mergeGraphBlobentry!(args...)
@deprecate updateAgentBlobEntry!(args...) mergeAgentBlobentry!(args...)

@deprecate getBlobStore(args...) getBlobstore(args...)
@deprecate addBlobStore!(args...) addBlobstore!(args...)
@deprecate updateBlobStore!(args...) updateBlobstore!(args...)
@deprecate deleteBlobStore!(args...) deleteBlobstore!(args...)
@deprecate emptyBlobStore!(args...) emptyBlobstore!(args...)
@deprecate listBlobStores(args...) listBlobstores(args...)

@deprecate BlobEntry(args...; kwargs...) Blobentry(args...; kwargs...)
@deprecate getGraphBlobEntry(args...; kwargs...) getGraphBlobentry(args...; kwargs...)
@deprecate getGraphBlobEntries(args...; kwargs...) getGraphBlobentries(args...; kwargs...)
@deprecate addGraphBlobEntry!(args...; kwargs...) addGraphBlobentry!(args...; kwargs...)
@deprecate addGraphBlobEntries!(args...; kwargs...) addGraphBlobentries!(args...; kwargs...)
@deprecate mergeGraphBlobEntry!(args...; kwargs...) mergeGraphBlobentry!(args...; kwargs...)
@deprecate deleteGraphBlobEntry!(args...; kwargs...) deleteGraphBlobentry!(
    args...;
    kwargs...,
)
@deprecate getAgentBlobEntry(args...; kwargs...) getAgentBlobentry(args...; kwargs...)
@deprecate getAgentBlobEntries(args...; kwargs...) getAgentBlobentries(args...; kwargs...)
@deprecate addAgentBlobEntry!(args...; kwargs...) addAgentBlobentry!(args...; kwargs...)
@deprecate addAgentBlobEntries!(args...; kwargs...) addAgentBlobentries!(args...; kwargs...)
@deprecate mergeAgentBlobEntry!(args...; kwargs...) mergeAgentBlobentry!(args...; kwargs...)
@deprecate deleteAgentBlobEntry!(args...; kwargs...) deleteAgentBlobentry!(
    args...;
    kwargs...,
)
@deprecate listGraphBlobEntries(args...; kwargs...) listGraphBlobentries(args...; kwargs...)
@deprecate listAgentBlobEntries(args...; kwargs...) listAgentBlobentries(args...; kwargs...)
@deprecate hasBlobEntry(args...; kwargs...) hasBlobentry(args...; kwargs...)
@deprecate getBlobEntry(args...; kwargs...) getBlobentry(args...; kwargs...)
@deprecate getBlobEntryFirst(args...; kwargs...) getfirstBlobentry(args...; kwargs...)
@deprecate getBlobentry(var::AbstractGraphVariable, blobId::UUID) getfirstBlobentry(
    var::AbstractGraphVariable,
    blobId::UUID,
)
@deprecate addBlobEntry!(args...; kwargs...) addBlobentry!(args...; kwargs...)
@deprecate addBlobEntries!(args...; kwargs...) addBlobentries!(args...; kwargs...)
@deprecate mergeBlobEntry!(args...; kwargs...) mergeBlobentry!(args...; kwargs...)
@deprecate deleteBlobEntry!(args...; kwargs...) deleteBlobentry!(args...; kwargs...)
@deprecate listBlobEntrySequence(args...; kwargs...) listBlobentrySequence(
    args...;
    kwargs...,
)
@deprecate mergeBlobEntries!(args...; kwargs...) mergeBlobentries!(args...; kwargs...)

@deprecate getVariableSolverData(args...; kwargs...) getState(args...; kwargs...)
@deprecate addVariableSolverData!(args...; kwargs...) addState!(args...; kwargs...)
@deprecate deleteVariableSolverData!(args...; kwargs...) deleteState!(args...; kwargs...)
@deprecate listVariableSolverData(args...; kwargs...) listStates(args...; kwargs...)
@deprecate getVariableSolverDataAll(args...; kwargs...) getStates(args...; kwargs...)

@deprecate getSolverData(v::VariableCompute, solveKey::Symbol = :default) getState(
    v,
    solveKey,
)

@deprecate packVariableNodeData(args...; kwargs...) packState(args...; kwargs...)
@deprecate unpackVariableNodeData(args...; kwargs...) unpackState(args...; kwargs...)

export updateVariableSolverData!

#TODO possibly completely deprecated or not exported until update verb is standardized
function updateVariableSolverData!(
    dfg::AbstractDFG,
    variablekey::Symbol,
    vnd::State,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    Base.depwarn(
        "updateVariableSolverData! is deprecated, use mergeState! or copytoState! instead",
        :updateVariableSolverData!,
    )
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    warn_if_absent &&
        !haskey(var.solverDataDict, vnd.solveKey) &&
        @warn "State '$(vnd.solveKey)' does not exist, adding"

    # for InMemoryDFGTypes do memory copy or repointing, for cloud this would be an different kind of update.
    usevnd = vnd # useCopy ? deepcopy(vnd) : vnd
    # should just one, or many pointers be updated?
    useExisting =
        haskey(var.solverDataDict, vnd.solveKey) &&
        isa(var.solverDataDict[vnd.solveKey], State) &&
        length(fields) != 0
    # @error useExisting vnd.solveKey
    if useExisting
        # change multiple pointers inside the VND var.solverDataDict[solvekey]
        for field in fields
            destField = getfield(var.solverDataDict[vnd.solveKey], field)
            srcField = getfield(usevnd, field)
            if isa(destField, Array) && size(destField) == size(srcField)
                # use broadcast (in-place operation)
                destField .= srcField
            else
                # change pointer of destination VND object member
                setfield!(var.solverDataDict[vnd.solveKey], field, srcField)
            end
        end
    else
        # change a single pointer in var.solverDataDict
        var.solverDataDict[vnd.solveKey] = usevnd
    end

    return var.solverDataDict[vnd.solveKey]
end

function updateVariableSolverData!(
    dfg::AbstractDFG,
    variablekey::Symbol,
    vnd::State,
    solveKey::Symbol,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    # TODO not very clean
    if vnd.solveKey != solveKey
        Base.depwarn(
            "updateVariableSolverData with solveKey is deprecated use copytoState! instead.",
            :updateVariableSolverData!,
        )
        usevnd = useCopy ? deepcopy(vnd) : vnd
        usevnd.solveKey = solveKey
        return updateVariableSolverData!(
            dfg,
            variablekey,
            usevnd,
            useCopy,
            fields;
            warn_if_absent = warn_if_absent,
        )
    else
        return updateVariableSolverData!(
            dfg,
            variablekey,
            vnd,
            useCopy,
            fields;
            warn_if_absent = warn_if_absent,
        )
    end
end

function updateVariableSolverData!(
    dfg::AbstractDFG,
    sourceVariable::VariableCompute,
    solveKey::Symbol = :default,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    #
    vnd = getSolverData(sourceVariable, solveKey)
    # toshow = listSolveKeys(sourceVariable) |> collect
    # @info "update DFGVar solveKey" solveKey vnd.solveKey 
    # @show toshow
    @assert solveKey == vnd.solveKey "State's solveKey=:$(vnd.solveKey) does not match requested :$solveKey"
    return updateVariableSolverData!(
        dfg,
        sourceVariable.label,
        vnd,
        useCopy,
        fields;
        warn_if_absent = warn_if_absent,
    )
end

function updateVariableSolverData!(
    dfg::AbstractDFG,
    sourceVariables::Vector{<:VariableCompute},
    solveKey::Symbol = :default,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updateVariableSolverData!(
            dfg,
            var.label,
            getSolverData(var, solveKey),
            useCopy,
            fields;
            warn_if_absent = warn_if_absent,
        )
    end
end

## factor refactor deprecations
Base.@kwdef mutable struct GenericFunctionNodeData{
    T <: Union{<:AbstractPackedObservation, <:AbstractObservation, <:FactorCache},
}
    eliminated::Bool = false
    potentialused::Bool = false
    edgeIDs::Vector{Int} = Int[]
    fnc::T
    multihypo::Vector{Float64} = Float64[] # TODO re-evaluate after refactoring w #477
    certainhypo::Vector{Int} = Int[]
    nullhypo::Float64 = 0.0
    solveInProgress::Int = 0
    inflation::Float64 = 0.0
end

function FactorCompute(
    label::Symbol,
    timestamp::Union{DateTime, ZonedDateTime},
    nstime::Nanosecond,
    tags::Set{Symbol},
    solverData::GenericFunctionNodeData,
    solvable::Int,
    variableOrder::Union{Vector{Symbol}, Tuple};
    observation = getFactorType(solverData),
    state::FactorState = FactorState(),
    solvercache::Base.RefValue{<:FactorCache} = Ref{FactorCache}(),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
)
    error(
        "This constructor is deprecated, use FactorCompute(label, variableOrder, solverData; ...) instead",
    )
    return FactorCompute(
        id,
        label,
        tags,
        Tuple(variableOrder),
        timestamp,
        nstime,
        Ref(solverData),
        Ref(solvable),
        smallData,
        observation,
        state,
        solvercache,
    )
end

export getSolverData, setSolverData!

function getSolverData(f::FactorCompute)
    return error(
        "getSolverData(f::FactorCompute) is obsolete, use getFactorState, getObservation, or getCache instead",
    )
end

function setSolverData!(f::FactorCompute, data::GenericFunctionNodeData)
    return error(
        "setSolverData!(f::FactorCompute, data::GenericFunctionNodeData) is obsolete, use setState!, or setCache! instead",
    )
end

@deprecate unpackFactor(dfg::AbstractDFG, factor::FactorDFG; skipVersionCheck::Bool = false) unpackFactor(
    factor;
    skipVersionCheck,
)

@deprecate rebuildFactorMetadata!(args...; kwargs...) rebuildFactorCache!(
    args...;
    kwargs...,
)

export reconstFactorData
function reconstFactorData end

function decodePackedType(
    dfg::AbstractDFG,
    varOrder::AbstractVector{Symbol},
    ::Type{T},
    packeddata::GenericFunctionNodeData{PT},
) where {T <: FactorCache, PT}
    error("decodePackedType is obsolete")
    #
    # TODO, to solve IIF 1424
    # variables = map(lb->getVariable(dfg, lb), varOrder)

    # Also look at parentmodule
    usrtyp = convertStructType(PT)
    fulltype = DFG.FunctionNodeData{T{usrtyp}}
    factordata = reconstFactorData(dfg, varOrder, fulltype, packeddata)
    return factordata
end

export _packSolverData
function _packSolverData(f::FactorCompute, fnctype::AbstractObservation)
    #
    error("_packSolverData is deprecated, use seperate packing of observation #TODO")
    packtype = convertPackedType(fnctype)
    try
        packed = convert(PackedFunctionNodeData{packtype}, getSolverData(f)) #TODO getSolverData 
        packedJson = packed
        return packedJson
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end
end

export GenericFunctionNodeData, PackedFunctionNodeData, FunctionNodeData

const PackedFunctionNodeData{T} =
    GenericFunctionNodeData{T} where {T <: AbstractPackedObservation}
function PackedFunctionNodeData(args...; kw...)
    error("PackedFunctionNodeData is obsolete")
    return PackedFunctionNodeData{typeof(args[4])}(args...; kw...)
end

const FunctionNodeData{T} =
    GenericFunctionNodeData{T} where {T <: Union{<:AbstractObservation, <:FactorCache}}
FunctionNodeData(args...; kw...) = FunctionNodeData{typeof(args[4])}(args...; kw...)

# this is the GenericFunctionNodeData for packed types
#TODO deprecate FactorData in favor of FactorState (with no more distinction between packed and compute)
const FactorData = PackedFunctionNodeData{AbstractPackedObservation}

function FactorCompute(
    label::Symbol,
    variableOrder::Union{Vector{Symbol}, Tuple},
    solverData::GenericFunctionNodeData;
    tags::Set{Symbol} = Set{Symbol}(),
    timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
    solvable::Int = 1,
    nstime::Nanosecond = Nanosecond(0),
    id::Union{UUID, Nothing} = nothing,
    smallData::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}(),
)
    Base.depwarn(
        "`FactorCompute` constructor with `GenericFunctionNodeData` is deprecated. observation, state, and solvercache should be provided explicitly.",
        :FactorCompute,
    )
    observation = getFactorType(solverData)
    state = FactorState(
        solverData.eliminated,
        solverData.potentialused,
        solverData.multihypo,
        solverData.certainhypo,
        solverData.nullhypo,
        solverData.solveInProgress,
        solverData.inflation,
    )

    if solverData.fnc isa FactorCache
        solvercache = solverData.fnc
    else
        solvercache = nothing
    end

    return FactorCompute(
        label,
        Tuple(variableOrder),
        observation,
        state,
        solvercache;
        id,
        timestamp,
        nstime,
        tags,
        smallData,
        solvable,
    )
end

# Deprecated check usefull? # packedFnc = fncStringToData(factor.fnctype, factor.data)
# Deprecated check usefull? # decodeType = getFactorOperationalMemoryType(dfg)
# Deprecated check usefull? # fullFactorData = decodePackedType(dfg, factor._variableOrderSymbols, decodeType, packedFnc)
function fncStringToData(args...; kwargs...)
    @warn "fncStringToData is obsolete, called with" args kwargs
    return error("fncStringToData is obsolete.")
end

#TODO make sure getFactorOperationalMemoryType is obsolete
function getFactorOperationalMemoryType(dummy)
    return error(
        "Please extend your workspace with function getFactorOperationalMemoryType(<:AbstractParams) for your usecase, e.g. IncrementalInference uses `CommonConvWrapper <: FactorCache`",
    )
end
function getFactorOperationalMemoryType(dfg::AbstractDFG)
    return getFactorOperationalMemoryType(getSolverParams(dfg))
end

function typeModuleName(variableType::StateType)
    Base.depwarn("typeModuleName is obsolete", :typeModuleName)
    io = IOBuffer()
    ioc = IOContext(io, :module => DistributedFactorGraphs)
    show(ioc, typeof(variableType))
    return String(take!(io))
end

typeModuleName(varT::Type{<:StateType}) = typeModuleName(varT())

## ================================================================================
## Deprecated in v0.25
##=================================================================================
@deprecate getSessionBlobEntry(args...) getGraphBlobEntry(args...)
@deprecate getSessionBlobEntries(args...) getGraphBlobEntries(args...)
@deprecate addSessionBlobEntry!(args...) addGraphBlobEntry!(args...)
@deprecate addSessionBlobEntries!(args...) addGraphBlobEntries!(args...)
@deprecate updateSessionBlobEntry!(args...) updateGraphBlobEntry!(args...)
@deprecate deleteSessionBlobEntry!(args...) deleteGraphBlobEntry!(args...)
@deprecate getRobotBlobEntry(args...) getAgentBlobEntry(args...)
@deprecate getRobotBlobEntries(args...) getAgentBlobEntries(args...)
@deprecate addRobotBlobEntry!(args...) addAgentBlobEntry!(args...)
@deprecate addRobotBlobEntries!(args...) addAgentBlobEntries!(args...)
@deprecate updateRobotBlobEntry!(args...) updateAgentBlobEntry!(args...)
@deprecate deleteRobotBlobEntry!(args...) deleteAgentBlobEntry!(args...)
@deprecate getUserBlobEntry(args...) getAgentBlobEntry(args...)
@deprecate getUserBlobEntries(args...) getAgentBlobEntries(args...)
@deprecate addUserBlobEntry!(args...) addAgentBlobEntry!(args...)
@deprecate addUserBlobEntries!(args...) addAgentBlobEntries!(args...)
@deprecate updateUserBlobEntry!(args...) updateAgentBlobEntry!(args...)
@deprecate deleteUserBlobEntry!(args...) deleteAgentBlobEntry!(args...)
@deprecate listSessionBlobEntries(args...) listGraphBlobEntries(args...)
@deprecate listRobotBlobEntries(args...) listAgentBlobEntries(args...)
@deprecate listUserBlobEntries(args...) listAgentBlobEntries(args...)

@deprecate getUserData(args...) getAgentMetadata(args...)
@deprecate getRobotData(args...) getAgentMetadata(args...)
@deprecate getSessionData(args...) getGraphMetadata(args...)

@deprecate setUserData!(args...) setAgentMetadata!(args...)
@deprecate setRobotData!(args...) setAgentMetadata!(args...)
@deprecate setSessionData!(args...) setGraphMetadata!(args...)

@deprecate getUserLabel(dfg) getAgentLabel(dfg)
@deprecate getRobotLabel(dfg) getAgentLabel(dfg)
@deprecate getSessionLabel(dfg) getGraphLabel(dfg)

export DFGSummary
DFGSummary(args) = error("DFGSummary is deprecated")
@deprecate getSummary(dfg::AbstractDFG) getSummaryGraph(dfg)

@deprecate getKey(store::AbstractBlobstore) getLabel(store)
