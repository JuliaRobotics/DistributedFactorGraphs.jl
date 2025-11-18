## ================================================================================
## Deprecated in v0.29
##=================================================================================
export FactorCompute
const FactorCompute = FactorDFG

"""
Types valid for small data.
"""
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
    var::Union{VariableCompute, FactorCompute},
    solveKey::Symbol = :default,
)
    # Variable
    if var isa VariableCompute
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
    node::Union{VariableCompute, FactorCompute},
    solvekey::Symbol = :default,
)
    return getSolveInProgress(node, solvekey) > 0
end

"""
    $(SIGNATURES)
Get a type from the serialization module.
"""
function getTypeFromSerializationModule(_typeString::AbstractString)
    @debug "DFG converting type string to Julia type" _typeString
    try
        # split the type at last `.`
        split_st = split(_typeString, r"\.(?!.*\.)")
        #if module is specified look for the module in main, otherwise use Main        
        if length(split_st) == 2
            m = getfield(Main, Symbol(split_st[1]))
        else
            m = Main
        end
        noparams = split(split_st[end], r"{")
        ret = if 1 < length(noparams)
            # fix #671, but does not work with specific module yet
            bidx = findfirst(r"{", split_st[end])[1]
            error("getTypeFromSerializationModule eval obsolete")
            # Core.eval(m, Base.Meta.parse("$(noparams[1])$(split_st[end][bidx:end])"))
        else
            getfield(m, Symbol(split_st[end]))
        end

        return ret

    catch ex
        @error "Unable to deserialize type $(_typeString)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    return nothing
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

function packDistribution end
function unpackDistribution end

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

#TODO is Type correct
@deprecate getVariableType(args...) getStateType(args...)

function getVariableTypeName(v::VariableSummary)
    Base.depwarn("getVariableTypeName is deprecated.", :getVariableTypeName)
    return v.statetype
end

"""
    $(SIGNATURES)
Get the Metadata entry at `key` for variable `label` in `dfg`
"""
function getMetadata(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getVariable(dfg, label).smallData[key]
end

"""
    $(SIGNATURES)
Add a Metadata pair `key=>value` for variable `label` in `dfg`
"""
function addMetadata!(dfg::AbstractDFG, label::Symbol, pair::Pair{Symbol, <:MetadataTypes})
    v = getVariable(dfg, label)
    haskey(v.smallData, pair.first) && throw(LabelExistsError("Metadata", pair.first))
    push!(v.smallData, pair)
    mergeVariable!(dfg, v)
    return v.smallData #or pair TODO
end

"""
    $(SIGNATURES)
Update a Metadata pair `key=>value` for variable `label` in `dfg`
"""
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

"""
    $(SIGNATURES)
Delete a Metadata entry at `key` for variable `label` in `dfg`
"""
function deleteMetadata!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    v = getVariable(dfg, label)
    pop!(v.smallData, key)
    mergeVariable!(dfg, v)
    return 1
end

"""
    $(SIGNATURES)
List all Metadata keys for a variable `label` in `dfg`
"""
function listMetadata(dfg::AbstractDFG, label::Symbol)
    v = getVariable(dfg, label)
    return collect(keys(v.smallData)) #or pair TODO
end

"""
    $(SIGNATURES)
Empty all Metadata from variable `label` in `dfg`
"""
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
updateAgentMetadata!(args...) = error("updateAgentMetadata! is obsolete, use Bloblets instead.")
updateGraphMetadata!(args...) = error("updateGraphMetadata! is obsolete, use Bloblets instead.")
deleteAgentMetadata!(args...) = error("deleteAgentMetadata! is obsolete, use Bloblets instead.")
deleteGraphMetadata!(args...) = error("deleteGraphMetadata! is obsolete, use Bloblets instead.")
emptyAgentMetadata!(args...) = error("emptyAgentMetadata! is obsolete, use Bloblets instead.")
emptyGraphMetadata!(args...) = error("emptyGraphMetadata! is obsolete, use Bloblets instead.")

#TODO deprecate AbstractPackedObservation
abstract type AbstractPackedObservation end
const PackedObservation = AbstractPackedObservation
#TODO deprecate AbstractPackedBelief
abstract type AbstractPackedBelief end
const PackedBelief = AbstractPackedBelief

getAddHistory(dfg::AbstractDFG) = error("getAddHistory is obsolete.")

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

@deprecate getBlobentry(fg::AbstractDFG, varlabel::Symbol, key::Symbol) getVariableBlobentry(fg, varlabel, key)
@deprecate getBlobentries(fg::AbstractDFG, varlabel::Symbol; kwargs...) getVariableBlobentries(fg, varlabel; kwargs...)
@deprecate addBlobentry!(fg::AbstractDFG, varlabel::Symbol, entry::Blobentry) addVariableBlobentry!(fg, varlabel, entry)
@deprecate mergeBlobentry!(fg::AbstractDFG, varlabel::Symbol, entry::Blobentry) mergeVariableBlobentry!(fg, varlabel, entry)
@deprecate deleteBlobentry!(fg::AbstractDFG, varlabel::Symbol, key::Symbol) deleteVariableBlobentry!(fg, varlabel, key)
@deprecate listBlobentries(fg::AbstractDFG, varlabel::Symbol) listVariableBlobentries(fg, varlabel)

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
const SmallDataTypes = MetadataTypes
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

# """
#     $TYPEDSIGNATURES
# List all the solvekeys used amongst all variables in the distributed factor graph object.

# Related

# [`listSolveKeys`](@ref), [`refStates`](@ref), [`listVariables`](@ref)
# """
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

# """
#     $(SIGNATURES)

# Get all blob entries matching a Regex pattern over variables

# Notes
# - Use `dropEmpties=true` to not include empty lists in result.
# - Use keyword `varList` for which variables to search through.
# """
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

function getBlobentries(
    dfg::AbstractDFG,
    label::Symbol,
    skey::Union{Symbol, <:AbstractString},
)
    Base.depwarn(
        "getBlobentries(dfg, label, ::Union{Symbol, <:AbstractString}) is deprecated, use getBlobentries(dfg, label; labelFilter=contains(regex)) instead.",
        :getBlobentries,
    )
    return getBlobentries(dfg, label, Regex(string(skey)))
end

function getfirstBlobentry(var::AbstractGraphVariable, blobId::UUID)
    Base.depwarn(
        "getfirstBlobentry(var, blobId) is deprecated, use getfirstBlobentry(var; blobIdFilter = ==(string(blobId))) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(var; blobIdFilter = ==(string(blobId)))
end

function getfirstBlobentry(dfg::AbstractDFG, label::Symbol, blobId::UUID)
    Base.depwarn(
        "getfirstBlobentry(dfg, label, blobId) is deprecated, use getfirstBlobentry(dfg, label; blobIdFilter = ==(string(blobId))) instead.",
        :getfirstBlobentry,
    )
    return getfirstBlobentry(dfg, label; blobIdFilter = ==(string(blobId)))
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

function updateData!(
    dfg::AbstractDFG,
    label::Symbol,
    entry::Blobentry,
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool = true,
)
    @warn "updateData! is obsolete."
    checkhash && assertHash(entry, blob; hashfunction)
    # order of ops with unknown new blobId not tested
    mergeBlobentry!(dfg, label, entry)
    db = updateBlob!(dfg, de, blob)
    return 2
end

function updateData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    label::Symbol,
    entry::Blobentry,
    blob::Vector{UInt8};
    hashfunction = sha256,
)
    @warn "updateData! is obsolete."
    # Recalculate the hash - NOTE Assuming that this is going to be a Blobentry. TBD.
    # order of operations with unknown new blobId not tested
    newEntry = Blobentry(
        entry; # and kwargs to override new values
        blobstore = getLabel(blobstore),
        hash = string(bytes2hex(hashfunction(blob))),
        origin = buildSourceString(dfg, label),
        _version = _getDFGVersion(),
    )
    mergeBlobentry!(dfg, label, newEntry)
    updateBlob!(blobstore, newEntry, blob)
    return 2
end

function updateBlob!(store::RowBlobstore{T}, blobId::UUID, blob::T) where {T}
    @warn "updateBlob! is obsolete."
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = RowBlob(blobId, blob)
end

function getData(
    dfg::AbstractDFG,
    vlabel::Symbol,
    key::Union{Symbol, UUID, <:AbstractString, Regex};
    hashfunction = sha256,
    checkhash::Bool = true,
    getlast::Bool = true,
)
    Base.depwarn("getData is deprecated, use loadBlob_Variable instead.", :getData)
    _getblobentr(g, v, k) = getBlobentries(g, v, k)
    _getblobentr(g, v, k::UUID) = [getfirstBlobentry(g, v, k);]
    de_ = _getblobentr(dfg, vlabel, key)
    lbls = (s -> s.label).(de_)
    idx = sortperm(lbls; rev = getlast)
    _first(s) = s
    _first(s::AbstractVector) = 0 < length(s) ? s[1] : nothing
    de = _first(de_[idx])
    if isnothing(de)
        @error "Could not find in $vlabel the key $key"
        return nothing
    end
    db = getBlob(dfg, de)

    checkhash && assertHash(de, db; hashfunction = hashfunction)
    return de => db
end

# This is the normal one
function getData(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    var_label::Symbol,
    entry_label::Symbol;
    hashfunction = sha256,
    checkhash::Bool = true,
    getlast::Bool = true,
)
    Base.depwarn("getData is deprecated, use loadBlob_Variable instead.", :getData)
    de = getBlobentry(dfg, var_label, entry_label)
    db = getBlob(blobstore, de)
    checkhash && assertHash(de, db; hashfunction)
    return de => db
end

#FIXME Should `addData!`` not return entry=>blob pair?
function addData!(
    dfg::AbstractDFG,
    label::Symbol,
    entry::Blobentry,
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool = false,
)
    Base.depwarn("addData! is obsolete, use saveBlob_Variable! instead.", :addData!)
    checkhash && assertHash(entry, blob; hashfunction)
    blobId = addBlob!(dfg, entry, blob) |> UUID
    newEntry = Blobentry(entry; blobId) #, size=length(blob))
    return addBlobentry!(dfg, label, newEntry)
end

function addData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    label::Symbol,
    entry::Blobentry,
    blob::Vector{UInt8};
    hashfunction = sha256,
    checkhash::Bool = false,
)
    Base.depwarn("addData! is obsolete, use saveBlob_Variable! instead.", :addData!)
    checkhash && assertHash(entry, blob; hashfunction)
    blobId = addBlob!(blobstore, entry, blob) |> UUID
    newEntry = Blobentry(entry; blobId) #, size=length(blob))
    return addBlobentry!(dfg, label, newEntry)
end

function addData!(
    dfg::AbstractDFG,
    blobstorekey::Symbol,
    vLbl::Symbol,
    bLbl::Symbol,
    blob::Vector{UInt8},
    timestamp = now(localzone());
    kwargs...,
)
    Base.depwarn("addData! is obsolete, use saveBlob_Variable! instead.", :addData!)
    return addData!(
        dfg,
        getBlobstore(dfg, blobstorekey),
        vLbl,
        bLbl,
        blob,
        timestamp;
        kwargs...,
    )
end

function addData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    vLbl::Symbol,
    bLbl::Symbol,
    blob::Vector{UInt8},
    timestamp = now(localzone());
    description = "",
    metadata = "",
    mimeType::String = "application/octet-stream",
    id::Union{UUID, Nothing} = nothing,
    blobId::UUID = uuid4(),
    hashfunction = sha256,
)
    Base.depwarn("addData! is obsolete, use saveBlob_Variable! instead.", :addData!)
    #
    entry = Blobentry(;
        id,
        blobId,
        label = bLbl,
        blobstore = getLabel(blobstore),
        hash = string(bytes2hex(hashfunction(blob))),
        origin = buildSourceString(dfg, vLbl),
        description,
        mimeType,
        metadata,
        timestamp,
    )

    return addData!(dfg, blobstore, vLbl, entry, blob; hashfunction)
end

function addData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore{T},
    vLbl::Symbol,
    blobLabel::Symbol,
    blob::T,
    timestamp = now(localzone());
    description = "",
    metadata = "",
    mimeType::String = "application/octet-stream",
    origin = buildSourceString(dfg, vLbl),
    # hashfunction = sha256,
) where {T}
    Base.depwarn("addData! is obsolete, use saveBlob_Variable! instead.", :addData!)
    #
    # checkhash && assertHash(entry, blob; hashfunction)
    blobId = addBlob!(blobstore, blob)

    entry = Blobentry(;
        blobId,
        label = blobLabel,
        blobstore = getLabel(blobstore),
        # hash = string(bytes2hex(hashfunction(blob))),
        hash = "",
        origin,
        description,
        mimeType,
        metadata,
        timestamp,
    )
    addBlobentry!(dfg, vLbl, entry)
    return entry => blob
end

function deleteData!(dfg::AbstractDFG, vLbl::Symbol, bLbl::Symbol)
    Base.depwarn(
        "deleteData! is deprecated, use deleteBlob_Variable! instead.",
        :deleteData!,
    )
    de = getBlobentry(dfg, vLbl, bLbl)
    deleteBlobentry!(dfg, vLbl, bLbl)
    deleteBlob!(dfg, de)
    return 2
end

function deleteData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    vLbl::Symbol,
    entry::Blobentry,
)
    Base.depwarn(
        "deleteData! is deprecated, use deleteBlob_Variable! instead.",
        :deleteData!,
    )
    return deleteData!(dfg, blobstore, vLbl, entry.label)
end

function deleteData!(
    dfg::AbstractDFG,
    blobstore::AbstractBlobstore,
    vLbl::Symbol,
    bLbl::Symbol,
)
    Base.depwarn(
        "deleteData! is deprecated, use deleteBlob_Variable! instead.",
        :deleteData!,
    )
    de = getBlobentry(dfg, vLbl, bLbl)
    deleteBlobentry!(dfg, vLbl, bLbl)
    deleteBlob!(blobstore, de)
    return 2
end

## ================================================================================
## Deprecated in v0.27
##=================================================================================

# const AbstractFactor = AbstractObservation
# const AbstractPackedFactor = AbstractPackedObservation
# const FactorOperationalMemory = FactorCache
# const VariableNodeData = State

# @deprecate getNeighborhood(args...; kwargs...) listNeighborhood(args...; kwargs...)
# @deprecate addBlob!(store::AbstractBlobstore, blobId::UUID, data, ::String) addBlob!(
#     store,
#     blobId,
#     data,
# )
# @deprecate addBlob!(store::AbstractBlobstore{T}, data::T, ::String) where {T} addBlob!(
#     store,
#     uuid4(),
#     data,
# )

# @deprecate updateVariable!(args...) mergeVariable!(args...)
# @deprecate updateFactor!(args...) mergeFactor!(args...)

# @deprecate updateBlobEntry!(args...) mergeBlobentry!(args...)
# @deprecate updateGraphBlobEntry!(args...) mergeGraphBlobentry!(args...)
# @deprecate updateAgentBlobEntry!(args...) mergeAgentBlobentry!(args...)

# @deprecate getBlobStore(args...) getBlobstore(args...)
# @deprecate addBlobStore!(args...) addBlobstore!(args...)
# @deprecate updateBlobStore!(args...) updateBlobstore!(args...)
# @deprecate deleteBlobStore!(args...) deleteBlobstore!(args...)
# @deprecate emptyBlobStore!(args...) emptyBlobstore!(args...)
# @deprecate listBlobStores(args...) listBlobstores(args...)

# @deprecate BlobEntry(args...; kwargs...) Blobentry(args...; kwargs...)
# @deprecate getGraphBlobEntry(args...; kwargs...) getGraphBlobentry(args...; kwargs...)
# @deprecate getGraphBlobEntries(args...; kwargs...) getGraphBlobentries(args...; kwargs...)
# @deprecate addGraphBlobEntry!(args...; kwargs...) addGraphBlobentry!(args...; kwargs...)
# @deprecate addGraphBlobEntries!(args...; kwargs...) addGraphBlobentries!(args...; kwargs...)
# @deprecate mergeGraphBlobEntry!(args...; kwargs...) mergeGraphBlobentry!(args...; kwargs...)
# @deprecate deleteGraphBlobEntry!(args...; kwargs...) deleteGraphBlobentry!(
#     args...;
#     kwargs...,
# )
# @deprecate getAgentBlobEntry(args...; kwargs...) getAgentBlobentry(args...; kwargs...)
# @deprecate getAgentBlobEntries(args...; kwargs...) getAgentBlobentries(args...; kwargs...)
# @deprecate addAgentBlobEntry!(args...; kwargs...) addAgentBlobentry!(args...; kwargs...)
# @deprecate addAgentBlobEntries!(args...; kwargs...) addAgentBlobentries!(args...; kwargs...)
# @deprecate mergeAgentBlobEntry!(args...; kwargs...) mergeAgentBlobentry!(args...; kwargs...)
# @deprecate deleteAgentBlobEntry!(args...; kwargs...) deleteAgentBlobentry!(
#     args...;
#     kwargs...,
# )
# @deprecate listGraphBlobEntries(args...; kwargs...) listGraphBlobentries(args...; kwargs...)
# @deprecate listAgentBlobEntries(args...; kwargs...) listAgentBlobentries(args...; kwargs...)
# @deprecate hasBlobEntry(args...; kwargs...) hasBlobentry(args...; kwargs...)
# @deprecate getBlobEntry(args...; kwargs...) getBlobentry(args...; kwargs...)
# @deprecate getBlobEntryFirst(args...; kwargs...) getfirstBlobentry(args...; kwargs...)
# @deprecate getBlobentry(var::AbstractGraphVariable, blobId::UUID) getfirstBlobentry(
#     var::AbstractGraphVariable,
#     blobId::UUID,
# )
# @deprecate addBlobEntry!(args...; kwargs...) addBlobentry!(args...; kwargs...)
# @deprecate addBlobEntries!(args...; kwargs...) addBlobentries!(args...; kwargs...)
# @deprecate mergeBlobEntry!(args...; kwargs...) mergeBlobentry!(args...; kwargs...)
# @deprecate deleteBlobEntry!(args...; kwargs...) deleteBlobentry!(args...; kwargs...)
# @deprecate listBlobEntrySequence(args...; kwargs...) listBlobentrySequence(
#     args...;
#     kwargs...,
# )
# @deprecate mergeBlobEntries!(args...; kwargs...) mergeBlobentries!(args...; kwargs...)

# @deprecate getVariableSolverData(args...; kwargs...) getState(args...; kwargs...)
# @deprecate addVariableSolverData!(args...; kwargs...) addState!(args...; kwargs...)
# @deprecate deleteVariableSolverData!(args...; kwargs...) deleteState!(args...; kwargs...)
# @deprecate listVariableSolverData(args...; kwargs...) listStates(args...; kwargs...)
# @deprecate getVariableSolverDataAll(args...; kwargs...) getStates(args...; kwargs...)

# @deprecate getSolverData(v::VariableCompute, solveKey::Symbol = :default) getState(
#     v,
#     solveKey,
# ) false

# @deprecate packVariableNodeData(args...; kwargs...) packState(args...; kwargs...)
# @deprecate unpackVariableNodeData(args...; kwargs...) unpackState(args...; kwargs...)

# #TODO possibly completely deprecated or not exported until update verb is standardized
# function updateVariableSolverData!(
#     dfg::AbstractDFG,
#     variablekey::Symbol,
#     vnd::State,
#     useCopy::Bool = false,
#     fields::Vector{Symbol} = Symbol[];
#     warn_if_absent::Bool = true,
# )
#     Base.depwarn(
#         "updateVariableSolverData! is deprecated, use mergeState! or copytoState! instead",
#         :updateVariableSolverData!,
#     )
#     #This is basically just setSolverData
#     var = getVariable(dfg, variablekey)
#     warn_if_absent &&
#         !haskey(var.solverDataDict, vnd.solveKey) &&
#         @warn "State '$(vnd.solveKey)' does not exist, adding"

#     # for InMemoryDFGTypes do memory copy or repointing, for cloud this would be an different kind of update.
#     usevnd = vnd # useCopy ? deepcopy(vnd) : vnd
#     # should just one, or many pointers be updated?
#     useExisting =
#         haskey(var.solverDataDict, vnd.solveKey) &&
#         isa(var.solverDataDict[vnd.solveKey], State) &&
#         length(fields) != 0
#     # @error useExisting vnd.solveKey
#     if useExisting
#         # change multiple pointers inside the VND var.solverDataDict[solvekey]
#         for field in fields
#             destField = getfield(var.solverDataDict[vnd.solveKey], field)
#             srcField = getfield(usevnd, field)
#             if isa(destField, Array) && size(destField) == size(srcField)
#                 # use broadcast (in-place operation)
#                 destField .= srcField
#             else
#                 # change pointer of destination VND object member
#                 setfield!(var.solverDataDict[vnd.solveKey], field, srcField)
#             end
#         end
#     else
#         # change a single pointer in var.solverDataDict
#         var.solverDataDict[vnd.solveKey] = usevnd
#     end

#     return var.solverDataDict[vnd.solveKey]
# end

# function updateVariableSolverData!(
#     dfg::AbstractDFG,
#     variablekey::Symbol,
#     vnd::State,
#     solveKey::Symbol,
#     useCopy::Bool = false,
#     fields::Vector{Symbol} = Symbol[];
#     warn_if_absent::Bool = true,
# )
#     # TODO not very clean
#     if vnd.solveKey != solveKey
#         Base.depwarn(
#             "updateVariableSolverData with solveKey is deprecated use copytoState! instead.",
#             :updateVariableSolverData!,
#         )
#         usevnd = useCopy ? deepcopy(vnd) : vnd
#         usevnd.solveKey = solveKey
#         return updateVariableSolverData!(
#             dfg,
#             variablekey,
#             usevnd,
#             useCopy,
#             fields;
#             warn_if_absent = warn_if_absent,
#         )
#     else
#         return updateVariableSolverData!(
#             dfg,
#             variablekey,
#             vnd,
#             useCopy,
#             fields;
#             warn_if_absent = warn_if_absent,
#         )
#     end
# end

# function updateVariableSolverData!(
#     dfg::AbstractDFG,
#     sourceVariable::VariableCompute,
#     solveKey::Symbol = :default,
#     useCopy::Bool = false,
#     fields::Vector{Symbol} = Symbol[];
#     warn_if_absent::Bool = true,
# )
#     #
#     vnd = getSolverData(sourceVariable, solveKey)
#     # toshow = listSolveKeys(sourceVariable) |> collect
#     # @info "update DFGVar solveKey" solveKey vnd.solveKey 
#     # @show toshow
#     @assert solveKey == vnd.solveKey "State's solveKey=:$(vnd.solveKey) does not match requested :$solveKey"
#     return updateVariableSolverData!(
#         dfg,
#         sourceVariable.label,
#         vnd,
#         useCopy,
#         fields;
#         warn_if_absent = warn_if_absent,
#     )
# end

# function updateVariableSolverData!(
#     dfg::AbstractDFG,
#     sourceVariables::Vector{<:VariableCompute},
#     solveKey::Symbol = :default,
#     useCopy::Bool = false,
#     fields::Vector{Symbol} = Symbol[];
#     warn_if_absent::Bool = true,
# )
#     #I think cloud would do this in bulk for speed
#     for var in sourceVariables
#         updateVariableSolverData!(
#             dfg,
#             var.label,
#             getSolverData(var, solveKey),
#             useCopy,
#             fields;
#             warn_if_absent = warn_if_absent,
#         )
#     end
# end

# ## factor refactor deprecations
# Base.@kwdef mutable struct GenericFunctionNodeData{
#     T <: Union{<:AbstractPackedObservation, <:AbstractObservation, <:FactorCache},
# }
#     eliminated::Bool = false
#     potentialused::Bool = false
#     edgeIDs::Vector{Int} = Int[]
#     fnc::T
#     multihypo::Vector{Float64} = Float64[] # TODO re-evaluate after refactoring w #477
#     certainhypo::Vector{Int} = Int[]
#     nullhypo::Float64 = 0.0
#     solveInProgress::Int = 0
#     inflation::Float64 = 0.0
# end

# function FactorCompute(
#     label::Symbol,
#     timestamp::Union{DateTime, ZonedDateTime},
#     nstime::Nanosecond,
#     tags::Set{Symbol},
#     solverData::GenericFunctionNodeData,
#     solvable::Int,
#     variableOrder::Union{Vector{Symbol}, Tuple};
#     observation = getFactorType(solverData),
#     state::FactorState = FactorState(),
#     solvercache::Base.RefValue{<:FactorCache} = Ref{FactorCache}(),
#     id::Union{UUID, Nothing} = nothing,
#     smallData::Dict{Symbol, MetadataTypes} = Dict{Symbol, MetadataTypes}(),
# )
#     error(
#         "This constructor is deprecated, use FactorCompute(label, variableOrder, solverData; ...) instead",
#     )
#     return FactorCompute(
#         id,
#         label,
#         tags,
#         Tuple(variableOrder),
#         timestamp,
#         nstime,
#         Ref(solverData),
#         Ref(solvable),
#         smallData,
#         observation,
#         state,
#         solvercache,
#     )
# end

# function getSolverData(f::FactorCompute)
#     return error(
#         "getSolverData(f::FactorCompute) is obsolete, use getFactorState, getObservation, or getCache instead",
#     )
# end

# function setSolverData!(f::FactorCompute, data::GenericFunctionNodeData)
#     return error(
#         "setSolverData!(f::FactorCompute, data::GenericFunctionNodeData) is obsolete, use setState!, or setCache! instead",
#     )
# end

# @deprecate unpackFactor(dfg::AbstractDFG, factor::FactorDFG; skipVersionCheck::Bool = false) unpackFactor(
#     factor;
#     skipVersionCheck,
# ) false

# @deprecate rebuildFactorMetadata!(args...; kwargs...) rebuildFactorCache!(
#     args...;
#     kwargs...,
# )

# function reconstFactorData end

# function decodePackedType(
#     dfg::AbstractDFG,
#     varOrder::AbstractVector{Symbol},
#     ::Type{T},
#     packeddata::GenericFunctionNodeData{PT},
# ) where {T <: FactorCache, PT}
#     error("decodePackedType is obsolete")
#     #
#     # TODO, to solve IIF 1424
#     # variables = map(lb->getVariable(dfg, lb), varOrder)

#     # Also look at parentmodule
#     usrtyp = convertStructType(PT)
#     fulltype = DFG.FunctionNodeData{T{usrtyp}}
#     factordata = reconstFactorData(dfg, varOrder, fulltype, packeddata)
#     return factordata
# end

# function _packSolverData(f::FactorCompute, fnctype::AbstractObservation)
#     #
#     error("_packSolverData is deprecated, use seperate packing of observation #TODO")
#     packtype = convertPackedType(fnctype)
#     try
#         packed = convert(PackedFunctionNodeData{packtype}, getSolverData(f)) #TODO getSolverData 
#         packedJson = packed
#         return packedJson
#     catch ex
#         io = IOBuffer()
#         showerror(io, ex, catch_backtrace())
#         err = String(take!(io))
#         msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
#         error(msg)
#     end
# end

# const PackedFunctionNodeData{T} =
#     GenericFunctionNodeData{T} where {T <: AbstractPackedObservation}
# function PackedFunctionNodeData(args...; kw...)
#     error("PackedFunctionNodeData is obsolete")
#     return PackedFunctionNodeData{typeof(args[4])}(args...; kw...)
# end

# const FunctionNodeData{T} =
#     GenericFunctionNodeData{T} where {T <: Union{<:AbstractObservation, <:FactorCache}}
# FunctionNodeData(args...; kw...) = FunctionNodeData{typeof(args[4])}(args...; kw...)

# # this is the GenericFunctionNodeData for packed types
# #TODO deprecate FactorData in favor of FactorState (with no more distinction between packed and compute)
# const FactorData = PackedFunctionNodeData{AbstractPackedObservation}

# function FactorCompute(
#     label::Symbol,
#     variableOrder::Union{Vector{Symbol}, Tuple},
#     solverData::GenericFunctionNodeData;
#     tags::Set{Symbol} = Set{Symbol}(),
#     timestamp::Union{DateTime, ZonedDateTime} = now(localzone()),
#     solvable::Int = 1,
#     nstime::Nanosecond = Nanosecond(0),
#     id::Union{UUID, Nothing} = nothing,
#     smallData::Dict{Symbol, MetadataTypes} = Dict{Symbol, MetadataTypes}(),
# )
#     Base.depwarn(
#         "`FactorCompute` constructor with `GenericFunctionNodeData` is deprecated. observation, state, and solvercache should be provided explicitly.",
#         :FactorCompute,
#     )
#     observation = getFactorType(solverData)
#     state = FactorState(
#         solverData.eliminated,
#         solverData.potentialused,
#         solverData.multihypo,
#         solverData.certainhypo,
#         solverData.nullhypo,
#         solverData.solveInProgress,
#         solverData.inflation,
#     )

#     if solverData.fnc isa FactorCache
#         solvercache = solverData.fnc
#     else
#         solvercache = nothing
#     end

#     return FactorCompute(
#         label,
#         Tuple(variableOrder),
#         observation,
#         state,
#         solvercache;
#         id,
#         timestamp,
#         nstime,
#         tags,
#         smallData,
#         solvable,
#     )
# end

# # Deprecated check usefull? # packedFnc = fncStringToData(factor.fnctype, factor.data)
# # Deprecated check usefull? # decodeType = getFactorOperationalMemoryType(dfg)
# # Deprecated check usefull? # fullFactorData = decodePackedType(dfg, factor.variableorder, decodeType, packedFnc)
# function fncStringToData(args...; kwargs...)
#     @warn "fncStringToData is obsolete, called with" args kwargs
#     return error("fncStringToData is obsolete.")
# end

# #TODO make sure getFactorOperationalMemoryType is obsolete
# function getFactorOperationalMemoryType(dummy)
#     return error(
#         "Please extend your workspace with function getFactorOperationalMemoryType(<:AbstractParams) for your usecase, e.g. IncrementalInference uses `CommonConvWrapper <: FactorCache`",
#     )
# end
# function getFactorOperationalMemoryType(dfg::AbstractDFG)
#     return getFactorOperationalMemoryType(getSolverParams(dfg))
# end

# function typeModuleName(variableType::StateType)
#     Base.depwarn("typeModuleName is obsolete", :typeModuleName)
#     io = IOBuffer()
#     ioc = IOContext(io, :module => DistributedFactorGraphs)
#     show(ioc, typeof(variableType))
#     return String(take!(io))
# end

# typeModuleName(varT::Type{<:StateType}) = typeModuleName(varT())
