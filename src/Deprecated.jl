## ================================================================================
## Deprecated in v0.29
##=================================================================================
export FactorCompute
const FactorCompute = FactorDFG

#TODO maybe keep for Bloblet type assert later.
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
    return error("Blobentry field :hash has been deprecated; use :multihash instead")
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
        agents = deepcopy(dfg.agents),
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
    return v.statekind
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
    return error(
        "buildSourceString is deprecated. Use agents with `listAgents(dfg)` and `getAgent(dfg, agentlabel)` instead.",
    )
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
        "hasTagsNeighbors is deprecated, use listNeighbors with whereTags instead",
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
    whereSolvable::Union{Nothing, Function} = nothing,
)
    #
    varLabels = sort(map(v -> v.label, getVariables(dfg; whereSolvable)))
    factLabels = sort(map(f -> f.label, getFactors(dfg; whereSolvable)))
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

# old merge and copy functions, will be replaced by cleaner merge!, sync!, and copyto! functions

# """
#     $(SIGNATURES)
# Merger sourceDFG to destDFG given an optional list of variables and factors and distance.
# Notes:
# - Nodes already in the destination graph are updated from sourceDFG.
# - Orphaned factors (where the subgraph does not contain all the related variables) are not included.
# Related:
# - [`copyGraph!`](@ref)
# - [`getSubgraph`](@ref)
# - [`listNeighborhood`](@ref)
# - [`deepcopyGraph`](@ref)
# """

##==============================================================================
## Copy Functions #TODO replace with sync
##==============================================================================

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
Orphaned factors are not added, with a warning if verbose.
Set `overwriteDest` to overwrite existing variables and factors in the destination DFG.
NOTE: `copyGraphMetadata` is deprecated – use agent/graph Bloblets instead.
Related:
- [`deepcopyGraph`](@ref)
- [`deepcopyGraph!`](@ref)
- [`getSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
#
function copyGraph!(
    destDFG::AbstractDFG,
    sourceDFG::AbstractDFG,
    variableLabels::AbstractVector{Symbol} = listVariables(sourceDFG),
    factorLabels::AbstractVector{Symbol} = listFactors(sourceDFG);
    copyGraphMetadata::Bool = false,
    overwriteDest::Bool = false,
    deepcopyNodes::Bool = false,
    verbose::Bool = false,
    showprogress::Bool = verbose,
)
    # Split into variables and factors
    sourceVariables = getVariables(sourceDFG, variableLabels)
    sourceFactors = getFactors(sourceDFG, factorLabels)
    # Now we have to add all variables first,
    @showprogress desc = "copy variables" enabled = showprogress for variable in
                                                                     sourceVariables

        variableCopy = deepcopyNodes ? deepcopy(variable) : variable
        if !hasVariable(destDFG, variable.label)
            addVariable!(destDFG, variableCopy)
        elseif overwriteDest
            mergeVariable!(destDFG, variableCopy)
        else
            throw(LabelExistsError("Variable", variable.label))
        end
    end
    # And then all factors to the destDFG.
    @showprogress desc = "copy factors" enabled = showprogress for factor in sourceFactors
        # Get the original factor variables (we need them to create it)
        sourceFactorVariableIds = collect(factor.variableorder)
        # Find the labels and associated variables in our new subgraph
        factVariableIds = Symbol[]
        for variable in sourceFactorVariableIds
            if hasVariable(destDFG, variable)
                push!(factVariableIds, variable)
            end
        end
        # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
        if length(factVariableIds) == length(sourceFactorVariableIds)
            factorCopy = deepcopyNodes ? deepcopy(factor) : factor
            if !hasFactor(destDFG, factor.label)
                addFactor!(destDFG, factorCopy)
            elseif overwriteDest
                mergeFactor!(destDFG, factorCopy)
            else
                throw(LabelExistsError("Factor", factor.label))
            end
        elseif verbose
            @warn "Factor $(factor.label) will be an orphan in the destination graph, and therefore not added."
        end
    end

    if copyGraphMetadata
        error(
            "copyGraphMetadata keyword has been removed – metadata APIs were replaced by Bloblets. " *
            "Copy agent/graph Bloblets manually before calling copyGraph!",
        )
    end
    return nothing
end

"""
    $(SIGNATURES)
Copy nodes from one graph into another graph by making deepcopies.
see [`copyGraph!`](@ref) for more detail.
Related:
- [`deepcopyGraph`](@ref)
- [`getSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
#
function deepcopyGraph!(
    destDFG::AbstractDFG,
    sourceDFG::AbstractDFG,
    variableLabels::Vector{Symbol} = ls(sourceDFG),
    factorLabels::Vector{Symbol} = lsf(sourceDFG);
    kwargs...,
)
    return copyGraph!(
        destDFG,
        sourceDFG,
        variableLabels,
        factorLabels;
        deepcopyNodes = true,
        kwargs...,
    )
end

"""
    $(SIGNATURES)
Copy nodes from one graph into a new graph by making deepcopies.
see [`copyGraph!`](@ref) for more detail.
Related:
- [`deepcopyGraph!`](@ref)
- [`getSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
#
function deepcopyGraph(
    ::Type{T},
    sourceDFG::AbstractDFG,
    variableLabels::Vector{Symbol} = ls(sourceDFG),
    factorLabels::Vector{Symbol} = lsf(sourceDFG);
    graphLabel::Symbol = Symbol(getGraphLabel(sourceDFG), "_cp_$(string(uuid4())[1:6])"),
    kwargs...,
) where {T <: AbstractDFG}
    sp = getSolverParams(sourceDFG)
    sp_kw = sp isa fieldtype(T, :solverParams) ? (; solverParams = sp) : (;)
    destDFG = T(;
        sp_kw...,
        graph = sourceDFG.graph,
        agents = deepcopy(sourceDFG.agents),
        graphLabel,
    )
    copyGraph!(
        destDFG,
        sourceDFG,
        variableLabels,
        factorLabels;
        deepcopyNodes = true,
        kwargs...,
    )
    return destDFG
end

function mergeGraph!(
    destDFG::AbstractDFG,
    sourceDFG::AbstractDFG,
    variableLabels::Vector{Symbol},
    factorLabels::Vector{Symbol} = lsf(sourceDFG),
    distance::Int = 0;
    whereSolvable = nothing,
    whereTags = nothing,
    kwargs...,
)
    Base.depwarn(
        """
            mergeGraph! with variableLabels, factorLabels, and distance is deprecated. 
            For now use function composition ending with mergeGraph!,
            syncGraph!(Coming soon) will replace this functionality.
        """,
        :mergeGraph!,
    )
    # find neighbors at distance to add
    sourceVariables, sourceFactors = listNeighborhood(
        sourceDFG,
        union(variableLabels, factorLabels),
        distance;
        whereSolvable,
        whereTags,
    )

    copyGraph!(
        destDFG,
        sourceDFG,
        sourceVariables,
        sourceFactors;
        deepcopyNodes = true,
        overwriteDest = true,
        kwargs...,
    )

    return destDFG
end

@deprecate buildSubgraph(args...; kwargs...) getSubgraph(args...; kwargs...)

#TODO deprecate
# - the verb is not correct and should be `list` as the function returns a list of factors
# - The noun is also not correct and algorithm details are used in the name
# - A better noun is maybe Path or simply listFactors with a fancy filter, something like:
#     - [list/get]Path(dfg, from, to; algorithm...)
# the `search` verb can also come ito play, but it is more for knn search type functions.

function findFactorsBetweenNaive(args...)
    return error("findFactorsBetweenNaive is obsolete, use DFG.findPath[s] instead.")
end

#TODO deprecate `is` is the correct verb, but rather isHomogeneous(path::Path) the form is isAdjective
"""
    $SIGNATURES
Return (::Bool,::Vector{TypeName}) of types between two nodes in the factor graph 

DevNotes
- Only works on LigthDFG at the moment.

Related

[`findShortestPathDijkstra`](@ref)
"""
#
function isPathFactorsHomogeneous(dfg::AbstractDFG, from::Symbol, to::Symbol)
    # FIXME, must consider all paths, not just shortest...
    pth = intersect(findShortestPathDijkstra(dfg, from, to), lsf(dfg))
    types = getObservation.(dfg, pth) .|> typeof .|> x -> (x).name #TODO this might not be correct in julia 1.6
    utyp = unique(types)
    return (length(utyp) == 1), utyp
end

# deprecated use filter and path separately.
function findShortestPathDijkstra(
    dfg::GraphsDFG,
    from::Symbol,
    to::Symbol;
    whereVariableLabel::Union{Function, Nothing} = nothing,
    whereFactorLabel::Union{Function, Nothing} = nothing,
    whereVariableTags::Union{Function, Nothing} = nothing,
    whereFactorTags::Union{Function, Nothing} = nothing,
    whereVariableType::Union{Function, Nothing} = nothing,
    whereFactorType::Union{Function, Nothing} = nothing,
    whereSolvable::Union{Function, Nothing} = nothing,
    initialized::Union{Nothing, Bool} = nothing,
)
    Base.depwarn(
        "findShortestPathDijkstra is deprecated, use findPath with `variableLabels`/`factorLabels` kwargs instead.",
        :findShortestPathDijkstra,
    )
    any_active_filters = any(
        .!isnothing.([whereVariableLabel, whereFactorLabel, whereVariableTags, whereFactorTags, whereVariableType, whereFactorType, initialized, whereSolvable]),
    )

    if any_active_filters
        varList = listVariables(
            dfg;
            whereLabel = whereVariableLabel,
            whereTags = whereVariableTags,
            whereType = whereVariableType,
            whereSolvable,
        )
        fctList = listFactors(
            dfg;
            whereLabel = whereFactorLabel,
            whereTags = whereFactorTags,
            whereType = whereFactorType,
            whereSolvable,
        )

        varList = if initialized !== nothing
            initmask = isInitialized.(dfg, varList) .== initialized
            varList[initmask]
        else
            varList
        end
        restrict_labels = vcat(varList, fctList)
        subdfg = DFG.getSubgraph(
            GraphsDFG{NoSolverParams, VariableSkeleton, FactorSkeleton},
            dfg,
            restrict_labels,
        )
        result = try
            findPath(subdfg, from, to)
        catch ex
            ex isa DFG.LabelNotFoundError ? nothing : rethrow()
        end
        return result === nothing ? Symbol[] : result.path
    else
        result = findPath(dfg, from, to)
        return result === nothing ? Symbol[] : result.path
    end
end

# """
#     $SIGNATURES

# Small utility to return `::Int`, e.g. `0` from `getVariableLabelNumber(:x0)`

# Examples
# --------
# ```julia
# getVariableLabelNumber(:l10)          # 10
# getVariableLabelNumber(:x1)           # 1
# getVariableLabelNumber(:x1_10, "x1_") # 10
# ```

# DevNotes
# - make prefix Regex based for longer -- i.e. `:apriltag578`, `:lm1_4`

# """
function getVariableLabelNumber(vs::Symbol, prefix = string(vs)[1])
    return parse(Int, string(vs)[(length(prefix) + 1):end])
end

@deprecate FolderStore FolderBlobprovider

# Blobstore → Blobprovider renames
@deprecate InMemoryBlobstore MemoryBlobprovider
@deprecate getBlobstore getBlobprovider
@deprecate getBlobstores getBlobproviders
@deprecate addBlobstore! addBlobprovider!
@deprecate listBlobstores listBlobproviders
@deprecate hasBlobstore hasBlobprovider
@deprecate refBlobstores refBlobproviders
@deprecate deleteBlobstore! deleteBlobprovider!
@deprecate deleteBlobstorelink! deleteBlobprovider!
@deprecate mergeStorelink! mergeBlobprovider!
@deprecate mergeStorelinks! mergeBlobproviders!
@deprecate addBlob! putBlob!
@deprecate LinkStore LinkBlobprovider

"""
    $(SIGNATURES)

!!! warning "Deprecated"
    `getSolverParams(dfg)` is deprecated in DFG v0.29 Pass `SolverParams` directly
    to `solveTree!()` as a keyword argument instead.
"""
function getSolverParams(dfg::AbstractDFG)
    Base.depwarn(
        "getSolverParams(dfg) is deprecated. SolverParams will be removed from the DFG object. " *
        "Pass SolverParams directly to solveTree!() as a keyword argument instead.",
        :getSolverParams,
    )
    return dfg.solverParams
end

# TODO
# The `ref*` accessors use topology-specific lens names while the fields use topology-neutral homotopy names:
# Something like:
# refPrincipalElements(state::State) = state.belief.principal_elements
# refPrincipalForms(state::State) = state.belief.principal_forms
# refTrailingForms(state::State) = state.belief.trailing_forms
# Then IIF defines the lens-specific wrappers with topology dispatch, something like:
# refMeans(state) = refPrincipalElements(state)          # RootsOnly view
# refCovariances(state) = refPrincipalForms(state)       # RootsOnly view  
# refBandwidth(state) = refTrailingForms(state)[1]       # LeavesOnly view
# But my (JT) preference is for HomotopyBeliefDFG to contain a neutral homotopy tree of nodes
# and use tree accessors on the node level and not raw references. 

refMeans(state::State) = state.belief.principal_elements
refCovariances(state::State) = state.belief.principal_forms
refWeights(state::State) = state.belief.weights
refPoints(state::State) = state.belief.points
refBandwidth(state::State) = state.belief.trailing_forms[1]
refBandwidths(state::State) = SparseArrays.nonzeros(state.belief.trailing_forms)
getTopologyKind(state::State) = state.belief.topologykind
