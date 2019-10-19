
# TODO move to ...


# """
#     $(TYPEDEF)
# Abstract parent struct for big data entry.
# """
# abstract type AbstractBigDataEntry end

# --- AbstractBigData Interfaces ---
# fields to implement:
# - key::Symbol
# available methods:
# - addBigDataEntry!
# - getBigDataEntry
# - updateBigDataEntry!
# - deleteBigDataEntry!
# - getBigDataEntries
# - getBigDataKeys

export  addBigDataEntry!,
        getBigDataEntry,
        updateBigDataEntry!,
        deleteBigDataEntry!,
        getBigDataEntries,
        getBigDataKeys,
        MongodbBigDataEntry,
        FileBigDataEntry

# Methods

#TODO should this return Bool or the modified Variable?
"""
    $(SIGNATURES)
Add Big Data Entry to a DFG variable
"""
function addBigDataEntry!(var::AbstractDFGVariable, bde::AbstractBigDataEntry)::Bool
    haskey(var.bigData,bde.key) && @warn "$(bde.key) already exists in variable, overwriting!"
    var.bigData[bde.key] = bde
    return true
end

"""
    $(SIGNATURES)
Add Big Data Entry to distrubuted factor graph.
Should be extended if DFG variable is not returned by by reference.
"""
function addBigDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractBigDataEntry)::Bool
    return addBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Get big data entry
"""
function getBigDataEntry(var::AbstractDFGVariable, key::Symbol)::AbstractBigDataEntry
    return var.bigData[key]
end
function getBigDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)::AbstractBigDataEntry
    return getBigDataEntry(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Update big data entry
"""
function updateBigDataEntry!(var::AbstractDFGVariable,  bde::AbstractBigDataEntry)::Bool#TODO should this return Bool?
    !haskey(var.bigData,bde.key) && (@error "$(bde.key) does not exist in variable!"; return false)
    var.bigData[bde.key] = bde
    return true
end
function updateBigDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractBigDataEntry)::Bool
    updateBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry
"""
function deleteBigDataEntry!(var::AbstractDFGVariable, key::Symbol)::AbstractBigDataEntry #users responsibility to delete big data in db before deleting entry
    bde = getBigDataEntry(var, key)
    delete!(var.bigData, key)
    return bde
end

function deleteBigDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)::AbstractBigDataEntry #users responsibility to delete big data in db before deleting entry
    deleteBigDataEntry!(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractBigDataEntry}
"""
function getBigDataEntries(var::AbstractDFGVariable)::Vector{AbstractBigDataEntry}
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    collect(values(var.bigData))
end
function getBigDataEntries(dfg::AbstractDFG, label::Symbol)::Vector{AbstractBigDataEntry}
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
function getBigDataKeys(dfg::AbstractDFG, label::Symbol)::Vector{Symbol}
    getBigDataKeys(getVariable(dfg, label))
end



# Types <: AbstractBigDataEntry
"""
    $(TYPEDEF)
BigDataEntry in MongoDB.
"""
struct MongodbBigDataEntry <: AbstractBigDataEntry
    key::Symbol
    oid::NTuple{12, UInt8} #mongodb object id
    #maybe other fields such as:
    #flags::Bool ready, valid, locked, permissions
    #MIMEType::Symbol
end


"""
    $(TYPEDEF)
BigDataEntry in a file.
"""
struct FileBigDataEntry <: AbstractBigDataEntry
    key::Symbol
    filename::String
end
