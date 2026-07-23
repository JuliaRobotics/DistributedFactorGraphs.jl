function DFG.addFactor!(
    dfg::GraphsDFG{<:AbstractDFGParams, <:AbstractGraphVariable, F},
    factor::F,
) where {F <: AbstractGraphFactor}
    if haskey(dfg.g.factors, factor.label)
        throw(LabelExistsError("Factor", factor.label))
    end
    # TODO
    # @assert FactorGraphs.addFactor!(dfg.g, getVariableOrder(factor), factor)
    variableLabels = Symbol[factor.variableorder...]
    for vlabel in variableLabels
        !hasVariable(dfg, vlabel) && throw(LabelNotFoundError("Variable", vlabel))
    end
    @assert FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
    return factor
end

#TODO move to interface level
function DFG.addFactor!(
    dfg::GraphsDFG{<:AbstractDFGParams, <:AbstractGraphVariable, F},
    factor::AbstractGraphFactor,
) where {F <: AbstractGraphFactor}
    return addFactor!(dfg, F(factor))
end

function DFG.addFactors!(dfg::AbstractDFG, factors::Vector{<:AbstractGraphFactor})
    return asyncmap(factors) do f
        return addFactor!(dfg, f)
    end
end

function DFG.getFactor(dfg::GraphsDFG, label::Symbol)
    if !haskey(dfg.g.factors, label)
        throw(LabelNotFoundError("Factor", label))
    end
    return dfg.g.factors[label]
end

function DFG.getFactors(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    factors = collect(values(dfg.g.factors))
    filterDFG!(factors, whereLabel, getLabel)
    filterDFG!(factors, whereSolvable, getSolvable)
    filterDFG!(factors, whereTags, refTags)
    filterDFG!(factors, whereType, typeof ∘ DFG.getObservation)
    return factors
end

function DFG.mergeFactor!(dfg::GraphsDFG, factor::AbstractGraphFactor)
    label = getLabel(factor)
    if !haskey(dfg.g.factors, label)
        addFactor!(dfg, factor)
    else
        patch!(dfg.g.factors[label], factor)
    end
    #TODO also same metrics consideration as mergeVariable!
    return 1
end

function DFG.mergeFactors!(dfg::AbstractDFG, factors::Vector{<:AbstractGraphFactor})
    counts = asyncmap(f -> mergeFactor!(dfg, f), factors)
    return sum(counts; init = 0)
end

function DFG.deleteFactor!(dfg::GraphsDFG, label::Symbol)
    !haskey(dfg.g.factors, label) && return 0
    rem_vertex!(dfg.g, dfg.g.labels[label])
    return 1
end

function DFG.deleteFactors!(dfg::GraphsDFG, labels::Vector{Symbol})
    fac_labels = filter(l -> hasFactor(dfg, l), labels)
    rem_vertices!(dfg.g, map(l -> dfg.g.labels[l], fac_labels))
    return length(fac_labels)
end

function DFG.deleteFactors!(dfg::AbstractDFG; kwargs...)
    labels = listFactors(dfg; kwargs...)
    return deleteFactors!(dfg, labels)
end

##

function DFG.listFactors(
    dfg::GraphsDFG;
    whereSolvable::Union{Nothing, Function} = nothing,
    whereTags::Union{Nothing, Function} = nothing,
    whereType::Union{Nothing, Function} = nothing,
    whereLabel::Union{Nothing, Function} = nothing,
)
    if !isnothing(whereSolvable) || !isnothing(whereTags) || !isnothing(whereType)
        return map(
            getLabel,
            getFactors(dfg; whereSolvable, whereTags, whereType, whereLabel),
        )::Vector{Symbol}
    else
        # Is it ok to continue using the internal keys property? collect(keys(dfg.g.factors)) allowcates a lot.
        labels = copy(dfg.g.factors.keys)
        filterDFG!(labels, whereLabel, string)
        return labels
    end
end

function DFG.hasFactor(dfg::GraphsDFG, label::Symbol)
    return haskey(dfg.g.factors, label)
end
