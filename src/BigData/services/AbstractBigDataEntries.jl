import Base: ==

function ==(a::GeneralBigDataEntry, b::GeneralBigDataEntry)
    return a.key == b.key &&
        a.storeKey == b.storeKey &&
        a.mimeType == b.mimeType &&
        Dates.value(a.createdTimestamp - b.createdTimestamp) < 1000 &&
        Dates.value(a.lastUpdatedTimestamp - b.lastUpdatedTimestamp) < 1000 #1 second
end

function ==(a::MongodbBigDataEntry, b::MongodbBigDataEntry)
    return a.key == b.key && a.oid == b.oid
end

function ==(a::FileBigDataEntry, b::FileBigDataEntry)
    return a.key == b.key && a.filename == b.filename
end

"""
    $(SIGNATURES)
Add Big Data Entry to a DFG variable
"""
function addBigDataEntry!(var::AbstractDFGVariable, bde::AbstractBigDataEntry)::AbstractBigDataEntry
    haskey(var.bigData,bde.key) && error("BigData entry $(bde.key) already exists in variable")
    var.bigData[bde.key] = bde
    return bde
end

"""
    $(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addBigDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractBigDataEntry)::AbstractBigDataEntry
    return addBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Get big data entry
"""
function getBigDataEntry(var::AbstractDFGVariable, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    !haskey(var.bigData, key) && (error("BigData entry $(key) does not exist in variable"); return nothing)
    return var.bigData[key]
end

function getBigDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    return getBigDataEntry(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Update big data entry
"""
function updateBigDataEntry!(var::AbstractDFGVariable,  bde::AbstractBigDataEntry)::Union{Nothing, AbstractBigDataEntry}
    !haskey(var.bigData,bde.key) && (@warn "$(bde.key) does not exist in variable, adding")
    var.bigData[bde.key] = bde
    return bde
end
function updateBigDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractBigDataEntry)::Union{Nothing, AbstractBigDataEntry}
    # !isVariable(dfg, label) && return nothing
    return updateBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry from the factor graph.
Note this doesn't remove it from any data stores.
"""
function deleteBigDataEntry!(var::AbstractDFGVariable, key::Symbol)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    bde = getBigDataEntry(var, key)
    bde == nothing && return nothing
    delete!(var.bigData, key)
    return var
end
function deleteBigDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    !isVariable(dfg, label) && return nothing
    return deleteBigDataEntry!(getVariable(dfg, label), key)
end

function deleteBigDataEntry!(var::AbstractDFGVariable, entry::AbstractBigDataEntry)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    return deleteBigDataEntry!(var, entry.key)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractBigDataEntry}
"""
function getBigDataEntries(var::AbstractDFGVariable)::Vector{AbstractBigDataEntry}
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    collect(values(var.bigData))
end
function getBigDataEntries(dfg::AbstractDFG, label::Symbol)::Union{Nothing, Vector{AbstractBigDataEntry}}
    !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    getBigDataEntries(getVariable(dfg, label))
end


"""
    $(SIGNATURES)
getBigDataKeys
"""
function getBigDataKeys(var::AbstractDFGVariable)::Vector{Symbol}
    collect(keys(var.bigData))
end
function getBigDataKeys(dfg::AbstractDFG, label::Symbol)::Union{Nothing, Vector{Symbol}}
    !isVariable(dfg, label) && return nothing
    getBigDataKeys(getVariable(dfg, label))
end
