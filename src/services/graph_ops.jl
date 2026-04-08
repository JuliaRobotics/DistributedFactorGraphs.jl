# ==============================================================================
# Graph Operations (not applicable to a DFG)
# ==============================================================================
function addGraph! end
function deleteGraph! end
function listGraphs end
function getGraphs end

# ==============================================================================
# AbstractGraphNode Functions
# ==============================================================================

function Base.getindex(dfg::AbstractDFG, lbl::Symbol)
    if isVariable(dfg, lbl)
        getVariable(dfg, lbl)
    elseif isFactor(dfg, lbl)
        getFactor(dfg, lbl)
    else
        throw(LabelNotFoundError("GraphNode", lbl))
    end
end

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a variable vertex in the graph DFG.
Checks whether it both exists in the graph and is a variable.
(If you rather want a quick for type, just do node isa VariableDFG)
Implement `isVariable(dfg::AbstractDFG, label::Symbol)`
"""
function isVariable end

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a factor vertex in the graph DFG.
Checks whether it both exists in the graph and is a factor.
(If you rather want a quicker for type, just do node isa FactorDFG)
Implement `isFactor(dfg::AbstractDFG, label::Symbol)`
"""
function isFactor end

# rather use isa in code, but ok, here it is
isVariable(dfg::AbstractDFG, node::AbstractGraphVariable) = true
isFactor(dfg::AbstractDFG, node::AbstractGraphFactor) = true

##==============================================================================
## exists - alias for hasVariable || hasFactor
##==============================================================================
# exists alone is ambiguous and only for variables and factors where there rest of the nouns use has,
# TODO therefore, keep as internal or deprecate?
# additionally - variables and factors can possibly have the same label in other drivers such as NvaSDK

"""
    $(SIGNATURES)
True if a variable or factor with `label` exists in the graph.
"""
function exists(dfg::AbstractDFG, label::Symbol)
    return hasVariable(dfg, label) || hasFactor(dfg, label)
end

function exists(dfg::AbstractDFG, node::AbstractGraphNode)
    return exists(dfg, node.label)
end

"""
    $(SIGNATURES)
Build a deep subgraph copy from the DFG given a list of variables and factors and an optional distance.
Note: Orphaned factors (where the subgraph does not contain all the related variables) are not returned.
Related:
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
Dev Notes
- Bulk vs node for node: a list of labels are compiled and the sugraph is copied in bulk.
"""
function getSubgraph(
    ::Type{G},
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int = 0;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    graphLabel::Symbol = Symbol(getGraphLabel(dfg), "_sub_$(string(uuid4())[1:6])"),
    solvable = nothing, #TODO deprecated in v0.29
    kwargs...,
) where {G <: AbstractDFG}
    if !isnothing(solvable)
        Base.depwarn(
            "solvable kwarg is deprecated, use kwarg `whereSolvable = >=(solvable)` instead", #v0.29
            :getSubgraph,
        )
        !isnothing(whereSolvable) &&
            error("Cannot use both solvable and whereSolvable kwargs.")
        whereSolvable = >=(solvable)
    end
    #build up the neighborhood from variableFactorLabels
    variableLabels, factorLabels =
        listNeighborhood(dfg, variableFactorLabels, distance; whereSolvable, whereTags)

    # Copy the section of graph we want
    destDFG = deepcopyGraph(G, dfg, variableLabels, factorLabels; graphLabel, kwargs...)
    return destDFG
end

function getSubgraph(
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int = 0;
    kwargs...,
)
    return getSubgraph(LocalDFG, dfg, variableFactorLabels, distance; kwargs...)
end

"""
    $(SIGNATURES)
Merge the source DFG into the destination DFG cascading down the hierarchy of DFG nodes.
Merge rules:
- Variables, Factors, Agents, and Graphroot, with the same label are merged if they are equal.
    - On conflicts, a `MergeConflictError` is thrown.
    - Child nodes (eg. tags, Bloblets, Blobentries, States, etc.) are using `merge!`.
- The Blobstore links are merged provided they point to the same Blobstore.
    - On conflicts, a `MergeConflictError` is thrown.
"""
function mergeGraph!(destDFG::AbstractDFG, srcDFG::AbstractDFG)
    patch!(destDFG.graph, srcDFG.graph)
    mergeVariables!(destDFG, getVariables(srcDFG))
    mergeFactors!(destDFG, getFactors(srcDFG))
    mergeAgents!(destDFG, getAgents(srcDFG))
    mergeStorelinks!(destDFG, getBlobstores(srcDFG))
    return destDFG
end
