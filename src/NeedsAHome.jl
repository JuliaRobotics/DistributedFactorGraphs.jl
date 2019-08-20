
export hasFactor, hasVariable, isInitialized, getFactorFunction, isVariable, isFactor

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


"""
    $SIGNATURES

Return whether `sym::Symbol` represents a variable vertex in the graph.
"""
isVariable(dfg::G, sym::Symbol) where G <: AbstractDFG = hasVariable(dfg, sym)

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a factor vertex in the graph.
"""
isFactor(dfg::G, sym::Symbol) where G <: AbstractDFG = hasFactor(dfg, sym)

"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fcd::GenericFunctionNodeData) = fcd.fnc.usrfnc!
getFactorFunction(fc::DFGFactor) = getFactorFunction(getData(fc))
function getFactorFunction(dfg::G, fsym::Symbol) where G <: AbstractDFG
  getFactorFunction(getFactor(dfg, fsym))
end


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
showFactor(fgl::G, fsym::Symbol) where G <: AbstractDFG = @show getFactor(fgl,fsym)
