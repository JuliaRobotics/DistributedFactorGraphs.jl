##==============================================================================
## Blob CRUD interface
##==============================================================================

"""
Get the data blob for the specified blobstore or dfg.

Related
[`getBlobEntry`](@ref)

$(METHODLIST)
"""
function getBlob end

"""
Adds a blob to the blob store or dfg with the given entry.

Related
[`addBlobEntry!`](@ref)

$(METHODLIST)
"""
function addBlob! end

"""
Update a blob to the blob store or dfg with the given entry.
Related
[`updateBlobEntry!`](@ref)

$(METHODLIST)

DevNotes
- TODO TBD update verb on data since data blobs and entries are restricted to immutable only.
"""
function updateBlob! end

"""
Delete a blob from the blob store or dfg with the given entry.

Related
[`deleteBlobEntry!`](@ref)

$(METHODLIST)
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all ids in the blob store.
"""
function listBlobs end

##==============================================================================
## AbstractBlobStore CRUD Interface
##==============================================================================

function getBlob(store::AbstractBlobStore, ::UUID)
    return error("$(typeof(store)) doesn't override 'getBlob'.")
end

function addBlob!(store::AbstractBlobStore{T}, ::UUID, ::T) where {T}
    return error("$(typeof(store)) doesn't override 'addBlob!'.")
end

function updateBlob!(store::AbstractBlobStore{T}, ::UUID, ::T) where {T}
    return error("$(typeof(store)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(store::AbstractBlobStore, ::UUID)
    return error("$(typeof(store)) doesn't override 'deleteBlob!'.")
end

function listBlobs(store::AbstractBlobStore)
    return error("$(typeof(store)) doesn't override 'listBlobs'.")
end

function hasBlob(store::AbstractBlobStore, ::UUID)
    return error("$(typeof(store)) doesn't override 'hasBlob'.")
end

##==============================================================================
## AbstractBlobStore derived CRUD for Blob 
##==============================================================================

function getBlob(dfg::AbstractDFG, entry::BlobEntry)
    # cannot use entry.blobstore because the blob can be in any one of the blobstores
    stores = getBlobStores(dfg)
    for (k, store) in stores
        try
            blob = getBlob(store, entry)
            return blob
        catch err
            if !(err isa KeyError)
                throw(err)
            end
        end
    end
    throw(
        KeyError(
            "could not find $(entry.label), uuid $(entry.blobId) in any of the listed blobstores:\n $([s->getKey(s) for (s,v) in stores]))",
        ),
    )
end

function getBlob(store::AbstractBlobStore, entry::BlobEntry)
    blobId = isnothing(entry.blobId) ? entry.originId : entry.blobId
    return getBlob(store, blobId)
end

#add 
function addBlob!(dfg::AbstractDFG, entry::BlobEntry, data)
    return addBlob!(getBlobStore(dfg, entry.blobstore), entry, data)
end

function addBlob!(store::AbstractBlobStore{T}, entry::BlobEntry, data::T) where {T}
    blobId = isnothing(entry.blobId) ? entry.originId : entry.blobId
    return addBlob!(store, blobId, data)
end

# also creates an originId as uuid4
addBlob!(store::AbstractBlobStore, data) = addBlob!(store, uuid4(), data)

#fallback as not all blobStores use filename
function addBlob!(store::AbstractBlobStore, blobId::UUID, data, ::String)
    return addBlob!(store, blobId, data)
end

function addBlob!(store::AbstractBlobStore{T}, data::T, ::String) where {T}
    return addBlob!(store, uuid4(), data)
end

#update
function updateBlob!(dfg::AbstractDFG, entry::BlobEntry, data::T) where {T}
    return updateBlob!(getBlobStore(dfg, entry.blobstore), entry, data)
end

function updateBlob!(store::AbstractBlobStore, entry::BlobEntry, data)
    blobId = isnothing(entry.blobId) ? entry.originId : entry.blobId
    return updateBlob!(store, blobId, data)
end
#delete
function deleteBlob!(dfg::AbstractDFG, entry::BlobEntry)
    return deleteBlob!(getBlobStore(dfg, entry.blobstore), entry)
end

function deleteBlob!(store::AbstractBlobStore, entry::BlobEntry)
    blobId = isnothing(entry.blobId) ? entry.originId : entry.blobId
    return deleteBlob!(store, blobId)
end

#has
function hasBlob(dfg::AbstractDFG, entry::BlobEntry)
    return hasBlob(getBlobStore(dfg, entry.blobstore), entry.originId)
end

#TODO
# """
#     $(SIGNATURES)
# Copies all the entries from the source into the destination.
# Can specify which entries to copy with the `sourceEntries` parameter.
# Returns the list of copied entries.
# """
# function copyBlobStore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: BlobEntry}
#     # Quick check
#     destEntries = listBlobs(destStore)
#     typeof(sourceEntries) != typeof(destEntries) && error("Can't copy stores, source has entries of type $(typeof(sourceEntries)), destination has entries of type $(typeof(destEntries)).")
#     # Same source/destination check
#     sourceStore == destStore && error("Can't specify same store for source and destination.")
#     # Otherwise, continue
#     for sourceEntry in sourceEntries
#         addBlob!(destStore, deepcopy(sourceEntry), getBlob(sourceStore, sourceEntry))
#     end
#     return sourceEntries
# end

##==============================================================================
## FolderStore
##==============================================================================
struct FolderStore{T} <: AbstractBlobStore{T}
    key::Symbol
    folder::String
end

function FolderStore(foldername::String; label=:default_folder_store, createfolder = true)
    if createfolder && !isdir(foldername)
        @info "Folder '$foldername' doesn't exist - creating."
        # create new folder
        mkpath(foldername)
    end
    return FolderStore{Vector{UInt8}}(label, foldername)
end

blobfilename(store::FolderStore, blobId::UUID) = joinpath(store.folder, string(blobId))

function getBlob(store::FolderStore{T}, blobId::UUID) where {T}
    blobfilename = joinpath(store.folder, string(blobId))
    if isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        throw(KeyError("Could not find file '$(blobfilename)'."))
    end
end

function addBlob!(store::FolderStore{T}, blobId::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, string(blobId))
    if isfile(blobfilename)
        throw(KeyError("Key '$blobId' blob already exists."))
    else
        open(blobfilename, "w") do f
            return write(f, data)
        end
        # return data
        return blobId
    end
end

function updateBlob!(store::FolderStore{T}, blobId::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, string(blobId))
    if !isfile(blobfilename)
        @warn "Key '$blobId' doesn't exist."
    else
        open(blobfilename, "w") do f
            return write(f, data)
        end
        return data
    end
end

function deleteBlob!(store::FolderStore{T}, blobId::UUID) where {T}
    blobfilename = joinpath(store.folder, string(blobId))

    data = getBlob(store, blobId)
    rm(blobfilename)
    return data
end

#hasBlob or existsBlob?
function hasBlob(store::FolderStore, blobId::UUID)
    blobfilename = joinpath(store.folder, string(blobId))
    return isfile(blobfilename)
end

hasBlob(store::FolderStore, entry::BlobEntry) = hasBlob(store, entry.originId)

##==============================================================================
## InMemoryBlobStore
##==============================================================================

struct InMemoryBlobStore{T} <: AbstractBlobStore{T}
    key::Symbol
    blobs::Dict{UUID, T}
end

function InMemoryBlobStore{T}(storeKey::Symbol) where {T}
    return InMemoryBlobStore{T}(storeKey, Dict{UUID, T}())
end
function InMemoryBlobStore(storeKey::Symbol = :default_inmemory_store)
    return InMemoryBlobStore{Vector{UInt8}}(storeKey)
end

function getBlob(store::InMemoryBlobStore, blobId::UUID)
    return store.blobs[blobId]
end

function addBlob!(store::InMemoryBlobStore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, blobId)
        error("Key '$blobId' blob already exists.")
    end
    store.blobs[blobId] = data
    return blobId
end

function updateBlob!(store::InMemoryBlobStore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = data
end

function deleteBlob!(store::InMemoryBlobStore, blobId::UUID)
    return pop!(store.blobs, blobId)
end

hasBlob(store::InMemoryBlobStore, blobId::UUID) = haskey(store.blobs, blobId)

listBlobs(store::InMemoryBlobStore) = collect(keys(store.blobs))

##==============================================================================
## LinkStore Link blobId to a existing local folder
##==============================================================================

struct LinkStore <: AbstractBlobStore{String}
    key::Symbol
    csvfile::String
    cache::Dict{UUID, String}

    function LinkStore(key, csvfile)
        if !isfile(csvfile)
            @info "File '$csvfile' doesn't exist - creating."
            # create new folder
            open(csvfile, "w") do io
                return println(io, "blobid,path")
            end
            return new(key, csvfile, Dict{UUID, String}())
        else
            file = CSV.File(csvfile)
            cache = Dict(UUID.(file.blobid) .=> file.path)
            return new(key, csvfile, cache)
        end
    end
end

function getBlob(store::LinkStore, blobId::UUID)
    fname = get(store.cache, blobId, nothing)
    return read(fname)
end

function addBlob!(store::LinkStore, entry::BlobEntry, linkfile::String)
    return addBlob!(store, entry.originId, nothing, linkfile::String)
end

function addBlob!(store::LinkStore, blobId::UUID, blob::Any, linkfile::String)
    if haskey(store.cache, blobId)
        error("blobId $blobId already exists in the store")
    end
    push!(store.cache, blobId => linkfile)
    open(store.csvfile, "a") do f
        return println(f, blobId, ",", linkfile)
    end
    return getBlob(store, blobId)
end

function deleteBlob!(store::LinkStore, args...)
    return error("deleteDataBlob(::LinkStore) not supported")
end

deleteBlob!(store::LinkStore, ::BlobEntry) = deleteBlob!(store)
deleteBlob!(store::LinkStore, ::UUID) = deleteBlob!(store)

##==============================================================================
## RowBlobStore Ordered Dict Row Table Blob Store
##==============================================================================

# RowBlob
# T must be compatable with the AbstactRow iterator
# struct and named tuple as examples
struct RowBlob{T} <: Tables.AbstractRow
    id::UUID
    blob::T
end

function RowBlob(::Type{T}, nt::NamedTuple) where {T}
    id = nt.id
    blob = T(nt[keys(nt)[2:end]])
    return RowBlob(id, blob)
end

function Tables.getcolumn(row::RowBlob, i::Int)
    return i == 1 ? getfield(row, :id) : Tables.getcolumn(getfield(row, :blob), i - 1)
end
function Tables.getcolumn(row::RowBlob, nm::Symbol)
    return nm == :id ? getfield(row, :id) : Tables.getcolumn(getfield(row, :blob), nm)
end
function Tables.columnnames(row::RowBlob)
    return (:id, Tables.columnnames(getfield(row, :blob))...)
end

## RowBlobStore

struct RowBlobStore{T} <: AbstractBlobStore{T}
    key::Symbol
    blobs::OrderedDict{UUID, RowBlob{T}}
end

function RowBlobStore{T}(storeKey::Symbol) where {T}
    return RowBlobStore{T}(storeKey, OrderedDict{UUID, RowBlob{T}}())
end
function RowBlobStore(storeKey::Symbol, T::DataType)
    return RowBlobStore{T}(storeKey)
end

function RowBlobStore(storeKey::Symbol, T::DataType, table)
    store = RowBlobStore(storeKey, T)
    for nt in Tables.namedtupleiterator(table)
        row = DFG.RowBlob(T, nt)
        store.blobs[row.id] = row
    end
    return store
end

# Tables interface
Tables.istable(::Type{RowBlobStore{T}}) where {T} = true
Tables.rowaccess(::Type{RowBlobStore{T}}) where {T} = true
Tables.rows(store::RowBlobStore) = values(store.blobs)
#TODO
# Tables.materializer(::Type{RowBlobStore{T}}) where T = Tables.rowtable

##
function getBlob(store::RowBlobStore, blobId::UUID)
    return getfield(store.blobs[blobId], :blob)
end

function addBlob!(store::RowBlobStore{T}, blobId::UUID, blob::T) where {T}
    if haskey(store.blobs, blobId)
        error("Key '$blobId' blob already exists.")
    end
    store.blobs[blobId] = RowBlob(blobId, blob)
    return blobId
end

function updateBlob!(store::RowBlobStore{T}, blobId::UUID, blob::T) where {T}
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = RowBlob(blobId, blob)
end

function deleteBlob!(store::RowBlobStore, blobId::UUID)
    return getfield(pop!(store.blobs, blobId), :blob)
end

hasBlob(store::RowBlobStore, blobId::UUID) = haskey(store.blobs, blobId)

listBlobs(store::RowBlobStore) = collect(keys(store.blobs))

# TODO also see about wrapping a table directly
##
if false
    rb = RowBlob(uuid4(), (a = [1, 2], b = [3, 4]))

    Tables.columnnames(rb)

    tstore = RowBlobStore(:namedtuple, @NamedTuple{a::Vector{Int}, b::Vector{Int}})

    addBlob!(tstore, uuid4(), (a = [1, 2], b = [3, 4]))
    addBlob!(tstore, uuid4(), (a = [5, 6], b = [7, 8]))
    addBlob!(tstore, uuid4(), (a = [9, 10], b = [11, 12]))

    rowtbl = Tables.rowtable(tstore)
    coltbl = Tables.columntable(rowtbl)

    Tables.rows(tstore)
    tbl = Tables.rowtable(tstore)

    first(Tables.namedtupleiterator(tstore))

    # Tables.materializer(tstore)

    ##
    struct Foo
        a::Float64
        b::Float64
    end

    sstore = RowBlobStore(:struct_Foo, Foo)

    addBlob!(sstore, uuid4(), Foo(1, 2))
    addBlob!(sstore, uuid4(), Foo(3, 4))
    addBlob!(sstore, uuid4(), Foo(5, 6))

    Tables.rowtable(sstore)
end
##