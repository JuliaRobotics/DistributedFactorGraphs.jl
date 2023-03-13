
##==============================================================================
## BlobEntry - compare
##==============================================================================

import Base: ==

@generated function ==(x::T, y::T) where T <: BlobEntry
    mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
end


##==============================================================================
## BlobEntry - common
##==============================================================================

"""
    $(SIGNATURES)
Function to generate source string - userLabel|robotLabel|sessionLabel|varLabel
"""
buildSourceString(dfg::AbstractDFG, label::Symbol) =
    "$(getUserLabel(dfg))|$(getRobotLabel(dfg))|$(getSessionLabel(dfg))|$label"


##==============================================================================
## BlobEntry - Defined in src/entities/AbstractDFG.jl
##==============================================================================
# Fields to be implemented
# label
# id

getLabel(entry::BlobEntry) = entry.label
getId(entry::BlobEntry) = entry.id
getHash(entry::BlobEntry) = hex2bytes(entry.hash)
getTimestamp(entry::BlobEntry) = entry.timestamp



function assertHash(de::BlobEntry, db; hashfunction::Function = sha256)
    getHash(de) === nothing && @warn "Missing hash?" && return true
    if  hashfunction(db) == getHash(de)
        return true #or nothing?
    else
        error("Stored hash and data blob hash do not match")
    end
end


function Base.show(io::IO, entry::BlobEntry) 
    println(io, "_type=BlobEntry {")
    println(io, "  id:            ", entry.id) 
    println(io, "  blobId:        ", entry.blobId) 
    println(io, "  originId:      ", entry.originId) 
    println(io, "  label:         ", entry.label) 
    println(io, "  blobstore:     ", entry.blobstore) 
    println(io, "  hash:          ", entry.hash) 
    println(io, "  origin:        ", entry.origin) 
    println(io, "  description:   ", entry.description) 
    println(io, "  mimeType:      ", entry.mimeType)
    println(io, "  timestamp      ", entry.timestamp)
    println(io, "  _version:      ", entry._version) 
    println(io, "}") 
end 

Base.show(io::IO, ::MIME"text/plain", entry::BlobEntry) = show(io, entry)



##==============================================================================
## BlobEntry - CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get data entry

Also see: [`addBlobEntry`](@ref), [`getBlob`](@ref), [`listBlobEntries`](@ref)
"""
function getBlobEntry(var::AbstractDFGVariable, key::Symbol)
    !hasBlobEntry(var, key) && error("No dataEntry label $(key) found in variable $(getLabel(var))")
    return var.dataDict[key]
end

function getBlobEntry(var::AbstractDFGVariable, blobId::UUID)
    for (k,v) in var.dataDict
        if v.id == blobId
            return v
        end
    end
    throw(
        KeyError("No blobEntry with blobId $(blobId) found in variable $(getLabel(var))")
    )
end

#TODO consider changing this to use `first` as in julia's findfirst - as in findfirstBlobEntry->label::Symbol
# or getBlobEntryFirst, btw this returns a vector in some other places
function getBlobEntry(var::AbstractDFGVariable, key::Regex)
    for (k,v) in var.dataDict
        if occursin(key, string(v.label))
            return v
        end
    end
    throw(
        KeyError("No blobEntry with label matching regex $(key) found in variable $(getLabel(var))")
    )
end

getBlobEntry(var::AbstractDFGVariable, key::AbstractString) = getBlobEntry(var,Regex(key))


getBlobEntry(dfg::AbstractDFG, label::Symbol, key::Union{Symbol, UUID, <:AbstractString, Regex}) = getBlobEntry(getVariable(dfg, label), key)
# getBlobEntry(dfg::AbstractDFG, label::Symbol, key::Symbol) = getBlobEntry(getVariable(dfg, label), key)


"""
    $(SIGNATURES)
Add Data Entry to a DFG variable
Should be extended if DFG variable is not returned by reference.

Also see: [`getBlobEntry`](@ref), [`addBlob`](@ref), [`mergeBlobEntries!`](@ref)
"""
function addBlobEntry!(
    var::AbstractDFGVariable, 
    entry::BlobEntry;
    # see https://github.com/JuliaRobotics/DistributedFactorGraphs.jl/issues/985
    blobId::UUID = isnothing(entry.blobId) ? entry.id : entry.blobId ,
    blobSize::Int = hasfield(DistributedFactorGraphs.BlobEntry, :size) ? entry.size : -1 ,
)
    haskey(var.dataDict, entry.label) && error("blobEntry $(entry.label) already exists on variable $(getLabel(var))")
    var.dataDict[entry.label] = entry
    return entry
end

function addBlobEntry!(
    dfg::AbstractDFG, 
    vLbl::Symbol, 
    entry::BlobEntry;
    kw...
)
    return addBlobEntry!(getVariable(dfg, vLbl), entry; kw...)
end


"""
    $(SIGNATURES)
Update data entry

DevNote
- DF, unclear if `update` verb is applicable in this case, see #404
"""
function updateBlobEntry!(var::AbstractDFGVariable,  bde::BlobEntry)
    !haskey(var.dataDict, bde.label) && (@warn "$(bde.label) does not exist in variable $(getLabel(var)), adding")
    var.dataDict[bde.label] = bde
    return bde
end
function updateBlobEntry!(dfg::AbstractDFG, label::Symbol,  bde::BlobEntry)
    # !isVariable(dfg, label) && return nothing
    return updateBlobEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete a blob entry from the factor graph.
Note this doesn't remove it from any data stores.

Notes:
- users responsibility to delete data in db before deleting entry
"""
function deleteBlobEntry!(var::AbstractDFGVariable, key::Symbol)
    return pop!(var.dataDict, key)
end
function deleteBlobEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    #users responsibility to delete data in db before deleting entry
    # !isVariable(dfg, label) && return nothing
    return deleteBlobEntry!(getVariable(dfg, label), key)
end

function deleteBlobEntry!(var::AbstractDFGVariable, entry::BlobEntry)
    #users responsibility to delete data in db before deleting entry
    return deleteBlobEntry!(var, entry.label)
end




##==============================================================================
## BlobEntry - Helper functions, Lists, etc
##==============================================================================

"""
    $SIGNATURES

Does a blob entry (element) exist with `blobLabel`.
"""
hasBlobEntry(var::AbstractDFGVariable, blobLabel::Symbol) = haskey(var.dataDict, blobLabel)


"""
    $(SIGNATURES)
Get data entries, Vector{BlobEntry}
"""
function getBlobEntries(var::AbstractDFGVariable)
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,BlobEntry}}?
    collect(values(var.dataDict))
end
function getBlobEntries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,BlobEntry}}?
    getBlobEntries(getVariable(dfg, label))
end

"""
    $(SIGNATURES)
List the blob entries associated with a particular variable.
"""
function listBlobEntries(var::AbstractDFGVariable)
    collect(keys(var.dataDict))
end

function listBlobEntries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    listBlobEntries(getVariable(dfg, label))
end

"""
    $SIGNATURES
List a collection of blob entries per variable that match a particular `pattern::Regex`.

Notes
- Optional sort function argument, default is unsorted.
  - Likely use of `sortDFG` for basic Symbol sorting.

Example
```julia
listBlobEntrySequence(fg, :x0, r"IMG_CENTER", sortDFG)
15-element Vector{Symbol}:
 :IMG_CENTER_21676
 :IMG_CENTER_21677
 :IMG_CENTER_21678
 :IMG_CENTER_21679
...
```
"""
function listBlobEntrySequence( dfg::AbstractDFG,
                                lb::Symbol,
                                pattern::Regex,
                                _sort::Function=(x)->x)
    #
    ents_ = listBlobEntries(dfg, lb)
    entReg = map(l->match(pattern, string(l)), ents_)
    entMsk = entReg .!== nothing
    ents_[findall(entMsk)] |> _sort
end

"""
    $SIGNATURES

Add a blob entry into the destination variable which already exists 
in a source variable.

See also: [`addBlobEntry!`](@ref), [`getBlobEntry`](@ref), [`listBlobEntries`](@ref), [`getBlob`](@ref)
"""
function mergeBlobEntries!(
    dst::AbstractDFG, 
    dlbl::Symbol, 
    src::AbstractDFG, 
    slbl::Symbol, 
    bllb::Union{Symbol, UUID, <:AbstractString, Regex}
)
    #
    _makevec(s) = [s;]
    _makevec(s::AbstractVector) = s
    des_ = getBlobEntry(src, slbl, bllb)
    des = _makevec(des_)
    # don't add data entries that already exist 
    dde = listBlobEntries(dst, dlbl)
        # HACK, verb list should just return vector of Symbol. NCE36
        _getid(s) = s
        _getid(s::BlobEntry) = s.id
    uids = _getid.(dde) # (s->s.id).(dde)
    filter!(s -> !(_getid(s) in uids), des)
    # add any data entries not already in the destination variable, by uuid
    addBlobEntry!.(dst, dlbl, des)
end

function mergeBlobEntries!(
    dst::AbstractDFG, 
    dlbl::Symbol, 
    src::AbstractDFG, 
    slbl::Symbol, 
    ::Colon=:
)
    des = listBlobEntries(src, slbl)
    # don't add data entries that already exist 
    dde = listBlobEntries(dst, dlbl)
        # HACK, verb list should just return vector of Symbol. NCE36
        _getid(s) = s
        _getid(s::BlobEntry) = s.id    
    uids = _getid.(dde) # (s->s.id).(dde)
    filter!(s -> !(_getid(s) in uids), des)
    if 0  < length(des)
        union(((s->mergeBlobEntries!(dst, dlbl, src, slbl, s.id)).(des))...)
    end
end

function mergeBlobEntries!(
    dest::AbstractDFG,
    src::AbstractDFG,
    w...;
    varList::AbstractVector = listVariables(dest) |> sortDFG
)
    @showprogress 1 "merging data entries" for vl in varList
        mergeBlobEntries!(dest, vl, src, vl, w...)
    end
    varList
end

"""
    $SIGNATURES

If the blob label `datalabel` already exists, then this function will return the name `datalabel_1`.
If the blob label `datalabel_1` already exists, then this function will return the name `datalabel_2`.
"""
function incrDataLabelSuffix(
    dfg::AbstractDFG,
    vla,
    bllb::S; 
    datalabel=Ref("")
) where {S <: Union{Symbol, <:AbstractString}}
    count = 1
    hasund = false
    len = 0
    try
        de,_ = getData(dfg, Symbol(vla), bllb)
        bllb = string(bllb)
        # bllb *= bllb[end] != '_' ? "_" : ""
        datalabel[] = string(de.label)
        dlb = match(r"\d*", reverse(datalabel[]))
        # slightly complicated search if blob name already has an underscore number suffix, e.g. `_4`
        count, hasund, len = if occursin(Regex(dlb.match*"_"), reverse(datalabel[]))
            parse(Int, dlb.match |> reverse)+1, true, length(dlb.match)
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
    bllb = datalabel[][1:(end-len)]
    if !hasund || bllb[end] != '_'
        bllb *= "_"
    end
    bllb *= string(count)

    S(bllb)
end
