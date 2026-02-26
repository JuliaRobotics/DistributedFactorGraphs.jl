##==============================================================================
## AbstractDFG
##==============================================================================
##------------------------------------------------------------------------------
## Broadcasting
##------------------------------------------------------------------------------
# to allow stuff like `getObservation.(dfg, [:x1x2f1;:x10l3f2])`
# https://docs.julialang.org/en/v1/manual/interfaces/#
Base.Broadcast.broadcastable(dfg::AbstractDFG) = Ref(dfg)

##==============================================================================
## Interface for an AbstractDFG
##==============================================================================

##------------------------------------------------------------------------------
## Getters
##------------------------------------------------------------------------------

## WIP line =======================================================================

"""
    $(SIGNATURES)
"""
function getId end

"""
    $(SIGNATURES)
"""
function getAgent end

"""
    $(SIGNATURES)
"""
function getGraph end

"""
    $(SIGNATURES)
"""
getAgentLabel(dfg::AbstractDFG) = getLabel(getAgent(dfg))

"""
    $(SIGNATURES)
"""
getGraphLabel(dfg::AbstractDFG) = getLabel(getGraph(dfg))

"""
    $(SIGNATURES)
"""
getSolverParams(dfg::AbstractDFG) = dfg.solverParams

"""
    $(SIGNATURES)

Method must be overloaded by the user for Serialization to work.
"""
function rebuildFactorCache!(dfg::AbstractDFG, factor::AbstractGraphFactor, neighbors = [])
    @warn(
        "FactorCache not build, rebuildFactorCache! is not implemented for $(typeof(dfg)). `rebuildFactorCache!` is available in IncrementalInference.",
        maxlog = 1
    )
    return nothing
end

"""
    $(SIGNATURES)
Function to get the type of the variables in the DFG.
"""
getTypeDFGVariables(::AbstractDFG{V, F}) where {V, F} = V

"""
    $(SIGNATURES)
Function to get the type of the factors in the DFG.
"""
getTypeDFGFactors(::AbstractDFG{V, F}) where {V, F} = F

##------------------------------------------------------------------------------
## Setters
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
"""
#NOTE a MethodError will be thrown if solverParams type does not mach the one in dfg
# TODO Is it ok or do we want any abstract solver paramters
function setSolverParams!(dfg::AbstractDFG, solverParams::AbstractDFGParams)
    return dfg.solverParams = solverParams
end

##==============================================================================
## AbstractBlobstore  CRUD
##==============================================================================
# AbstractBlobstore should have label or overwrite getLabel

refBlobstores(dfg::AbstractDFG) = dfg.blobstores

function getBlobstore(dfg::AbstractDFG, storeLabel::Symbol)
    store = get(refBlobstores(dfg), storeLabel, nothing)
    if isnothing(store)
        throw(
            LabelNotFoundError("Blobstore", storeLabel, collect(keys(refBlobstores(dfg)))),
        )
    end
    return store
end

function addBlobstore!(dfg::AbstractDFG, store::AbstractBlobstore)
    label = getLabel(store)
    haskey(refBlobstores(dfg), label) && throw(LabelExistsError("Blobstore", label))
    return push!(refBlobstores(dfg), label => store)
end
function mergeBlobstore!(dfg::AbstractDFG, store::AbstractBlobstore)
    push!(refBlobstores(dfg), getLabel(store) => store)
    return 1
end
function deleteBlobstore!(dfg::AbstractDFG, key::Symbol)
    pop!(refBlobstores(dfg), key)
    return 1
end
listBlobstores(dfg::AbstractDFG) = collect(keys(refBlobstores(dfg)))

#TODO empty as verb or only `deleteNouns!`
# emptyBlobstore!(dfg::AbstractDFG) = empty!(refBlobstores(dfg))

##==============================================================================
## CRUD Interfaces
##==============================================================================
##------------------------------------------------------------------------------
## Variable And Factor CRUD
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
True if the variable exists in the graph.
Implement `hasVariable(dfg::AbstractDFG, label::Symbol)`
"""
function hasVariable end

"""
    $(SIGNATURES)
True if the factor exists in the graph.
Implement `hasFactor(dfg::AbstractDFG, label::Symbol)`
"""
function hasFactor end

"""
    $(SIGNATURES)
Add a VariableDFG to a DFG.
Implement `addVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)`
"""
function addVariable! end

"""
    $(SIGNATURES)
Add a Vector{VariableDFG} to a DFG.
Implement `addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})`
"""
function addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})
    return asyncmap(variables) do v
        return addVariable!(dfg, v)
    end
end

"""
    $(SIGNATURES)
Add a FactorDFG to a DFG.
Implement `addFactor!(dfg::AbstractDFG, factor::AbstractGraphFactor)`
"""
function addFactor! end

"""
    $(SIGNATURES)
Add a Vector{FactorDFG} to a DFG.
"""
function addFactors!(dfg::AbstractDFG, factors::Vector{<:AbstractGraphFactor})
    return asyncmap(factors) do f
        return addFactor!(dfg, f)
    end
end

"""
    $(SIGNATURES)
Get a VariableDFG from a DFG using its label.
Implement `getVariable(dfg::AbstractDFG, label::Symbol)`
"""
function getVariable end

"""
    $(SIGNATURES)
Get a VariableSummary from a DFG.
"""
function getVariableSummary end

"""
    $(SIGNATURES)
Get the variables from a DFG as a Vector{VariableSummary}.
"""
function getVariablesSummary end

"""
    $(SIGNATURES)
Get a VariableSkeleton from a DFG.
"""
function getVariableSkeleton end

"""
    $(SIGNATURES)
Get the variables from a DFG as a Vector{VariableSkeleton}.
"""
function getVariablesSkeleton end

"""
    $(SIGNATURES)
Get a FactorDFG from a DFG using its label.
Implement `getFactor(dfg::AbstractDFG, label::Symbol)`
"""
function getFactor end

"""
    $(SIGNATURES)
Get the skeleton factors from a DFG as a Vector{FactorSkeleton}.
"""
function getFactorsSkeleton end

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
    $(SIGNATURES)
Merge a variable into the DFG. If a variable with the same label exists, it will be overwritten; 
otherwise, the variable will be added to the graph.
Implement `mergeVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)`
"""
function mergeVariable! end

function mergeVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})
    counts = asyncmap(v->mergeVariable!(dfg, v), variables)
    return sum(counts)
end

"""
    $(SIGNATURES)
Merge a factor into the DFG. If a factor with the same label exists, it will be overwritten; 
otherwise, the factor will be added to the graph.
Implement `mergeFactor!(dfg::AbstractDFG, factor::AbstractGraphFactor)`
"""
function mergeFactor! end

function mergeFactors!(dfg::AbstractDFG, factors::Vector{<:AbstractGraphFactor})
    counts = asyncmap(f->mergeFactor!(dfg, f), factors)
    return sum(counts)
end

"""
    $(SIGNATURES)
Delete a VariableDFG from the DFG.
Implement `deleteVariable!(dfg::AbstractDFG, label::Symbol)`
"""
function deleteVariable! end
"""
    $(SIGNATURES)
Delete a FactorDFG from the DFG using its label.
Implement `deleteFactor!(dfg::AbstractDFG, label::Symbol)`
"""
function deleteFactor! end

"""
    $(SIGNATURES)
Get the variables in the DFG as a Vector, supporting various filters.

Arguments
- `regexFilt`: Optional Regex to filter variable labels (deprecated, use `labelFilter` instead).
Keyword arguments
- `solvableFilter`: Optional function to filter on the `solvable` property, eg `>=(1)`.
- `labelFilter`: Optional function to filter on label e.g., `contains(r"x1")`.
- `tagsFilter`: Optional function to filter on tags, eg. `⊇([:POSE])`.
- `typeFilter`: Optional function to filter on the variable type.

Returns
- `Vector{<:AbstractGraphVariable}` matching the filters.

See also: [`listVariables`](@ref), [`ls`](@ref)
"""
function getVariables end

function getVariables(dfg::AbstractDFG, labels::Vector{Symbol})
    return map(label -> getVariable(dfg, label), labels)
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors end

function getFactors(dfg::AbstractDFG, labels::Vector{Symbol})
    return map(label -> getFactor(dfg, label), labels)
end

##------------------------------------------------------------------------------
## Checking Types
##------------------------------------------------------------------------------

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

##------------------------------------------------------------------------------
## Neighbors
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
Implement `isConnected(dfg::AbstractDFG)`
"""
function isConnected end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
Implement `listNeighbors(dfg::AbstractDFG, label::Symbol; solvableFilter, tagsFilter)`
"""
function listNeighbors end

function listNeighbors(dfg::AbstractDFG, node::AbstractGraphNode; kwargs...)
    return listNeighbors(dfg, node.label; kwargs...)
end
##------------------------------------------------------------------------------
## copy and duplication
##------------------------------------------------------------------------------

##------------------------------------------------------------------------------
## CRUD Aliases
##------------------------------------------------------------------------------

function deleteVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)
    return deleteVariable!(dfg, variable.label)
end

function deleteVariables!(dfg::AbstractDFG, labels::Vector{Symbol})
    counts = asyncmap(labels) do l
        return deleteVariable!(dfg, l)
    end
    return sum(counts)
end

function deleteVariables!(dfg::AbstractDFG; kwargs...)
    labels = listVariables(dfg; kwargs...)
    return deleteVariables!(dfg, labels)
end

"""
    $(SIGNATURES)
Delete the referenced Factor from the DFG.
"""
function deleteFactor!(dfg::AbstractDFG, factor::AbstractGraphFactor)
    return deleteFactor!(dfg, factor.label)
end

function deleteFactors!(dfg::AbstractDFG, labels::Vector{Symbol})
    counts = asyncmap(labels) do l
        return deleteFactor!(dfg, l)
    end
    return sum(counts)
end

function deleteFactors!(dfg::AbstractDFG; kwargs...)
    labels = listFactors(dfg; kwargs...)
    return deleteFactors!(dfg, labels)
end

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
- [`buildSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
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
- [`buildSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
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
- [`buildSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
function deepcopyGraph(
    ::Type{T},
    sourceDFG::AbstractDFG,
    variableLabels::Vector{Symbol} = ls(sourceDFG),
    factorLabels::Vector{Symbol} = lsf(sourceDFG);
    graphLabel::Symbol = Symbol(getGraphLabel(sourceDFG), "_cp_$(string(uuid4())[1:6])"),
    kwargs...,
) where {T <: AbstractDFG}
    destDFG = T(;
        solverParams = getSolverParams(sourceDFG),
        graph = sourceDFG.graph,
        agent = sourceDFG.agent,
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

##==============================================================================
## Subgraphs and Neighborhoods
##==============================================================================

"""
    $SIGNATURES
Return (::Bool,::Vector{TypeName}) of types between two nodes in the factor graph 

DevNotes
- Only works on LigthDFG at the moment.

Related

[`findShortestPathDijkstra`](@ref)
"""
function isPathFactorsHomogeneous(dfg::AbstractDFG, from::Symbol, to::Symbol)
    # FIXME, must consider all paths, not just shortest...
    pth = intersect(findShortestPathDijkstra(dfg, from, to), lsf(dfg))
    types = getObservation.(dfg, pth) .|> typeof .|> x -> (x).name #TODO this might not be correct in julia 1.6
    utyp = unique(types)
    return (length(utyp) == 1), utyp
end

#TODO add pruning filters that is applied during traversal.
"""
    $(SIGNATURES)
Build a list of all unique neighbors inside 'distance'. Neighbors can be filtered by using keyword arguments, eg. [`tagsFilter`] and [`solvableFilter`].
Filters are applied to final neighborhood result.

Notes
- Returns `Vector{Symbol}`

Related:
- [`copyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`deepcopyGraph`](@ref)
- [`mergeGraph!`](@ref)
"""
function listNeighborhood(dfg::AbstractDFG, label::Symbol, distance::Int; filters...)
    neighborList = Set{Symbol}([label])
    curList = Set{Symbol}([label])

    for dist = 1:distance
        newNeighbors = Set{Symbol}()
        for node in curList
            neighbors = listNeighbors(dfg, node)
            union!(neighborList, neighbors)
            union!(newNeighbors, neighbors)
        end
        curList = newNeighbors
    end

    variableLabels = intersect(listVariables(dfg; filters...), neighborList)
    factorLabels = intersect(listFactors(dfg; filters...), neighborList)

    return variableLabels, factorLabels
end

function listNeighborhood(
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int;
    filters...,
)
    if distance > 0
        variableLabels = Symbol[]
        factorLabels = Symbol[]
        for l in variableFactorLabels
            varls, facls = listNeighborhood(dfg, l, distance; filters...)
            union!(variableLabels, varls)
            union!(factorLabels, facls)
        end
    else
        variableLabels = intersect(listVariables(dfg; filters...), variableFactorLabels)
        factorLabels = intersect(listFactors(dfg; filters...), variableFactorLabels)
    end

    return variableLabels, factorLabels
end

"""
    $(SIGNATURES)
Build a deep subgraph copy from the DFG given a list of variables and factors and an optional distance.
Note: Orphaned factors (where the subgraph does not contain all the related variables) are not returned.
Related:
- [`copyGraph!`](@ref)
- [`listNeighborhood`](@ref)
- [`deepcopyGraph`](@ref)
- [`mergeGraph!`](@ref)
Dev Notes
- Bulk vs node for node: a list of labels are compiled and the sugraph is copied in bulk.
"""
function buildSubgraph(
    ::Type{G},
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int = 0;
    solvableFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    graphLabel::Symbol = Symbol(getGraphLabel(dfg), "_sub_$(string(uuid4())[1:6])"),
    solvable = nothing, #TODO deprecated in v0.29
    kwargs...,
) where {G <: AbstractDFG}
    if !isnothing(solvable)
        Base.depwarn(
            "solvable kwarg is deprecated, use kwarg `solvableFilter = (>=solvable)` instead", #v0.29
            :listNeighbors,
        )
        !isnothing(solvableFilter) &&
            error("Cannot use both solvable and solvableFilter kwargs.")
        solvableFilter = >=(solvable)
    end
    #build up the neighborhood from variableFactorLabels
    variableLabels, factorLabels =
        listNeighborhood(dfg, variableFactorLabels, distance; solvableFilter, tagsFilter)

    # Copy the section of graph we want
    destDFG = deepcopyGraph(G, dfg, variableLabels, factorLabels; graphLabel, kwargs...)
    return destDFG
end

function buildSubgraph(
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int = 0;
    kwargs...,
)
    return buildSubgraph(LocalDFG, dfg, variableFactorLabels, distance; kwargs...)
end

"""
    $(SIGNATURES)
Merger sourceDFG to destDFG given an optional list of variables and factors and distance.
Notes:
- Nodes already in the destination graph are updated from sourceDFG.
- Orphaned factors (where the subgraph does not contain all the related variables) are not included.
Related:
- [`copyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`listNeighborhood`](@ref)
- [`deepcopyGraph`](@ref)
"""
function mergeGraph!(
    destDFG::AbstractDFG,
    sourceDFG::AbstractDFG,
    variableLabels::Vector{Symbol} = ls(sourceDFG),
    factorLabels::Vector{Symbol} = lsf(sourceDFG),
    distance::Int = 0;
    solvableFilter = nothing,
    tagsFilter = nothing,
    kwargs...,
)

    # find neighbors at distance to add
    sourceVariables, sourceFactors = listNeighborhood(
        sourceDFG,
        union(variableLabels, factorLabels),
        distance;
        solvableFilter,
        tagsFilter,
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

##==============================================================================
## Graphs Structures (Abstract, overwrite for performance)
##==============================================================================

# TODO API name get seems wrong maybe just biadjacencyMatrix
"""
    $(SIGNATURES)
Get a matrix indicating adjacency between variables and factors. Returned as
a named tuple: B::SparseMatrixCSC{Int}, varLabels::Vector{Symbol)
facLabels::Vector{Symbol). Rows are the factors, columns are the variables,
with the corresponding labels in varLabels,facLabels.

Notes
-  Returns `::NamedTuple{(:B, :varLabels, :facLabels), Tuple{SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}}`
"""
function getBiadjacencyMatrix(dfg::AbstractDFG; solvable::Int = 0)
    solvableFilter = >=(solvable) #FIXME solvableFilter should be kwarg
    varLabels = map(v -> v.label, getVariables(dfg; solvableFilter))
    factLabels = map(f -> f.label, getFactors(dfg; solvableFilter))

    vDict = Dict(varLabels .=> [1:length(varLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = listNeighbors(dfg, getFactor(dfg, factLabel); solvableFilter)
        map(vLabel -> adjMat[fIndex, vDict[vLabel]] = 1, factVars)
    end
    return (B = adjMat, varLabels = varLabels, facLabels = factLabels)
end

##==============================================================================
## DOT Files, falls back to GraphsDFG dot functions
##==============================================================================
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.

Notes
- Returns `::String`
"""
function toDot(dfg::AbstractDFG)
    #convert to GraphsDFG
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg))
    return toDot(ldfg)
end

"""
    $(SIGNATURES)
Produces a dot file of the graph for visualization.
Download XDot to see the data

Note
- Default location "/tmp/dfg.dot" -- MIGHT BE REMOVED
- Can be viewed with the `xdot` system application.
- Based on graphviz.org
"""
function toDotFile(dfg::AbstractDFG, fileName::String = "/tmp/dfg.dot")

    #convert to GraphsDFG
    ldfg = GraphsDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg))

    return toDotFile(ldfg, fileName)
end

##==============================================================================
## Summaries
##==============================================================================

"""
$(SIGNATURES)
Get a summary graph (first-class citizens of variables and factors) with the same structure as the original graph.

Notes
- this is a copy of the original.
- Returns `::GraphsDFG{NoSolverParams, VariableSummary, FactorSummary}`
"""
function getSummaryGraph(dfg::G) where {G <: AbstractDFG}
    #TODO fix deprecated constructor
    summaryDfg = GraphsDFG{NoSolverParams, VariableSummary, FactorSummary}(;
        graphDescription = "Summary of $(getDescription(dfg))",
        agent = dfg.agent,
        graphLabel = Symbol(getGraphLabel(dfg), "_summary_$(string(uuid4())[1:6])"),
    )
    deepcopyGraph!(summaryDfg, dfg)
    # for v in getVariables(dfg)
    #     newV = addVariable!(summaryDfg, VariableSummary(v))
    # end
    # for f in getFactors(dfg)
    #     addFactor!(summaryDfg, listNeighbors(dfg, f), FactorSummary(f))
    # end
    return summaryDfg
end
