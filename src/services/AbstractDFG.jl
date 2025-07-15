##==============================================================================
## AbstractDFG
##==============================================================================
##------------------------------------------------------------------------------
## Broadcasting
##------------------------------------------------------------------------------
# to allow stuff like `getFactorType.(dfg, [:x1x2f1;:x10l3f2])`
# https://docs.julialang.org/en/v1/manual/interfaces/#
Base.Broadcast.broadcastable(dfg::AbstractDFG) = Ref(dfg)

##==============================================================================
## Interface for an AbstractDFG
##==============================================================================
# TODO update to include graph and agent extras.
# Standard recommended fields to implement for AbstractDFG
# - `description::String`
# - `solverParams::T<:AbstractDFGParams`
# - `addHistory::Vector{Symbol}`
# - `blobStores::Dict{Symbol, AbstractBlobstore}`
# AbstractDFG Accessors

##------------------------------------------------------------------------------
## Getters
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
Get the id of the node.
"""
getId(node) = node.id

"""
    $(SIGNATURES)
Get the label of the node.
"""
getLabel(node) = node.label

"""
$SIGNATURES

Get the metadata of the node.
"""
getMetadata(node) = node.metadata

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
getDescription(dfg::AbstractDFG) = dfg.description

"""
    $(SIGNATURES)
"""
getAgentLabel(dfg::AbstractDFG) = getLabel(getAgent(dfg))

"""
    $(SIGNATURES)
"""
getGraphLabel(dfg::AbstractDFG) = getLabel(dfg)

"""
    $(SIGNATURES)
"""
getAddHistory(dfg::AbstractDFG) = dfg.addHistory

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
        "FactorCache not build, rebuildFactorCache! is not implemented for $(typeof(dfg)). Make sure to load IncrementalInference.",
        maxlog = 1
    )
    return nothing
end

"""
    $(SIGNATURES)
Function to get the type of the variables in the DFG.
"""
function getTypeDFGVariables end

"""
    $(SIGNATURES)
Function to get the type of the factors in the DFG.
"""
function getTypeDFGFactors end

##------------------------------------------------------------------------------
## Setters
##------------------------------------------------------------------------------
"""
    $SIGNATURES
Set the metadata of the node.
"""
function setMetadata!(node, metadata::Dict{Symbol, SmallDataTypes})
    # with set old data should be removed, but care is taken to make sure its not the same object
    node.metadata !== metadata && empty!(node.metadata)
    return merge!(node.metadata, metadata)
end

"""
    $(SIGNATURES)
"""
setDescription!(dfg::AbstractDFG, description::String) = dfg.description = description

"""
    $(SIGNATURES)
"""
#NOTE a MethodError will be thrown if solverParams type does not mach the one in dfg
# TODO Is it ok or do we want any abstract solver paramters
function setSolverParams!(dfg::AbstractDFG, solverParams::AbstractDFGParams)
    return dfg.solverParams = solverParams
end

# Accessors and CRUD for user/robot/session Data

"""
$SIGNATURES

Get the metadata from the agent in the AbstractDFG.
"""
getAgentMetadata(dfg::AbstractDFG) = getMetadata(getAgent(dfg))

"""
$SIGNATURES

Set the metadata of the agent in the AbstractDFG.
"""
function setAgentMetadata!(dfg::AbstractDFG, data::Dict{Symbol, SmallDataTypes})
    agent = getAgent(dfg)
    return setMetadata!(agent, data)
end

"""
$SIGNATURES

Get the metadata from the factorgraph in the AbstractDFG.
"""
getGraphMetadata(dfg::AbstractDFG) = getMetadata(dfg)

"""
$SIGNATURES

Set the metadata of the factorgraph in the AbstractDFG.
"""
function setGraphMetadata!(dfg::AbstractDFG, data::Dict{Symbol, SmallDataTypes})
    return setMetadata!(dfg, data)
end

##==============================================================================
## Agent/Graph Data CRUD
##==============================================================================
#TODO maybe only support get and set?
#NOTE with API standardization this should become something like:
getAgentMetadata(dfg::AbstractDFG, key::Symbol) = getAgentMetadata(dfg)[key]
getGraphMetadata(dfg::AbstractDFG, key::Symbol) = getGraphMetadata(dfg)[key]

function updateAgentMetadata!(dfg::AbstractDFG, pair::Pair{Symbol, String})
    return push!(dfg.agent.metadata, pair)
end
function updateGraphMetadata!(dfg::AbstractDFG, pair::Pair{Symbol, String})
    return push!(dfg.graph.metadata, pair)
end

function deleteAgentMetadata!(dfg::AbstractDFG, key::Symbol)
    pop!(dfg.agent.metadata, key)
    return 1
end

function deleteGraphMetadata!(dfg::AbstractDFG, key::Symbol)
    pop!(dfg.graph.metadata, key)
    return 1
end

emptyAgentMetadata!(dfg::AbstractDFG) = empty!(dfg.agent.metadata)
emptyGraphMetadata!(dfg::AbstractDFG) = empty!(dfg.graph.metadata)

#TODO add__Data!?

##==============================================================================
## Agent/Graph/Model Blob Entries CRUD
##==============================================================================

function getGraphBlobentry end
function getGraphBlobentries end
function addGraphBlobentry! end
function addGraphBlobentries! end
function mergeGraphBlobentry! end
function deleteGraphBlobentry! end

function getAgentBlobentry end
function getAgentBlobentries end
function addAgentBlobentry! end
function addAgentBlobentries! end
function mergeAgentBlobentry! end
function deleteAgentBlobentry! end

function getModelBlobentry end
function getModelBlobentries end
function addModelBlobentry! end
function addModelBlobentries! end
function updateModelBlobentry! end
function deleteModelBlobentry! end

function listGraphBlobentries end
function listAgentBlobentries end
function listModelBlobentries end

##==============================================================================
## AbstractBlobstore  CRUD
##==============================================================================
# AbstractBlobstore should have label or overwrite getLabel

getBlobstores(dfg::AbstractDFG) = dfg.blobStores

function getBlobstore(dfg::AbstractDFG, storeLabel::Symbol)
    store = get(dfg.blobStores, storeLabel, nothing)
    if isnothing(store)
        throw(
            LabelNotFoundError("Blobstore", storeLabel, collect(keys(getBlobstores(dfg)))),
        )
    end
    return store
end

function addBlobstore!(dfg::AbstractDFG, bs::AbstractBlobstore)
    return push!(dfg.blobStores, getLabel(bs) => bs)
end
function updateBlobstore!(dfg::AbstractDFG, bs::AbstractBlobstore)
    return push!(dfg.blobStores, getLabel(bs) => bs)
end
function deleteBlobstore!(dfg::AbstractDFG, key::Symbol)
    pop!(dfg.blobStores, key)
    return 1
end
emptyBlobstore!(dfg::AbstractDFG) = empty!(dfg.blobStores)
listBlobstores(dfg::AbstractDFG) = collect(keys(dfg.blobStores))

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
Add a VariableCompute to a DFG.
Implement `addVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)`
"""
function addVariable! end

"""
    $(SIGNATURES)
Add a Vector{VariableCompute} to a DFG.
Implement `addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})`
"""
function addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})
    return asyncmap(variables) do v
        return addVariable!(dfg, v)
    end
end

"""
    $(SIGNATURES)
Add a FactorCompute to a DFG.
Implement `addFactor!(dfg::AbstractDFG, factor::AbstractGraphFactor)`
"""
function addFactor! end

"""
    $(SIGNATURES)
Add a Vector{FactorCompute} to a DFG.
"""
function addFactors!(dfg::AbstractDFG, factors::Vector{<:AbstractGraphFactor})
    return asyncmap(factors) do f
        return addFactor!(dfg, f)
    end
end

"""
    $(SIGNATURES)
Get a VariableCompute from a DFG using its label.
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
Get a FactorCompute from a DFG using its label.
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

"""
    $(SIGNATURES)
Merge a factor into the DFG. If a factor with the same label exists, it will be overwritten; 
otherwise, the factor will be added to the graph.
Implement `mergeFactor!(dfg::AbstractDFG, factor::AbstractGraphFactor)`
"""
function mergeFactor! end

"""
    $(SIGNATURES)
Delete a VariableCompute from the DFG using its label.
Implement `deleteVariable!(dfg::AbstractDFG, label::Symbol)`
"""
function deleteVariable! end
"""
    $(SIGNATURES)
Delete a FactorCompute from the DFG using its label.
Implement `deleteFactor!(dfg::AbstractDFG, label::Symbol)`
"""
function deleteFactor! end

"""
    $(SIGNATURES)
Get the variables in the DFG as a Vector, supporting various filters.

Arguments
- `regexFilt`: Optional Regex to filter variable labels (deprecated, use `labelFilter` instead).
Keyword arguments
- `tags`: Vector of tags; only variables with at least one matching tag are returned.
- `solvable`: Optional Int; only variables with `solvable >= solvable` are returned.
- `solvableFilter`: Optional function to filter on the `solvable` property, eg `>=(1)`.
- `labelFilter`: Optional function to filter on label e.g., `contains(r"x1")`.
- `tagsFilter`: Optional function to filter on tags, eg. `⊇([:x1])`.
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
(If you rather want a quick for type, just do node isa VariableCompute)
Implement `isVariable(dfg::AbstractDFG, label::Symbol)`
"""
function isVariable end

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a factor vertex in the graph DFG.
Checks whether it both exists in the graph and is a factor.
(If you rather want a quicker for type, just do node isa FactorCompute)
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
Implement `listNeighbors(dfg::AbstractDFG, label::Symbol; solvable::Int = 0)`
"""
function listNeighbors end

##------------------------------------------------------------------------------
## copy and duplication
##------------------------------------------------------------------------------

#TODO use copy functions currently in attic
"""
    $(SIGNATURES)
Gets an empty and unique DFG derived from an existing DFG.
Implement `_getDuplicatedEmptyDFG(dfg::AbstractDFG)`
"""
function _getDuplicatedEmptyDFG end

##------------------------------------------------------------------------------
## CRUD Aliases
##------------------------------------------------------------------------------

#TODO should this signiture be standardized or removed?
"""
    $(SIGNATURES)
Get a VariableCompute with a specific solver key.
In memory types still return a reference, other types returns a variable with only solveKey.
"""
function getVariable(dfg::AbstractDFG, label::Symbol, solveKey::Symbol)
    # TODO maybe change solveKey param to stateLabelFilter 
    # function getVariable(dfg::AbstractDFG, label::Symbol; stateLabelFilter::Union{Nothing, ...} = nothing) 
    var = getVariable(dfg, label)

    if isa(var, VariableCompute) && !haskey(var.solverDataDict, solveKey)
        throw(LabelNotFoundError("VariableNode", solveKey))
    elseif !isa(var, VariableCompute)
        @warn "getVariable(dfg, label, solveKey) only supported for type VariableCompute."
    end

    return var
end

"""
    $(SIGNATURES)
Delete a referenced VariableCompute from the DFG.

Notes
- Returns `Tuple{AbstractGraphVariable, Vector{<:AbstractGraphFactor}}`
"""
function deleteVariable!(dfg::AbstractDFG, variable::AbstractGraphVariable)
    return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete the referened FactorCompute from the DFG.
"""
function deleteFactor!(
    dfg::G,
    factor::F;
    suppressGetFactor::Bool = false,
) where {G <: AbstractDFG, F <: AbstractGraphFactor}
    return deleteFactor!(dfg, factor.label; suppressGetFactor = suppressGetFactor)
end

# rather use isa in code, but ok, here it is
isVariable(dfg::AbstractDFG, node::AbstractGraphVariable) = true
isFactor(dfg::AbstractDFG, node::AbstractGraphFactor) = true

##------------------------------------------------------------------------------
## Connectivity Alias
##------------------------------------------------------------------------------

function listNeighbors(
    dfg::AbstractDFG,
    node::AbstractGraphNode;
    solvable::Union{Nothing, Int} = nothing,
)
    return listNeighbors(dfg, node.label; solvable)
end

##==============================================================================
## Listing and listing aliases
##==============================================================================

##------------------------------------------------------------------------------
## Overwrite in driver for performance
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
Get a list of labels of the DFGVariables in the graph.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

Notes
- Returns `::Vector{Symbol}`

Example
```julia
listVariables(dfg, r"l", tags=[:APRILTAG;])
```

See also: [`ls`](@ref)
"""
function listVariables(dfg::AbstractDFG, args...; kwargs...)
    return map(getLabel, getVariables(dfg, args...; kwargs...))::Vector{Symbol}
end

"""
    $(SIGNATURES)
Get a list of the labels of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function listFactors(dfg::AbstractDFG, args...; kwargs...)
    return map(getLabel, getFactors(dfg, args...; kwargs...))::Vector{Symbol}
end

##------------------------------------------------------------------------------
## Aliases and Other filtered lists
##------------------------------------------------------------------------------

## ls Shorthands
##--------
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

Notes:
- Returns `Vector{Symbol}`
"""
function ls(
    dfg::AbstractDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Union{Nothing, Int} = nothing,
    solvableFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    typeFilter::Union{Nothing, Function} = nothing,
    labelFilter::Union{Nothing, Function} = nothing,
)
    return listVariables(
        dfg,
        regexFilter;
        tags,
        solvable,
        solvableFilter,
        tagsFilter,
        typeFilter,
        labelFilter,
    )
end

#TODO tags kwarg
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.

Notes
- Return `Vector{Symbol}`
"""
function lsf(
    dfg::AbstractDFG,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Union{Nothing, Int} = nothing,
    solvableFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    typeFilter::Union{Nothing, Function} = nothing,
    labelFilter::Union{Nothing, Function} = nothing,
)
    return listFactors(
        dfg,
        regexFilter;
        tags,
        solvable,
        solvableFilter,
        tagsFilter,
        typeFilter,
        labelFilter,
    )
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(
    dfg::AbstractDFG,
    node::AbstractGraphNode;
    solvable::Union{Nothing, Int} = nothing,
)
    return listNeighbors(dfg, node; solvable = solvable)
end
function ls(dfg::AbstractDFG, label::Symbol; solvable::Union{Nothing, Int} = nothing)
    return listNeighbors(dfg, label; solvable = solvable)
end

function lsf(dfg::AbstractDFG, label::Symbol; solvable::Union{Nothing, Int} = nothing)
    return listNeighbors(dfg, label; solvable = solvable)
end

## list by types
##--------------

function ls(dfg::AbstractDFG, ::Type{T}) where {T <: StateType}
    return listVariables(dfg; typeFilter = ==(T()))
end

"""
    $(SIGNATURES)
Lists the factors of a specific type in the factor graph. 
Example, list all the Point2Point2 factors in the factor graph `dfg`:
    lsf(dfg, Point2Point2)

Notes
- Return `Vector{Symbol}`
"""
function lsf(dfg::AbstractDFG, ::Type{T}) where {T <: AbstractObservation}
    typeFilter = isconcretetype(T) ? x -> x == T : x -> x <: T
    return listFactors(dfg; typeFilter)
end

function ls(dfg::AbstractDFG, ::Type{T}) where {T <: AbstractObservation}
    return lsf(dfg, T)
end

"""
    $(SIGNATURES)
Helper to return neighbors at distance 2 around a given node.
"""
function ls2(dfg::AbstractDFG, label::Symbol)
    l2 = listNeighborhood(dfg, label, 2)
    l1 = listNeighborhood(dfg, label, 1)
    return setdiff(l2, l1)
end
ls2(dfg::AbstractDFG, v::AbstractGraphNode) = ls2(dfg, getLabel(v))

"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.

Notes:
- Returns `Vector{Symbol}`
"""
function lsfPriors(dfg::AbstractDFG)
    return listFactors(dfg; typeFilter = x -> x <: AbstractPriorObservation)
end

## Listing DataTypes in a DFG

"""
    $SIGNATURES

Return `Vector{DataType}` of all unique variable types in factor graph.
"""
function lsTypes(dfg::AbstractDFG)
    vars = getVariables(dfg)
    alltypes = Set{DataType}()
    for v in vars
        varType = typeof(getVariableType(v))
        push!(alltypes, varType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{DataType, Vector{Symbol}}` of all unique variable types with labels in a factor graph.
"""
function lsTypesDict(dfg::AbstractDFG)
    vars = getVariables(dfg)
    alltypes = Dict{DataType, Vector{Symbol}}()
    for v in vars
        varType = typeof(getVariableType(v))
        d = get!(alltypes, varType, Symbol[])
        push!(d, v.label)
    end
    return alltypes
end

"""
    $SIGNATURES

Return `Vector{Symbol}` of all unique factor types in factor graph.
"""
function lsfTypes(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Set{DataType}()
    for f in facs
        facType = typeof(getFactorType(f))
        push!(alltypes, facType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{DataType, Vector{Symbol}}` of all unique factors types with labels in a factor graph.
"""
function lsfTypesDict(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Dict{DataType, Vector{Symbol}}()
    for f in facs
        facType = typeof(getFactorType(f))
        d = get!(alltypes, facType, Symbol[])
        push!(d, f.label)
    end
    return alltypes
end

##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTags(dfg::AbstractDFG, sym::Symbol, tags::Vector{Symbol}; matchAll::Bool = true)
    #
    alltags = listTags(dfg, sym)
    return length(filter(x -> x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTagsNeighbors(
    dfg::AbstractDFG,
    sym::Symbol,
    tags::Vector{Symbol};
    matchAll::Bool = true,
)
    #
    # assume only variables or factors are neighbors
    getNeiFnc = isVariable(dfg, sym) ? getFactor : getVariable
    alltags = union((ls(dfg, sym) .|> x -> getTags(getNeiFnc(dfg, x)))...)
    return length(filter(x -> x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

##==============================================================================
## Finding
##==============================================================================
# function findClosestTimestamp(setA::Vector{Tuple{DateTime,T}},
# setB::Vector{Tuple{DateTime,S}}) where {S,T}
"""
    $SIGNATURES

Find and return the closest timestamp from two sets of Tuples.  Also return the minimum delta-time (`::Millisecond`) and how many elements match from the two sets are separated by the minimum delta-time.
"""
function findClosestTimestamp(
    setA::Vector{Tuple{ZonedDateTime, T}},
    setB::Vector{Tuple{ZonedDateTime, S}},
) where {S, T}
    #
    # build matrix of delta times, ranges on rows x vars on columns
    DT = Array{Millisecond, 2}(undef, length(setA), length(setB))
    for i = 1:length(setA), j = 1:length(setB)
        DT[i, j] = setB[j][1] - setA[i][1]
    end

    DT .= abs.(DT)

    # absolute time differences
    # DTi = (x->x.value).(DT) .|> abs

    # find the smallest element
    mdt = minimum(DT)
    corrs = findall(x -> x == mdt, DT)

    # return the closest timestamp, deltaT, number of correspondences
    return corrs[1].I, mdt, length(corrs)
end

"""
    $SIGNATURES

Find and return nearest variable labels per delta time.  Function will filter on `regexFilter`, `tags`, and `solvable`.

Notes
- Returns `Vector{Tuple{Vector{Symbol}, Millisecond}}`

DevNotes:
- TODO `number` should allow returning more than one for k-nearest matches.
- Future versions likely will require some optimization around the internal `getVariable` call.
  - Perhaps a dedicated/efficient `getVariableTimestamp` for all DFG flavors.

Related

ls, listVariables, findClosestTimestamp
"""
function findVariableNearTimestamp(
    dfg::AbstractDFG,
    timest::ZonedDateTime,
    regexFilter::Union{Nothing, Regex} = nothing;
    tags::Vector{Symbol} = Symbol[],
    solvable::Int = 0,
    warnDuplicate::Bool = true,
    number::Int = 1,
)
    #
    # get the variable labels based on filters
    # syms = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
    syms = listVariables(dfg, regexFilter; tags = tags, solvable = solvable)
    # compile timestamps with label
    # vars = map( x->getVariable(dfg, x), syms )
    timeset = map(x -> (getTimestamp(getVariable(dfg, x)), x), syms)
    mask = BitArray{1}(undef, length(syms))
    fill!(mask, true)

    RET = Vector{Tuple{Vector{Symbol}, Millisecond}}()
    SYMS = Symbol[]
    CORRS = 1
    NUMBER = number
    while 0 < CORRS + NUMBER
        # get closest
        link, mdt, corrs = findClosestTimestamp([(timest, 0)], timeset[mask])
        newsym = syms[link[2]]
        union!(SYMS, !isa(newsym, Vector) ? [newsym] : newsym)
        mask[link[2]] = false
        CORRS = corrs - 1
        # last match, done with this delta time
        if corrs == 1
            NUMBER -= 1
            push!(RET, (deepcopy(SYMS), mdt))
            SYMS = Symbol[]
        end
    end
    # warn if duplicates found
    # warnDuplicate && 1 < corrs ? @warn("getVariableNearTimestamp found more than one variable at $timestamp") :   nothing

    return RET
end

function findVariableNearTimestamp(
    dfg::AbstractDFG,
    timest::DateTime,
    regexFilter::Union{Nothing, Regex} = nothing;
    timezone = tz"UTC",
    kwargs...,
)
    return findVariableNearTimestamp(
        dfg,
        ZonedDateTime(timest, timezone),
        regexFilter;
        kwargs...,
    )
end

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
## Copy Functions
##==============================================================================

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
Orphaned factors are not added, with a warning if verbose.
Set `overwriteDest` to overwrite existing variables and factors in the destination DFG.
NOTE: copyGraphMetadata not supported yet.
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
        sourceFactorVariableIds = collect(factor._variableOrderSymbols)
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
        setAgentMetadata(destDFG, getAgentMetadata(sourceDFG))
        setGraphMetadata(destDFG, getGraphMetadata(sourceDFG))
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
    sessionId = nothing,
    kwargs...,
) where {T <: AbstractDFG}
    ginfo = getDFGInfo(sourceDFG)

    !isnothing(sessionId) && @warn "sessionId is deprecated, use graphLabel instead"

    destDFG = T(; ginfo..., graphLabel)
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
## Automated Graph Searching
##==============================================================================
"""
    $SIGNATURES

Speciallized function available to only GraphsDFG at this time.

Notes
- Has option for various types of filters (increases memory usage)

Example
```julia
using IncrementalInference

# canonical example graph as example
fg = generateGraph_Kaess()

@show path = findShortestPathDijkstra(fg, :x1, :x3)
@show isVariable.(fg, path)
@show isFactor.(fg, path)
```

DevNotes
- TODO expand to other AbstractDFG entities.
- TODO use of filter resource consumption can be improved.

Related

[`findFactorsBetweenNaive`](@ref), `Graphs.dijkstra_shortest_paths`
"""
function findShortestPathDijkstra end

"""
    $SIGNATURES

Relatively naive function counting linearly from-to

DevNotes
- Convert to using Graphs shortest path methods instead.
"""
function findFactorsBetweenNaive(
    dfg::AbstractDFG,
    from::Symbol,
    to::Symbol,
    assertSingles::Bool = false,
)
    #
    @info "findFactorsBetweenNaive is naive linear number method -- improvements welcome"
    SRT = getVariableLabelNumber(from)
    STP = getVariableLabelNumber(to)
    prefix = string(from)[1]
    @assert prefix == string(to)[1] "from-to prefixes must match, one is $prefix, other $(string(to)[1])"
    prev = from
    fctlist = Symbol[]
    for num = (SRT + 1):STP
        next = Symbol(prefix, num)
        fct = intersect(ls(dfg, prev), ls(dfg, next))
        if assertSingles
            @assert length(fct) == 1 "assertSingles=true, won't return multiple factors joining variables at this time"
        end
        union!(fctlist, fct)
        prev = next
    end

    return fctlist
end

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
    types = getFactorType.(dfg, pth) .|> typeof .|> x -> (x).name #TODO this might not be correct in julia 1.6
    utyp = unique(types)
    return (length(utyp) == 1), utyp
end

##==============================================================================
## Subgraphs and Neighborhoods
##==============================================================================

"""
    $(SIGNATURES)
Build a list of all unique neighbors inside 'distance'

Notes
- Returns `Vector{Symbol}`

Related:
- [`copyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`deepcopyGraph`](@ref)
- [`mergeGraph!`](@ref)
"""
function listNeighborhood(dfg::AbstractDFG, label::Symbol, distance::Int)
    neighborList = Set{Symbol}([label])
    curList = Set{Symbol}([label])

    for dist = 1:distance
        newNeighbors = Set{Symbol}()
        for node in curList
            neighbors = listNeighbors(dfg, node)
            for neighbor in neighbors
                push!(neighborList, neighbor)
                push!(newNeighbors, neighbor)
            end
        end
        curList = newNeighbors
    end
    return collect(neighborList)
end

function listNeighborhood(
    dfg::AbstractDFG,
    variableFactorLabels::Vector{Symbol},
    distance::Int;
    solvable::Int = 0,
)
    # find neighbors at distance to add
    neighbors = Set{Symbol}()
    if distance > 0
        for l in variableFactorLabels
            union!(neighbors, listNeighborhood(dfg, l, distance))
        end
    end

    allvarfacs = union(variableFactorLabels, neighbors)

    solvable != 0 && filter!(nlbl -> (getSolvable(dfg, nlbl) >= solvable), allvarfacs)

    return allvarfacs
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
    solvable::Int = 0,
    graphLabel::Symbol = Symbol(getGraphLabel(dfg), "_sub_$(string(uuid4())[1:6])"),
    kwargs...,
) where {G <: AbstractDFG}

    #build up the neighborhood from variableFactorLabels
    allvarfacs = listNeighborhood(dfg, variableFactorLabels, distance; solvable = solvable)

    variableLabels = intersect(allvarfacs, listVariables(dfg))
    factorLabels = intersect(allvarfacs, listFactors(dfg))
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
    solvable::Int = 0,
    kwargs...,
)

    # find neighbors at distance to add
    allvarfacs = listNeighborhood(
        sourceDFG,
        union(variableLabels, factorLabels),
        distance;
        solvable = solvable,
    )

    sourceVariables = intersect(listVariables(sourceDFG), allvarfacs)
    sourceFactors = intersect(listFactors(sourceDFG), allvarfacs)

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
"""
    $(SIGNATURES)
Get a matrix indicating relationships between variables and factors. Rows are
all factors, columns are all variables, and each cell contains either nothing or
the symbol of the relating factor. The first row and first column are factor and
variable headings respectively.
Note:
- rather use getBiadjacencyMatrix
- Returns either of `::Matrix{Union{Nothing, Symbol}}`
"""
function getAdjacencyMatrixSymbols(
    dfg::AbstractDFG;
    solvable::Union{Int, Nothing} = nothing,
)
    #
    varLabels = sort(map(v -> v.label, getVariables(dfg; solvable)))
    factLabels = sort(map(f -> f.label, getFactors(dfg; solvable)))
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
    varLabels = map(v -> v.label, getVariables(dfg; solvable = solvable))
    factLabels = map(f -> f.label, getFactors(dfg; solvable = solvable))

    vDict = Dict(varLabels .=> [1:length(varLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = listNeighbors(dfg, getFactor(dfg, factLabel); solvable = solvable)
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
        description = "Summary of $(getDescription(dfg))",
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
