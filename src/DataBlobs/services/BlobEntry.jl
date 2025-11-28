##==============================================================================
## Blobentry - Generic node CRUD
##==============================================================================

"""
    $(SIGNATURES)
"""
function getBlobentry(node, label::Symbol)
    !haskey(refBlobentries(node), label) && throw(LabelNotFoundError("Blobentry", label))
    return refBlobentries(node)[label]
end

function getBlobentries(
    node;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
)
    entries = collect(values(refBlobentries(node)))
    filterDFG!(entries, labelFilter, getLabel)
    filterDFG!(entries, blobIdFilter, x -> string(x.blobid))
    return entries
end

"""
    $(SIGNATURES)
"""
function addBlobentry!(node, entry::Blobentry)
    label = getLabel(entry)
    haskey(refBlobentries(node), label) && throw(LabelExistsError("Blobentry", label))
    refBlobentries(node)[label] = entry
    return entry
end

function addBlobentries!(node, entries::Vector{Blobentry})
    addBlobentry!.(node, entries)
    return entries
end

"""
    $(SIGNATURES)
"""
function mergeBlobentry!(node, entry::Blobentry)
    label = getLabel(entry)
    refBlobentries(node)[label] = entry
    return 1
end

function mergeBlobentries!(node, entries::Vector{Blobentry})
    mergeBlobentry!.(node, entries)
    return length(entries)
end

"""
    $(SIGNATURES)
"""
function deleteBlobentry!(node, label::Symbol)
    !haskey(refBlobentries(node), label) && throw(LabelNotFoundError("Blobentry", label))
    pop!(refBlobentries(node), label)
    return 1
end

deleteBlobentry!(node, entry) = deleteBlobentry!(node, getLabel(entry))

function deleteBlobentries!(node, labels::Vector{Symbol})
    deleteBlobentry!.(node, labels)
    return length(labels)
end

"""
    $(SIGNATURES)
List all Blobentry keys for a variable `label` in `dfg`
"""
function listBlobentries(node)
    return collect(keys(refBlobentries(node)))
end

"""
    $SIGNATURES

Does a blob entry exist with `label`.
"""
hasBlobentry(node, label::Symbol) = haskey(refBlobentries(node), label)

##==============================================================================
## Blobentry - utils
##==============================================================================

"""
    checkHash(entry::Blobentry, blob) -> Union{Bool,Nothing}

Checks the integrity of a blob against the hashes (crc32c, sha256) stored in the given `Blobentry`.

- Returns `true` if all present hashes (`crchash`, `shahash`) match the computed values from `blob`.
- Returns `false` if any present hash does not match.
- Returns `nothing` if no hashes are stored in the `Blobentry` to check against.
"""
function checkHash(entry::Blobentry, blob)
    if !isnothing(entry.crchash)
        crc32c(blob) != entry.crchash && return false
    end
    if entry.shahash != ""
        sha256(blob) != entry.shahash && return false
    end
    if isnothing(entry.crchash) && entry.shahash == ""
        return nothing
    end
    return true
end

function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
    println(io, "Blobentry {")
    println(io, "  blobid:        ", entry.blobid)
    println(io, "  label:         ", entry.label)
    println(io, "  blobstore:     ", entry.blobstore)
    println(io, "  origin:        ", entry.origin)
    println(io, "  description:   ", entry.description)
    println(io, "  mimetype:      ", entry.mimetype)
    println(io, "  timestamp      ", entry.timestamp)
    println(io, "  version:       ", entry.version)
    return println(io, "}")
end

# TODO Consider autogenerating all methods of the form:
# verbNoun(dfg::VariableCompute, label::Symbol, args...; kwargs...) = verbNoun(getVariable(dfg, label), args...; kwargs...)
# with something like:
# getvariablemethod = [
#     :getfirstBlobentry,
# ]
# for met in methodstooverload  
#     @eval DistributedFactorGraphs $met(dfg::AbstractDFG, label::Symbol, args...; kwargs...) = $met(getVariable(dfg, label), args...; kwargs...)
# end

##==============================================================================
## Blobentry - CRUD
##==============================================================================
function getVariableBlobentry end
function getVariableBlobentries end
function addVariableBlobentry! end
function addVariableBlobentries! end
function mergeVariableBlobentry! end
function mergeVariableBlobentries! end
function deleteVariableBlobentry! end
function deleteVariableBlobentries! end

function getFactorBlobentry end
function getFactorBlobentries end
function addFactorBlobentry! end
function addFactorBlobentries! end
function mergeFactorBlobentry! end
function mergeFactorBlobentries! end
function deleteFactorBlobentry! end
function deleteFactorBlobentries! end

function listVariableBlobentries end
function listFactorBlobentries end

function hasVariableBlobentry end
function hasFactorBlobentry end

##==============================================================================
## Agent/Graph/Model Blob Entries CRUD
##==============================================================================

function getGraphBlobentry end
function getGraphBlobentries end
function addGraphBlobentry! end
function addGraphBlobentries! end
function mergeGraphBlobentry! end
function mergeGraphBlobentries! end
function deleteGraphBlobentry! end
function deleteGraphBlobentries! end

function getAgentBlobentry end
function getAgentBlobentries end
function addAgentBlobentry! end
function addAgentBlobentries! end
function mergeAgentBlobentry! end
function mergeAgentBlobentries! end
function deleteAgentBlobentry! end
function deleteAgentBlobentries! end

function getModelBlobentry end
function getModelBlobentries end
function addModelBlobentry! end
function addModelBlobentries! end
function mergeModelBlobentry! end
function mergeModelBlobentries! end
function deleteModelBlobentry! end
function deleteModelBlobentries! end

function listGraphBlobentries end
function listAgentBlobentries end
function listModelBlobentries end

function hasGraphBlobentry end
function hasAgentBlobentry end
function hasModelBlobentry end
##==============================================================================
## Blobentry [default] bulk operations
##==============================================================================

function addVariableBlobentries!(dfg::AbstractDFG, vLbl::Symbol, entries::Vector{Blobentry})
    addVariableBlobentry!.(dfg, vLbl, entries)
    return entries
end

function addFactorBlobentries!(dfg::AbstractDFG, fLbl::Symbol, entries::Vector{Blobentry})
    addFactorBlobentry!.(dfg, fLbl, entries)
    return entries
end

function addAgentBlobentries!(dfg::AbstractDFG, entries::Vector{Blobentry})
    addAgentBlobentry!.(dfg, entries)
    return entries
end

function addGraphBlobentries!(dfg::AbstractDFG, entries::Vector{Blobentry})
    addGraphBlobentry!.(dfg, entries)
    return entries
end

function mergeVariableBlobentries!(
    dfg::AbstractDFG,
    vLbl::Symbol,
    entries::Vector{Blobentry},
)
    mergeVariableBlobentry!.(dfg, vLbl, entries)
    return length(entries)
end
function mergeFactorBlobentries!(dfg::AbstractDFG, fLbl::Symbol, entries::Vector{Blobentry})
    mergeFactorBlobentry!.(dfg, fLbl, entries)
    return length(entries)
end
function mergeAgentBlobentries!(dfg::AbstractDFG, entries::Vector{Blobentry})
    mergeAgentBlobentry!.(dfg, entries)
    return length(entries)
end
function mergeGraphBlobentries!(dfg::AbstractDFG, entries::Vector{Blobentry})
    mergeGraphBlobentry!.(dfg, entries)
    return length(entries)
end

function deleteVariableBlobentries!(
    dfg::AbstractDFG,
    varLabel::Symbol,
    labels::Vector{Symbol},
)
    cnts = map(labels) do label
        return deleteVariableBlobentry!(dfg, varLabel, label)
    end
    return sum(cnts)
end

function deleteFactorBlobentries!(
    dfg::AbstractDFG,
    facLabel::Symbol,
    labels::Vector{Symbol},
)
    cnts = map(labels) do label
        return deleteFactorBlobentry!(dfg, facLabel, label)
    end
    return sum(cnts)
end

function deleteAgentBlobentries!(dfg::AbstractDFG, labels::Vector{Symbol})
    cnts = map(labels) do label
        return deleteAgentBlobentry!(dfg, label)
    end
    return sum(cnts)
end

function deleteGraphBlobentries!(dfg::AbstractDFG, labels::Vector{Symbol})
    cnts = map(labels) do label
        return deleteGraphBlobentry!(dfg, label)
    end
    return sum(cnts)
end

##==============================================================================
## Blobentry - Helper functions, Lists, etc
##==============================================================================

function getVariableBlobentries(
    dfg::AbstractDFG,
    variableLabel::Symbol;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
)
    return getBlobentries(getVariable(dfg, variableLabel); labelFilter, blobIdFilter)
end

function gatherBlobentries(
    dfg::AbstractDFG;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
    solvableFilter::Union{Nothing, Function} = nothing,
    tagsFilter::Union{Nothing, Function} = nothing,
    typeFilter::Union{Nothing, Function} = nothing,
    variableLabelFilter::Union{Nothing, Function} = nothing,
)
    vls = listVariables(
        dfg;
        solvableFilter,
        tagsFilter,
        typeFilter,
        labelFilter = variableLabelFilter,
    )
    return map(vls) do vl
        return vl => getVariableBlobentries(dfg, vl; labelFilter, blobIdFilter)
    end
end
const collectBlobentries = gatherBlobentries

function listVariableBlobentries(dfg::AbstractDFG, label::Symbol)
    return listBlobentries(getVariable(dfg, label))
end

"""
    $(SIGNATURES)
Finds and returns the first blob entry that matches the filter.
The result is sorted by `sortby[=getLabel]` and `sortlt[=natural_lt]` before returning the first entry.
Also see: [`getBlobentry`](@ref)
"""
function getfirstBlobentry(
    node;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
    sortby::Function = getLabel,
    sortlt::Function = natural_lt,
)
    entries = getBlobentries(node; labelFilter, blobIdFilter)
    if isempty(entries)
        return nothing
    else
        return sort(entries; by = sortby, lt = sortlt)[1]
    end
end

function getfirstVariableBlobentry(
    dfg::AbstractDFG,
    label::Symbol;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
)
    return getfirstBlobentry(getVariable(dfg, label); labelFilter, blobIdFilter)
end

## =============================================================================
## TODO Maybe deprecate/remove
## =============================================================================

"""
    $SIGNATURES
List a collection of blob entries per variable that match a particular `pattern::Regex`.

Notes
- Optional sort function argument, default is unsorted.
  - Likely use of `sortDFG` for basic Symbol sorting.

Example
```julia
listBlobentrySequence(fg, :x0, r"IMG_CENTER", sortDFG)
15-element Vector{Symbol}:
 :IMG_CENTER_21676
 :IMG_CENTER_21677
 :IMG_CENTER_21678
 :IMG_CENTER_21679
...
```
"""
function listBlobentrySequence(
    dfg::AbstractDFG,
    lb::Symbol,
    pattern::Regex,
    _sort::Function = (x) -> x,
)
    #
    ents_ = listVariableBlobentries(dfg, lb)
    entReg = map(l -> match(pattern, string(l)), ents_)
    entMsk = entReg .!== nothing
    return ents_[findall(entMsk)] |> _sort
end

"""
    $SIGNATURES

If the blob label `datalabel` already exists, then this function will return the name `datalabel_1`.
If the blob label `datalabel_1` already exists, then this function will return the name `datalabel_2`.
"""
function incrDataLabelSuffix(
    dfg::AbstractDFG,
    vla::Symbol,
    bllb::Union{Symbol, <:AbstractString};
    datalabel = Ref(""),
)
    count = 1
    hasund = false
    len = 0
    try
        de = getfirstVariableBlobentry(dfg, vla; labelFilter = contains(string(bllb)))
        isnothing(de) && return Symbol(bllb) # no match, return as is
        bllb = string(bllb)
        # bllb *= bllb[end] != '_' ? "_" : ""
        datalabel[] = string(de.label)
        dlb = match(r"\d*", reverse(datalabel[]))
        # slightly complicated search if blob name already has an underscore number suffix, e.g. `_4`
        count, hasund, len = if occursin(Regex(dlb.match * "_"), reverse(datalabel[]))
            parse(Int, dlb.match |> reverse) + 1, true, length(dlb.match)
        else
            1, datalabel[][end] == '_', 0
        end
    catch err
        # append latest count
        if !(err isa KeyError)
            throw(err)
        end
    end
    # the piece from old label without the suffix count number
    bllb = datalabel[][1:(end - len)]
    if !hasund || bllb[end] != '_'
        bllb *= "_"
    end
    bllb *= string(count)

    return Symbol(bllb)
end
