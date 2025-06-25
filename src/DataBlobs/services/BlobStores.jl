##==============================================================================
## Blob CRUD interface
##==============================================================================

"""
Get the data blob for the specified blobstore or dfg.

Related
[`getBlobentry`](@ref)

$(METHODLIST)
"""
function getBlob end

"""
Adds a blob to the blob store or dfg with the given entry.

Related
[`addBlobentry!`](@ref)

$(METHODLIST)
"""
function addBlob! end

"""
Update a blob to the blob store or dfg with the given entry.
Related
[`mergeBlobentry!`](@ref)

$(METHODLIST)

DevNotes
- TODO TBD update verb on data since data blobs and entries are restricted to immutable only.
"""
function updateBlob! end

"""
Delete a blob from the blob store or dfg with the given entry.

Related
[`deleteBlobentry!`](@ref)

$(METHODLIST)
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all ids in the blob store.
"""
function listBlobs end

##==============================================================================
## AbstractBlobstore CRUD Interface
##==============================================================================

function getBlob(store::AbstractBlobstore, ::UUID)
    return error("$(typeof(store)) doesn't override 'getBlob'.")
end

function addBlob!(store::AbstractBlobstore{T}, ::UUID, ::T) where {T}
    return error("$(typeof(store)) doesn't override 'addBlob!'.")
end

function updateBlob!(store::AbstractBlobstore{T}, ::UUID, ::T) where {T}
    return error("$(typeof(store)) doesn't override 'updateBlob!'.")
end

function deleteBlob!(store::AbstractBlobstore, ::UUID)
    return error("$(typeof(store)) doesn't override 'deleteBlob!'.")
end

function listBlobs(store::AbstractBlobstore)
    return error("$(typeof(store)) doesn't override 'listBlobs'.")
end

function hasBlob(store::AbstractBlobstore, ::UUID)
    return error("$(typeof(store)) doesn't override 'hasBlob'.")
end

##==============================================================================
## AbstractBlobstore derived CRUD for Blob 
##==============================================================================
#TODO looking in all the blobstores does not make sense since since there is a chance that the blobId is not unique across blobstores.
# using the cached blobstore is the right way to go here.
function getBlob(dfg::AbstractDFG, entry::Blobentry)
    stores = getBlobstores(dfg)
    storekeys = collect(keys(stores))
    # first check the saved blobstore and then fall back to the rest
    fidx = findfirst(==(entry.blobstore), storekeys)
    if !isnothing(fidx)
        skey = storekeys[fidx]
        popat!(storekeys, fidx)
        pushfirst!(storekeys, skey)
    end
    for k in storekeys
        store = stores[k]
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
            "could not find $(entry.label), uuid $(entry.blobId) in any of the listed blobstores:\n $([s->getLabel(s) for (s,v) in stores]))",
        ),
    )
end

function getBlob(store::AbstractBlobstore, entry::Blobentry)
    return getBlob(store, entry.blobId)
end

#add 
function addBlob!(dfg::AbstractDFG, entry::Blobentry, data)
    return addBlob!(getBlobstore(dfg, entry.blobstore), entry, data)
end

function addBlob!(store::AbstractBlobstore{T}, entry::Blobentry, data::T) where {T}
    return addBlob!(store, entry.blobId, data)
end

# also creates an blobId as uuid4
addBlob!(store::AbstractBlobstore, data) = addBlob!(store, uuid4(), data)

#update
function updateBlob!(dfg::AbstractDFG, entry::Blobentry, data)
    return updateBlob!(getBlobstore(dfg, entry.blobstore), entry.blobId, data)
end

function updateBlob!(store::AbstractBlobstore, entry::Blobentry, data)
    return updateBlob!(store, entry.blobId, data)
end
#delete
function deleteBlob!(dfg::AbstractDFG, entry::Blobentry)
    return deleteBlob!(getBlobstore(dfg, entry.blobstore), entry)
end

function deleteBlob!(store::AbstractBlobstore, entry::Blobentry)
    return deleteBlob!(store, entry.blobId)
end

#has
function hasBlob(store::AbstractBlobstore, entry::Blobentry)
    return hasBlob(store, entry.blobId)
end
function hasBlob(dfg::AbstractDFG, entry::Blobentry)
    return hasBlob(getBlobstore(dfg, entry.blobstore), entry.blobId)
end

#TODO
# """
#     $(SIGNATURES)
# Copies all the entries from the source into the destination.
# Can specify which entries to copy with the `sourceEntries` parameter.
# Returns the list of copied entries.
# """
# function copyBlobstore(sourceStore::D1, destStore::D2; sourceEntries=listEntries(sourceStore))::Vector{E} where {T, D1 <: AbstractDataStore{T}, D2 <: AbstractDataStore{T}, E <: Blobentry}
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
struct FolderStore{T} <: AbstractBlobstore{T}
    label::Symbol
    folder::String
end

#TODO added in v0.25 to avoid a breaking change in deserialization old DFGs, remove.
StructTypes.StructType(::Type{<:FolderStore}) = StructTypes.OrderedStruct()

function FolderStore(foldername::String; label::Symbol = :default, createfolder = true)
    storepath = joinpath(foldername, string(label))
    if createfolder && !isdir(storepath)
        @info "Folder '$storepath' doesn't exist - creating."
        # create new folder
        mkpath(storepath)
    end
    return FolderStore{Vector{UInt8}}(label, foldername)
end

function blobfilename(store::FolderStore, blobId::UUID)
    return joinpath(store.folder, string(store.label), string(blobId))
end

function getBlob(store::FolderStore{T}, blobId::UUID) where {T}
    blobfilename = joinpath(store.folder, string(store.label), string(blobId))
    if isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        throw(KeyError("Could not find file '$(blobfilename)'."))
    end
end

function addBlob!(store::FolderStore{T}, blobId::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, string(store.label), string(blobId))
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
    blobfilename = joinpath(store.folder, string(store.label), string(blobId))
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
    blobfilename = joinpath(store.folder, string(store.label), string(blobId))
    rm(blobfilename)
    return 1
end

#hasBlob or existsBlob?
function hasBlob(store::FolderStore, blobId::UUID)
    blobfilename = joinpath(store.folder, string(store.label), string(blobId))
    return isfile(blobfilename)
end

hasBlob(store::FolderStore, entry::Blobentry) = hasBlob(store, entry.blobId)

listBlobs(store::FolderStore) = readdir(store.folder)
##==============================================================================
## InMemoryBlobstore
##==============================================================================

struct InMemoryBlobstore{T} <: AbstractBlobstore{T}
    label::Symbol
    blobs::Dict{UUID, T}
end

function InMemoryBlobstore{T}(storeKey::Symbol) where {T}
    return InMemoryBlobstore{T}(storeKey, Dict{UUID, T}())
end
function InMemoryBlobstore(storeKey::Symbol = :default_inmemory_store)
    return InMemoryBlobstore{Vector{UInt8}}(storeKey)
end

function getBlob(store::InMemoryBlobstore, blobId::UUID)
    return store.blobs[blobId]
end

function addBlob!(store::InMemoryBlobstore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, blobId)
        error("Key '$blobId' blob already exists.")
    end
    store.blobs[blobId] = data
    return blobId
end

function updateBlob!(store::InMemoryBlobstore{T}, blobId::UUID, data::T) where {T}
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = data
end

function deleteBlob!(store::InMemoryBlobstore, blobId::UUID)
    pop!(store.blobs, blobId)
    return 1
end

hasBlob(store::InMemoryBlobstore, blobId::UUID) = haskey(store.blobs, blobId)

listBlobs(store::InMemoryBlobstore) = collect(keys(store.blobs))

##==============================================================================
## LinkStore Link blobId to a existing local folder
##==============================================================================

struct LinkStore <: AbstractBlobstore{String}
    label::Symbol
    csvfile::String
    cache::Dict{UUID, String}

    function LinkStore(label, csvfile)
        if !isfile(csvfile)
            @info "File '$csvfile' doesn't exist - creating."
            # create new folder
            open(csvfile, "w") do io
                return println(io, "blobid,path")
            end
            return new(label, csvfile, Dict{UUID, String}())
        else
            file = CSV.File(csvfile)
            cache = Dict(UUID.(file.blobid) .=> file.path)
            return new(label, csvfile, cache)
        end
    end
end

function getBlob(store::LinkStore, blobId::UUID)
    fname = get(store.cache, blobId, nothing)
    return read(fname)
end

function addBlob!(store::LinkStore, entry::Blobentry, linkfile::String)
    return addBlob!(store, entry.blobId, nothing, linkfile::String)
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

deleteBlob!(store::LinkStore, ::Blobentry) = deleteBlob!(store)
deleteBlob!(store::LinkStore, ::UUID) = deleteBlob!(store)

##==============================================================================
## RowBlobstore Ordered Dict Row Table Blob Store
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

## RowBlobstore

struct RowBlobstore{T} <: AbstractBlobstore{T}
    label::Symbol
    blobs::OrderedDict{UUID, RowBlob{T}}
end

function RowBlobstore{T}(storeKey::Symbol) where {T}
    return RowBlobstore{T}(storeKey, OrderedDict{UUID, RowBlob{T}}())
end
function RowBlobstore(storeKey::Symbol, T::DataType)
    return RowBlobstore{T}(storeKey)
end

function RowBlobstore(storeKey::Symbol, T::DataType, table)
    store = RowBlobstore(storeKey, T)
    for nt in Tables.namedtupleiterator(table)
        row = DFG.RowBlob(T, nt)
        store.blobs[row.id] = row
    end
    return store
end

# Tables interface
Tables.istable(::Type{RowBlobstore{T}}) where {T} = true
Tables.rowaccess(::Type{RowBlobstore{T}}) where {T} = true
Tables.rows(store::RowBlobstore) = values(store.blobs)
#TODO
# Tables.materializer(::Type{RowBlobstore{T}}) where T = Tables.rowtable

##
function getBlob(store::RowBlobstore, blobId::UUID)
    return getfield(store.blobs[blobId], :blob)
end

function addBlob!(store::RowBlobstore{T}, blobId::UUID, blob::T) where {T}
    if haskey(store.blobs, blobId)
        error("Key '$blobId' blob already exists.")
    end
    store.blobs[blobId] = RowBlob(blobId, blob)
    return blobId
end

function updateBlob!(store::RowBlobstore{T}, blobId::UUID, blob::T) where {T}
    if haskey(store.blobs, blobId)
        @warn "Key '$blobId' doesn't exist."
    end
    return store.blobs[blobId] = RowBlob(blobId, blob)
end

function deleteBlob!(store::RowBlobstore, blobId::UUID)
    getfield(pop!(store.blobs, blobId), :blob)
    return 1
end

hasBlob(store::RowBlobstore, blobId::UUID) = haskey(store.blobs, blobId)

listBlobs(store::RowBlobstore) = collect(keys(store.blobs))

# TODO also see about wrapping a table directly
##
if false
    rb = RowBlob(uuid4(), (a = [1, 2], b = [3, 4]))

    Tables.columnnames(rb)

    tstore = RowBlobstore(:namedtuple, @NamedTuple{a::Vector{Int}, b::Vector{Int}})

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

    sstore = RowBlobstore(:struct_Foo, Foo)

    addBlob!(sstore, uuid4(), Foo(1, 2))
    addBlob!(sstore, uuid4(), Foo(3, 4))
    addBlob!(sstore, uuid4(), Foo(5, 6))

    Tables.rowtable(sstore)
end
##
