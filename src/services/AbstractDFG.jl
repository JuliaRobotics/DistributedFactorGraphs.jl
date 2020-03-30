##==============================================================================
## Interface for an AbstractDFG
##==============================================================================
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

##------------------------------------------------------------------------------
## Getters
##------------------------------------------------------------------------------
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

##------------------------------------------------------------------------------
## Setters
##------------------------------------------------------------------------------

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
    dfg.userData = data #TODO keep memory? use clear and then add
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

##==============================================================================
## User/Robot/Session Data CRUD
##==============================================================================

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



##==============================================================================
## CRUD Interfaces
##==============================================================================
##------------------------------------------------------------------------------
## Variable And Factor CRUD
##------------------------------------------------------------------------------
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
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::G, label::Union{Symbol, String})::AbstractDFGVariable where G <: AbstractDFG
    error("getVariable not implemented for $(typeof(dfg))")
end

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
function deleteVariable!(dfg::AbstractDFG, label::Symbol)::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    error("deleteVariable! not implemented for $(typeof(dfg))")
end
"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::G, label::Symbol)::AbstractDFGFactor where G <: AbstractDFG
    error("deleteFactors not implemented for $(typeof(dfg))")
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
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGFactor} where G <: AbstractDFG
    error("getFactors not implemented for $(typeof(dfg))")
end



##------------------------------------------------------------------------------
## Checking Types
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Return whether `sym::Symbol` represents a variable vertex in the graph DFG.
Checks whether it both exists in the graph and is a variable.
(If you rather want a quick for type, just do node isa DFGVariable)
"""
function isVariable(dfg::G, sym::Symbol) where G <: AbstractDFG
    error("isVariable not implemented for $(typeof(dfg))")
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


##------------------------------------------------------------------------------
## Neighbors
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
Checks if the graph is fully connected, returns true if so.
"""
function isFullyConnected(dfg::AbstractDFG)::Bool
    error("isFullyConnected not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::AbstractDFG, label::Symbol; solvable::Int=0)::Vector{Symbol}
    error("getNeighbors not implemented for $(typeof(dfg))")
end


##------------------------------------------------------------------------------
## copy and duplication
##------------------------------------------------------------------------------

#TODO use copy functions currently in attic
"""
    $(SIGNATURES)
Gets an empty and unique CloudGraphsDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::G)::G where G <: AbstractDFG
    error("_getDuplicatedEmptyDFG not implemented for $(typeof(dfg))")
end


##------------------------------------------------------------------------------
## CRUD Aliases
##------------------------------------------------------------------------------

# TODO: Confirm we can remove this.
# """
#     $(SIGNATURES)
# Get a DFGVariable from a DFG using its underlying integer ID.
# """
# function getVariable(dfg::G, variableId::Int64)::AbstractDFGVariable where G <: AbstractDFG
#     error("getVariable not implemented for $(typeof(dfg))")
# end
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


"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.
"""
function deleteVariable!(dfg::AbstractDFG, variable::AbstractDFGVariable)::Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}
    return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
function deleteFactor!(dfg::G, factor::F)::AbstractDFGFactor where {G <: AbstractDFG, F <: AbstractDFGFactor}
    return deleteFactor!(dfg, factor.label)
end

# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isVariable(dfg::G, node::N)::Bool where {G <: AbstractDFG, N <: DFGNode}
    return isVariable(dfg, node.label)
end
# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isFactor(dfg::G, node::N)::Bool where {G <: AbstractDFG, N <: DFGNode}
    return isFactor(dfg, node.label)
end

##------------------------------------------------------------------------------
## Connectivity Alias
##------------------------------------------------------------------------------

function getNeighbors(dfg::AbstractDFG, node::DFGNode; solvable::Int=0)::Vector{Symbol}
    getNeighbors(dfg, node.label, solvable=solvable)
end

#Alias
#TODO rather actually check if there are orphaned factors (factors without all variables)
"""
    $(SIGNATURES)
Checks if the graph is not fully connected, returns true if it is not contiguous.
"""
function hasOrphans(dfg::G)::Bool where G <: AbstractDFG
    return !isFullyConnected(dfg)
end

##==============================================================================
## Listing and listing aliases
##==============================================================================

##------------------------------------------------------------------------------
## Overwrite in driver for performance
##------------------------------------------------------------------------------
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

"""
    $(SIGNATURES)
Get a list of the IDs (labels) of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function listFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return map(f -> f.label, getFactors(dfg, regexFilter, tags=tags, solvable=solvable))
end

##------------------------------------------------------------------------------
## Aliases and Other filtered lists
##------------------------------------------------------------------------------


## Aliases
##--------
"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).

"""
function ls(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
end

#TODO tags kwarg
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function lsf(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return listFactors(dfg, regexFilter, tags=tags, solvable=solvable)
end


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
Alias for getNeighbors - returns neighbors around a given node label.
"""
function lsf(dfg::G, label::Symbol; solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
  return getNeighbors(dfg, label, solvable=solvable)
end

## list by types
##--------------

function ls(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: InferenceVariable}
  xx = getVariables(dfg)
  mask = getVariableType.(xx) .|> typeof .== T
  vxx = view(xx, mask)
  map(x->x.label, vxx)
end


function ls(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: FunctorInferenceType}
  xx = getFactors(dfg)
  names = getfield.(typeof.(getFactorType.(xx)), :name) .|> Symbol
  vxx = view(xx, names .== Symbol(T))
  map(x->x.label, vxx)
end


function lsf(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: FunctorInferenceType}
    ls(dfg, T)
end


"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.
"""
function lsfPriors(dfg::G)::Vector{Symbol} where G <: AbstractDFG
  priors = Symbol[]
  fcts = lsf(dfg)
  for fc in fcts
    if isPrior(dfg, fc)
      push!(priors, fc)
    end
  end
  return priors
end


#TODO is this repeated functionality?

"""
    $(SIGNATURES)
Gives back all factor labels that fit the bill:
    lsWho(dfg, :Pose3)

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsWho(dfg::AbstractDFG, type::Symbol)::Vector{Symbol}
    vars = getVariables(dfg)
    labels = Symbol[]
    for v in vars
        varType = typeof(getVariableType(v)).name |> Symbol
        varType == type && push!(labels, v.label)
    end
    return labels
end


"""
    $(SIGNATURES)
Gives back all factor labels that fit the bill:
    lsfWho(dfg, :Point2Point2)

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsfWho(dfg::AbstractDFG, type::Symbol)::Vector{Symbol}
    facs = getFactors(dfg)
    labels = Symbol[]
    for f in facs
        facType = typeof(getFactorType(f)).name |> Symbol
        facType == type && push!(labels, f.label)
    end
    return labels
end


## list types
##-----------
#TODO why a dictionary?
"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{String}}` of all unique variable types in factor graph.
"""
function lsTypes(dfg::G)::Dict{Symbol, Vector{String}} where G <: AbstractDFG
  alltypes = Dict{Symbol,Vector{String}}()
  for fc in ls(dfg)
    Tt = typeof(getVariableType(dfg, fc))
    sTt = string(Tt)
    name = Symbol(Tt.name)
    if !haskey(alltypes, name)
      alltypes[name] = String[string(Tt)]
    else
      if sum(alltypes[name] .== sTt) == 0
        push!(alltypes[name], sTt)
      end
    end
  end
  return alltypes
end


"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{String}}` of all unique factor types in factor graph.
"""
function lsfTypes(dfg::G)::Dict{Symbol, Vector{String}} where G <: AbstractDFG
  alltypes = Dict{Symbol,Vector{String}}()
  for fc in lsf(dfg)
    Tt = typeof(getFactorType(dfg, fc))
    sTt = string(Tt)
    name = Symbol(Tt.name)
    if !haskey(alltypes, name)
      alltypes[name] = String[string(Tt)]
    else
      if sum(alltypes[name] .== sTt) == 0
        push!(alltypes[name], sTt)
      end
    end
  end
  return alltypes
end



##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------
"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTags(dfg::AbstractDFG,
                 sym::Symbol,
                 tags::Vector{Symbol};
                 matchAll::Bool=true  )::Bool
  #
  alltags = listTags(dfg, sym)
  length(filter(x->x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end


"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTagsNeighbors(dfg::AbstractDFG,
                          sym::Symbol,
                          tags::Vector{Symbol};
                          matchAll::Bool=true  )::Bool
  #
  # assume only variables or factors are neighbors
  getNeiFnc = isVariable(dfg, sym) ? getFactor : getVariable
  alltags = union( (ls(dfg, sym) .|> x->getTags(getNeiFnc(dfg,x)))... )
  length(filter(x->x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

##==============================================================================
## Finding
##==============================================================================

"""
    $SIGNATURES

Find and return the closest timestamp from two sets of Tuples.  Also return the minimum delta-time (`::Millisecond`) and how many elements match from the two sets are separated by the minimum delta-time.
"""
function findClosestTimestamp(setA::Vector{Tuple{DateTime,T}},
                              setB::Vector{Tuple{DateTime,S}}) where {S,T}
  #
  # build matrix of delta times, ranges on rows x vars on columns
  DT = Array{Millisecond, 2}(undef, length(setA), length(setB))
  for i in 1:length(setA), j in 1:length(setB)
    DT[i,j] = setB[j][1] - setA[i][1]
  end

  DT .= abs.(DT)

  # absolute time differences
  # DTi = (x->x.value).(DT) .|> abs

  # find the smallest element
  mdt = minimum(DT)
  corrs = findall(x->x==mdt, DT)

  # return the closest timestamp, deltaT, number of correspondences
  return corrs[1].I, mdt, length(corrs)
end


"""
    $SIGNATURES

Find and return nearest variable labels per delta time.  Function will filter on `regexFilter`, `tags`, and `solvable`.

DevNotes:
- TODO `number` should allow returning more than one for k-nearest matches.
- Future versions likely will require some optimization around the internal `getVariable` call.
  - Perhaps a dedicated/efficient `getVariableTimestamp` for all DFG flavors.

Related

ls, listVariables, findClosestTimestamp
"""
function findVariableNearTimestamp(dfg::AbstractDFG,
                                   timest::DateTime,
                                   regexFilter::Union{Nothing, Regex}=nothing;
                                   tags::Vector{Symbol}=Symbol[],
                                   solvable::Int=0,
                                   warnDuplicate::Bool=true,
                                   number::Int=1  )::Vector{Tuple{Vector{Symbol}, Millisecond}}
  #
  # get the variable labels based on filters
  # syms = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
  syms = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
  # compile timestamps with label
  # vars = map( x->getVariable(dfg, x), syms )
  timeset = map(x->(getTimestamp(getVariable(dfg,x)), x), syms)
  mask = BitArray{1}(undef, length(syms))
  fill!(mask, true)

  RET = Vector{Tuple{Vector{Symbol},Millisecond}}()
  SYMS = Symbol[]
  CORRS = 1
  NUMBER = number
  while 0 < CORRS + NUMBER
    # get closest
    link, mdt, corrs = findClosestTimestamp([(timest,0)], timeset[mask])
    newsym = syms[link[2]]
    union!(SYMS, !isa(newsym, Vector) ? [newsym] : newsym)
    mask[link[2]] = false
    CORRS = corrs-1
    # last match, done with this delta time
    if corrs == 1
      NUMBER -=  1
      push!(RET, (deepcopy(SYMS),mdt))
      SYMS = Symbol[]
    end
  end
  # warn if duplicates found
  # warnDuplicate && 1 < corrs ? @warn("getVariableNearTimestamp found more than one variable at $timestamp") :   nothing

  return RET
end


##==============================================================================
## Subgraphs and Neighborhoods
##==============================================================================

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
    includeOrphanFactors && (@error "Adding orphaned factors is not supported")

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
                addFactor!(destDFG, deepcopy(factor))
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

##==============================================================================
## Variable Data: VND and PPE
##==============================================================================

#TODO API
"""
    $(SIGNATURES)
Merges and updates solver and estimate data for a variable (variable can be from another graph).
Note: Makes a copy of the estimates and solver data so that there is no coupling between graphs.
"""
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

#TODO API
"""
    $(SIGNATURES)
Common function to update all solver data and estimates from one graph to another.
This should be used to push local solve data back into a cloud graph, for example.
"""
function mergeGraphVariableData!(destDFG::H, sourceDFG::G, varSyms::Vector{Symbol})::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Update all variables in the destination
    # (For now... we may change this soon)
    for variableId in varSyms
        mergeVariableData!(destDFG, getVariable(sourceDFG, variableId))
    end
end


##==============================================================================
## Graphs Structures (Abstract, overwrite for performance)
##==============================================================================
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



# TODO API name get seems wrong maybe just biadjacencyMatrix
"""
    $(SIGNATURES)
Get a matrix indicating adjacency between variables and factors. Returned as
a named tuple: B::SparseMatrixCSC{Int}, varLabels::Vector{Symbol)
facLabels::Vector{Symbol). Rows are the factors, columns are the variables,
with the corresponding labels in varLabels,facLabels.
"""
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


##==============================================================================
## DOT Files, falls back to GraphsDFG
##==============================================================================
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

##==============================================================================
## Summaries
##==============================================================================

"""
    $(SIGNATURES)
Get a summary of the graph (first-class citizens of variables and factors).
Returns a DFGSummary.
"""
function getSummary(dfg::G)::DFGSummary where {G <: AbstractDFG}
    vars = map(v -> convert(DFGVariableSummary, v), getVariables(dfg))
    facts = map(f -> convert(DFGFactorSummary, f), getFactors(dfg))
    return DFGSummary(
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
        description="Summary of $(getDescription(dfg))",
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
