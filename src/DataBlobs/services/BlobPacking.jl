##==============================================================================
## BlobPacking: format <-> MIME type bridging and blob serialization
##==============================================================================

# Override dictionary for formats not covered by MIMEs.jl + FileIO auto-detection.
# Standard types (PNG, JPEG, CSV, etc.) are auto-detected and don't need entries here.
const _MIMEOverrides = OrderedDict{DataType, MIME}(
    format"JSON" => MIME("application/json"),
    format"BSON" => MIME("application/bson"),
    format"LAS" => MIME("application/vnd.las"),
    format"Parquet" => MIME("application/vnd.apache.parquet"),
)

"""
    format_to_mime(::Type{DataFormat{S}}) -> MIME

Get the MIME type for a FileIO `DataFormat`. Uses FileIO's extension registry
and MIMEs.jl for standard types, falls back to `_MIMEOverrides` for
domain-specific formats.

# Examples
```julia
format_to_mime(format"PNG")  # MIME("image/png")
format_to_mime(format"JSON") # MIME("application/json")
```
"""
function format_to_mime(::Type{DataFormat{S}}) where {S}
    T = DataFormat{S}
    haskey(_MIMEOverrides, T) && return _MIMEOverrides[T]
    try
        finfo = FileIO.info(T)
        ext = finfo[2]
        ext = ext isa AbstractVector ? first(ext) : ext
        m = mime_from_extension(ext)
        !isnothing(m) && return m
    catch
    end
    return MIME("application/octet-stream")
end

"""
    mime_to_format(::MIME) -> Union{Type{DataFormat{S}}, Nothing}

Get the FileIO `DataFormat` for a MIME type. Uses MIMEs.jl and FileIO's extension
registry, falls back to `_MIMEOverrides`.

Returns `nothing` if no matching format is found.

# Examples
```julia
mime_to_format(MIME("image/png"))        # format"PNG"
mime_to_format(MIME("application/json")) # format"JSON"
```
"""
function mime_to_format(m::MIME)
    for (fmt, mime) in _MIMEOverrides
        mime == m && return fmt
    end
    ext = extension_from_mime(m)
    sym = get(FileIO.ext2sym, ext, nothing)
    !isnothing(sym) && return DataFormat{sym}
    return nothing
end

"""
    packBlob
Convert data to `Vector{UInt8}` for use as a Blob. Returns `(blob, mimetype)`.
The MIME type is automatically determined from the DataFormat.
"""
function packBlob end

"""
    unpackBlob
Convert a Blob back to the original type using the MIME type or DataFormat type.
"""
function unpackBlob end

unpackBlob(mime::String, blob) = unpackBlob(MIME(mime), blob)

function unpackBlob(T::MIME, blob)
    dataformat = mime_to_format(T)
    isnothing(dataformat) && error("Format not found for MIME type $(T)")
    return unpackBlob(dataformat, blob)
end

# 1. JSON strings are saved as is
function packBlob(::Type{format"JSON"}, json_str::String)
    mimetype = format_to_mime(format"JSON")
    blob = Vector{UInt8}(json_str)
    return blob, mimetype
end

function unpackBlob(::Type{format"JSON"}, blob::Vector{UInt8})
    return String(copy(blob))
end

unpackBlob(entry::Blobentry, blob::Vector{UInt8}) = unpackBlob(entry.mimetype, blob)
unpackBlob(eb::Pair{<:Blobentry, Vector{UInt8}}) = unpackBlob(eb[1], eb[2])

# 2. FileIO formats (PNG, JPEG, BSON, LAS, Parquet, etc.)
function packBlob(::Type{T}, data::Any; kwargs...) where {T <: DataFormat}
    io = IOBuffer()
    save(Stream{T}(io), data; kwargs...)
    blob = take!(io)
    mimetype = format_to_mime(T)
    return blob, mimetype
end

function unpackBlob(::Type{T}, blob::Vector{UInt8}) where {T <: DataFormat}
    io = IOBuffer(blob)
    return load(Stream{T}(io))
end

"""    
    getMimetype(io::IO) -> MIME

Detect the MIME type of data in an IO stream using FileIO's format detection.
"""
function getMimetype(io::IO)
    _getFormat(s::FileIO.Stream{T}) where {T} = T
    stream = FileIO.query(io)
    return format_to_mime(_getFormat(stream))
end
