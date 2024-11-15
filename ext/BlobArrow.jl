module BlobArrow

using Arrow
using DistributedFactorGraphs
using DistributedFactorGraphs: _MIMETypes

function __init__()
    @info "Including Arrow blobs support in DFG."
    return push!(_MIMETypes, MIME("application/vnd.apache.arrow.file") => format"Arrow") # see issue #507
end

# kwargs: compress = :lz4,
function DFG.packBlob(::Type{format"Arrow"}, data; kwargs...)
    io = IOBuffer()
    Arrow.write(io, data; kwargs...)
    blob = take!(io)
    mimetype = findfirst(==(format"Arrow"), _MIMETypes)
    return blob, mimetype
end

function DFG.unpackBlob(::Type{format"Arrow"}, blob::Vector{UInt8})
    io = IOBuffer(blob)
    return Arrow.Table(io)
end

end
