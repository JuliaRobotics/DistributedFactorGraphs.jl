##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.10
##==============================================================================

# temporary promote with warning
Base.promote_rule(::Type{DateTime}, ::Type{ZonedDateTime}) = DateTime
function Base.convert(::Type{DateTime}, ts::ZonedDateTime)
    @warn "DFG now uses ZonedDateTime, temporary promoting and converting to DateTime local time"
    return DateTime(ts, Local)
end

export listSolvekeys

@deprecate listSolvekeys(x...) listSolveKeys(x...)

export InferenceType
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize

abstract type InferenceType end

# These will become AbstractPrior, AbstractRelativeFactor, and AbstractRelativeFactorMinimize in 0.9.
abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

# I don't know how to deprecate this, any suggestions?
const AbstractBigDataEntry = AbstractDataEntry

@deprecate GeneralBigDataEntry(args...; kwargs...) GeneralDataEntry(args...; kwargs...)
@deprecate MongodbBigDataEntry(args...)  MongodbDataEntry(args...)
@deprecate FileBigDataEntry(args...)  FileDataEntry(args...)

# TODO entities/DFGVariable.jl DFGVariableSummary.bigData getproperty and setproperty!
# TODO entities/DFGVariable.jl DFGVariable.bigData getproperty and setproperty!
@deprecate getBigData(args...) getDataBlob(args...)
@deprecate addBigData!(args...) addDataBlob!(args...)
@deprecate updateBigData!(args...) updateDataBlob!(args...)
@deprecate deleteBigData!(args...) deleteDataBlob!(args...)
@deprecate listStoreEntries(args...) listDataBlobs(args...)
@deprecate hasBigDataEntry(args...) hasDataEntry(args...)


@deprecate getBigDataEntry(args...) getDataEntry(args...)
@deprecate addBigDataEntry!(args...)  addDataEntry!(args...)
@deprecate updateBigDataEntry!(args...) updateDataEntry!(args...)
@deprecate deleteBigDataEntry!(args...) deleteDataEntry!(args...)
@deprecate getBigDataKeys(args...) listDataEntries(args...)
@deprecate getBigDataEntries(args...) getDataEntries(args...)
@deprecate getDataEntryElement(args...) getDataEntryBlob(args...)


##==============================================================================
## Remove in 0.11
##==============================================================================

@deprecate addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solverKey::Symbol) addVariableSolverData!(dfg, variablekey, vnd)

@deprecate updateVariableSolverData!(dfg::AbstractDFG,
                                     variablekey::Symbol,
                                     vnd::VariableNodeData,
                                     solverKey::Symbol,
                                     useCopy::Bool=true,
                                     fields::Vector{Symbol}=Symbol[],
                                     verbose::Bool=true  ) updateVariableSolverData!(dfg, variablekey, vnd, useCopy, fields, verbose)


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
