
export hasFactor, hasVariable, isInitialized

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


"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
TODO: Refactor
"""
function isInitialized(var::DFGVariable; key::Symbol=:default)::Bool
  return var.solverDataDict[key].initialized
end
function isInitialized(fct::DFGFactor; key::Symbol=:default)::Bool
  return fct.solverDataDict[key].initialized
end
function isInitialized(dfg::G, label::Symbol; key::Symbol=:default)::Bool where G <: AbstractDFG
  return isInitialized(getVariable(dfg, label), key=key)
end
