
import Base: *


# FIXME remove! is it really needed? This is type piracy
*(a::Symbol, b::AbstractString)::Symbol = Symbol(string(a,b))

## Utility functions for getting type names and modules (from IncrementalInference)
function _getmodule(t::T) where T
  T.name.module
end
function _getname(t::T) where T
  T.name.name
end


##==============================================================================
## Sorting
##==============================================================================
#Natural Sorting less than

# Adapted from https://rosettacode.org/wiki/Natural_sorting
# split at digit to not digit change
splitbynum(x::AbstractString) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
#parse to Int
numstringtonum(arr::Vector{<:AbstractString}) = [(n = tryparse(Int, e)) != nothing ? n : e for e in arr]
#natural less than
function natural_lt(x::T, y::T) where T <: AbstractString
    xarr = numstringtonum(splitbynum(x))
    yarr = numstringtonum(splitbynum(y))
    for i in 1:min(length(xarr), length(yarr))
        if typeof(xarr[i]) != typeof(yarr[i])
            return isa(xarr[i], Int)
        elseif xarr[i] == yarr[i]
            continue
        else
            return xarr[i] < yarr[i]
        end
    end
    return length(xarr) < length(yarr)
end

natural_lt(x::Symbol, y::Symbol) = natural_lt(string(x),string(y))

"""
    $SIGNATURES

Convenience wrapper for `Base.sort`.
Sort variable (factor) lists in a meaningful way (by `timestamp`, `label`, etc), for example `[:april;:x1_3;:x1_6;]`
Defaults to sorting by timestamp for variables and factors and using `natural_lt` for Symbols.
See Base.sort for more detail.

Notes
- Not fool proof, but does better than native sort.

Example

`sortDFG(ls(dfg))`
`sortDFG(ls(dfg), by=getLabel, lt=natural_lt)`

Related

ls, lsf
"""
sortDFG(vars::Vector{<:DFGNode}; by=getTimestamp, kwargs...) = sort(vars; by=by, kwargs...)
sortDFG(vars::Vector{Symbol}; lt=natural_lt, kwargs...)::Vector{Symbol} = sort(vars; lt=lt, kwargs...)
