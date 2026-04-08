##==============================================================================
## Blobentry - CRUD
##==============================================================================
function addVariableBlobentry! end
function addVariableBlobentries! end
function getVariableBlobentry end
function getVariableBlobentries end
function mergeVariableBlobentry! end
function mergeVariableBlobentries! end
function deleteVariableBlobentry! end
function deleteVariableBlobentries! end
function listVariableBlobentries end
function hasVariableBlobentry end

function getFactorBlobentry end
function getFactorBlobentries end
function addFactorBlobentry! end
function addFactorBlobentries! end
function mergeFactorBlobentry! end
function mergeFactorBlobentries! end
function deleteFactorBlobentry! end
function deleteFactorBlobentries! end
function listFactorBlobentries end
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

# ==============================================================================
# THE FOLLOWING ARE UNSTABLE OPPERATIONS
# ==============================================================================

# ==============================================================================
# Blobentry - Helper functions, Lists, etc
# ==============================================================================

function gatherBlobentries(
    dfg::AbstractDFG;
    whereLabel::Union{Nothing, Function} = nothing,
    whereBlobid::Union{Nothing, Function} = nothing,
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereVariableLabel::Union{Nothing, Function} = nothing,
)
    vls = listVariables(
        dfg;
        whereSolvable,
        whereTags,
        whereType,
        whereLabel = whereVariableLabel,
    )
    return map(vls) do vl
        return vl => getVariableBlobentries(dfg, vl; whereLabel, whereBlobid)
    end
end
const collectBlobentries = gatherBlobentries

"""
    $(SIGNATURES)
Finds and returns the first blob entry that matches the filter.
The result is sorted by `sortby[=getLabel]` and `sortlt[=natural_lt]` before returning the first entry.
Also see: [`getBlobentry`](@ref)
"""
function getfirstBlobentry(
    node;
    whereLabel::Union{Nothing, Function} = nothing,
    whereBlobid::Union{Nothing, Function} = nothing,
    sortby::Function = getLabel,
    sortlt::Function = natural_lt,
)
    entries = getBlobentries(node; whereLabel, whereBlobid)
    if isempty(entries)
        return nothing
    else
        return sort(entries; by = sortby, lt = sortlt)[1]
    end
end

function getfirstVariableBlobentry(
    dfg::AbstractDFG,
    label::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
    whereBlobid::Union{Nothing, Function} = nothing,
)
    return getfirstBlobentry(getVariable(dfg, label); whereLabel, whereBlobid)
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
        de = getfirstVariableBlobentry(dfg, vla; whereLabel = contains(string(bllb)))
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
