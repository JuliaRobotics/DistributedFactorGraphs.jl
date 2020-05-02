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
function addBigDataEntry!(var::AbstractDFGVariable, bde::AbstractBigDataEntry)
    haskey(var.bigData,bde.key) && error("BigData entry $(bde.key) already exists in variable")
    var.bigData[bde.key] = bde
    return bde
end

"""
    $(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addBigDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractBigDataEntry)
    return addBigDataEntry!(getVariable(dfg, label), bde)
end

addDataEntry!(x...) = addBigDataEntry!(x...)

"""
$(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.

Example

See docs for `getDataEntryElement`.

Related

addData!, getDataEntryElement, fetchData
"""
function addDataEntry!(dfg::AbstractDFG,
                       lbl::Symbol,
                       datastore::Union{FileDataStore, InMemoryDataStore},
                       descr::Symbol,
                       mimeType::AbstractString,
                       data::Vector{UInt8} )
  #
  node = isVariable(dfg, lbl) ? getVariable(dfg, lbl) : getFactor(dfg, lbl)
  # Make a big data entry in the graph - use JSON2 to just write this
  entry = GeneralBigDataEntry(dfg, node, descr, mimeType=mimeType)
  # Set it in the store
  addBigData!(datastore, entry, data)
  # Add the entry to the graph
  addBigDataEntry!(node, entry)
end
const addData! = addDataEntry!

"""
    $SIGNATURES

Does a data entry (element) exist at `key`.
"""
hasDataEntry(var::DFGVariable, key::Symbol) = haskey(var.bigData, key)
const hasBigDataEntry = hasDataEntry

"""
    $(SIGNATURES)
Get big data entry
"""
function getBigDataEntry(var::AbstractDFGVariable, key::Symbol)
    !hasDataEntry(var, key) && (error("BigData entry $(key) does not exist in variable"); return nothing)
    return var.bigData[key]
end

function getBigDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getBigDataEntry(getVariable(dfg, label), key)
end

"""
$SIGNATURES
Get both the entry and raw data element from datastore returning as a tuple.

Notes:
- This is the counterpart to `addDataEntry!`.
- Data is identified by the node in the DFG object `dfglabel::Symbol` as well as `datalabel::Symbol`.
- The data should have been stored along with a `entry.mimeType::String` which describes the format of the data.
- ImageMagick.jl is useful for storing images in png or jpg compressed format.

Example

```julia
# some dfg object
fg = initfg()
addVariable!(fg, :x0, IIF.ContinuousScalar) # using IncrementalInference
# FileDataStore (as example)
datastore = FileDataStore(joinLogPath(fg,"datastore"))

# now some data comes in
mydata = Dict(:soundBite => randn(Float32, 10000), :meta => "something about lazy foxes and fences.")

# store the data
addDataEntry!( fg, :x0, datastore, :SOUND_DATA, "application/json", Vector{UInt8}(JSON2.write( mydata ))  )

# get/fetch the data

# unpack data to original format (this must be done by the user)
@show entry.mimeType # "applicatio/json"
userFormat = JSON2.read(IOBuffer(rawData))
```

Related

addDataEntry!, addData!, fetchData, fetchDataEntryElement
"""
function getDataEntryElement(dfg::AbstractDFG, dfglabel::Symbol, datastore::DataStore, datalabel::Symbol)
  vari = getVariable(dfg, dfglabel)
  if !hasDataEntry(vari, datalabel)
    @error "missing data entry $datalabel in $dfglabel"
    return nothing, nothing
  end
  entry = getBigDataEntry(vari, datalabel)
  element = getBigData(datastore, entry)
  return entry, element
end
const fetchDataEntryElement = getDataEntryElement
const fetchData = getDataEntryElement



"""
    $(SIGNATURES)
Update big data entry

DevNote
- DF, unclear if `update` verb is applicable in this case, see #404
"""
function updateBigDataEntry!(var::AbstractDFGVariable,  bde::AbstractBigDataEntry)
    !haskey(var.bigData,bde.key) && (@warn "$(bde.key) does not exist in variable, adding")
    var.bigData[bde.key] = bde
    return bde
end
function updateBigDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractBigDataEntry)
    # !isVariable(dfg, label) && return nothing
    return updateBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry from the factor graph.
Note this doesn't remove it from any data stores.

Notes:
- users responsibility to delete big data in db before deleting entry
"""
function deleteBigDataEntry!(var::AbstractDFGVariable, key::Symbol)
    bde = getBigDataEntry(var, key)
    bde == nothing && return nothing
    delete!(var.bigData, key)
    return var
end
function deleteBigDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    #users responsibility to delete big data in db before deleting entry
    !isVariable(dfg, label) && return nothing
    return deleteBigDataEntry!(getVariable(dfg, label), key)
end

function deleteBigDataEntry!(var::AbstractDFGVariable, entry::AbstractBigDataEntry)
    #users responsibility to delete big data in db before deleting entry
    return deleteBigDataEntry!(var, entry.key)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractBigDataEntry}
"""
function getBigDataEntries(var::AbstractDFGVariable)
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    collect(values(var.bigData))
end
function getBigDataEntries(dfg::AbstractDFG, label::Symbol)
    !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    getBigDataEntries(getVariable(dfg, label))
end


"""
    $(SIGNATURES)
getBigDataKeys
"""
function getBigDataKeys(var::AbstractDFGVariable)
    collect(keys(var.bigData))
end
function getBigDataKeys(dfg::AbstractDFG, label::Symbol)
    !isVariable(dfg, label) && return nothing
    getBigDataKeys(getVariable(dfg, label))
end
