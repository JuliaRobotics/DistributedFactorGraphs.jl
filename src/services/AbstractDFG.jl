## ===== Interface for an AbstractDFG =====

# Standard recommended fields to implement for AbstractDFG
# - `description::String`
# - `userId::String`
# - `robotId::String`
# - `sessionId::String`
# - `userData::Dict{Symbol, String}`
# - `robotData::Dict{Symbol, String}`
# - `sessionData::Dict{Symbol, String}`
# - `solverParams::T<:AbstractParams`
# - `addHistory::Vector{Symbol}`
# AbstractDFG Accessors

# Getters
"""
    $(SIGNATURES)
Convenience function to get all the matadata of a DFG
"""
getDFGInfo(dfg::AbstractDFG) = (dfg.description, dfg.userId, dfg.robotId, dfg.sessionId, dfg.userData, dfg.robotData, dfg.sessionData, dfg.solverParams)

"""
    $(SIGNATURES)
"""
getDescription(dfg::AbstractDFG) = dfg.description

"""
    $(SIGNATURES)
"""
getUserId(dfg::AbstractDFG) = dfg.userId

"""
    $(SIGNATURES)
"""
getRobotId(dfg::AbstractDFG) = dfg.robotId

"""
    $(SIGNATURES)
"""
getSessionId(dfg::AbstractDFG) = dfg.sessionId

"""
    $(SIGNATURES)
"""
getAddHistory(dfg::AbstractDFG) = dfg.addHistory

"""
    $(SIGNATURES)
"""
getSolverParams(dfg::AbstractDFG) = dfg.solverParams


# Setters
"""
    $(SIGNATURES)
"""
setDescription!(dfg::AbstractDFG, description::String) = dfg.description = description

"""
    $(SIGNATURES)
"""
setUserId!(dfg::AbstractDFG, userId::String) = dfg.userId = userId

"""
    $(SIGNATURES)
"""
setRobotId!(dfg::AbstractDFG, robotId::String) = dfg.robotId = robotId

"""
    $(SIGNATURES)
"""
setSessionId!(dfg::AbstractDFG, sessionId::String) = dfg.sessionId = sessionId

"""
    $(SIGNATURES)
"""
#NOTE a MethodError will be thrown if solverParams type does not mach the one in dfg
# TODO Is it ok or do we want any abstract solver paramters
setSolverParams!(dfg::AbstractDFG, solverParams::AbstractParams) = dfg.solverParams = solverParams

# Accessors and CRUD for user/robot/session Data
"""
$SIGNATURES

Get the user data associated with the graph.
"""
getUserData(dfg::AbstractDFG)::Union{Nothing, Dict{Symbol, String}} = return dfg.userData

"""
$SIGNATURES

Set the user data associated with the graph.
"""
function setUserData!(dfg::AbstractDFG, data::Dict{Symbol, String})::Union{Nothing, Dict{Symbol, String}}
    dfg.userData = data
    return dfg.userData
end

"""
$SIGNATURES

Get the robot data associated with the graph.
"""
getRobotData(dfg::AbstractDFG)::Union{Nothing, Dict{Symbol, String}} = return dfg.robotData

"""
$SIGNATURES

Set the robot data associated with the graph.
"""
function setRobotData!(dfg::AbstractDFG, data::Dict{Symbol, String})::Union{Nothing, Dict{Symbol, String}}
    dfg.robotData = data
    return dfg.robotData
end

"""
$SIGNATURES

Get the session data associated with the graph.
"""
getSessionData(dfg::AbstractDFG)::Dict{Symbol, String} = return dfg.sessionData

"""
$SIGNATURES

Set the session data associated with the graph.
"""
function setSessionData!(dfg::AbstractDFG, data::Dict{Symbol, String})::Union{Nothing, Dict{Symbol, String}}
    dfg.sessionData = data
    return dfg.sessionData
end

#NOTE with API standardization this should become something like:
# JT, I however do not feel we should force it, as I prever dot notation
getUserData(dfg::AbstractDFG, key::Symbol)::String = dfg.userData[key]
getRobotData(dfg::AbstractDFG, key::Symbol)::String = dfg.robotData[key]
getSessionData(dfg::AbstractDFG, key::Symbol)::String = dfg.sessionData[key]

updateUserData!(dfg::AbstractDFG, pair::Pair{Symbol,String}) = push!(dfg.userData, pair)
updateRobotData!(dfg::AbstractDFG, pair::Pair{Symbol,String}) = push!(dfg.robotData, pair)
updateSessionData!(dfg::AbstractDFG, pair::Pair{Symbol,String}) = push!(dfg.sessionData, pair)

deleteUserData!(dfg::AbstractDFG, key::Symbol) = pop!(dfg.userData, key)
deleteRobotData!(dfg::AbstractDFG, key::Symbol) = pop!(dfg.robotData, key)
deleteSessionData!(dfg::AbstractDFG, key::Symbol) = pop!(dfg.sessionData, key)

emptyUserData!(dfg::AbstractDFG) = empty!(dfg.userData)
emptyRobotData!(dfg::AbstractDFG) = empty!(dfg.robotData)
emptySessionData!(dfg::AbstractDFG) = empty!(dfg.sessionData)

#TODO add__Data!?


##
"""
    $(SIGNATURES)

Deserialization of IncrementalInference objects require discovery of foreign types.

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
True if the variable or factor exists in the graph.
"""
function exists(dfg::G, node::N) where {G <: AbstractDFG, N <: DFGNode}
    error("exists not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::G, variable::V)::AbstractDFGVariable where {G <: AbstractDFG, V <: AbstractDFGVariable}
    error("addVariable! not implemented for $(typeof(dfg))")
end

"""
Add a DFGFactor to a DFG.
    $(SIGNATURES)
"""
function addFactor!(dfg::AbstractDFG, factor::F)::F where F <: AbstractDFGFactor
    error("addFactor! not implemented for $(typeof(dfg))(dfg, factor)")
end

"""
$(SIGNATURES)
"""
function addFactor!(dfg::AbstractDFG, variables::Vector{<:AbstractDFGVariable}, factor::F)::F where  F <: AbstractDFGFactor

        variableLabels = map(v->v.label, variables)

        resize!(factor._variableOrderSymbols, length(variableLabels))
        factor._variableOrderSymbols .= variableLabels

        return addFactor!(dfg, factor)

end

"""
$(SIGNATURES)
"""
function addFactor!(dfg::AbstractDFG, variableLabels::Vector{Symbol}, factor::F)::AbstractDFGFactor where F <: AbstractDFGFactor

    resize!(factor._variableOrderSymbols, length(variableLabels))
    factor._variableOrderSymbols .= variableLabels

    return addFactor!(dfg, factor)
end

# TODO: Confirm we can remove this.
# """
#     $(SIGNATURES)
# Get a DFGVariable from a DFG using its underlying integer ID.
# """
# function getVariable(dfg::G, variableId::Int64)::AbstractDFGVariable where G <: AbstractDFG
#     error("getVariable not implemented for $(typeof(dfg))")
# end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::G, label::Union{Symbol, String})::AbstractDFGVariable where G <: AbstractDFG
    error("getVariable not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGVariable with a specific solver key.
In memory types still return a reference, other types returns a variable with only solveKey.
"""
function getVariable(dfg::AbstractDFG, label::Symbol, solveKey::Symbol)::AbstractDFGVariable

    var = getVariable(dfg, label)

    if isa(var, DFGVariable) && !haskey(var.solverDataDict, solveKey)
        error("Solvekey '$solveKey' does not exists in the variable")
    elseif !isa(var, DFGVariable)
        @warn "getVariable(dfg, label, solveKey) only supported for type DFGVariable."
    end

    return var
end

# TODO: Confirm we can remove this.
# """
#     $(SIGNATURES)
# Get a DFGFactor from a DFG using its underlying integer ID.
# """
# function getFactor(dfg::G, factorId::Int64)::AbstractDFGFactor where G <: AbstractDFG
#     error("getFactor not implemented for $(typeof(dfg))")
# end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::G, label::Union{Symbol, String})::AbstractDFGFactor where G <: AbstractDFG
    error("getFactor not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::G, variable::V)::AbstractDFGVariable where {G <: AbstractDFG, V <: AbstractDFGVariable}
    error("updateVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::G, factor::F)::AbstractDFGFactor where {G <: AbstractDFG, F <: AbstractDFGFactor}
    error("updateFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::G, label::Symbol)::AbstractDFGVariable where G <: AbstractDFG
    error("deleteVariable! not implemented for $(typeof(dfg))")
end

#Alias
"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
function deleteVariable!(dfg::G, variable::V)::AbstractDFGVariable where {G <: AbstractDFG, V <: AbstractDFGVariable}
    return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::G, label::Symbol)::AbstractDFGFactor where G <: AbstractDFG
    error("deleteFactors not implemented for $(typeof(dfg))")
end

# Alias
"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
function deleteFactor!(dfg::G, factor::F)::AbstractDFGFactor where {G <: AbstractDFG, F <: AbstractDFGFactor}
    return deleteFactor!(dfg, factor.label)
end

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).
"""
function getVariables(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGVariable} where G <: AbstractDFG
    error("getVariables not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a list of IDs of the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

Example
```julia
listVariables(dfg, r"l", tags=[:APRILTAG;])
```

Related:
- ls
"""
function listVariables(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
  vars = getVariables(dfg, regexFilter, tags=tags, solvable=solvable)
  return map(v -> v.label, vars)
end
#TODO alias or deprecate
@deprecate getVariableIds(dfg::AbstractDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) listVariables(dfg, regexFilter, tags=tags, solvable=solvable)

# Alias
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

"""
function ls(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGFactor} where G <: AbstractDFG
    error("getFactors not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a list of the IDs (labels) of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function listFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return map(f -> f.label, getFactors(dfg, regexFilter, solvable=solvable))
end
#TODO alias or deprecate
@deprecate getFactorIds(dfg, regexFilter=nothing; solvable=0) listFactors(dfg, regexFilter, solvable=solvable)

# Alias
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function lsf(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return listFactors(dfg, regexFilter, solvable=solvable)
end

"""
    $(SIGNATURES)
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::G, label::Symbol; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
  return getNeighbors(dfg, label, solvable=solvable)
end

"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::G)::Bool where G <: AbstractDFG
    error("isFullyConnected not implemented for $(typeof(dfg))")
end

#Alias
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
function hasOrphans(dfg::G)::Bool where G <: AbstractDFG
    return !isFullyConnected(dfg)
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function getNeighbors(dfg::G, node::T; solvable::Int=0)::Vector{Symbol}  where {G <: AbstractDFG, T <: DFGNode}
    error("getNeighbors not implemented for $(typeof(dfg))")
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::G, label::Symbol; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    error("getNeighbors not implemented for $(typeof(dfg))")
end

# Aliases
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::G, node::T; solvable::Int=0)::Vector{Symbol} where {G <: AbstractDFG, T <: DFGNode}
    return getNeighbors(dfg, node, solvable=solvable)
end
"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function ls(dfg::G, label::Symbol; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return getNeighbors(dfg, label, solvable=solvable)
end

"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::G)::G where G <: AbstractDFG
    error("_getDuplicatedEmptyDFG not implemented for $(typeof(dfg))")
end

# TODO: NEED TO FIGURE OUT SIGNATURE FOR DEFAULT ARGS


# TODO export, test and overwrite in LightGraphs and CloudGraphsDFG
"""
    $(SIGNATURES)
Build a list of all unique neighbors inside 'distance'
"""
function getNeighborhood(dfg::AbstractDFG, label::Symbol, distance::Int)::Vector{Symbol}
    neighborList = Set{Symbol}([label])
    curList = Set{Symbol}([label])

    for dist in 1:distance
        newNeighbors = Set{Symbol}()
        for node in curList
            neighbors = getNeighbors(dfg, node)
            for neighbor in neighbors
                push!(neighborList, neighbor)
                push!(newNeighbors, neighbor)
            end
        end
        curList = newNeighbors
    end
    return collect(neighborList)
end

"""
    $(SIGNATURES)
Retrieve a deep subgraph copy around a given variable or factor.
Optionally provide a distance to specify the number of edges should be followed.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
Note: Always returns the node at the center, but filters around it if solvable is set.
"""
function getSubgraphAroundNode(dfg::AbstractDFG, node::DFGNode, distance::Int=1, includeOrphanFactors::Bool=false, addToDFG::AbstractDFG=_getDuplicatedEmptyDFG(dfg); solvable::Int=0)::AbstractDFG

    if !exists(dfg, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    neighbors = getNeighborhood(dfg, node.label, distance)

    # for some reason: always returns the node at the center with  || (nlbl == node.label)
    solvable != 0 && filter!(nlbl -> (getSolvable(dfg, nlbl) >= solvable) || (nlbl == node.label), neighbors)

    # Copy the section of graph we want
    _copyIntoGraph!(dfg, addToDFG, neighbors, includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Get a deep subgraph copy from the DFG given a list of variables and factors.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
"""
function getSubgraph(dfg::G,
                     variableFactorLabels::Vector{Symbol},
                     includeOrphanFactors::Bool=false,
                     addToDFG::H=_getDuplicatedEmptyDFG(dfg))::H where {G <: AbstractDFG, H <: AbstractDFG}
    for label in variableFactorLabels
        if !exists(dfg, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
NOTE: copyGraphMetadata not supported yet.
"""
function _copyIntoGraph!(sourceDFG::G, destDFG::H, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false; copyGraphMetadata::Bool=false)::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
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
            addVariable!(destDFG, deepcopy(variable))
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
                addFactor!(destDFG, factVariableIds, deepcopy(factor))
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

"""
    $(SIGNATURES)
List all the solver data keys in the variable.
"""
function listVariableSolverData(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
    v = getVariable(dfg, variablekey)
    return collect(keys(v.solverDataDict))
end

"""
    $(SIGNATURES)
Get variable solverdata for a given solve key.
"""
function getVariableSolverData(dfg::AbstractDFG, variablekey::Symbol, solvekey::Symbol=:default)::VariableNodeData
    v = getVariable(dfg, variablekey)
    !haskey(v.solverDataDict, solvekey) && error("Solve key '$solvekey' not found in variable '$variablekey'")
    return v.solverDataDict[solvekey]
end


"""
    $(SIGNATURES)
Add variable solver data, errors if it already exists.
"""
function addVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solvekey::Symbol=:default)::VariableNodeData
    var = getVariable(dfg, variablekey)
    if haskey(var.solverDataDict, solvekey)
        error("VariableNodeData '$(solvekey)' already exists")
    end
    var.solverDataDict[solvekey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Add a new solver data  entry from a deepcopy of the source variable solver data.
NOTE: Copies the solver data.
"""
addVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    addVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solvekey)), solvekey)


"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
"""
function updateVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, vnd::VariableNodeData, solvekey::Symbol=:default)::VariableNodeData
    #This is basically just setSolverData
    var = getVariable(dfg, variablekey)
    if !haskey(var.solverDataDict, solvekey)
        @warn "VariableNodeData '$(solvekey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.solverDataDict[solvekey] = vnd
    return vnd
end

"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
NOTE: Copies the solver data.
"""
updateVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    updateVariableSolverData!(dfg, sourceVariable.label, deepcopy(getSolverData(sourceVariable, solvekey)), solvekey)

"""
    $(SIGNATURES)
Update variable solver data if it exists, otherwise add it.
"""
function updateVariableSolverData!(dfg::AbstractDFG, sourceVariables::Vector{<:DFGVariable}, solvekey::Symbol=:default)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updateVariableSolverData!(dfg, var.label, getSolverData(var, solvekey), solvekey)
    end
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
function deleteVariableSolverData!(dfg::AbstractDFG, variablekey::Symbol, solvekey::Symbol=:default)::VariableNodeData
    var = getVariable(dfg, variablekey)

    if !haskey(var.solverDataDict, solvekey)
        error("VariableNodeData '$(solvekey)' does not exist")
    end
    vnd = pop!(var.solverDataDict, solvekey)
    return vnd
end

"""
    $(SIGNATURES)
Delete variable solver data, returns the deleted element.
"""
deleteVariableSolverData!(dfg::AbstractDFG, sourceVariable::DFGVariable, solvekey::Symbol=:default) =
    deleteVariableSolverData!(dfg, sourceVariable.label, solvekey)

#####

"""
    $(SIGNATURES)
List all the PPE data keys in the variable.
"""
function listPPE(dfg::AbstractDFG, variablekey::Symbol)::Vector{Symbol}
    v = getVariable(dfg, variablekey)
    return collect(keys(v.ppeDict))
end

"""
    $(SIGNATURES)
Get the parametric point estimate (PPE) for a variable in the factor graph for a given solve key.

Notes
- Defaults on keywords `solveKey` and `method`

Related
getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default)::AbstractPointParametricEst
    v = getVariable(dfg, variablekey)
    !haskey(v.ppeDict, ppekey) && error("PPE key '$ppekey' not found in variable '$variablekey'")
    return v.ppeDict[ppekey]
end

# Not the most efficient call but it at least reuses above (in memory it's probably ok)
getPPE(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=default)::AbstractPointParametricEst = getPPE(dfg, sourceVariable.label, ppekey)

"""
    $(SIGNATURES)
Add variable PPE, errors if it already exists.
"""
function addPPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default)::AbstractPointParametricEst where P <: AbstractPointParametricEst
    var = getVariable(dfg, variablekey)
    if haskey(var.ppeDict, ppekey)
        error("PPE '$(ppekey)' already exists")
    end
    var.ppeDict[ppekey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Add a new PPE entry from a deepcopy of the source variable PPE.
NOTE: Copies the solver data.
"""
addPPE!(dfg::AbstractDFG, sourceVariable::DFGVariable, ppekey::Symbol=:default) =
    addPPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)), ppekey)


"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, variablekey::Symbol, ppe::P, ppekey::Symbol=:default)::P where P <: AbstractPointParametricEst

    var = getVariable(dfg, variablekey)
    if !haskey(var.ppeDict, ppekey)
        @warn "PPE '$(ppekey)' does not exist, adding"
    end
    #for InMemoryDFGTypes, cloud would update here
    var.ppeDict[ppekey] = ppe
    return ppe
end

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
NOTE: Copies the PPE data.
"""
updatePPE!(dfg::AbstractDFG, sourceVariable::VariableDataLevel1, ppekey::Symbol=:default) =
    updatePPE!(dfg, sourceVariable.label, deepcopy(getPPE(sourceVariable, ppekey)), ppekey)

"""
    $(SIGNATURES)
Update PPE data if it exists, otherwise add it.
"""
function updatePPE!(dfg::AbstractDFG, sourceVariables::Vector{<:VariableDataLevel1}, ppekey::Symbol=:default)
    #I think cloud would do this in bulk for speed
    for var in sourceVariables
        updatePPE!(dfg, var.label, getPPE(dfg, var, ppekey), ppekey)
    end
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
function deletePPE!(dfg::AbstractDFG, variablekey::Symbol, ppekey::Symbol=:default)::AbstractPointParametricEst
    var = getVariable(dfg, variablekey)

    if !haskey(var.ppeDict, ppekey)
        error("VariableNodeData '$(ppekey)' does not exist")
    end
    vnd = pop!(var.ppeDict, ppekey)
    return vnd
end

"""
    $(SIGNATURES)
Delete PPE data, returns the deleted element.
"""
deletePPE!(dfg::AbstractDFG, sourceVariable::DFGVariable, ppekey::Symbol=:default) =
    deletePPE!(dfg, sourceVariable.label, ppekey)

####


export mergeVariableSolverData!, mergePPEs!, mergeVariableData!, mergeGraphVariableData!
# update is implied, see API wiki
@deprecate mergeUpdateVariableSolverData!(dfg, sourceVariable) mergeVariableData!(dfg, sourceVariable)
@deprecate mergeUpdateGraphSolverData!(sourceDFG, destDFG, varSyms) mergeGraphVariableData!(destDFG, sourceDFG, varSyms)

"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
If the same key is present in another collection, the value for that key will be the value it has in the last collection listed (updated).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
#TODO API
function mergeVariableSolverData!(destVariable::DFGVariable, sourceVariable::DFGVariable)::DFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.solverDataDict, deepcopy(sourceVariable.solverDataDict))
    return destVariable
end

"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
#TODO API and only correct level
function mergePPEs!(destVariable::AbstractDFGVariable, sourceVariable::AbstractDFGVariable)::AbstractDFGVariable
    # We don't know which graph this came from, must be copied!
    merge!(destVariable.ppeDict, deepcopy(sourceVariable.ppeDict))
    return destVariable
end

"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
#TODO API
function mergeVariableData!(dfg::AbstractDFG, sourceVariable::AbstractDFGVariable)::AbstractDFGVariable

    var = getVariable(dfg, sourceVariable.label)

    mergePPEs!(var, sourceVariable)
    # If this variable has solverDataDict (summaries do not)
    :solverDataDict in fieldnames(typeof(var)) && mergeVariableSolverData!(var, sourceVariable)

    #update if its not a InMemoryDFGTypes, otherwise it was a reference
    # if satelite nodes are used it can be updated seprarately
    # !(isa(dfg, InMemoryDFGTypes)) && updateVariable!(dfg, var)

    return var
end

"""
    $(SIGNATURES)
Common function to update all solver data and estimates from one graph to another.
This should be used to push local solve data back into a cloud graph, for example.
"""
#TODO API
function mergeGraphVariableData!(destDFG::H, sourceDFG::G, varSyms::Vector{Symbol})::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Update all variables in the destination
    # (For now... we may change this soon)
    for variableId in varSyms
        mergeVariableData!(destDFG, getVariable(sourceDFG, variableId))
    end
end

# Alias

"""
    $(SIGNATURES)
Get a matrix indicating relationships between variables and factors. Rows are
all factors, columns are all variables, and each cell contains either nothing or
the symbol of the relating factor. The first row and first column are factor and
variable headings respectively.
Note: rather use getBiadjacencyMatrix
"""
function getAdjacencyMatrixSymbols(dfg::AbstractDFG; solvable::Int=0)::Matrix{Union{Nothing, Symbol}}
    #
    varLabels = sort(map(v->v.label, getVariables(dfg, solvable=solvable)))
    factLabels = sort(map(f->f.label, getFactors(dfg, solvable=solvable)))
    vDict = Dict(varLabels .=> [1:length(varLabels)...].+1)

    adjMat = Matrix{Union{Nothing, Symbol}}(nothing, length(factLabels)+1, length(varLabels)+1)
    # Set row/col headings
    adjMat[2:end, 1] = factLabels
    adjMat[1, 2:end] = varLabels
    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = getNeighbors(dfg, getFactor(dfg, factLabel), solvable=solvable)
        map(vLabel -> adjMat[fIndex+1,vDict[vLabel]] = factLabel, factVars)
    end
    return adjMat
end



"""
    $(SIGNATURES)
Get a matrix indicating adjacency between variables and factors. Returned as
a named tuple: B::SparseMatrixCSC{Int}, varLabels::Vector{Symbol)
facLabels::Vector{Symbol). Rows are the factors, columns are the variables,
with the corresponding labels in varLabels,facLabels.
"""
# TODO API name get seems wrong maybe just biadjacencyMatrix
function getBiadjacencyMatrix(dfg::AbstractDFG; solvable::Int=0)::NamedTuple{(:B, :varLabels, :facLabels), Tuple{SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}}
    varLabels = map(v->v.label, getVariables(dfg, solvable=solvable))
    factLabels = map(f->f.label, getFactors(dfg, solvable=solvable))

    vDict = Dict(varLabels .=> [1:length(varLabels)...])

    adjMat = spzeros(Int, length(factLabels), length(varLabels))

    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = getNeighbors(dfg, getFactor(dfg, factLabel), solvable=solvable)
        map(vLabel -> adjMat[fIndex,vDict[vLabel]] = 1, factVars)
    end
    return (B=adjMat, varLabels=varLabels, facLabels=factLabels)
end


"""
    $SIGNATURES

Variables or factors may or may not be 'solvable', depending on a user definition.  Useful for ensuring atomic transactions.

Related:
- isSolveInProgress
"""
getSolvable(var::Union{DFGVariable, DFGFactor})::Int = var._dfgNodeParams.solvable

"""
    $SIGNATURES

Get 'solvable' parameter for either a variable or factor.
"""
function getSolvable(dfg::AbstractDFG, sym::Symbol)
  if isVariable(dfg, sym)
    return getVariable(dfg, sym)._dfgNodeParams.solvable
  elseif isFactor(dfg, sym)
    return getFactor(dfg, sym)._dfgNodeParams.solvable
  end
end


isSolvable(node::Union{DFGVariable, DFGFactor}) = getSolvable(node) > 0

"""
    $SIGNATURES

Which variables or factors are currently being used by an active solver.  Useful for ensuring atomic transactions.

DevNotes:
- Will be renamed to `data.solveinprogress` which will be in VND, not DFGNode -- see DFG #201

Related

isSolvable
"""
function getSolveInProgress(var::Union{DFGVariable, DFGFactor}, solveKey::Symbol=:default)::Int
    # Variable
    var isa DFGVariable && return haskey(getSolverDataDict(var), solveKey) ? getSolverDataDict(var)[solveKey].solveInProgress : 0
    # Factor
    return getSolverData(var).solveInProgress
end

isSolveInProgress(node::Union{DFGVariable, DFGFactor}, solvekey::Symbol=:default) = getSolveInProgress(node, solvekey) > 0

"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(dfg::AbstractDFG, sym::Symbol, solvable::Int)::Int
  if isVariable(dfg, sym)
    getVariable(dfg, sym)._dfgNodeParams.solvable = solvable
  elseif isFactor(dfg, sym)
    getFactor(dfg, sym)._dfgNodeParams.solvable = solvable
  end
  return solvable
end

"""
    $SIGNATURES

Set the `solvable` parameter for either a variable or factor.
"""
function setSolvable!(node::N, solvable::Int)::Int where N <: DFGNode
  node._dfgNodeParams.solvable = solvable
  return solvable
end

"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::DFGVariable; key::Symbol=:default)::Bool
      data = getSolverData(var, key)
      if data == nothing
        @error "Variable does not have solver data $(key)"
        return false
      else
          return data.initialized
    end
end

function isInitialized(dfg::AbstractDFG, label::Symbol; key::Symbol=:default)::Bool
  return isInitialized(getVariable(dfg, label), key=key)
end


"""
    $SIGNATURES

Return whether `sym::Symbol` represents a variable vertex in the graph DFG.
Checks whether it both exists in the graph and is a variable.
(If you rather want a quick for type, just do node isa DFGVariable)
"""
function isVariable(dfg::G, sym::Symbol) where G <: AbstractDFG
    error("isVariable not implemented for $(typeof(dfg))")
end
# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isVariable(dfg::G, node::N)::Bool where {G <: AbstractDFG, N <: DFGNode}
    return isVariable(dfg, node.label)
end

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a factor vertex in the graph DFG.
Checks whether it both exists in the graph and is a factor.
(If you rather want a quicker for type, just do node isa DFGFactor)
"""
function isFactor(dfg::G, sym::Symbol) where G <: AbstractDFG
    error("isFactor not implemented for $(typeof(dfg))")
end
# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isFactor(dfg::G, node::N)::Bool where {G <: AbstractDFG, N <: DFGNode}
    return isFactor(dfg, node.label)
end

"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fcd::GenericFunctionNodeData) = fcd.fnc.usrfnc!
getFactorFunction(fc::DFGFactor) = getFactorFunction(getSolverData(fc))
function getFactorFunction(dfg::G, fsym::Symbol) where G <: AbstractDFG
  getFactorFunction(getFactor(dfg, fsym))
end


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
showFactor(fgl::G, fsym::Symbol) where G <: AbstractDFG = @show getFactor(fgl,fsym)


"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.
"""
function toDot(dfg::AbstractDFG)::String
    #TODO implement convert
    graphsdfg = GraphsDFG{NoSolverParams}()
    DistributedFactorGraphs._copyIntoGraph!(dfg, graphsdfg, union(listVariables(dfg), listFactors(dfg)), true)

    # Calls down to GraphsDFG.toDot
    return toDot(graphsdfg)
end

"""
    $(SIGNATURES)
Produces a dot file of the graph for visualization.
Download XDot to see the data

Note
- Default location "/tmp/dfg.dot" -- MIGHT BE REMOVED
- Can be viewed with the `xdot` system application.
- Based on graphviz.org
"""
function toDotFile(dfg::AbstractDFG, fileName::String="/tmp/dfg.dot")::Nothing
    #TODO implement convert
    if isa(dfg, GraphsDFG)
        graphsdfg = dfg
    else
        graphsdfg = GraphsDFG{NoSolverParams}()
        DistributedFactorGraphs._copyIntoGraph!(dfg, graphsdfg, union(listVariables(dfg), listFactors(dfg)), true)
    end

    open(fileName, "w") do fid
        write(fid,Graphs.to_dot(graphsdfg.g))
    end
    return nothing
end

"""
    $(SIGNATURES)
Get a summary of the graph (first-class citizens of variables and factors).
Returns a AbstractDFGSummary.
"""
function getSummary(dfg::G)::AbstractDFGSummary where {G <: AbstractDFG}
    vars = map(v -> convert(DFGVariableSummary, v), getVariables(dfg))
    facts = map(f -> convert(DFGFactorSummary, f), getFactors(dfg))
    return AbstractDFGSummary(
        Dict(map(v->v.label, vars) .=> vars),
        Dict(map(f->f.label, facts) .=> facts),
        dfg.userId,
        dfg.robotId,
        dfg.sessionId)
end

"""
$(SIGNATURES)
Get a summary graph (first-class citizens of variables and factors) with the same structure as the original graph.
Note this is a copy of the original.
Returns a LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}.
"""
function getSummaryGraph(dfg::G)::LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary} where {G <: AbstractDFG}
    summaryDfg = LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}(
        description="Summary of $(dfg.description)",
        userId=dfg.userId,
        robotId=dfg.robotId,
        sessionId=dfg.sessionId)
    for v in getVariables(dfg)
        newV = addVariable!(summaryDfg, convert(DFGVariableSummary, v))
    end
    for f in getFactors(dfg)
        addFactor!(summaryDfg, getNeighbors(dfg, f), convert(DFGFactorSummary, f))
    end
    return summaryDfg
end
