##==============================================================================
# deprecation staging area
##==============================================================================

##==============================================================================
## Remove in 0.11
##==============================================================================
@deprecate addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solverKey::Symbol) addVariableSolverData!(dfg, variablekey, vnd)

@deprecate updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::AbstractPointParametricEst, ppekey::Symbol) updatePPE!(dfg, variablekey, ppe)

@deprecate addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::AbstractPointParametricEst, ppekey::Symbol) addPPE!(dfg, variablekey, ppe)


export AbstractDataStore
abstract type AbstractDataStore end
struct GeneralDataEntry <: AbstractDataEntry end
GeneralDataEntry(args...; kwargs...) = error("`GeneralDataEntry` is deprecated, use `BlobStoreEntry`")

struct FileDataStore <: AbstractDataStore end
FileDataStore(args...; kwargs...) = error("`FileDataStore` is deprecated, use `FolderStore`")

struct InMemoryDataStore <: AbstractDataStore end
InMemoryDataStore(args...; kwargs...) = error("`InMemoryDataStore` is deprecated, use TBD")#TODO

_uniqueKey(dfg::AbstractDFG, v::AbstractDFGVariable, key::Symbol)::Symbol = error("_uniqueKey is deprecated")

getDataBlob(store::AbstractDataStore, entry::AbstractDataEntry) = error("AbstractDataStore $(typeof(store)) is deprecated.")
addDataBlob!(store::AbstractDataStore, entry::AbstractDataEntry, data) = error("AbstractDataStore $(typeof(store)) is deprecated.")
updateDataBlob!(store::AbstractDataStore, entry::AbstractDataEntry, data)  = error("AbstractDataStore $(typeof(store)) is deprecated.")
deleteDataBlob!(store::AbstractDataStore, entry::AbstractDataEntry) = error("AbstractDataStore $(typeof(store)) is deprecated.")
listDataBlobs(store::AbstractDataStore) = error("AbstractDataStore $(typeof(store)) is deprecated.")



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

## softtype deprections
function Base.getproperty(x::InferenceVariable, f::Symbol)
  if f==:dims
      Base.depwarn("Softtype $(typeof(x)), field dims is deprecated, extend and use `getDims` instead",:getproperty)
  elseif f==:manifolds
      Base.depwarn("Softtype $(typeof(x)), field manifolds is deprecated, extend and use `getManifolds` instead",:getproperty)
  else
    if !(@isdefined softtypeFieldsWarnOnce)
      Base.depwarn("Softtype $(typeof(x)), will be required to be a singleton type in the future and can no longer have fields. *.$f called. Further warnings are suppressed",:getproperty)
      global softtypeFieldsWarnOnce = true
    end
  end
  return getfield(x,f)
end



# SmallData is now a Symbol Dict
function createSymbolDict(d::Dict{String, String})
  newsmalld = Dict{Symbol,SmallDataTypes}() 
  for p in pairs(d)
    push!(newsmalld, Symbol(p.first) => p.second)
  end
  return newsmalld
end

@deprecate setSmallData!(v::DFGVariable, smallData::Dict{String, String}) setSmallData!(v, createSymbolDict(smallData)) 



