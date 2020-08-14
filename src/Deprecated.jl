##==============================================================================
# deprecation staging area
##==============================================================================

##==============================================================================
## Remove in 0.11
##==============================================================================

@deprecate listSolvekeys(x...; kwargs...) listSolveKeys(x...;kwargs...)

@deprecate addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solveKey::Symbol) addVariableSolverData!(dfg, variablekey, vnd)

@deprecate updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::AbstractPointParametricEst, ppekey::Symbol) updatePPE!(dfg, variablekey, ppe)

@deprecate addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::AbstractPointParametricEst, ppekey::Symbol) addPPE!(dfg, variablekey, ppe)


export AbstractDataStore
abstract type AbstractDataStore end
struct GeneralDataEntry <: AbstractDataEntry end
GeneralDataEntry(args...; kwargs...) = error("`GeneralDataEntry` is deprecated, use `BlobStoreEntry`")

export InMemoryDataStore, FileDataStore

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


addData!(dfg::AbstractDFG,
         lbl::Symbol,
         datastore::Union{FileDataStore, InMemoryDataStore},
         descr::Symbol,
         mimeType::AbstractString,
         data::Vector{UInt8} ) = error("This API, FileDataStore and in MemoryDataStore is deprecated use new api parameter order and FolderStore")

export addDataElement!
addDataElement!(dfg::AbstractDFG,
                lbl::Symbol,
                datastore::Union{FileDataStore, InMemoryDataStore},
                descr::Symbol,
                mimeType::AbstractString,
                data::Vector{UInt8} ) = error("This API, FileDataStore and in MemoryDataStore is deprecated use addData! and FolderStore")



export getDataEntryBlob
getDataEntryBlob(dfg::AbstractDFG,
                 dfglabel::Symbol,
                 datastore::Union{FileDataStore, InMemoryDataStore},
                 datalabel::Symbol) = error("This API, FileDataStore and in MemoryDataStore is deprecated use getData and FolderStore")

export fetchDataEntryElement
const fetchDataEntryElement = getDataEntryBlob
export fetchData
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



