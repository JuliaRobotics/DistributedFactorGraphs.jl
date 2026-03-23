module BlobArrow

using Arrow
using DistributedFactorGraphs
using DistributedFactorGraphs: _MIMEOverrides, getMimetype

function __init__()
    @info "Including Arrow blobs support in DFG."
    push!(_MIMEOverrides, format"Arrow" => MIME("application/vnd.apache.arrow.file"))
    return nothing
end

# kwargs: compress = :lz4,
function DFG.packBlob(::Type{format"Arrow"}, data; kwargs...)
    io = IOBuffer()
    Arrow.write(io, data; kwargs...)
    blob = take!(io)
    mimetype = getMimetype(format"Arrow")
    return blob, mimetype
end

function DFG.unpackBlob(::Type{format"Arrow"}, blob::Vector{UInt8})
    io = IOBuffer(blob)
    return Arrow.Table(io)
end

end
