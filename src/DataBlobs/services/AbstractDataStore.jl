"""
    $(SIGNATURES)
Get the data for the specified entry, returns the data or Nothing.
"""
function getDataBlob(store::D, entry::E)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractDataEntry}
    error("$(typeof(store)) doesn't override 'getDataBlob'.")
end

"""
    $(SIGNATURES)
Adds the data to the store with the given entry. The function will warn if the entry already
exists and will overwrite it.
"""
function addDataBlob!(store::D, entry::E, data::T)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractDataEntry}
    error("$(typeof(store)) doesn't override 'addDataBlob!'.")
end

"""
    $(SIGNATURES)
Update the data in the store. The function will error and return nothing if
the entry does not exist.
"""
function updateDataBlob!(store::D, entry::E, data::T)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractDataEntry}
    error("$(typeof(store)) doesn't override 'updateDataBlob!'.")
end

"""
    $(SIGNATURES)
Delete the data in the store for the given entry. The function will error and return nothing if
the entry does not exist.
"""
function deleteDataBlob!(store::D, entry::E)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractDataEntry}
    error("$(typeof(store)) doesn't override 'deleteDataBlob!'.")
end

"""
    $(SIGNATURES)
List all entries in the data store.
"""
function listDataBlobs(store::D) where D <: AbstractDataStore
    error("$(typeof(store)) doesn't override 'listDataBlobs'.")
end

"""
    $(SIGNATURES)
Copies all the entries from the source into the destination.
Can specify which entries to copy with the `sourceEntries` parameter.
Returns the list of copied entries.
"""
function copyStore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: AbstractDataEntry}
    # Quick check
    destEntries = listDataBlobs(destStore)
    typeof(sourceEntries) != typeof(destEntries) && error("Can't copy stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
    # Same source/destination check
    sourceStore == destStore && error("Can't specify same store for source and destination.")
    # Otherwise, continue
    for sourceEntry in sourceEntries
        addDataBlob!(destStore, deepcopy(sourceEntry), getDataBlob(sourceStore, sourceEntry))
    end
    return sourceEntries
end
