##==============================================================================
## AbstractDataEntry - compare
##==============================================================================

import Base: ==

@generated function ==(x::T, y::T) where T <: AbstractDataEntry
    mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
end

##==============================================================================
## AbstractDataEntry - common
##==============================================================================

"""
    $(SIGNATURES)
Function to generate source string - userId|robotId|sessionId|varLabel
"""
buildSourceString(dfg::AbstractDFG, label::Symbol) =
    "$(dfg.userId)|$(dfg.robotId)|$(dfg.sessionId)|$label"


##==============================================================================
## AbstractDataEntry - CRUD
##==============================================================================

"""
    $(SIGNATURES)
Get data entry
"""
function getDataEntry(var::AbstractDFGVariable, key::Symbol)
    !hasDataEntry(var, key) && error("Data entry $(key) does not exist in variable $(getLabel(var))")
    return var.dataDict[key]
end

function getDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getDataEntry(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Add Data Entry to a DFG variable
"""
function addDataEntry!(var::AbstractDFGVariable, bde::AbstractDataEntry)
    haskey(var.dataDict, bde.label) && error("Data entry $(bde.label) already exists in variable $(getLabel(var))")
    var.dataDict[bde.label] = bde
    return bde
end


"""
    $(SIGNATURES)
Add Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractDataEntry)
    return addDataEntry!(getVariable(dfg, label), bde)
end


"""
    $(SIGNATURES)
Update data entry

DevNote
- DF, unclear if `update` verb is applicable in this case, see #404
"""
function updateDataEntry!(var::AbstractDFGVariable,  bde::AbstractDataEntry)
    !haskey(var.dataDict, bde.label) && (@warn "$(bde.label) does not exist in variable $(getLabel(var)), adding")
    var.dataDict[bde.label] = bde
    return bde
end
function updateDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractDataEntry)
    # !isVariable(dfg, label) && return nothing
    return updateDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete data entry from the factor graph.
Note this doesn't remove it from any data stores.

Notes:
- users responsibility to delete data in db before deleting entry
"""
function deleteDataEntry!(var::AbstractDFGVariable, key::Symbol)
    return pop!(var.dataDict, key)
end
function deleteDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    #users responsibility to delete data in db before deleting entry
    # !isVariable(dfg, label) && return nothing
    return deleteDataEntry!(getVariable(dfg, label), key)
end

function deleteDataEntry!(var::AbstractDFGVariable, entry::AbstractDataEntry)
    #users responsibility to delete data in db before deleting entry
    return deleteDataEntry!(var, entry.label)
end

##==============================================================================
## AbstractDataEntry - Helper functions, Lists, etc
##==============================================================================

"""
    $SIGNATURES

Does a data entry (element) exist at `key`.
"""
hasDataEntry(var::DFGVariable, key::Symbol) = haskey(var.dataDict, key)


"""
    $(SIGNATURES)
Get data entries, Vector{AbstractDataEntry}
"""
function getDataEntries(var::AbstractDFGVariable)
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractDataEntry}}?
    collect(values(var.dataDict))
end
function getDataEntries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractDataEntry}}?
    getDataEntries(getVariable(dfg, label))
end

"""
    $(SIGNATURES)
List the data entries associated with a particular variable.
"""
function listDataEntries(var::AbstractDFGVariable)
    collect(keys(var.dataDict))
end

function listDataEntries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    listDataEntries(getVariable(dfg, label))
end

"""
    $SIGNATURES
List a collection of data entries per variable that match a particular `pattern::Regex`.

Notes
- Optional sort function argument, default is unsorted.
  - Likely use of `sortDFG` for basic Symbol sorting.

Example
```julia
listDataEntrySequence(fg, :x0, r"IMG_CENTER", sortDFG)
15-element Vector{Symbol}:
 :IMG_CENTER_21676
 :IMG_CENTER_21677
 :IMG_CENTER_21678
 :IMG_CENTER_21679
...
```
"""
function listDataEntrySequence( dfg::AbstractDFG,
                                lb::Symbol,
                                pattern::Regex,
                                _sort::Function=(x)->x)
    #
    ents_ = listDataEntries(dfg, lb)
    entReg = map(l->match(pattern, string(l)), ents_)
    entMsk = entReg .!== nothing
    ents_[findall(entMsk)] |> _sort
end
