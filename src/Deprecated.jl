## ================================================================================
## Deprecated in v0.27
##=================================================================================
export AbstractFactor
const AbstractFactor = AbstractFactorObservation

export AbstractPackedFactor
const AbstractPackedFactor = AbstractPackedFactorObservation

export FactorOperationalMemory
const FactorOperationalMemory = FactorSolverCache

export VariableNodeData
const VariableNodeData = VariableState

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
@deprecate getBlobEntryFirst(args...; kwargs...) getBlobentryFirst(args...; kwargs...)
@deprecate addBlobEntry!(args...; kwargs...) addBlobentry!(args...; kwargs...)
@deprecate addBlobEntries!(args...; kwargs...) addBlobentries!(args...; kwargs...)
@deprecate mergeBlobEntry!(args...; kwargs...) mergeBlobentry!(args...; kwargs...)
@deprecate deleteBlobEntry!(args...; kwargs...) deleteBlobentry!(args...; kwargs...)
@deprecate listBlobEntrySequence(args...; kwargs...) listBlobentrySequence(
    args...;
    kwargs...,
)
@deprecate mergeBlobEntries!(args...; kwargs...) mergeBlobentries!(args...; kwargs...)

@deprecate getVariableSolverData(args...; kwargs...) getVariableState(args...; kwargs...)
@deprecate addVariableSolverData!(args...; kwargs...) addVariableState!(args...; kwargs...)
@deprecate deleteVariableSolverData!(args...; kwargs...) deleteVariableState!(
    args...;
    kwargs...,
)
@deprecate listVariableSolverData(args...; kwargs...) listVariableStates(args...; kwargs...)
@deprecate getVariableSolverDataAll(args...; kwargs...) getVariableStates(
    args...;
    kwargs...,
)

@deprecate getSolverData(v::VariableCompute, solveKey::Symbol = :default) getVariableState(
    v,
    solveKey,
)

@deprecate packVariableNodeData(args...; kwargs...) packVariableState(args...; kwargs...)
@deprecate unpackVariableNodeData(args...; kwargs...) unpackVariableState(
    args...;
    kwargs...,
)

export updateVariableSolverData!

#TODO possibly completely deprecated or not exported until update verb is standardized
function updateVariableSolverData!(
    dfg::AbstractDFG,
    variablekey::Symbol,
    vnd::VariableState,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    Base.depwarn(
        "updateVariableSolverData! is deprecated, use mergeVariableState! or copytoVariableState! instead",
        :updateVariableSolverData!,
    )
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    warn_if_absent &&
        !haskey(var.solverDataDict, vnd.solveKey) &&
        @warn "VariableState '$(vnd.solveKey)' does not exist, adding"

    # for InMemoryDFGTypes do memory copy or repointing, for cloud this would be an different kind of update.
    usevnd = vnd # useCopy ? deepcopy(vnd) : vnd
    # should just one, or many pointers be updated?
    useExisting =
        haskey(var.solverDataDict, vnd.solveKey) &&
        isa(var.solverDataDict[vnd.solveKey], VariableState) &&
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
    vnd::VariableState,
    solveKey::Symbol,
    useCopy::Bool = false,
    fields::Vector{Symbol} = Symbol[];
    warn_if_absent::Bool = true,
)
    # TODO not very clean
    if vnd.solveKey != solveKey
        Base.depwarn(
            "updateVariableSolverData with solveKey is deprecated use copytoVariableState! instead.",
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
    @assert solveKey == vnd.solveKey "VariableState's solveKey=:$(vnd.solveKey) does not match requested :$solveKey"
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
    T <: Union{
        <:AbstractPackedFactorObservation,
        <:AbstractFactorObservation,
        <:FactorSolverCache,
    },
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
    solvercache::Base.RefValue{<:FactorSolverCache} = Ref{FactorSolverCache}(),
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
) where {T <: FactorSolverCache, PT}
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
function _packSolverData(f::FactorCompute, fnctype::AbstractFactorObservation)
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
    GenericFunctionNodeData{T} where {T <: AbstractPackedFactorObservation}
function PackedFunctionNodeData(args...; kw...)
    error("PackedFunctionNodeData is obsolete")
    return PackedFunctionNodeData{typeof(args[4])}(args...; kw...)
end

const FunctionNodeData{T} = GenericFunctionNodeData{
    T,
} where {T <: Union{<:AbstractFactorObservation, <:FactorSolverCache}}
FunctionNodeData(args...; kw...) = FunctionNodeData{typeof(args[4])}(args...; kw...)

# this is the GenericFunctionNodeData for packed types
#TODO deprecate FactorData in favor of FactorState (with no more distinction between packed and compute)
const FactorData = PackedFunctionNodeData{AbstractPackedFactorObservation}

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

    if solverData.fnc isa FactorSolverCache
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
