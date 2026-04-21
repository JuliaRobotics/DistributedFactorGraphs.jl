
# =============================================================================

function DFG.addState!(dfg::GraphsDFG, variableLabel::Symbol, state::State)
    var = getVariable(dfg, variableLabel)
    return addState!(var, state)
end

function DFG.addStates!(dfg::GraphsDFG, variableLabel::Symbol, states::Vector{<:State})
    s = asyncmap(states) do state
        return addState!(dfg, variableLabel, state)
    end
    return s
end

function DFG.addStates!(
    dfg::GraphsDFG,
    varLabel_state_pairs::Vector{<:Pair{Symbol, <:State}},
)
    s = asyncmap(varLabel_state_pairs) do (varLabel, state)
        return addState!(dfg, varLabel, state)
    end
    return s
end

# =============================================================================

function DFG.getState(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    v = getVariable(dfg, variableLabel)
    return getState(v, label)
end

#TODO add filters
function DFG.getStates(dfg::GraphsDFG, variableLabel::Symbol)
    v = getVariable(dfg, variableLabel)
    return collect(values(refStates(v)))
end

# ==============================================================================

function DFG.mergeState!(dfg::GraphsDFG, variableLabel::Symbol, vnd::State)
    return mergeState!(getVariable(dfg, variableLabel), vnd)
end

function DFG.mergeStates!(
    dfg::GraphsDFG,
    varLabel_state_pairs::Vector{<:Pair{Symbol, <:State}},
)
    cnt = asyncmap(varLabel_state_pairs) do (varLabel, state)
        return mergeState!(dfg, varLabel, state)
    end
    return sum(cnt)
end

function DFG.mergeStates!(dfg::GraphsDFG, variableLabel::Symbol, states::Vector{<:State})
    cnt = asyncmap(states) do state
        return mergeState!(dfg, variableLabel, state)
    end
    return sum(cnt)
end

# =============================================================================
function DFG.deleteState!(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return deleteState!(getVariable(dfg, variableLabel), label)
end

function DFG.deleteState!(dfg::GraphsDFG, sourceVariable::VariableDFG, label::Symbol)
    return deleteState!(dfg, sourceVariable.label, label)
end

function DFG.deleteStates!(dfg::GraphsDFG, variableLabel::Symbol, labels::Vector{Symbol})
    cnt = asyncmap(labels) do label
        return deleteState!(dfg, variableLabel, label)
    end
    return sum(cnt)
end

function DFG.deleteStates!(
    dfg::GraphsDFG,
    varLabel_stateLabel_pairs::Vector{Pair{Symbol, Symbol}},
)
    cnt = asyncmap(varLabel_stateLabel_pairs) do (varLabel, stateLabel)
        return deleteState!(dfg, varLabel, stateLabel)
    end
    return sum(cnt)
end

# =============================================================================

function DFG.listStates(
    dfg::GraphsDFG,
    lbl::Symbol;
    whereLabel::Union{Nothing, Function} = nothing,
)
    return listStates(getVariable(dfg, lbl); whereLabel)
end

function DFG.listStates(
    dfg::GraphsDFG;
    whereLabel::Union{Nothing, Function} = nothing,
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereVariableLabel::Union{Nothing, Function} = nothing,
)
    labels = Set{Symbol}()
    vls = listVariables(
        dfg;
        whereSolvable,
        whereTags,
        whereType,
        whereLabel = whereVariableLabel,
    )
    for vl in vls
        union!(labels, listStates(dfg, vl; whereLabel))
    end
    return collect(labels)
end

# =============================================================================

DFG.hasState(v::VariableDFG, label::Symbol) = haskey(v.states, label)
function DFG.hasState(dfg::GraphsDFG, variableLabel::Symbol, label::Symbol)
    return hasState(getVariable(dfg, variableLabel), label)
end

# =============================================================================
# other TODO
# =============================================================================

function DFG.copytoState!(
    dfg::GraphsDFG,
    variableLabel::Symbol,
    stateLabel::Symbol,
    state::State,
)
    newstate = State(state; label = stateLabel)
    return mergeState!(dfg, variableLabel, newstate)
end
