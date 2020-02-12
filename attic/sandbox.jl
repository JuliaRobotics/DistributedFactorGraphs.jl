
function copyGraph!(destDFG::AbstractDFG, sourceDFG::AbstractDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false; copyGraphMetadata::Bool=false)
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
        if !exists(destDFG, variable)
            addVariable!(destDFG, variable)
        else
            #TODO Technically this should be an error
            @warn "Variable $(variable.label) already exists in destination graph, ignoring!"
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
        if includeOrphanFactors || length(factVariableIds) == length(sourceFactorVariableIds)
            if !exists(destDFG, factor)
                addFactor!(destDFG, factVariableIds, factor)
            end
        end
    end

    if copyGraphMetadata
        setUserData(destDFG, getUserData(sourceDFG))
        setRobotData(destDFG, getRobotData(sourceDFG))
        setSessionData(destDFG, getSessionData(sourceDFG))
    end
    return nothing
end

function deepcopyGraph!(destDFG::AbstractDFG, sourceDFG::AbstractDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false; copyGraphMetadata::Bool=false)
    sourceDFGcopy = deepcopy(sourceDFG)
    deepcopyGraph!(destDFG, sourceDFGcopy, union(ls(sourceDFG), lsf(sourceDFG)), includeOrphanFactors, copyGraphMetadata=copyGraphMetadata)
end

function deepcopyGraph!(destDFG::AbstractDFG, sourceDFG::AbstractDFG)
    deepcopyGraph!(destDFG, sourceDFG, union(ls(sourceDFG), lsf(sourceDFG)), includeOrphanFactors, copyGraphMetadata=copyGraphMetadata)
end

function deepcopyGraph(::Type{T}, sourceDFG::AbstractDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false; copyGraphMetadata::Bool=false) where T <: AbstractDFG
    destDFG = T(getConstructionData(sourceDFG))
    deepcopyGraph!(destDFG, sourceDFG, variableFactorLabels, includeOrphanFactors, copyGraphMetadata=copyGraphMetadata)
    return destDFG
end

function deepcopyGraph(::Type{T}, sourceDFG::AbstractDFG) where T <: AbstractDFG
    destDFG = T(getConstructionData(sourceDFG))
    return destDFG
end

Base.convert(::Type{T}, fg::AbstractDFG) where T <: AbstractDFG = deepcopyGraph(T, fg)
