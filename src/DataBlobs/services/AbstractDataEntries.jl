##

getHash(entry::AbstractDataEntry) = hex2bytes(entry.hash)


##

import Base: ==

function ==(a::GeneralDataEntry, b::GeneralDataEntry)
    return a.label == b.label &&
        a.storeKey == b.storeKey &&
        a.mimeType == b.mimeType &&
        Dates.value(a.createdTimestamp - b.createdTimestamp) < 1000 &&
        Dates.value(a.lastUpdatedTimestamp - b.lastUpdatedTimestamp) < 1000 #1 second
end

# function ==(a::MongodbDataEntry, b::MongodbDataEntry)
#     return a.label == b.label && a.oid == b.oid
# end
#
# function ==(a::FileDataEntry, b::FileDataEntry)
#     return a.label == b.label && a.filename == b.filename
# end

"""
    $(SIGNATURES)
Add Big Data Entry to a DFG variable
"""
function addDataEntry!(var::AbstractDFGVariable, bde::AbstractDataEntry)
    haskey(var.dataDict, bde.label) && error("Data entry $(bde.label) already exists in variable")
    var.dataDict[bde.label] = bde
    return bde
end


"""
    $(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractDataEntry)
    return addDataEntry!(getVariable(dfg, label), bde)
end


"""
$(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.

Example

See docs for `getDataEntryElement`.

Related

addData!, getDataEntryElement, fetchData
"""
function addData!(dfg::AbstractDFG,
                  lbl::Symbol,
                  datastore::Union{FileDataStore, InMemoryDataStore},
                  descr::Symbol,
                  mimeType::AbstractString,
                  data::Vector{UInt8} )
  #
  node = isVariable(dfg, lbl) ? getVariable(dfg, lbl) : getFactor(dfg, lbl)
  # Make a big data entry in the graph - use JSON2 to just write this
  entry = GeneralDataEntry(dfg, node, descr, mimeType=mimeType)
  # Set it in the store
  addDataBlob!(datastore, entry, data)
  # Add the entry to the graph
  addDataEntry!(node, entry)
end
# const addDataEntry! = addData!

"""
    $SIGNATURES

Does a data entry (element) exist at `key`.
"""
hasDataEntry(var::DFGVariable, key::Symbol) = haskey(var.dataDict, key)

"""
    $(SIGNATURES)
Get big data entry
"""
function getDataEntry(var::AbstractDFGVariable, key::Symbol)
    !hasDataEntry(var, key) && error("Data entry $(key) does not exist in variable")
    return var.dataDict[key]
end

function getDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)
    return getDataEntry(getVariable(dfg, label), key)
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
entry, rawData = fetchData(fg, :x0, datastore, :SOUND_DATA)

# unpack data to original format (this must be done by the user)
@show entry.mimeType # "applicatio/json"
userFormat = JSON2.read(IOBuffer(rawData))
```

Related

addDataEntry!, addData!, fetchData, fetchDataEntryElement
"""
function getDataEntryBlob(dfg::AbstractDFG,
                          dfglabel::Symbol,
                          datastore::Union{FileDataStore, InMemoryDataStore},
                          datalabel::Symbol)
  #
  vari = getVariable(dfg, dfglabel)
  if !hasDataEntry(vari, datalabel)
      # current standards is to fail hard
    error("missing data entry $datalabel in $dfglabel")
    # return nothing, nothing
  end
  entry = getDataEntry(vari, datalabel)
  element = getDataBlob(datastore, entry)
  return entry, element
end
const fetchDataEntryElement = getDataEntryBlob
const fetchData = getDataEntryBlob

#

"""
    $(SIGNATURES)
Update big data entry

DevNote
- DF, unclear if `update` verb is applicable in this case, see #404
"""
function updateDataEntry!(var::AbstractDFGVariable,  bde::AbstractDataEntry)
    !haskey(var.dataDict, bde.label) && (@warn "$(bde.label) does not exist in variable, adding")
    var.dataDict[bde.label] = bde
    return bde
end
function updateDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractDataEntry)
    # !isVariable(dfg, label) && return nothing
    return updateDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry from the factor graph.
Note this doesn't remove it from any data stores.

Notes:
- users responsibility to delete big data in db before deleting entry
"""
function deleteDataEntry!(var::AbstractDFGVariable, key::Symbol)
    return pop!(var.dataDict, key)
end
function deleteDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)
    #users responsibility to delete big data in db before deleting entry
    # !isVariable(dfg, label) && return nothing
    return deleteDataEntry!(getVariable(dfg, label), key)
end

function deleteDataEntry!(var::AbstractDFGVariable, entry::AbstractDataEntry)
    #users responsibility to delete big data in db before deleting entry
    return deleteDataEntry!(var, entry.label)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractDataEntry}
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
listDataEntries
"""
function listDataEntries(var::AbstractDFGVariable)
    collect(keys(var.dataDict))
end

function listDataEntries(dfg::AbstractDFG, label::Symbol)
    # !isVariable(dfg, label) && return nothing
    listDataEntries(getVariable(dfg, label))
end
