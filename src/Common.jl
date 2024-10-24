
## Utility functions for getting type names and modules (from IncrementalInference)
_getmodule(t::T) where {T} = T.name.module
_getname(t::T) where {T} = T.name.name

function convertPackedType(t::Union{T, Type{T}}) where {T <: AbstractFactor}
    return getfield(_getmodule(t), Symbol("Packed$(_getname(t))"))
end
function convertStructType(::Type{PT}) where {PT <: AbstractPackedFactor}
    # see #668 for expanded reasoning.  PT may be ::UnionAll if the type is of template type.
    ptt = PT isa DataType ? PT.name.name : PT
    moduleName = PT isa DataType ? PT.name.module : Main
    symbolName = Symbol(string(ptt)[7:end])
    return getfield(moduleName, symbolName)
end

##==============================================================================
## Sorting
##==============================================================================
#Natural Sorting less than

# Adapted from https://rosettacode.org/wiki/Natural_sorting
# split at digit to not digit change
splitbynum(x::AbstractString) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
#parse to Int
function numstringtonum(arr::Vector{<:AbstractString})
    return [(n = tryparse(Int, e)) !== nothing ? n : e for e in arr]
end
#natural less than
function natural_lt(x::T, y::T) where {T <: AbstractString}
    xarr = numstringtonum(splitbynum(x))
    yarr = numstringtonum(splitbynum(y))
    for i = 1:min(length(xarr), length(yarr))
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

natural_lt(x::Symbol, y::Symbol) = natural_lt(string(x), string(y))

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
function sortDFG(vars::Vector{<:DFGNode}; by = getTimestamp, kwargs...)
    return sort(vars; by = by, kwargs...)
end
sortDFG(vars::Vector{Symbol}; lt = natural_lt, kwargs...) = sort(vars; lt = lt, kwargs...)

##==============================================================================
## Validation of session, robot, and user labels.
##==============================================================================
global _invalidIds =
    ["GRAPH", "AGENT", "VARIABLE", "FACTOR", "PPE", "BLOB_ENTRY", "FACTORGRAPH"]

const global _validLabelRegex::Regex = r"^[a-zA-Z][-\w\.\@]*$"

"""
$(SIGNATURES)

Returns true if the label is valid for node.
"""
function isValidLabel(id::Union{Symbol, String})
    if typeof(id) == Symbol
        id = String(id)
    end
    return !in(uppercase(id), _invalidIds) && !isnothing(match(_validLabelRegex, id))
end

"""
    $SIGNATURES

Small utility to return `::Int`, e.g. `0` from `getVariableLabelNumber(:x0)`

Examples
--------
```julia
getVariableLabelNumber(:l10)          # 10
getVariableLabelNumber(:x1)           # 1
getVariableLabelNumber(:x1_10, "x1_") # 10
```

DevNotes
- make prefix Regex based for longer -- i.e. `:apriltag578`, `:lm1_4`

"""
function getVariableLabelNumber(vs::Symbol, prefix = string(vs)[1])
    return parse(Int, string(vs)[(length(prefix) + 1):end])
end

## =================================
## Additional Downstream dispatches
## =================================

"""
    $SIGNATURES

Default non-parametric graph solution.
"""
function solveGraph! end

"""
    $SIGNATURES

Standard parametric graph solution (Experimental).
"""
function solveGraphParametric! end
