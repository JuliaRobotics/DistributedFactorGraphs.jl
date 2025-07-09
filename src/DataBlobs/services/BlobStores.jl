##==============================================================================
## Blob CRUD interface
##==============================================================================

"""
Get the data blob for the specified blobstore or dfg.

Related
[`getBlobentry`](@ref)
Implement 
`getBlob(store::AbstractBlobstore, blobid::UUID)`

$(METHODLIST)
"""
function getBlob end

"""
Adds a blob to the blob store or dfg with the blobid.

Related
[`addBlobentry!`](@ref)
Implement
`addBlob!(store::AbstractBlobstore, blobid::UUID, data)`
$(METHODLIST)
"""
function addBlob! end

"""
Delete a blob from the blob store or dfg with the given entry.

Related
[`deleteBlobentry!`](@ref)
Implement
`deleteBlob!(store::AbstractBlobstore, blobid::UUID)`
$(METHODLIST)
"""
function deleteBlob! end

"""
    $(SIGNATURES)
List all `blobid`s in the blob store.
Implement
`listBlobs(store::AbstractBlobstore)`
"""
function listBlobs end

"""
    $(SIGNATURES)
Check if the blob store has a blob with the given `blobid`.
"""
function hasBlob end

##==============================================================================
## AbstractBlobstore derived CRUD for Blob 
##==============================================================================
#TODO maybe we should generalize and move the cached blobstore to DFG.
function getBlob(dfg::AbstractDFG, entry::Blobentry)
    storeLabel = entry.blobstore
    store = getBlobstore(dfg, storeLabel)
    return getBlob(store, entry.blobid)
end

function getBlob(store::AbstractBlobstore, entry::Blobentry)
    return getBlob(store, entry.blobid)
end

#add 
function addBlob!(dfg::AbstractDFG, entry::Blobentry, data)
    return addBlob!(getBlobstore(dfg, entry.blobstore), entry, data)
end

function addBlob!(store::AbstractBlobstore{T}, entry::Blobentry, data::T) where {T}
    return addBlob!(store, entry.blobid, data)
end

# also creates an blobid as uuid4
addBlob!(store::AbstractBlobstore, data) = addBlob!(store, uuid4(), data)

#update
function updateBlob!(dfg::AbstractDFG, entry::Blobentry, data)
    return updateBlob!(getBlobstore(dfg, entry.blobstore), entry.blobid, data)
end

function updateBlob!(store::AbstractBlobstore, entry::Blobentry, data)
    return updateBlob!(store, entry.blobid, data)
end
#delete
function deleteBlob!(dfg::AbstractDFG, entry::Blobentry)
    return deleteBlob!(getBlobstore(dfg, entry.blobstore), entry)
end

function deleteBlob!(store::AbstractBlobstore, entry::Blobentry)
    return deleteBlob!(store, entry.blobid)
end

#has
function hasBlob(store::AbstractBlobstore, entry::Blobentry)
    return hasBlob(store, entry.blobid)
end
function hasBlob(dfg::AbstractDFG, entry::Blobentry)
    return hasBlob(getBlobstore(dfg, entry.blobstore), entry.blobid)
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

FolderStore(label::Symbol, folder::String) = FolderStore{Vector{UInt8}}(label, folder)

function FolderStore(foldername::String; label::Symbol = :default, createfolder = true)
    storepath = joinpath(foldername, string(label))
    if createfolder && !isdir(storepath)
        @info "Folder '$storepath' doesn't exist - creating."
        # create new folder
        mkpath(storepath)
    end
    return FolderStore{Vector{UInt8}}(label, foldername)
end

function blobfilename(store::FolderStore, blobid::UUID)
    return joinpath(store.folder, string(store.label), string(blobid))
end

function getBlob(store::FolderStore{T}, blobid::UUID) where {T}
    blobfilename = joinpath(store.folder, string(store.label), string(blobid))
    tombstonefile = blobfilename * ".deleted"
    if isfile(tombstonefile)
        throw(IdNotFoundError("Blob (deleted)", blobid))
    elseif isfile(blobfilename)
        open(blobfilename) do f
            return read(f)
        end
    else
        throw(IdNotFoundError("Blob", blobid))
    end
end

function addBlob!(store::FolderStore{T}, blobid::UUID, data::T) where {T}
    blobfilename = joinpath(store.folder, string(store.label), string(blobid))
    if isfile(blobfilename)
        throw(IdExistsError("Blob", blobid))
    else
        open(blobfilename, "w") do f
            return write(f, data)
        end
        return blobid
    end
end

function updateBlob!(store::FolderStore{T}, blobid::UUID, data::T) where {T}
   error("updateBlob! is obsolete as blobsId=>Blob pairs are immutable.")
end

function deleteBlob!(store::FolderStore{T}, blobid::UUID) where {T}
    # Tombstone pattern: instead of deleting the file, create a tombstone marker file
    blobfilename = joinpath(store.folder, string(store.label), string(blobid))
    tombstonefile = blobfilename * ".deleted"
    if isfile(blobfilename)
        # Remove the actual blob file
        rm(blobfilename)
        # Create a tombstone marker
        open(tombstonefile, "w") do f
            write(f, "deleted")
        end
        return 1
    elseif isfile(tombstonefile)
        # Already deleted
        return 0
    else
        # Not found
        throw(IdNotFoundError("Blob", blobId))
    end
end

function hasBlob(store::FolderStore, blobid::UUID)
    blobfilename = joinpath(store.folder, string(store.label), string(blobid))
    return isfile(blobfilename)
end

hasBlob(store::FolderStore, entry::Blobentry) = hasBlob(store, entry.blobid)

function listBlobs(store::FolderStore)
    folder = joinpath(store.folder, string(store.label))
    # Parse folder to only include UUIDs automatically excluding tombstone files this way.
    blobIds = map(readdir(folder)) do filename
        tryparse(UUID, filename)
    end
    return filter(!isnothing, blobIds)
end

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

function getBlob(store::InMemoryBlobstore, blobid::UUID)
    if !haskey(store.blobs, blobid)
        throw(IdNotFoundError("Blob", blobid))
    end
    return store.blobs[blobid]
end

function addBlob!(store::InMemoryBlobstore{T}, blobid::UUID, data::T) where {T}
    if haskey(store.blobs, blobid)
        throw(IdExistsError("Blob", blobid))
    end
    store.blobs[blobid] = data
    return blobid
end

function updateBlob!(store::InMemoryBlobstore{T}, blobid::UUID, data::T) where {T}
    if haskey(store.blobs, blobid)
        @warn "Key '$blobid' doesn't exist."
    end
    return store.blobs[blobid] = data
end

function deleteBlob!(store::InMemoryBlobstore, blobid::UUID)
    if !haskey(store.blobs, blobid)
        throw(IdNotFoundError("Blob", blobid))
    end
    pop!(store.blobs, blobid)
    return 1
end

hasBlob(store::InMemoryBlobstore, blobid::UUID) = haskey(store.blobs, blobid)

listBlobs(store::InMemoryBlobstore) = collect(keys(store.blobs))

##==============================================================================
## LinkStore Link blobid to a existing local folder
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

function getBlob(store::LinkStore, blobid::UUID)
    fname = get(store.cache, blobid, nothing)
    if isnothing(fname)
        throw(IdNotFoundError("Blob", blobid))
    end
    return read(fname)
end

function addBlob!(store::LinkStore, blobid::UUID, linkfile::String)
    if haskey(store.cache, blobid)
        throw(IdExistsError("Blob", blobid))
    end
    push!(store.cache, blobid => linkfile)
    open(store.csvfile, "a") do f
        return println(f, blobid, ",", linkfile)
    end
    return blobid
end

function deleteBlob!(store::LinkStore)
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
function getBlob(store::RowBlobstore, blobid::UUID)
    if !haskey(store.blobs, blobid)
        throw(IdNotFoundError("Blob", blobid))
    end
    return getfield(store.blobs[blobid], :blob)
end

function addBlob!(store::RowBlobstore{T}, blobid::UUID, blob::T) where {T}
    if haskey(store.blobs, blobid)
        throw(IdExistsError("Blob", blobid))
    end
    store.blobs[blobid] = RowBlob(blobid, blob)
    return blobid
end

function deleteBlob!(store::RowBlobstore, blobid::UUID)
    if !haskey(store.blobs, blobid)
        throw(IdNotFoundError("Blob", blobid))
    end
    pop!(store.blobs, blobid)
    return 1
end

hasBlob(store::RowBlobstore, blobid::UUID) = haskey(store.blobs, blobid)

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
##
