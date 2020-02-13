
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



#TODO confirm this is only used in sortVarNested, then delete
# """
#     $(SIGNATURES)
# Test if all elements of the string is a number:  Ex, "123" is true, "1_2" is false.
# """
# allnums(str::S) where {S <: AbstractString} = occursin(Regex(string(["[0-9]" for j in 1:length(str)]...)), str)
# occursin(r"_+|,+|-+", node_idx)

# isnestednum(str::S; delim='_') where {S <: AbstractString} = occursin(Regex("[0-9]+$(delim)[0-9]+"), str)

# function sortnestedperm(strs::Vector{<:AbstractString}; delim='_')
#   str12 = split.(strs, delim)
#   sp1 = sortperm(parse.(Int,getindex.(str12,2)))
#   sp2 = sortperm(parse.(Int,getindex.(str12,1)[sp1]))
#   return sp1[sp2]
# end

# function getFirstNumericalOffset(st::AS) where AS <: AbstractString
#   i = 1
#   while !allnums(st[i:i])  i+=1; end
#   return i
# end
#
# """
#     $SIGNATURES
#
# Sort a variable list which may have nested structure such as `:x1_2` -- does not sort for alphabetic characters.
# """
# function sortVarNested(vars::Vector{Symbol})::Vector{Symbol}
#     # whos nested and first numeric character offset
#     sv = string.(vars)
#     offsets = getFirstNumericalOffset.(sv)
#     masknested = isnestednum.(sv)
#     masknotnested = true .⊻ masknested
#
#     # strip alphabetic characters from front
#     msv = sv[masknotnested]
#     msvO = offsets[masknotnested]
#     nsv = sv[masknested]
#     nsvO = offsets[masknested]
#
#     # do nonnested list separately
#     nnreducelist = map((s,o) -> s[o:end], msv, msvO)
#     nnintlist = parse.(Int, nnreducelist)
#     nnp = sortperm(nnintlist)
#     nnNums = nnintlist[nnp] # used in mixing later
#     nonnested = msv[nnp]
#     smsv = vars[masknotnested][nnp]
#
#     # do nested list separately
#     nestedreducelist = map((s,o) -> s[o:end], nsv, nsvO)
#     nestedp = sortnestedperm(nestedreducelist)
#     nesNums = parse.(Int, getindex.(split.(nestedreducelist[nestedp], '_'),1)) # used in mixing later
#     nested = nsv[nestedp]
#     snsv = vars[masknested][nestedp]
#
#     # mix back together, pick next sorted item from either pile
#     retvars = Vector{Symbol}(undef, length(vars))
#     nni = 1
#     nesi = 1
#     lsmsv = length(smsv)
#     lsnsv = length(snsv)
#     MAXMAX = 999999999999
#     for i in 1:length(vars)
#       # inner ifs to ensure bounds and correct sorting at end of each list
#       if (nni<=lsmsv ? nnNums[nni] : MAXMAX) <= (nesi<=lsnsv ? nesNums[nesi] : MAXMAX)
#         retvars[i] = smsv[nni]
#         nni += 1
#       else
#         retvars[i] = snsv[nesi]
#         nesi += 1
#       end
#     end
#     return retvars
# end
#END TODO confirm this is only used in sortVarNested, then delete
