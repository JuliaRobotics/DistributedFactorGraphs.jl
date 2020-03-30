"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
Orphaned factors are not added.
Set `overwriteDest` to overwrite existing variables and factors in the destination DFG.
NOTE: copyGraphMetadata not supported yet.
"""
function copyGraph!(destDFG::AbstractDFG, sourceDFG::AbstractDFG, variableFactorLabels::Vector{Symbol}; copyGraphMetadata::Bool=false, overwriteDest::Bool=false, deepcopyNodes::Bool=false)
    # Split into variables and factors
    sourceVariables = map(vId->getVariable(sourceDFG, vId), intersect(listVariables(sourceDFG), variableFactorLabels))
    sourceFactors = map(fId->getFactor(sourceDFG, fId), intersect(listFactors(sourceDFG), variableFactorLabels))
    if length(sourceVariables) + length(sourceFactors) != length(variableFactorLabels)
        rem = symdiff(map(v->v.label, sourceVariables), variableFactorLabels)
        rem = symdiff(map(f->f.label, sourceFactors), variableFactorLabels)
        error("Cannot copy because cannot find the following nodes in the source graph: $rem")
    end

    # Now we have to add all variables first,
    for variable in sourceVariables
        variableCopy = deepcopyNodes ? deepcopy(variable) : variable
        if !exists(destDFG, variable)
            addVariable!(destDFG, variableCopy)
        elseif overwriteDest
            updateVariable!(destDFG, variableCopy)
        else
            error("Variable $(variable.label) already exists in destination graph!")
        end
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
        if length(factVariableIds) == length(sourceFactorVariableIds)
            factorCopy = deepcopyNodes ? deepcopy(factor) : factor
            if !exists(destDFG, factor)
                addFactor!(destDFG, factorCopy)
            elseif overwriteDest
                updateFactor!(destDFG, factorCopy)
            else
                error("Factor $(factor.label) already exists in destination graph!")
            end
        else
            @warn "Factor $(factor.label) will be an orphan in the destination graph, and therefore not added."
        end
    end

    if copyGraphMetadata
        setUserData(destDFG, getUserData(sourceDFG))
        setRobotData(destDFG, getRobotData(sourceDFG))
        setSessionData(destDFG, getSessionData(sourceDFG))
    end
    return nothing
end

function deepcopyGraph!(destDFG::AbstractDFG,
                        sourceDFG::AbstractDFG,
                        variableFactorLabels::Vector{Symbol} = union(ls(sourceDFG), lsf(sourceDFG));
                        kwargs...)
    copyGraph!(destDFG, sourceDFG, variableFactorLabels; deepcopyNodes=true, kwargs...)
end


function deepcopyGraph( ::Type{T},
                        sourceDFG::AbstractDFG,
                        variableFactorLabels::Vector{Symbol} = union(ls(sourceDFG), lsf(sourceDFG));
                        kwargs...) where T <: AbstractDFG
    destDFG = T(getDFGInfo(sourceDFG)...)
    copyGraph!(destDFG, sourceDFG, variableFactorLabels; deepcopyNodes=true, kwargs...)
    return destDFG
end

Base.convert(::Type{T}, fg::AbstractDFG) where T <: AbstractDFG = deepcopyGraph(T, fg)
