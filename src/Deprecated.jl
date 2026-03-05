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
        "getTypeFromSerializationModule is obsolete, use DFG.parseStateKind or IIF.getTypeFromSerializationModule.",
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
    return v.statekindsymbol
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

# """
#     $(SIGNATURES)
# Get a matrix indicating relationships between variables and factors. Rows are
# all factors, columns are all variables, and each cell contains either nothing or
# the symbol of the relating factor. The first row and first column are factor and
# variable headings respectively.
# Note:
# - rather use getBiadjacencyMatrix
# - Returns either of `::Matrix{Union{Nothing, Symbol}}`
# """
# Deprecated in favor of getBiadjacencyMatrix as it is not efficient for large graphs.
function getAdjacencyMatrixSymbols(
    dfg::AbstractDFG;
    solvableFilter::Union{Nothing, Function} = nothing,
)
    #
    varLabels = sort(map(v -> v.label, getVariables(dfg; solvableFilter)))
    factLabels = sort(map(f -> f.label, getFactors(dfg; solvableFilter)))
    vDict = Dict(varLabels .=> [1:length(varLabels)...] .+ 1)

    adjMat = Matrix{Union{Nothing, Symbol}}(
        nothing,
        length(factLabels) + 1,
        length(varLabels) + 1,
    )
    # Set row/col headings
    adjMat[2:end, 1] = factLabels
    adjMat[1, 2:end] = varLabels
    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = listNeighbors(dfg, getFactor(dfg, factLabel); solvable)
        map(vLabel -> adjMat[fIndex + 1, vDict[vLabel]] = factLabel, factVars)
    end
    return adjMat
end

@deprecate findVariableNearTimestamp(args...; kwargs...) findVariablesNearTimestamp(
    args...;
    kwargs...,
)

function getVariable(dfg::AbstractDFG, label::Symbol, stateLabel::Symbol)
    Base.depwarn("getVariable with stateLabel is deprecated", :getVariable)
    #TODO DFG v1.x will maybe use getVariable(dfg, label; stateLabelFilter) instead.
    return getVariable(dfg, label)
    # return getVariable(dfg, label; stateLabelFilter = ==(stateLabel))
end

# Deprecated with new State serialization.
# """
#     $SIGNATURES

# Default escalzation from coordinates to a group representation point.  Override if defaults are not correct.
# E.g. coords -> se(2) -> SE(2).

# DevNotes
# - TODO Likely remove as part of serialization updates, see #590
# - Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.

# Related

# [`getCoordinates`](@ref)
# """
function getPoint(
    ::Type{T},
    v::AbstractVector,
    basis = ManifoldsBase.DefaultOrthogonalBasis(),
) where {T <: StateType}
    Base.depwarn("getPoint is deprecated. Use get_vector and exp directly.", :getPoint)
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.get_vector(M, p0, v, basis)
    return ManifoldsBase.exp(M, p0, X)
end

# """
#     $SIGNATURES

# Default reduction of a variable point value (a group element) into coordinates as `Vector`.  Override if defaults are not correct.

# DevNotes
# - TODO Likely remove as part of serialization updates, see #590
# - Used in transition period for Serialization.  This function will likely be changed or deprecated entirely.

# Related

# [`getPoint`](@ref)
# """
function getCoordinates(
    ::Type{T},
    p,
    basis = ManifoldsBase.DefaultOrthogonalBasis(),
) where {T <: StateType}
    Base.depwarn(
        "getCoordinates is deprecated. Use log and get_coordinates directly.",
        :getCoordinates,
    )
    M = getManifold(T)
    p0 = getPointIdentity(T)
    X = ManifoldsBase.log(M, p0, p)
    return ManifoldsBase.get_coordinates(M, p0, X, basis)
end
