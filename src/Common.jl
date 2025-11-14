
## Utility functions for getting type names and modules (from IncrementalInference)
_getmodule(t::T) where {T} = T.name.module
_getname(t::T) where {T} = T.name.name

function convertPackedType(t::Union{T, Type{T}}) where {T <: AbstractObservation}
    return getfield(_getmodule(t), Symbol("Packed$(_getname(t))"))
end
function convertStructType(::Type{PT}) where {PT <: AbstractPackedObservation}
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
function sortDFG(vars::Vector{<:AbstractGraphNode}; by = getTimestamp, kwargs...)
    return sort(vars; by = by, kwargs...)
end
sortDFG(vars::Vector{Symbol}; lt = natural_lt, kwargs...) = sort(vars; lt = lt, kwargs...)

##==============================================================================
## Filtering
##==============================================================================

# std_numeric_predicates = [==, <, <=, >, >=, in]
# std_string_predicates = [==, in, contains, startswith, endswith]

# # full list
# tags_includes(tag::Symbol) = Base.Fix1(in, tag)
# solvable_eq(x::Int) = ==(x)
# solvable_in(x::Vector{Int}) = in(x)
# solvable_lt(x::Int) = <(x)
# solvable_lte(x::Int) = <=(x)
# solvable_gt(x::Int) = >(x)
# solvable_gte(x::Int) = >=(x)
# label_in(x::Vector{Symbol}) = in(x)
# label_contains(x::String) = contains(x)
# label_startswith(x::String) = startswith(x)
# label_endswith(x::String) = endswith(x)
# type_eq(x::AbstractStateType) = ==(x)
# type_in(x::Vector{<:AbstractStateType}) = in(x)
# type_contains(x::String) = contains(x)
# type_startswith(x::String) = startswith(x)
# type_endswith(x::String) = endswith(x)

# Set predicates
# collection_includes(item) = Base.Fix1(in, item) # collection includes item (item in collection)

# not supported helper
# collection_overlap(collection) = !isdisjoint(collection) # collection overlaps with another collection

"""
    $SIGNATURES
Filter nodes in a DFG based on a predicate function.
This function modifies the input `nodes` vector in place, removing nodes that do not satisfy the predicate.

- **For cross-backend compatibility:**  
  Use only the standard predicates (`==`, `<`, `<=`, `>`, `>=`, `in`, `contains`, `startswith`, `endswith`) 
  when you need your code to work with both in-memory and database-backed DFGs. 
  These are likely to be supported by database query languages and are defined in `std_numeric_predicates` and `std_string_predicates`.

- **For in-memory only operations:**  
  You can use any Julia predicate, since you have full access to the data and Julia's capabilities.
  This is more flexible but will not work if you later switch to a database backend or another programming language.

Standard predicates
- Numeric predicates: `==`, `<`, `<=`, `>`, `>=`, `in`
- String predicates: `==`, `contains`, `startswith`, `endswith`, `in`
"""
function filterDFG! end

filterDFG!(nodes, predicate::Nothing, by::Function = identity) = nodes
# function filterDFG!(nodes, predicate::Base.Fix2, by=identity)
function filterDFG!(nodes, predicate::Function, by::Function = identity)
    return filter!(predicate ∘ by, nodes)
end

# specialized for label::Symbol filtering
function filterDFG!(nodes, predicate::Function, by::typeof(getLabel))
    # TODO this is not as clean as it should be, revisit if any issues arise
    # Standard predicates that needs to be converted to string to work with Symbols
    # OR look for the type if predicate isa Base.Fix2 && (predicate.x isa AbstractString || predicate.x isa Regex)
    if predicate isa Base.Fix2 &&
       typeof(predicate.f) in [typeof(contains), typeof(startswith), typeof(endswith)]
        return filter!(predicate ∘ string ∘ by, nodes)
    else
        return filter!(predicate ∘ by, nodes)
    end
end

##==============================================================================
## Validation of session, robot, and user labels.
##==============================================================================
global _invalidIds = ["GRAPH", "AGENT", "VARIABLE", "FACTOR", "BLOB_ENTRY", "FACTORGRAPH"]

const global _validLabelRegex::Regex = r"^[a-zA-Z][-\w\.\@]*$"

"""
$(SIGNATURES)

Returns true if the label is valid for node.
"""
function isValidLabel(id::Union{Symbol, String})
    _id = string(id)
    return occursin(_validLabelRegex, _id) && !in(uppercase(_id), _invalidIds)
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
