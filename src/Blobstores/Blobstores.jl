
# ==============================================================================
# FolderStore
# TODO rename to FolderBlobstore
# ==============================================================================
struct FolderStore{T} <: AbstractBlobstore{T}
    label::Symbol
    folder::String
end

FolderStore(label::Symbol, folder::String) = FolderStore{Vector{UInt8}}(label, folder)

function FolderStore(foldername::String; label::Symbol = :primary, createfolder = true)
    storepath = expanduser(joinpath(foldername, string(label)))
    if createfolder && !isdir(storepath)
        @info "Folder '$storepath' doesn't exist - creating."
        # create new folder
        mkpath(storepath)
    end
    return FolderStore{Vector{UInt8}}(label, foldername)
end

function blobfilename(store::FolderStore, blobid::UUID)
    return expanduser(joinpath(store.folder, string(store.label), string(blobid)))
end

function getBlob(store::FolderStore{T}, blobid::UUID) where {T}
    blobfilename = expanduser(joinpath(store.folder, string(store.label), string(blobid)))
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
    blobfilename = expanduser(joinpath(store.folder, string(store.label), string(blobid)))
    if isfile(blobfilename)
        throw(IdExistsError("Blob", blobid))
    else
        open(blobfilename, "w") do f
            return write(f, data)
        end
        return blobid
    end
end

function deleteBlob!(store::FolderStore{T}, blobid::UUID) where {T}
    # Tombstone pattern: instead of deleting the file, create a tombstone marker file
    blobfilename = expanduser(joinpath(store.folder, string(store.label), string(blobid)))
    tombstonefile = blobfilename * ".deleted"
    if isfile(blobfilename)
        # Remove the actual blob file
        rm(blobfilename)
        # Create a tombstone marker
        open(tombstonefile, "w") do f
            return write(f, string("DELETED: ", now(UTC)))
        end
        return 1
    else
        # Already deleted or doesn't exist
        return 0
    end
end

function hasBlob(store::FolderStore, blobid::UUID)
    blobfilename = expanduser(joinpath(store.folder, string(store.label), string(blobid)))
    return isfile(blobfilename)
end

hasBlob(store::FolderStore, entry::Blobentry) = hasBlob(store, entry.blobid)

function listBlobs(store::FolderStore)
    folder = expanduser(joinpath(store.folder, string(store.label)))
    # Parse folder to only include UUIDs automatically excluding tombstone files this way.
    blobids = UUID[]
    for filename in readdir(folder)
        id = tryparse(UUID, filename)
        isnothing(id) && continue
        push!(blobids, id)
    end
    return blobids
end

# ==============================================================================
# InMemoryBlobstore
# TODO rename to MemoryBlobstore
# ==============================================================================

struct InMemoryBlobstore{T} <: AbstractBlobstore{T}
    label::Symbol
    blobs::Dict{UUID, T}
end

function InMemoryBlobstore{T}(storeKey::Symbol) where {T}
    return InMemoryBlobstore{T}(storeKey, Dict{UUID, T}())
end
function InMemoryBlobstore(storeKey::Symbol = :primary)
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

function deleteBlob!(store::InMemoryBlobstore, blobid::UUID)
    !haskey(store.blobs, blobid) && return 0
    pop!(store.blobs, blobid)
    return 1
end

hasBlob(store::InMemoryBlobstore, blobid::UUID) = haskey(store.blobs, blobid)

listBlobs(store::InMemoryBlobstore) = collect(keys(store.blobs))

# ==============================================================================
# LinkStore Link blobid to a existing local folder
# TODO Rename to LinkBlobstore
# ==============================================================================
#TODO consider using a deterministic blobid (uuid5) with ns stored in the csv?
@tags struct LinkStore <: AbstractBlobstore{String}
    label::Symbol
    csvfile::String
    cache::Dict{UUID, String} & (json = (ignore = true,),)

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

# ==============================================================================
# RowBlobstore Ordered Dict Row Table Blob Store
# ==============================================================================

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

#  RowBlobstore

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

# 
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
    !haskey(store.blobs, blobid) && return 0
    pop!(store.blobs, blobid)
    return 1
end

hasBlob(store::RowBlobstore, blobid::UUID) = haskey(store.blobs, blobid)

listBlobs(store::RowBlobstore) = collect(keys(store.blobs))

# TODO also see about wrapping a table directly
# 
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

    # 
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
# 
# 
