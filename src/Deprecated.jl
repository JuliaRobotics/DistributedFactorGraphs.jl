
## ================================================================================
## Remove in v0.25
##=================================================================================
@deprecate getBlobEntry(var::AbstractDFGVariable, key::AbstractString) =
    getBlobEntryFirst(var, Regex(key))

## ================================================================================
## Remove in v0.24
##=================================================================================
#NOTE free up getNeighbors to return the variables or factors
@deprecate getNeighbors(args...; kwargs...) listNeighbors(args...; kwargs...)
