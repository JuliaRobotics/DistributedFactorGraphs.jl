function DFG.addVariable!(
    dfg::GraphsDFG{<:AbstractDFGParams, V, <:AbstractGraphFactor},
    variable::V,
) where {V <: AbstractGraphVariable}
    if haskey(dfg.g.variables, variable.label)
        throw(LabelExistsError("Variable", variable.label))
    end

    @assert FactorGraphs.addVariable!(dfg.g, variable)

    return variable
end

#TODO move to interface level
function DFG.addVariable!(
    dfg::GraphsDFG{<:AbstractDFGParams, VD, <:AbstractGraphFactor},
    variable::AbstractGraphVariable,
) where {VD <: AbstractGraphVariable}
    return addVariable!(dfg, VD(variable))
end

function DFG.addVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})
    return asyncmap(variables) do v
        return addVariable!(dfg, v)
    end
end

function DFG.getVariable(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.variables, label)
        throw(LabelNotFoundError("Variable", label))
    end

    return dfg.g.variables[label]
end

function DFG.getVariables(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
)
    variables = collect(values(dfg.g.variables))

    filterDFG!(variables, whereLabel, getLabel)
    filterDFG!(variables, whereSolvable, getSolvable)
    filterDFG!(variables, whereTags, refTags)
    filterDFG!(variables, whereType, getStateKind)

    return variables
end

function DFG.mergeVariable!(dfg::GraphsDFG, variable::AbstractGraphVariable)
    if !haskey(dfg.g.variables, variable.label)
        addVariable!(dfg, variable)
    else
        patch!(dfg.g.variables[variable.label], variable)
    end
    # metrics = (;
    #     tags = length(variable.tags),
    #     states = length(variable.states),
    #     bloblets = length(variable.bloblets),
    #     blobentries = length(variable.blobentries),
    # )
    #TODO return metrics or 1 to keep it simple?
    # if 1, the merge result does not include the children.
    # if metrics, the merge result includes the children counts
    return 1
end

function DFG.mergeVariables!(dfg::AbstractDFG, variables::Vector{<:AbstractGraphVariable})
    counts = asyncmap(v -> mergeVariable!(dfg, v), variables)
    return sum(counts; init = 0)
end

function DFG.deleteVariable!(dfg::GraphsDFG, label::Symbol)#::Tuple{AbstractGraphVariable, Vector{<:AbstractGraphFactor}}
    !haskey(dfg.g.variables, label) && return 0

    # orphaned factors are not supported.
    del_facs = map(l -> deleteFactor!(dfg, l), listNeighbors(dfg, label))

    rem_vertex!(dfg.g, dfg.g.labels[label])
    return sum(del_facs; init = 0) + 1
end

function DFG.listVariables(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    if !isnothing(whereSolvable) || !isnothing(whereTags) || !isnothing(whereType)
        return map(
            getLabel,
            getVariables(dfg; whereSolvable, whereTags, whereType, whereLabel),
        )::Vector{Symbol}
    else
        # Is it ok to continue using the internal keys property? collect(keys(dfg.g.variables)) allowcates a lot.
        labels = copy(dfg.g.variables.keys)
        filterDFG!(labels, whereLabel, string)
        return labels
    end
end

function DFG.hasVariable(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.variables, label)
end
