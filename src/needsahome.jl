
function print(vert::DFGVariable, solveKey::Symbol=:default)
  vnd = getSolverData(vert, solveKey)
  println("label: $(vert.label)")
  println("tags: $(getTags(vert))")
  println("size marginal samples $(size(vnd.val))")
  println("kde bandwidths: $((vnd.bw)[:,1])")
  if 0 < length(getPPEDict(vert))
    println("PPE.suggested: $(round.(getPPE(vert).suggested,digits=4))")
  else
    println("No PPEs")
  end
  # println("kde max: $(round.(getKDEMax(getKDE(vnd)),digits=4))")
  # println("kde max: $(round.(getKDEMax(getKDE(vnd)),digits=4))")
  println()
  vnd
end

print(fct::DFGFactor) = @show fct


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
printFactor(dfg::AbstractDFG, sym::Symbol) = print(getFactor(dfg, sym))

"""
   $SIGNATURES

Display the content of `VariableNodeData` to console for a given factor graph and variable tag`::Symbol`.

Dev Notes
- TODO split as two show macros between AMP and DFG
"""
printVariable(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = print(getVariable(dfg, sym))

print(dfg::AbstractDFG, sym::Symbol) = isVariable(dfg,sym) ? printVariable(dfg, sym) : printFactor(dfg, sym)
