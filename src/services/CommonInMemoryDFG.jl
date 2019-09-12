## Common funtions to all InMemoryDFGTypes


#TODO consider moving IIF InMemoryDFGTypes here and exporting,
# but what IIF supports and what DFG support is different?
# define and don't export yet
const InMemoryDFGTypes = Union{SymbolDFG, LightDFG, GraphsDFG, MetaGraphsDFG}
#Union{SymbolDFG, LightDFG}

"""
    $(SIGNATURES)
Update solver and estimate data for a variable (variable can be from another graph).
"""
function updateVariableSolverData!(dfg::InMemoryDFGTypes, sourceVariable::DFGVariable)::DFGVariable
    #TODO test graphs that pass var/factor by reference
    if !exists(dfg, sourceVariable)
        error("Source variable '$(sourceVariable.label)' doesn't exist in the graph.")
    end
    var = getVariable(dfg, sourceVariable.label)
    merge!(var.estimateDict, sourceVariable.estimateDict)
    merge!(var.solverDataDict, sourceVariable.solverDataDict)
    return sourceVariable
end
