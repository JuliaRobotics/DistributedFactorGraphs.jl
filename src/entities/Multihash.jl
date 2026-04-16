# ==============================================================================
#  Multihash
# ==============================================================================
# Matches the multicodec table, https://github.com/multiformats/multicodec/blob/master/table.csv
const MULTIHASH_FUNCTIONS = Dict{Function, UInt64}(
    sha1 => 0x11,
    sha2_256 => 0x12,
    sha2_512 => 0x13,
    sha3_512 => 0x14,
    sha3_256 => 0x16,
)

@nonstruct struct Multihash
    bytes::Vector{UInt8}

    function Multihash(bytes::Vector{UInt8})
        if _parse_multihash_structure(bytes) === nothing
            error("Invalid Multihash: Protocol violation or truncated bytes.")
        end
        return new(bytes)
    end

    function Multihash(code::Integer, digest::Vector{UInt8})
        c, d_len = UInt64(code), UInt64(length(digest))

        c_size, l_size = _uvarint_size(c), _uvarint_size(d_len)
        buf = Vector{UInt8}(undef, c_size + l_size + d_len)

        next = _encode_uvarint(buf, 1, c)
        next = _encode_uvarint(buf, next, d_len)
        copyto!(buf, next, digest, 1, d_len)

        return new(buf)
    end
end

# Hex string convenience constructor
Multihash(hex::String) = Multihash(hex2bytes(hex))
Base.string(m::Multihash) = bytes2hex(m.bytes)

# Equality and hashing for use as Dict keys
Base.:(==)(a::Multihash, b::Multihash) = a.bytes == b.bytes
Base.hash(m::Multihash, h::UInt) = hash(m.bytes, h)

JSON.lower(m::Multihash) = bytes2hex(m.bytes)
JSON.lift(::Type{Multihash}, s) = Multihash(hex2bytes(s))

"""
    Multihash(hash_func::Function, blob::Union{Vector{UInt8}, IO})

Constructs a Multihash by executing the provided function. Supports IO streaming.
"""
function Multihash(hash_func::Function, blob::Union{Vector{UInt8}, IO})
    if !haskey(MULTIHASH_FUNCTIONS, hash_func)
        error("Unregistered Multihash function: $(string(hash_func))")
    end

    code = MULTIHASH_FUNCTIONS[hash_func]
    raw_digest = hash_func(blob) # SHA.jl handles Vector{UInt8} and IO

    return Multihash(code, raw_digest)
end

"""
    tryparse(::Type{Multihash}, hex::String) -> Union{Multihash, Nothing}

Attempts to parse a hex string into a `Multihash`. Returns `nothing` if the
string is not valid hex or if the decoded bytes do not form a valid multihash
according to the Multiformats encoding rules. Examples of invalid inputs
include truncated bytes, invalid varint encodings for the hash code or digest
length, and non-minimal varint encodings.
"""
function Base.tryparse(::Type{Multihash}, hex::String)
    (length(hex) % 2 != 0 || !all(isxdigit, hex)) && return nothing
    bytes = hex2bytes(hex)

    if _parse_multihash_structure(bytes) !== nothing
        return Multihash(bytes) # Constructor validation is redundant but safe
    end
    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", m::Multihash)
    bytes = m.bytes
    #find the headersize by reading the first two varints (code and length)
    idx = 1
    for _ = 1:2
        while bytes[idx] >= 0x80
            idx += 1
        end
        idx += 1
    end

    header = bytes2hex(bytes[1:(idx - 1)])
    digest_hex = bytes2hex(bytes[idx:end])

    p1 = digest_hex[1:min(8, end)]
    p2 = digest_hex[min(9, end + 1):end]

    print(io, "multihash:")
    printstyled(io, header; color = :cyan)
    printstyled(io, p1; color = :cyan, bold = true)
    return printstyled(io, p2; color = :cyan)
end

# ==========================================
# Low-Level Uvarint Encoding / Decoding
# ==========================================
"""
    _uvarint_size(x::UInt64) -> Int

Returns the exact number of bytes required to encode `x` as a varint.
"""
function _uvarint_size(x::UInt64)
    x == 0 && return 1
    # Bits required: 64 - leading zeros. Divided by 7 bits per varint byte.
    return cld(64 - leading_zeros(x), 7)
end

"""
    encode_uvarint

Encodes a UInt64 into a minimally encoded Multiformats unsigned varint.
Enforces the 9-byte (63-bit max) protocol limit.
"""
function _encode_uvarint(buf::Vector{UInt8}, offset::Int, x::UInt64)
    i = offset
    while x >= 0x80
        buf[i] = UInt8((x & 0x7f) | 0x80)
        x >>= 7
        i += 1
    end
    buf[i] = UInt8(x)
    return i + 1
end

"""
    _decode_uvarint(buf, offset) -> (value, n_read)

Internal helper. Returns n_read = -1 on any protocol violation.
"""
function _decode_uvarint(buf, offset)
    x = UInt64(0)
    s = 0
    for i = offset:length(buf)
        (i - offset) >= 9 && return (0, -1) # Too long
        b = buf[i]
        if b < 0x80
            (b == 0x00 && i > offset) && return (0, -1) # Non-minimal
            return (x | (UInt64(b) << s)), (i - offset + 1)
        end
        x |= UInt64(b & 0x7f) << s
        s += 7
    end
    return (0, -1)
end

"""
    _parse_multihash_structure(bytes) -> (code, digest_len, header_len) or nothing
"""
function _parse_multihash_structure(bytes)
    isempty(bytes) && return nothing

    # Read Code
    code, n1 = _decode_uvarint(bytes, 1)
    n1 < 0 && return nothing

    # Read Length
    d_len, n2 = _decode_uvarint(bytes, 1 + n1)
    n2 < 0 && return nothing

    # Verify exact fit
    (n1 + n2 + d_len) == length(bytes) || return nothing

    return (code, Int(d_len), n1 + n2)
end

# ==========================================
# High-Level Multihash Encode / Decode
# ==========================================

"""
    decode(m::Multihash) -> (UInt64, Vector{UInt8})

Validates and decodes a Multihash into its constituent parts.
Returns `(hash_function_code, digest_bytes)`.
Throws an error if the multihash is truncated, malformed, or contains trailing garbage.
"""
function decode(m::Multihash)
    code, d_len, h_len = _parse_multihash_structure(m.bytes)
    digest = m.bytes[(h_len + 1):end]
    return code, digest
end
