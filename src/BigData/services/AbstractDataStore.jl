"""
    $(SIGNATURES)
Get the data for the specified entry, returns the data or Nothing.
"""
function getBigData(store::D, entry::E)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractBigDataEntry}
    error("$(typeof(store)) doesn't override 'getData'.")
end

"""
    $(SIGNATURES)
Adds the data to the store with the given entry. The function will warn if the entry already
exists and will overwrite it.
"""
function addBigData!(store::D, entry::E, data::T)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractBigDataEntry}
    error("$(typeof(store)) doesn't override 'addData!'.")
end

"""
    $(SIGNATURES)
Update the data in the store. The function will error and return nothing if
the entry does not exist.
"""
function updateBigData!(store::D, entry::E, data::T)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractBigDataEntry}
    error("$(typeof(store)) doesn't override 'updateData!'.")
end

"""
    $(SIGNATURES)
Delete the data in the store for the given entry. The function will error and return nothing if
the entry does not exist.
"""
function deleteBigData!(store::D, entry::E)::Union{Nothing, T} where {T, D <: AbstractDataStore{T}, E <: AbstractBigDataEntry}
    error("$(typeof(store)) doesn't override 'deleteData!'.")
end

"""
    $(SIGNATURES)
List all entries in the data store.
"""
function listStoreEntries(store::D)::Vector{E} where {D <: AbstractDataStore, E <: AbstractBigDataEntry}
    error("$(typeof(store)) doesn't override 'listEntries'.")
end

"""
    $(SIGNATURES)
Copies all the entries from the source into the destination.
Can specify which entries to copy with the `sourceEntries` parameter.
Returns the list of copied entries.
"""
function copyStore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: AbstractBigDataEntry}
    # Quick check
    destEntries = listStoreEntries(destStore)
    typeof(sourceEntries) != typeof(destEntries) && error("Can't copy stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
    # Same source/destination check
    sourceStore == destStore && error("Can't specify same store for source and destination.")
    # Otherwise, continue
    for sourceEntry in sourceEntries
        addBigData!(destStore, deepcopy(sourceEntry), getBigData(sourceStore, sourceEntry))
    end
    return sourceEntries
end
