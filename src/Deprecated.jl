## ================================================================================
## Deprecated in v0.29
##=================================================================================
export FactorCompute
const FactorCompute = FactorDFG

const MetadataTypes = Union{
    Int,
    Float64,
    String,
    Bool,
    Vector{Int},
    Vector{Float64},
    Vector{String},
    Vector{Bool},
}

function getHash(entry::Blobentry)
    return error(
        "Blobentry field :hash has been deprecated; use :crchash or :shahash instead",
    )
end

function getMetadata(node)
    return error(
        "getMetadata(node::$(typeof(node))) is deprecated; metadata is now stored in bloblets. Use getBloblets instead.",
    )
    # return JSON.parse(base64decode(f.metadata), Dict{Symbol, MetadataTypes})
end

# getTimestamp

# setTimestamp is deprecated for now we can implement setTimestamp!(dfg, lbl, ts) later.
function setTimestamp(args...; kwargs...)
    return error("setTimestamp is obsolete, use addVariable!(..., timestamp=...) instead.")
end
function setTimestamp!(args...; kwargs...)
    return error(
        "setTimestamp! is not implemented, use addVariable!(..., timestamp=...) instead.",
    )
end

##------------------------------------------------------------------------------
## solveInProgress
##------------------------------------------------------------------------------

# getSolveInProgress and isSolveInProgress is deprecated for DFG v1.0, we can bring it back fully implemented when needed.
# """
#     $SIGNATURES

# Which variables or factors are currently being used by an active solver.  Useful for ensuring atomic transactions.

# DevNotes:
# - Will be renamed to `data.solveinprogress` which will be in VND, not AbstractGraphNode -- see DFG #201

# Related

# isSolvable
# """
function getSolveInProgress(
    var::Union{VariableDFG, FactorCompute},
    solveKey::Symbol = :default,
)
    # Variable
    if var isa VariableDFG
        if haskey(refStates(var), solveKey)
            return refStates(var)[solveKey].solveInProgress
        else
            return 0
        end
    end
    # Factor
    return getFactorState(var).solveInProgress
end

#TODO missing set solveInProgress and graph level accessor

function isSolveInProgress(
    node::Union{VariableDFG, FactorCompute},
    solvekey::Symbol = :default,
)
    return getSolveInProgress(node, solvekey) > 0
end

function getTypeFromSerializationModule(::AbstractString)
    return error(
        "getTypeFromSerializationModule is obsolete, use DFG.parseVariableType or IIF.getTypeFromSerializationModule.",
    )
end

## Version checking
#NOTE fixed really bad function but kept similar as fallback #TODO upgrade to use pkgversion(m::Module)
function _getDFGVersion()
    return pkgversion(DistributedFactorGraphs)
end

function _versionCheck(node::Union{<:VariableDFG, <:FactorDFG})
    if node._version.minor < _getDFGVersion().minor
        @warn "This data was serialized using DFG $(node._version) but you have $(_getDFGVersion()) installed, there may be deserialization issues." maxlog =
            10
    end
end

refMetadata(node) = node.metadata

@deprecate packDistribution(d) pack(d)
@deprecate unpackDistribution(d) unpack(d)

function setDescription!(args...)
    return error("setDescription! was removed and may be implemented later.")
end

# TODO find replacement.
function _getDuplicatedEmptyDFG(
    dfg::GraphsDFG{P, V, F},
) where {P <: AbstractDFGParams, V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    Base.depwarn("_getDuplicatedEmptyDFG is deprecated.", :_getDuplicatedEmptyDFG)
    newDfg = GraphsDFG{P, V, F}(;
        agentLabel = getAgentLabel(dfg),
        graphLabel = getGraphLabel(dfg),
        solverParams = deepcopy(dfg.solverParams),
    )
    # DFG.setDescription!(newDfg, "(Copy of) $(DFG.getDescription(dfg))")
    return newDfg
end

#Type gets confused with returning a DataType, Kind is an instance of StateType
@deprecate getVariableType(args...) getStateKind(args...)

function getVariableTypeName(v::VariableSummary)
    Base.depwarn("getVariableTypeName is deprecated.", :getVariableTypeName)
    return v.statetype
end

function getMetadata(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getVariable(dfg, label).smallData[key]
end

function addMetadata!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:MetadataTypes})
    v = getVariable(dfg, label)
    haskey(v.smallData, pair.first) && throw(LabelExistsError("Metadata", pair.first))
    push!(v.smallData, pair)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

function updateMetadata!(
    dfg::AbstractDFG,
    label::Symbol,
    pair::Pair{Symbol, <:MetadataTypes};
    warn_if_absent::Bool = true,
)
    v = getVariable(dfg, label)
    warn_if_absent &&
        !haskey(v.smallData, pair.first) &&
        @warn("$(pair.first) does not exist, adding.")
    push!(v.smallData, pair)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

function deleteMetadata!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    v = getVariable(dfg, label)
    pop!(v.smallData, key)
    mergeVariable!(dfg, v)
    return 1
end

function listMetadata(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    return collect(keys(v.smallData)) #or pair TODO
end

function emptyMetadata!(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    empty!(v.smallData)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

# """
# $(SIGNATURES)
# Function to generate source string - agentLabel|graphLabel|varLabel
# """
function buildSourceString(dfg::AbstractDFG, label::Symbol)
    return "$(getAgentLabel(dfg))|$(getGraphLabel(dfg))|$label"
end

getAgentMetadata(args...) = error("getAgentMetadata is obsolete, use Bloblets instead.")
setAgentMetadata!(args...) = error("setAgentMetadata! is obsolete, use Bloblets instead.")
getGraphMetadata(args...) = error("getGraphMetadata is obsolete, use Bloblets instead.")
setGraphMetadata!(args...) = error("setGraphMetadata! is obsolete, use Bloblets instead.")
function updateAgentMetadata!(args...)
    return error("updateAgentMetadata! is obsolete, use Bloblets instead.")
end
function updateGraphMetadata!(args...)
    return error("updateGraphMetadata! is obsolete, use Bloblets instead.")
end
function deleteAgentMetadata!(args...)
    return error("deleteAgentMetadata! is obsolete, use Bloblets instead.")
end
function deleteGraphMetadata!(args...)
    return error("deleteGraphMetadata! is obsolete, use Bloblets instead.")
end
function emptyAgentMetadata!(args...)
    return error("emptyAgentMetadata! is obsolete, use Bloblets instead.")
end
function emptyGraphMetadata!(args...)
    return error("emptyGraphMetadata! is obsolete, use Bloblets instead.")
end

#TODO deprecate AbstractPackedObservation
abstract type AbstractPackedObservation end
const PackedObservation = AbstractPackedObservation
#TODO deprecate AbstractPackedBelief
abstract type AbstractPackedBelief end
const PackedBelief = AbstractPackedBelief

#TODO maybe replace with `listVariablesAddOrder` or using sort on `listVariables`
getAddHistory(dfg::AbstractDFG) = error("getAddHistory is deprecated.")
getAddHistory(dfg::GraphsDFG) = listVariables(dfg) #default listVariables on GraphsDFG is ordered

## Utility functions for getting type names and modules (from IncrementalInference)
_getmodule(t::T) where {T} = T.name.module
_getname(t::T) where {T} = T.name.name

function convertPackedType(t::Union{T, Type{T}}) where {T <: AbstractObservation}
    return getfield(_getmodule(t), Symbol("Packed$(_getname(t))"))
end
function convertStructType(::Type{PT}) where {PT <: AbstractPackedObservation}
    # see #668 for expanded reasoning.  PT may be ::UnionAll if the type is of template type.
    ptt = PT isa DataType ? PT.name.name : PT
    moduleName = PT isa DataType ? PT.name.module : Main
    symbolName = Symbol(string(ptt)[7:end])
    return getfield(moduleName, symbolName)
end

@deprecate getBlobentry(fg::AbstractDFG, varlabel::Symbol, key::Symbol) getVariableBlobentry(
    fg,
    varlabel,
    key,
)
@deprecate getBlobentries(fg::AbstractDFG, varlabel::Symbol; kwargs...) getVariableBlobentries(
    fg,
    varlabel;
    kwargs...,
)
@deprecate addBlobentry!(fg::AbstractDFG, varlabel::Symbol, entry::Blobentry) addVariableBlobentry!(
    fg,
    varlabel,
    entry,
)
@deprecate mergeBlobentry!(fg::AbstractDFG, varlabel::Symbol, entry::Blobentry) mergeVariableBlobentry!(
    fg,
    varlabel,
    entry,
)
@deprecate deleteBlobentry!(fg::AbstractDFG, varlabel::Symbol, key::Symbol) deleteVariableBlobentry!(
    fg,
    varlabel,
    key,
)
@deprecate listBlobentries(fg::AbstractDFG, varlabel::Symbol) listVariableBlobentries(
    fg,
    varlabel,
)

# """
#     $SIGNATURES

# Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
# """
function hasTagsNeighbors(
    dfg::AbstractDFG,
    node_label::Symbol,
    tags::Vector{Symbol};
    matchAll::Bool = true,
)
    #
    Base.depwarn(
        "hasTagsNeighbors is deprecated, use listNeighbors with tagsFilter instead",
        :hasTagsNeighbors,
    )
    # assume only variables or factors are neighbors
    alltags = union((listNeighbors(dfg, node_label) .|> x -> listTags(dfg, x))...)
    return length(filter(x -> x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

#Obsolete PPEs
abstract type AbstractPointParametricEst end
function _ppe_obsolete()
    return error(
        "PPEs are obsolete and will be replaced soon (IIF.calcMeanMaxSuggested can be used in some cases), see #1133.",
    )
end
getPPEMax(args...) = _ppe_obsolete()
getPPEMean(args...) = _ppe_obsolete()
getPPESuggested(args...) = _ppe_obsolete()
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = _ppe_obsolete()
getPPE(args...) = _ppe_obsolete()
addPPE!(args...) = _ppe_obsolete()
addPPEs!(args...) = _ppe_obsolete()
updatePPE!(args...) = _ppe_obsolete()
deletePPE!(args...) = _ppe_obsolete()
listPPEs(args...) = _ppe_obsolete()
mergePPEs!(args...) = _ppe_obsolete()
getPPEDict(args...) = _ppe_obsolete()
getPPEs(args...) = _ppe_obsolete()
getVariablePPEDict(args...) = _ppe_obsolete()
getVariablePPE(args...) = _ppe_obsolete()
MeanMaxPPE(args...; kwargs...) = _ppe_obsolete()
getEstimateFields(args...) = _ppe_obsolete()

function getFactorState(args...)
    return error(
        "getFactorState is deprecated, use DFG.getRecipehyper or DFG.getRecipestate instead.",
    )
end

function setTags!(node, tags::Union{Vector{Symbol}, Set{Symbol}})
    Base.depwarn("setTags! is deprecated, use mergeTags! or addTags! instead.", :setTags!)
    node.tags !== tags && empty!(node.tags)
    return union!(node.tags, tags)
end

## ================================================================================
## Deprecated in v0.28
##=================================================================================
abstract type AbstractRelativeMinimize <: RelativeObservation end
abstract type AbstractManifoldMinimize <: RelativeObservation end

const SkeletonDFGVariable = VariableSkeleton
const DFGVariableSummary = VariableSummary
const PackedVariable = VariableDFG
const Variable = VariableDFG
const DFGVariable = VariableCompute
const SkeletonDFGFactor = FactorSkeleton
const DFGFactorSummary = FactorSummary
const DFGFactor = FactorCompute
const PackedFactor = FactorDFG
const Factor = FactorDFG
const AbstractPrior = PriorObservation
const AbstractRelative = RelativeObservation
const AbstractParams = AbstractDFGParams
const InferenceVariable = StateType{Any}
const InferenceType = AbstractPackedObservation
const PackedSamplableBelief = PackedBelief
const getVariableState = getState
const addVariableState! = addState!
const mergeVariableState! = mergeState!
const deleteVariableState! = deleteState!
const listVariableStates = listStates
const VariableState = State
const VariableStateType = StateType
const copytoVariableState! = copytoState!

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
    return v.states[key] = data
end

@deprecate mergeVariableSolverData!(args...; kwargs...) mergeState!(args...; kwargs...)

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
        varType = typeof(getStateKind(v)) |> nameof
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

#TODO make a replacement if used a lot... not a good function, as it's not complete.
# """
#     $(SIGNATURES)
# Convenience function to get all the metadata of a DFG
# """
function getDFGInfo(dfg::AbstractDFG)
    Base.depwarn("getDFGInfo is deprecated and needs a replacement.", :getDFGInfo)
    return (
        graphDescription = getDescription(dfg),
        agentLabel = getAgentLabel(dfg),
        graphLabel = getGraphLabel(dfg),
        # agentBloblets = getAgentBloblets(dfg),
        # graphBloblets = getGraphBloblets(dfg),
        solverParams = getSolverParams(dfg),
    )
end

function listSolveKeys(
    variable::VariableCompute,
    filterSolveKeys::Union{Regex, Nothing} = nothing,
    skeys = Set{Symbol}(),
)
    Base.depwarn("listSolveKeys is deprecated, use listStates instead.", :listSolveKeys)
    #
    for ky in keys(refStates(variable))
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
    for vs in varList  #, ky in keys(refStates(getVariable(dfg, vs)))
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
# Add a blob entry into the destination variable which already exists in a source variable.
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

function getBlobentriesVariables(
    dfg::AbstractDFG,
    bLblPattern::Regex;
    varList::AbstractVector{Symbol} = sort(listVariables(dfg); lt = natural_lt),
    dropEmpties::Bool = false,
)
    Base.depwarn(
        "getBlobentriesVariables is deprecated, use gatherBlobentries instead.",
        :getBlobentriesVariables,
    )
    RETLIST = Vector{Vector{Blobentry}}()
    @showprogress "Get entries matching $bLblPattern" for vl in varList
        bes = filter(s -> occursin(bLblPattern, string(s.label)), listBlobentries(dfg, vl))
        # only push to list if there are entries on this variable
        (!dropEmpties || 0 < length(bes)) ? nothing : continue
        push!(RETLIST, bes)
    end

    return RETLIST
end

function getBlobentries(dfg::AbstractDFG, label::Symbol, regex::Regex)
    Base.depwarn(
        "getBlobentries(dfg, label, ::Regex) is deprecated, use getBlobentries(dfg, label; labelFilter=contains(regex)) instead.",
        :getBlobentries,
    )
    return entries = getBlobentries(dfg, label; labelFilter = contains(regex))
end

function getBlobentries(dfg::AbstractDFG, label::Symbol, skey::AbstractString)
    Base.depwarn(
        "getBlobentries(dfg, label, regex::AbstractString) is deprecated, use getBlobentries(dfg, label; labelFilter=contains(regex)) instead.",
        :getBlobentries,
    )
    return getBlobentries(dfg, label, Regex(string(skey)))
end

function getfirstBlobentry(var::AbstractGraphVariable, blobId::UUID)
    Base.depwarn(
        "getfirstBlobentry(var, blobId) is deprecated, use getfirstBlobentry(var; blobidFilter = ==(string(blobId))) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(var; blobidFilter = ==(string(blobId)))
end

function getfirstBlobentry(dfg::AbstractDFG, label::Symbol, blobId::UUID)
    Base.depwarn(
        "getfirstBlobentry(dfg, label, blobId) is deprecated, use getfirstBlobentry(dfg, label; blobidFilter = ==(string(blobId))) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(dfg, label; blobidFilter = ==(string(blobId)))
end

function getfirstBlobentry(var::AbstractGraphVariable, key::Regex)
    Base.depwarn(
        "getfirstBlobentry(var, key::Regex) is deprecated, use getfirstBlobentry(var; labelFilter=contains(key)) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(var; labelFilter = contains(key))
end

function getfirstBlobentry(dfg::AbstractDFG, label::Symbol, key::Regex)
    Base.depwarn(
        "getfirstBlobentry(dfg, label, key::Regex) is deprecated, use getfirstBlobentry(dfg, label; labelFilter=contains(key)) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(dfg, label; labelFilter = contains(key))
end

macro defVariable(args...)
    return esc(:(DFG.@defStateType $(args...)))
end

@deprecate getFactorFunction(args...) getObservation(args...)
@deprecate getFactorType(args...) getObservation(args...)

setMetadata!(args...) = error("setMetadata is obsolete, use Bloblets instead.")

updateData!(args...; kwargs...) = error("updateData! is obsolete.")
updateBlob!(args...; kwargs...) = error("updateBlob! is obsolete.")
getData(args...; kwargs...) = error("getData is obsolete, use loadBlob_Variable")
addData!(args...; kwargs...) = error("addData! is obsolete, use saveBlob_Variable!")
deleteData!(args...; kwargs...) = error("deleteData! is obsolete, use deleteBlob_Variable!")
