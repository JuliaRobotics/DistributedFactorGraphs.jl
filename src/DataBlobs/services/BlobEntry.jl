
##==============================================================================
## Blobentry - compare
##==============================================================================

import Base: ==

@generated function ==(x::T, y::T) where {T <: Blobentry}
    return mapreduce(n -> :(x.$n == y.$n), (a, b) -> :($a && $b), fieldnames(x))
end

##==============================================================================
## Blobentry - common
##==============================================================================

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

getHash(entry::Blobentry) = hex2bytes(entry.hash)
getTimestamp(entry::Blobentry) = entry.timestamp

function assertHash(de::Blobentry, db; hashfunction::Function = sha256)
    getHash(de) === nothing && @warn "Missing hash?" && return true
    if hashfunction(db) == getHash(de)
        return true #or nothing?
    else
        error("Stored hash and data blob hash do not match")
    end
end

function Base.show(io::IO, ::MIME"text/plain", entry::Blobentry)
    println(io, "Blobentry {")
    println(io, "  id:            ", entry.id)
    println(io, "  blobId:        ", entry.blobId)
    println(io, "  label:         ", entry.label)
    println(io, "  blobstore:     ", entry.blobstore)
    println(io, "  hash:          ", entry.hash)
    println(io, "  origin:        ", entry.origin)
    println(io, "  description:   ", entry.description)
    println(io, "  mimeType:      ", entry.mimeType)
    println(io, "  timestamp      ", entry.timestamp)
    println(io, "  _version:      ", entry._version)
    return println(io, "}")
end

##==============================================================================
## Blobentry - CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get data entry

Also see: [`addBlobentry!`](@ref), [`getBlob`](@ref), [`listBlobentries`](@ref)
"""
function getBlobentry(var::AbstractDFGVariable, key::Symbol)
    if !hasBlobentry(var, key)
        throw(LabelNotFoundError(key, keys(var.dataDict)))
    end
    return var.dataDict[key]
end

function getBlobentry(var::VariableDFG, key::Symbol)
    if !hasBlobentry(var, key)
        throw(LabelNotFoundError(key))
    end
    return var.blobEntries[findfirst(x -> x.label == key, var.blobEntries)]
end

"""
    $(SIGNATURES)
Finds and returns the first blob entry that matches the filter.

Also see: [`getBlobentry`](@ref)
"""
function getfirstBlobentry(var::AbstractDFGVariable, blobId::UUID)
    for (k, v) in var.dataDict
        if blobId == v.blobId
            return v
        end
    end
    throw(KeyError("No blobEntry with blobId $(blobId) found in variable $(getLabel(var))"))
end

function getfirstBlobentry(dfg::AbstractDFG, label::Symbol, blobId::UUID)
    return getfirstBlobentry(getVariable(dfg, label), blobId)
end

function getfirstBlobentry(var::AbstractDFGVariable, key::Regex)
    for (k, v) in var.dataDict
        if occursin(key, string(v.label))
            return v
        end
    end
    throw(
        KeyError(
            "No blobEntry with label matching regex $(key) found in variable $(getLabel(var))",
        ),
    )
end

function getfirstBlobentry(var::VariableDFG, key::Regex)
    firstIdx = findfirst(x -> contains(string(x.label), key), var.blobEntries)
    if isnothing(firstIdx)
        throw(KeyError("$key"))
    end
    return var.blobEntries[firstIdx]
end

function getfirstBlobentry(dfg::AbstractDFG, label::Symbol, key::Regex)
    els = listBlobentries(dfg, label)
    firstIdx = findfirst(contains(key), string.(els))
    isnothing(firstIdx) && throw(
        KeyError(
            "No blobEntry with label matching regex $(key) found in variable $(label)",
        ),
    )
    return getBlobentry(dfg, label, els[firstIdx])
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

function getBlobentry(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getBlobentry(getVariable(dfg, label), key)
end
# getBlobentry(dfg::AbstractDFG, label::Symbol, key::Symbol) = getBlobentry(getVariable(dfg, label), key)

"""
    $(SIGNATURES)
Add Data Entry to a DFG variable
Should be extended if DFG variable is not returned by reference.

Also see: [`getBlobentry`](@ref), [`addBlob!`](@ref), [`mergeBlobentries!`](@ref)
"""
function addBlobentry!(var::AbstractDFGVariable, entry::Blobentry;)
    # see https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/985
    # blobId::Union{UUID,Nothing} = (isnothing(entry.blobId) ? entry.id : entry.blobId),
    # blobSize::Int = (hasfield(Blobentry, :size) ? entry.size : -1)
    haskey(var.dataDict, entry.label) &&
        error("blobEntry $(entry.label) already exists on variable $(getLabel(var))")
    var.dataDict[entry.label] = entry
    return entry
end

function addBlobentry!(var::VariableDFG, entry::Blobentry)
    entry.label in getproperty.(var.blobEntries, :label) &&
        error("blobEntry $(entry.label) already exists on variable $(getLabel(var))")
    push!(var.blobEntries, entry)
    return entry
end

function addBlobentry!(dfg::AbstractDFG, vLbl::Symbol, entry::Blobentry;)
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
function mergeBlobentry!(var::AbstractDFGVariable, bde::Blobentry)
    if !haskey(var.dataDict, bde.label)
        addBlobentry!(var, bde)
    else
        var.dataDict[bde.label] = bde
    end
    return 1
end
function mergeBlobentry!(dfg::AbstractDFG, label::Symbol, bde::Blobentry)
    # !isVariable(dfg, label) && return nothing
    return mergeBlobentry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete a blob entry from the factor graph.
Note this doesn't remove it from any data stores.

Notes:
- users responsibility to delete data in db before deleting entry
"""
function deleteBlobentry!(var::AbstractDFGVariable, key::Symbol)
    pop!(var.dataDict, key)
    return 1
end

function deleteBlobentry!(var::VariableDFG, key::Symbol)
    if !hasBlobentry(var, key)
        throw(
            KeyError(
                "No dataEntry label $(key) found in variable $(getLabel(var)). Available keys: $(keys(var.dataDict))",
            ),
        )
    end
    deleteat!(var.blobEntries, findfirst(x -> x.label == key, var.blobEntries))
    return 1
end

function deleteBlobentry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    #users responsibility to delete data in db before deleting entry
    # !isVariable(dfg, label) && return nothing
    return deleteBlobentry!(getVariable(dfg, label), key)
end

function deleteBlobentry!(var::AbstractDFGVariable, entry::Blobentry)
    #users responsibility to delete data in db before deleting entry
    return deleteBlobentry!(var, entry.label)
end

##==============================================================================
## Blobentry - Helper functions, Lists, etc
##==============================================================================

"""
    $SIGNATURES

Does a blob entry (element) exist with `blobLabel`.
"""
hasBlobentry(var::AbstractDFGVariable, blobLabel::Symbol) = haskey(var.dataDict, blobLabel)

function hasBlobentry(var::VariableDFG, label::Symbol)
    return label in getproperty.(var.blobEntries, :label)
end

"""
    $(SIGNATURES)

Get blob entries, Vector{Blobentry}
"""
function getBlobentries(var::AbstractDFGVariable)
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,Blobentry}}?
    return collect(values(var.dataDict))
end

function getBlobentries(var::VariableDFG)
    return var.blobEntries
end

function getBlobentries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,Blobentry}}?
    return getBlobentries(getVariable(dfg, label))
end

function getBlobentries(dfg::AbstractDFG, label::Symbol, regex::Regex)
    entries = getBlobentries(dfg, label)
    return filter(entries) do e
        return occursin(regex, string(e.label))
    end
end

function getBlobentries(
    dfg::AbstractDFG,
    label::Symbol,
    skey::Union{Symbol, <:AbstractString},
)
    return getBlobentries(dfg, label, Regex(string(skey)))
end

"""
    $(SIGNATURES)

Get all blob entries matching a Regex pattern over variables

Notes
- Use `dropEmpties=true` to not include empty lists in result.
- Use keyword `varList` for which variables to search through.
"""
function getBlobentriesVariables(
    dfg::AbstractDFG,
    bLblPattern::Regex;
    varList::AbstractVector{Symbol} = sort(listVariables(dfg); lt = natural_lt),
    dropEmpties::Bool = false,
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

"""
    $(SIGNATURES)
List the blob entries associated with a particular variable.
"""
function listBlobentries(var::AbstractDFGVariable)
    return collect(keys(var.dataDict))
end

function listBlobentries(var::VariableDFG)
    return getproperty.(var.blobEntries, :label)
end

function listBlobentries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
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

Add a blob entry into the destination variable which already exists 
in a source variable.

See also: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`listBlobentries`](@ref), [`getBlob`](@ref)
"""
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

"""
    $SIGNATURES

If the blob label `datalabel` already exists, then this function will return the name `datalabel_1`.
If the blob label `datalabel_1` already exists, then this function will return the name `datalabel_2`.
"""
function incrDataLabelSuffix(
    dfg::AbstractDFG,
    vla::Union{Symbol, <:AbstractString},
    bllb::S;
    datalabel = Ref(""),
) where {S <: Union{Symbol, <:AbstractString}}
    count = 1
    hasund = false
    len = 0
    try
        de, _ = getData(dfg, Symbol(vla), bllb)
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

    return S(bllb)
end
