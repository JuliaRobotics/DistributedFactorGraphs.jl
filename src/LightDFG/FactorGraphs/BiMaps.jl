# import Base: getindex, setindex!, firstindex, lastindex, iterate, keys, isempty
struct BiDictMap{T <: Integer}
    int_sym::Dict{T,Symbol}
    sym_int::Dict{Symbol,T}
end

BiDictMap{T}(;sizehint=100) where T<:Integer = begin
    int_sym = Dict{T,Symbol}()
    sizehint!(int_sym, sizehint)
    sym_int = Dict{Symbol,T}()
    sizehint!(sym_int, sizehint)
    BiDictMap{T}(int_sym, sym_int)
end

BiDictMap(;sizehint=100) = BiDictMap{Int}(;sizehint=sizehint)


Base.getindex(b::BiDictMap, key::Int) = b.int_sym[key]
Base.getindex(b::BiDictMap, key::Symbol) = b.sym_int[key]

# setindex!(b, value, key) = b[key] = value
function Base.setindex!(b::BiDictMap, s::Symbol, i::Int)
    haskey(b.sym_int, s) && delete!(b.int_sym, b[s])
    haskey(b.int_sym, i) && delete!(b.sym_int, b[i])

    b.int_sym[i] = s
    b.sym_int[s] = i
end

function Base.setindex!(b::BiDictMap, i::Int, s::Symbol)
    haskey(b.int_sym, i) && delete!(b.sym_int, b[i])
    haskey(b.sym_int, s) && delete!(b.int_sym, b[s])

    b.int_sym[i] = s
    b.sym_int[s] = i
end

function Base.delete!(b::BiDictMap, i::Int)
    s = b[i]
    delete!(b.int_sym, i)
    delete!(b.sym_int, s)
    return b
end

Base.haskey(b::BiDictMap, s::Symbol) = haskey(b.sym_int, s)
Base.haskey(b::BiDictMap, i::Int) = haskey(b.int_sym, i)

Base.length(b::BiDictMap) = length(b.int_sym)
Base.firstindex(v::BiDictMap) = 1
Base.lastindex(v::BiDictMap) = length(v.int_sym)
Base.iterate(v::BiDictMap, i=1) = (length(v.int_sym) < i ? nothing : (v.int_sym[i], i + 1))
Base.keys(v::BiDictMap) = Base.OneTo(length(v.int_sym))
Base.isempty(v::BiDictMap) = (length(v.int_sym) == 0)
