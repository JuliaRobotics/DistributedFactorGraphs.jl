# using FileIO
# using ImageIO
# using LasIO
# using BSON
# using OrderedCollections

# 2 types for now with MIME type
# 1. JSON     - application/octet-stream/json
# 2. FileIO   - application/octet-stream 
#             - application/bson 
#             - image/jpeg
#             - image/png

const _MIMETypes = OrderedDict{MIME, DataType}()
push!(_MIMETypes, MIME("application/octet-stream/json")=>format"JSON")
push!(_MIMETypes, MIME("application/bson")=>format"BSON")
push!(_MIMETypes, MIME("image/png")=>format"PNG")
push!(_MIMETypes, MIME("image/jpeg")=>format"JPG")
push!(_MIMETypes, MIME("application/octet-stream; ext=las")=>format"LAS")

"""
    packBlob
Convert a file (JSON, JPG, PNG, BSON, LAS) to Vector{UInt8} for use as a Blob.  
Returns the blob and MIME type.
"""
function packBlob end
"""
    unpackBlob
Convert a Blob back to the origanal typ using the MIME type or DataFormat type.
"""
function unpackBlob end

unpackBlob(mime::String, blob) = unpackBlob(MIME(mime), blob)

function unpackBlob(T::MIME, blob)
    dataformat = get(_MIMETypes, T, nothing)
    isnothing(dataformat) && error("Format not found for MIME type $(T)")
    return unpackBlob(dataformat, blob)
end


# 1. JSON strings are saved as is
function packBlob(::Type{format"JSON"}, json_str::String)
    mimetype = findfirst(==(format"JSON"), _MIMETypes)
    # blob = codeunits(json_str)
    blob = Vector{UInt8}(json_str)
    return blob, mimetype
end

function unpackBlob(::Type{format"JSON"}, blob::Vector{UInt8})
    return String(copy(blob))
end


# 2/ FileIO
function packBlob(::Type{T}, data::Any; kwargs...) where T <: DataFormat
    io = IOBuffer()
    save(Stream{T}(io), data; kwargs...)
    blob = take!(io)
    mimetype = findfirst(==(T), _MIMETypes)
    if isnothing(mimetype)
        @warn "No MIME type found for format $T"
        mimetype = MIME"application/octet-stream"
    end
    return blob, mimetype
end

function unpackBlob(::Type{T}, blob::Vector{UInt8}) where T <: DataFormat
    io = IOBuffer(blob)
    return load(Stream{T}(io))
end




# if false
# json_str = "{\"name\":\"John\"}"
# blob, mimetype = packBlob(format"JSON", json_str)
# @assert json_str == unpackBlob(format"JSON", blob)
# @assert json_str == unpackBlob(MIME("application/octet-stream/json"), blob)
# @assert json_str == unpackBlob("application/octet-stream/json", blob)


# blob,mime = packBlob(format"PNG", img)
# up_img = unpackBlob(format"PNG", blob)

# #TODO BSON does not work yet, can extend [un]packBlob(::Type{format"BSON"}, ...)
# packBlob(format"BSON", Dict("name"=>"John"))
# unpackBlob(format"BSON", Dict("name"=>"John"))


# end



