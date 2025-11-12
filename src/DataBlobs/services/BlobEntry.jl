##==============================================================================
## Blobentry - common
##==============================================================================
#TODO think buildSourceString should be deprecated.
"""
    $(SIGNATURES)
Function to generate source string - agentLabel|graphLabel|varLabel
"""
function buildSourceString(dfg::AbstractDFG, label::Symbol)
    return "$(getAgentLabel(dfg))|$(getGraphLabel(dfg))|$label"
end

##==============================================================================
## Blobentry - Defined in src/entities/AbstractDFG.jl
##==============================================================================
# Fields to be implemented
# label
# id

getTimestamp(entry::Blobentry) = entry.timestamp

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

# function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
#     println(io, "Blobentry {")
#     println(io, "  id:            ", entry.id)
#     println(io, "  blobid:        ", entry.blobid)
#     println(io, "  label:         ", entry.label)
#     println(io, "  blobstore:     ", entry.blobstore)
#     println(io, "  origin:        ", entry.origin)
#     println(io, "  description:   ", entry.description)
#     println(io, "  mimetype:      ", entry.mimetype)
#     println(io, "  timestamp      ", entry.timestamp)
#     println(io, "  version:      ", entry.version)
#     return println(io, "}")
# end

##==============================================================================
## Blobentry - CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get data entry

Also see: [`addBlobentry!`](@ref), [`getBlob`](@ref), [`listBlobentries`](@ref)
"""
function getBlobentry(var::AbstractGraphVariable, key::Symbol)
    if !hasBlobentry(var, key)
        throw(LabelNotFoundError("Blobentry", key, collect(keys(var.blobentries))))
    end
    return var.blobentries[key]
end

# function getBlobentry(var::VariableDFG, key::Symbol)
#     if !hasBlobentry(var, key)
#         throw(LabelNotFoundError("Blobentry", key))
#     end
#     return var.blobEntries[findfirst(x -> x.label == key, var.blobEntries)]
# end

"""
    $(SIGNATURES)
Finds and returns the first blob entry that matches the filter.
The result is sorted by `sortby[=getLabel]` and `sortlt[=natural_lt]` before returning the first entry.
Also see: [`getBlobentry`](@ref)
"""
function getfirstBlobentry(
    v::AbstractGraphVariable;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
    sortby::Function = getLabel,
    sortlt::Function = natural_lt,
)
    entries = getBlobentries(v; labelFilter, blobIdFilter)
    if isempty(entries)
        return nothing
    else
        return sort(entries; by = sortby, lt = sortlt)[1]
    end
end

function getfirstBlobentry(
    dfg::AbstractDFG,
    label::Symbol;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
)
    return getfirstBlobentry(getVariable(dfg, label); labelFilter, blobIdFilter)
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

function getBlobentry(dfg::AbstractDFG, varLabel::Symbol, label::Symbol)
    return getBlobentry(getVariable(dfg, varLabel), label)
end

"""
    $(SIGNATURES)
Add a `Blobentry` to a variable
Should be extended if DFG variable is not returned by reference.

Also see: [`getBlobentry`](@ref), [`addBlob!`](@ref), [`mergeBlobentry!`](@ref)
"""
function addBlobentry!(var::VariableCompute, entry::Blobentry)
    haskey(var.blobentries, entry.label) && throw(LabelExistsError("Blobentry", entry.label))
    var.blobentries[entry.label] = entry
    return entry
end

# function addBlobentry!(var::VariableDFG, entry::Blobentry)
#     entry.label in getproperty.(var.blobEntries, :label) &&
#         throw(LabelExistsError("Blobentry", entry.label))
#     push!(var.blobEntries, entry)
#     return entry
# end

function addBlobentry!(dfg::AbstractDFG, vLbl::Symbol, entry::Blobentry)
    return addBlobentry!(getVariable(dfg, vLbl), entry)
end

function addBlobentries!(dfg::AbstractDFG, vLbl::Symbol, entries::Vector{Blobentry})
    return addBlobentry!.(dfg, vLbl, entries)
end

"""
    $(SIGNATURES)
Update a Blobentry in the factor graph.
If the Blobentry does not exist, it will be added.
Notes:
"""
function mergeBlobentry!(var::AbstractGraphVariable, bde::Blobentry)
    if !haskey(var.blobentries, bde.label)
        addBlobentry!(var, bde)
    else
        var.blobentries[bde.label] = bde
    end
    return 1
end
function mergeBlobentry!(dfg::AbstractDFG, label::Symbol, bde::Blobentry)
    # !isVariable(dfg, label) && return nothing
    return mergeBlobentry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete a `Blobentry` from the factor graph variable.

Notes:
- This doesn't remove the associated `Blob` from any Blobstores.
"""
function deleteBlobentry!(var::VariableCompute, key::Symbol)
    !hasBlobentry(var, key) && throw(LabelNotFoundError("Blobentry", key))
    delete!(var.blobentries, key)
    return 1
end

# function deleteBlobentry!(var::VariableDFG, key::Symbol)
#     !hasBlobentry(var, key) && throw(LabelNotFoundError("Blobentry", key))
#     deleteat!(var.blobEntries, findfirst(x -> x.label == key, var.blobEntries))
#     return 1
# end

function deleteBlobentry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return deleteBlobentry!(getVariable(dfg, label), key)
end

function deleteBlobentry!(var::AbstractGraphVariable, entry::Blobentry)
    return deleteBlobentry!(var, entry.label)
end

##==============================================================================
## Default bulk Agent and Graph Blobentry operations
##==============================================================================
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

"""
    $SIGNATURES

Does a blob entry exist with `blobLabel`.
"""
hasBlobentry(v::VariableCompute, blobLabel::Symbol) = haskey(v.blobentries, blobLabel)

# function hasBlobentry(v::VariableDFG, label::Symbol)
#     return label in getproperty.(v.blobEntries, :label)
# end

"""
    $(SIGNATURES)

Get blob entries, returns a `Vector{Blobentry}`.
"""
function getBlobentries(v::VariableCompute)
    return collect(values(v.blobentries))
end

# function getBlobentries(v::VariableDFG)
#     return copy(v.blobEntries)
# end

function getBlobentries(
    v::AbstractGraphVariable;
    labelFilter::Union{Nothing, Function} = nothing,
    blobIdFilter::Union{Nothing, Function} = nothing,
)
    entries = getBlobentries(v)
    filterDFG!(entries, labelFilter, getLabel)
    filterDFG!(entries, blobIdFilter, x -> string(x.blobid))
    return entries
end

function getBlobentries(
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
        return vl => getBlobentries(dfg, vl; labelFilter, blobIdFilter)
    end
end
const collectBlobentries = gatherBlobentries

"""
    $(SIGNATURES)
List the blob entries associated with a particular variable.
"""
function listBlobentries(var::AbstractGraphVariable)
    return collect(keys(var.blobentries))
end

# function listBlobentries(var::VariableDFG)
#     return getproperty.(var.blobEntries, :label)
# end

function listBlobentries(dfg::AbstractDFG, label::Symbol)
    return listBlobentries(getVariable(dfg, label))
end

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
    ents_ = listBlobentries(dfg, lb)
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
        de = getfirstBlobentry(dfg, vla; labelFilter = contains(string(bllb)))
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
