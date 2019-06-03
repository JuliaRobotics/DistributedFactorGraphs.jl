
export hasFactor, hasVariable

"""
    $SIGNATURES

Return boolean whether a factor `label` is present in `<:AbstractDFG`.
"""
function hasFactor(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
  return haskey(dfg.labelDict, label)
end

"""
    $(SIGNATURES)

Return `::Bool` on whether `dfg` contains the variable `lbl::Symbol`.
"""
function hasVariable(dfg::G, label::Symbol)::Bool where {G <: AbstractDFG}
  return haskey(dfg.labelDict, label) # haskey(vertices(dfg.g), label)
end
