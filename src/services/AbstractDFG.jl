
"""
    $(SIGNATURES)

De-serialization of IncrementalInference objects require discovery of foreign types.

Example:

Template to tunnel types from a user module:
```julia
# or more generic solution -- will always try Main if available
IIF.setSerializationNamespace!(Main)

# or a specific package such as RoME if you import all variable and factor types into a specific module.
using RoME
IIF.setSerializationNamespace!(RoME)
```
"""
function setSerializationModule!(dfg::G, mod::Module)::Nothing where G <: AbstractDFG
    @warn "Setting serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is being ignored."
end

function getSerializationModule(dfg::G)::Module where G <: AbstractDFG
    @warn "Retrieving serialization module from AbstractDFG - override this in the '$(typeof(dfg)) structure! This is returning Main"
    return Main
end

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
"""
function _copyIntoGraph!(sourceDFG::G, destDFG::H, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Split into variables and factors
    sourceVariables = map(vId->getVariable(sourceDFG, vId), intersect(getVariableIds(sourceDFG), variableFactorLabels))
    sourceFactors = map(fId->getFactor(sourceDFG, fId), intersect(getFactorIds(sourceDFG), variableFactorLabels))
    if length(sourceVariables) + length(sourceFactors) != length(variableFactorLabels)
        rem = symdiff(map(v->v.label, sourceVariables), variableFactorLabels)
        rem = symdiff(map(f->f.label, sourceFactors), variableFactorLabels)
        error("Cannot copy because cannot find the following nodes in the source graph: $rem")
    end

    # Now we have to add all variables first,
    for variable in sourceVariables
        addVariable!(destDFG, deepcopy(variable))
    end
    # And then all factors to the destDFG.
    for factor in sourceFactors
        # Get the original factor variables (we need them to create it)
        sourceFactorVariableIds = getNeighbors(sourceDFG, factor)
        # Find the labels and associated variables in our new subgraph
        factVariableIds = Symbol[]
        for variable in sourceFactorVariableIds
            if exists(destDFG, variable)
                push!(factVariableIds, variable)
            end
        end
        # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
        if includeOrphanFactors || length(factVariableIds) == length(sourceFactorVariableIds)
            addFactor!(destDFG, factVariableIds, deepcopy(factor))
        end
    end
    return nothing
end
