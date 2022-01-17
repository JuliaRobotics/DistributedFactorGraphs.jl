##==============================================================================
## AbstractDFG
##==============================================================================
##------------------------------------------------------------------------------
## Broadcasting
##------------------------------------------------------------------------------
# to allow stuff like `getFactorType.(dfg, [:x1x2f1;:x10l3f2])`
# https://docs.julialang.org/en/v1/manual/interfaces/#
Base.Broadcast.broadcastable(dfg::AbstractDFG) = Ref(dfg)

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
# - `blobStores::Dict{Symbol, AbstractBlobStore}`
# AbstractDFG Accessors

##------------------------------------------------------------------------------
## Getters
##------------------------------------------------------------------------------
"""
    $(SIGNATURES)
Convenience function to get all the metadata of a DFG
"""
getDFGInfo(dfg::AbstractDFG) = (getDescription(dfg), getUserId(dfg), getRobotId(dfg), getSessionId(dfg), getUserData(dfg), getRobotData(dfg), getSessionData(dfg), getSolverParams(dfg))

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

"""
    $(SIGNATURES)

Method must be overloaded by the user for Serialization to work.  E.g. IncrementalInference uses `CommonConvWrapper <: FactorOperationalMemory`.
"""
getFactorOperationalMemoryType(dummy) = error("Please extend your workspace with function getFactorOperationalMemoryType(<:AbstractParams) for your usecase, e.g. IncrementalInference uses `CommonConvWrapper <: FactorOperationalMemory`")
getFactorOperationalMemoryType(dfg::AbstractDFG) = getFactorOperationalMemoryType(getSolverParams(dfg))

"""
    $(SIGNATURES)

Method must be overloaded by the user for Serialization to work.
"""
rebuildFactorMetadata!(dfg::AbstractDFG{<:AbstractParams}, factor::AbstractDFGFactor, neighbors=[]) = error("rebuildFactorMetadata! is not implemented for $(typeof(dfg))")

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
getUserData(dfg::AbstractDFG) = return dfg.userData

"""
$SIGNATURES

Set the user data associated with the graph.
"""
function setUserData!(dfg::AbstractDFG, data::Dict{Symbol, String})
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
function setRobotData!(dfg::AbstractDFG, data::Dict{Symbol, String})
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
function setSessionData!(dfg::AbstractDFG, data::Dict{Symbol, String})
    dfg.sessionData = data
    return dfg.sessionData
end

##==============================================================================
## User/Robot/Session Data CRUD
##==============================================================================

#NOTE with API standardization this should become something like:
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
## AbstractBlobStore  CRUD
##==============================================================================
abstract type AbstractBlobStore{T} end
# AbstractBlobStore should have key or overwrite getKey
getKey(store::AbstractBlobStore) = store.key

getBlobStore(dfg::AbstractDFG, key::Symbol) = dfg.blobStores[key]
addBlobStore!(dfg::AbstractDFG, bs::AbstractBlobStore) = push!(dfg.blobStores, getKey(bs)=>bs)
updateBlobStore!(dfg::AbstractDFG, bs::AbstractBlobStore) = push!(dfg.blobStores, getKey(bs)=>bs)
deleteBlobStore!(dfg::AbstractDFG, key::Symbol) = pop!(dfg.blobStores, key)
emptyBlobStore!(dfg::AbstractDFG) = empty!(dfg.blobStores)
listBlobStores(dfg::AbstractDFG) = collect(keys(dfg.blobStores))

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
function exists(dfg::AbstractDFG, node::DFGNode)
    error("exists not implemented for $(typeof(dfg))")
end

function exists(dfg::AbstractDFG, label::Symbol)
    error("exists not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Add a DFGVariable to a DFG.
"""
function addVariable!(dfg::G, variable::V) where {G <: AbstractDFG, V <: AbstractDFGVariable}
    error("addVariable! not implemented for $(typeof(dfg))")
end

"""
Add a DFGFactor to a DFG.
    $(SIGNATURES)
"""
function addFactor!(dfg::AbstractDFG, factor::F) where F <: AbstractDFGFactor
    error("addFactor! not implemented for $(typeof(dfg))(dfg, factor)")
end

"""
    $(SIGNATURES)
Get a DFGVariable from a DFG using its label.
"""
function getVariable(dfg::G, label::Union{Symbol, String}) where G <: AbstractDFG
    error("getVariable not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Get a DFGFactor from a DFG using its label.
"""
function getFactor(dfg::G, label::Union{Symbol, String}) where G <: AbstractDFG
    error("getFactor not implemented for $(typeof(dfg))")
end

function Base.getindex(dfg::AbstractDFG, lbl::Union{Symbol, String})
    if isVariable(dfg, lbl)
        getVariable(dfg, lbl)
    elseif isFactor(dfg, lbl)
        getFactor(dfg, lbl)
    else
        error("Cannot find $lbl in this $(typeof(dfg))")
    end
end

"""
    $(SIGNATURES)
Update a complete DFGVariable in the DFG.
"""
function updateVariable!(dfg::G, variable::V) where {G <: AbstractDFG, V <: AbstractDFGVariable}
    error("updateVariable! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Update a complete DFGFactor in the DFG.
"""
function updateFactor!(dfg::G, factor::F) where {G <: AbstractDFG, F <: AbstractDFGFactor}
    error("updateFactor! not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Delete a DFGVariable from the DFG using its label.
"""
function deleteVariable!(dfg::AbstractDFG, label::Symbol)
    error("deleteVariable! not implemented for $(typeof(dfg))")
end
"""
    $(SIGNATURES)
Delete a DFGFactor from the DFG using its label.
"""
function deleteFactor!(dfg::G, label::Symbol; suppressGetFactor::Bool=false) where G <: AbstractDFG
    error("deleteFactors not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
List the DFGVariables in the DFG.
Optionally specify a label regular expression to retrieves a subset of the variables.
Tags is a list of any tags that a node must have (at least one match).
"""
function getVariables(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) where G <: AbstractDFG
    error("getVariables not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function getFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) where G <: AbstractDFG
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
function isConnected(dfg::AbstractDFG)
    error("isConnected not implemented for $(typeof(dfg))")
end

"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor specified by its label.
"""
function getNeighbors(dfg::AbstractDFG, label::Symbol; solvable::Int=0)
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
function _getDuplicatedEmptyDFG(dfg::G) where G <: AbstractDFG
    error("_getDuplicatedEmptyDFG not implemented for $(typeof(dfg))")
end


##------------------------------------------------------------------------------
## CRUD Aliases
##------------------------------------------------------------------------------

"""
    $(SIGNATURES)
Get a DFGVariable with a specific solver key.
In memory types still return a reference, other types returns a variable with only solveKey.
"""
function getVariable(dfg::AbstractDFG, label::Symbol, solveKey::Symbol)

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
function addFactor!(dfg::AbstractDFG, variables::Vector{<:AbstractDFGVariable}, factor::F) where  F <: AbstractDFGFactor

    Base.depwarn("addFactor!(dfg, variables, factor) is deprecated, use addFactor!(dfg, factor)", :addFactor!)
    variableLabels = map(v->v.label, variables)

    if factor isa DFGFactor
        f = factor
        newfactor =  DFGFactor(f.label, f.timestamp, f.nstime, f.tags, f.solverData, f.solvable, Tuple(variableLabels))
        return addFactor!(dfg, newfactor)
    else
        resize!(factor._variableOrderSymbols, length(variableLabels))
        factor._variableOrderSymbols .= variableLabels
        return addFactor!(dfg, factor)
    end

end

"""
$(SIGNATURES)
"""
function addFactor!(dfg::AbstractDFG, variableLabels::Vector{Symbol}, factor::F) where F <: AbstractDFGFactor

    Base.depwarn("addFactor!(dfg, variables, factor) is deprecated, use addFactor!(dfg, factor)", :addFactor!)

    if factor isa DFGFactor
        f = factor
        newfactor =  DFGFactor(f.label, f.timestamp, f.nstime, f.tags, f.solverData, f.solvable, Tuple(variableLabels))
        return addFactor!(dfg, newfactor)
    else
        resize!(factor._variableOrderSymbols, length(variableLabels))
        factor._variableOrderSymbols .= variableLabels
        return addFactor!(dfg, factor)
    end

end


"""
    $(SIGNATURES)
Delete a referenced DFGVariable from the DFG.

Notes
- Returns `Tuple{AbstractDFGVariable, Vector{<:AbstractDFGFactor}}`
"""
function deleteVariable!(dfg::AbstractDFG, variable::AbstractDFGVariable)
    return deleteVariable!(dfg, variable.label)
end

"""
    $(SIGNATURES)
Delete the referened DFGFactor from the DFG.
"""
function deleteFactor!(dfg::G, factor::F; suppressGetFactor::Bool=false) where {G <: AbstractDFG, F <: AbstractDFGFactor}
    return deleteFactor!(dfg, factor.label, suppressGetFactor=suppressGetFactor)
end

# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isVariable(dfg::G, node::N) where {G <: AbstractDFG, N <: DFGNode}
    return isVariable(dfg, node.label)
end
# Alias - bit ridiculous but know it'll come up at some point. Does existential and type check.
function isFactor(dfg::G, node::N) where {G <: AbstractDFG, N <: DFGNode}
    return isFactor(dfg, node.label)
end

##------------------------------------------------------------------------------
## Connectivity Alias
##------------------------------------------------------------------------------

function getNeighbors(dfg::AbstractDFG, node::DFGNode; solvable::Int=0)
    getNeighbors(dfg, node.label, solvable=solvable)
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

NOtes
- Returns `::Vector{Symbol}`

Example
```julia
listVariables(dfg, r"l", tags=[:APRILTAG;])
```

Related:
- ls
"""
function listVariables( dfg::AbstractDFG, 
                        regexFilter::Union{Nothing, Regex}=nothing; 
                        tags::Vector{Symbol}=Symbol[], 
                        solvable::Int=0 )
    #
    vars = getVariables(dfg, regexFilter, tags=tags, solvable=solvable)
    return map(v -> v.label, vars)::Vector{Symbol}
end

# to be consolidated, see #612
function listVariables( dfg::AbstractDFG, 
                        typeFilter::Type{<:InferenceVariable}; 
                        tags::Vector{Symbol}=Symbol[], 
                        solvable::Int=0 )
    #
    retlist::Vector{Symbol} = ls(dfg, typeFilter)
    0 < length(tags) || solvable != 0 ? intersect(retlist, ls(dfg, tags=tags, solvable=solvable)) : retlist
end

"""
    $(SIGNATURES)
Get a list of the IDs (labels) of the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.
"""
function listFactors(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol} where G <: AbstractDFG
    return map(f -> f.label, getFactors(dfg, regexFilter, tags=tags, solvable=solvable))
end

"""
    $TYPEDSIGNATURES
List all the solvekeys used amongst all variables in the distributed factor graph object.

Related

[`listSupersolves`](@ref), [`getSolverDataDict`](@ref), [`listVariables`](@ref)
"""
function listSolveKeys( variable::DFGVariable,
                        filterSolveKeys::Union{Regex,Nothing}=nothing,
                        skeys = Set{Symbol}() )
    #
    for ky in keys(getSolverDataDict(variable))
        push!(skeys, ky)
    end

    #filter the solveKey set with filterSolveKeys regex
    !isnothing(filterSolveKeys) && return filter!(k -> occursin(filterSolveKeys, string(k)), skeys)
    return skeys
end

listSolveKeys(  dfg::AbstractDFG, lbl::Symbol,
                filterSolveKeys::Union{Regex,Nothing}=nothing,
                skeys = Set{Symbol}() ) = listSolveKeys(getVariable(dfg, lbl), filterSolveKeys, skeys)
#

function listSolveKeys( dfg::AbstractDFG, 
                        filterVariables::Union{Type{<:InferenceVariable},Regex, Nothing}=nothing;
                        filterSolveKeys::Union{Regex,Nothing}=nothing,
                        tags::Vector{Symbol}=Symbol[], 
                        solvable::Int=0  )
    #
    skeys = Set{Symbol}()
    varList = listVariables(dfg, filterVariables, tags=tags, solvable=solvable)
    for vs in varList  #, ky in keys(getSolverDataDict(getVariable(dfg, vs)))
        listSolveKeys(dfg, vs, filterSolveKeys, skeys)
    end

    # done inside the loop
    # #filter the solveKey set with filterSolveKeys regex
    # !isnothing(filterSolveKeys) && return filter!(k -> occursin(filterSolveKeys, string(k)), skeys)

    return skeys
end
const listSupersolves = listSolveKeys


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

Notes:
- Returns `Vector{Symbol}`
"""
function ls(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) where G <: AbstractDFG
    return listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
end

#TODO tags kwarg
"""
    $(SIGNATURES)
List the DFGFactors in the DFG.
Optionally specify a label regular expression to retrieves a subset of the factors.

Notes
- Return `Vector{Symbol}`
"""
function lsf(dfg::G, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) where G <: AbstractDFG
    return listFactors(dfg, regexFilter, tags=tags, solvable=solvable)
end


"""
    $(SIGNATURES)
Retrieve a list of labels of the immediate neighbors around a given variable or factor.
"""
function ls(dfg::G, node::T; solvable::Int=0) where {G <: AbstractDFG, T <: DFGNode}
    return getNeighbors(dfg, node, solvable=solvable)
end
function ls(dfg::G, label::Symbol; solvable::Int=0) where G <: AbstractDFG
    return getNeighbors(dfg, label, solvable=solvable)
end

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


function ls(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: AbstractFactor}
  xx = getFactors(dfg)
  names = typeof.(getFactorType.(xx)) .|> nameof
  vxx = view(xx, names .== Symbol(T))
  map(x->x.label, vxx)
end


function lsf(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: AbstractFactor}
    ls(dfg, T)
end

"""
    $(SIGNATURES)
Helper to return neighbors at distance 2 around a given node label.
"""
function ls2(dfg::AbstractDFG, label::Symbol)
    l2 = getNeighborhood(dfg, label, 2)
    l1 = getNeighborhood(dfg, label, 1)
    return setdiff(l2, l1)
end

"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.

Notes:
- Returns `Vector{Symbol}`
"""
function lsfPriors(dfg::G) where G <: AbstractDFG
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

Notes
- Returns `Vector{Symbol}`

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsWho(dfg::AbstractDFG, type::Symbol)
    vars = getVariables(dfg)
    labels = Symbol[]
    for v in vars
        varType = typeof(getVariableType(v)) |> nameof
        varType == type && push!(labels, v.label)
    end
    return labels
end


"""
    $(SIGNATURES)
Gives back all factor labels that fit the bill:
    lsfWho(dfg, :Point2Point2)

Notes
- Returns `Vector{Symbol}`

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsfWho(dfg::AbstractDFG, type::Symbol)
    facs = getFactors(dfg)
    labels = Symbol[]
    for f in facs
        facType = typeof(getFactorType(f)) |> nameof
        facType == type && push!(labels, f.label)
    end
    return labels
end


## list types
##-----------

"""
    $SIGNATURES

Return `Vector{Symbol}` of all unique variable types in factor graph.
"""
function lsTypes(dfg::AbstractDFG)
    vars = getVariables(dfg)
    alltypes = Set{Symbol}()
    for v in vars
        varType = typeof(getVariableType(v)) |> nameof
        push!(alltypes, varType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{Symbol}}` of all unique variable types with labels in a factor graph.
"""
function lsTypesDict(dfg::AbstractDFG)

    vars = getVariables(dfg)
    alltypes = Dict{Symbol,Vector{Symbol}}()
    for v in vars
        varType = typeof(getVariableType(v)) |> nameof
        d = get!(alltypes, varType, Symbol[])
        push!(d, v.label)
    end
  return alltypes
end

"""
    $SIGNATURES

Return `Vector{Symbol}` of all unique factor types in factor graph.
"""
function lsfTypes(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Set{Symbol}()
    for f in facs
        facType = typeof(getFactorType(f)) |> nameof
        push!(alltypes, facType)
    end
    return collect(alltypes)
end

"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{Symbol}}` of all unique factors types with labels in a factor graph.
"""
function lsfTypesDict(dfg::AbstractDFG)
    facs = getFactors(dfg)
    alltypes = Dict{Symbol,Vector{Symbol}}()
    for f in facs
        facType = typeof(getFactorType(f)) |> nameof
        d = get!(alltypes, facType, Symbol[])
        push!(d, f.label)
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
                 matchAll::Bool=true  )
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
                          matchAll::Bool=true  )
  #
  # assume only variables or factors are neighbors
  getNeiFnc = isVariable(dfg, sym) ? getFactor : getVariable
  alltags = union( (ls(dfg, sym) .|> x->getTags(getNeiFnc(dfg,x)))... )
  length(filter(x->x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end

##==============================================================================
## Finding
##==============================================================================
# function findClosestTimestamp(setA::Vector{Tuple{DateTime,T}},
                              # setB::Vector{Tuple{DateTime,S}}) where {S,T}
"""
    $SIGNATURES

Find and return the closest timestamp from two sets of Tuples.  Also return the minimum delta-time (`::Millisecond`) and how many elements match from the two sets are separated by the minimum delta-time.
"""
function findClosestTimestamp(setA::Vector{Tuple{ZonedDateTime,T}},
                              setB::Vector{Tuple{ZonedDateTime,S}}) where {S,T}
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

Notes
- Returns `Vector{Tuple{Vector{Symbol}, Millisecond}}`

DevNotes:
- TODO `number` should allow returning more than one for k-nearest matches.
- Future versions likely will require some optimization around the internal `getVariable` call.
  - Perhaps a dedicated/efficient `getVariableTimestamp` for all DFG flavors.

Related

ls, listVariables, findClosestTimestamp
"""
function findVariableNearTimestamp(dfg::AbstractDFG,
                                   timest::ZonedDateTime,
                                   regexFilter::Union{Nothing, Regex}=nothing;
                                   tags::Vector{Symbol}=Symbol[],
                                   solvable::Int=0,
                                   warnDuplicate::Bool=true,
                                   number::Int=1  )
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

findVariableNearTimestamp(dfg::AbstractDFG, timest::DateTime, regexFilter::Union{Nothing, Regex}=nothing;
                          timezone=localzone(), kwargs...) =
    findVariableNearTimestamp(dfg, ZonedDateTime(timest, timezone), regexFilter; kwargs...)

##==============================================================================
## Copy Functions
##==============================================================================

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
Orphaned factors are not added, with a warning if verbose.
Set `overwriteDest` to overwrite existing variables and factors in the destination DFG.
NOTE: copyGraphMetadata not supported yet.
Related:
- [`deepcopyGraph`](@ref)
- [`deepcopyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`getNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
function copyGraph!(destDFG::AbstractDFG,
                    sourceDFG::AbstractDFG,
                    variableLabels::Vector{Symbol},
                    factorLabels::Vector{Symbol};
                    copyGraphMetadata::Bool=false,
                    overwriteDest::Bool=false,
                    deepcopyNodes::Bool=false,
                    verbose::Bool = true)
    # Split into variables and factors
    sourceVariables = map(vId->getVariable(sourceDFG, vId), variableLabels)
    sourceFactors = map(fId->getFactor(sourceDFG, fId), factorLabels)

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
        elseif verbose
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

"""
    $(SIGNATURES)
Copy nodes from one graph into another graph by making deepcopies.
see [`copyGraph!`](@ref) for more detail.
Related:
- [`deepcopyGraph`](@ref)
- [`buildSubgraph`](@ref)
- [`getNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
function deepcopyGraph!(destDFG::AbstractDFG,
                        sourceDFG::AbstractDFG,
                        variableLabels::Vector{Symbol} = ls(sourceDFG),
                        factorLabels::Vector{Symbol} = lsf(sourceDFG);
                        kwargs...)
    copyGraph!(destDFG, sourceDFG, variableLabels, factorLabels; deepcopyNodes=true, kwargs...)
end

"""
    $(SIGNATURES)
Copy nodes from one graph into a new graph by making deepcopies.
see [`copyGraph!`](@ref) for more detail.
Related:
- [`deepcopyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`getNeighborhood`](@ref)
- [`mergeGraph!`](@ref)
"""
function deepcopyGraph( ::Type{T},
                        sourceDFG::AbstractDFG,
                        variableLabels::Vector{Symbol} = ls(sourceDFG),
                        factorLabels::Vector{Symbol} = lsf(sourceDFG);
                        sessionId::String = "",
                        kwargs...) where T <: AbstractDFG

    ginfo = [getDFGInfo(sourceDFG)...]
    if sessionId == ""
        ginfo[4] *= "_copy$(string(uuid4())[1:6])"
    else
        ginfo[4] = sessionId
    end
    destDFG = T(ginfo...)
    copyGraph!(destDFG, sourceDFG, variableLabels, factorLabels; deepcopyNodes=true, kwargs...)
    return destDFG
end



##==============================================================================
## Automated Graph Searching
##==============================================================================


function findShortestPathDijkstra end

"""
    $SIGNATURES

Relatively naive function counting linearly from-to

DevNotes
- Convert to using LightGraphs shortest path methods instead.
"""
function findFactorsBetweenNaive(   dfg::AbstractDFG, 
                                    from::Symbol,
                                    to::Symbol, 
                                    assertSingles::Bool=false)
  #
  @info "findFactorsBetweenNaive is naive linear number method -- improvements welcome"
  SRT = getVariableLabelNumber(from)
  STP = getVariableLabelNumber(to)
  prefix = string(from)[1]
  @assert prefix == string(to)[1] "from-to prefixes must match, one is $prefix, other $(string(to)[1])"
  prev = from
  fctlist = Symbol[]
  for num in (SRT+1):STP
    next = Symbol(prefix,num)
    fct = intersect(ls(dfg, prev),ls(dfg,next))
    !assertSingles ? nothing : @assert length(fct) == 1 "assertSingles=true, won't return multiple factors joining variables at this time"
    union!(fctlist, fct)
    prev = next
  end

  return fctlist
end

"""
    $SIGNATURES
Return (::Bool,::Vector{TypeName}) of types between two nodes in the factor graph 

DevNotes
- Only works on LigthDFG at the moment.

Related

[`LightDFG.findShortestPathDijkstra`](@ref)
"""
function isPathFactorsHomogeneous(dfg::AbstractDFG, from::Symbol, to::Symbol)
    # FIXME, must consider all paths, not just shortest...
    pth = intersect(findShortestPathDijkstra(dfg, from, to), lsf(dfg))
    types = getFactorType.(dfg, pth) .|> typeof .|> x->(x).name #TODO this might not be correct in julia 1.6
    utyp = unique(types)
    (length(utyp) == 1), utyp
end

function existsPathOfFactorsType(dfg::AbstractDFG, from::Symbol, to::Symbol, ftype::AbstractFactor)
  error("WIP")
end

##==============================================================================
## Subgraphs and Neighborhoods
##==============================================================================

"""
    $(SIGNATURES)
Build a list of all unique neighbors inside 'distance'

Notes
- Returns `Vector{Symbol}`

Related:
- [`copyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`deepcopyGraph`](@ref)
- [`mergeGraph!`](@ref)
"""
function getNeighborhood(dfg::AbstractDFG, label::Symbol, distance::Int)
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

function getNeighborhood(dfg::AbstractDFG, variableFactorLabels::Vector{Symbol}, distance::Int; solvable::Int=0)
    # find neighbors at distance to add
    neighbors = Symbol[]
    if distance > 0
        for l in variableFactorLabels
            union!(neighbors, getNeighborhood(dfg, l, distance))
        end
    end

    allvarfacs = union(variableFactorLabels, neighbors)

    solvable != 0 && filter!(nlbl -> (getSolvable(dfg, nlbl) >= solvable), allvarfacs)

    return allvarfacs

end

"""
    $(SIGNATURES)
Build a deep subgraph copy from the DFG given a list of variables and factors and an optional distance.
Note: Orphaned factors (where the subgraph does not contain all the related variables) are not returned.
Related:
- [`copyGraph!`](@ref)
- [`getNeighborhood`](@ref)
- [`deepcopyGraph`](@ref)
- [`mergeGraph!`](@ref)
Dev Notes
- Bulk vs node for node: a list of labels are compiled and the sugraph is copied in bulk.
"""
function buildSubgraph(::Type{G},
                       dfg::AbstractDFG,
                       variableFactorLabels::Vector{Symbol},
                       distance::Int=0;
                       solvable::Int=0,
                       sessionId::String = "",
                       kwargs...) where G <: AbstractDFG

    if sessionId == ""
        sessionId = getSessionId(dfg) * "_sub_$(string(uuid4())[1:6])"
    end

    #build up the neighborhood from variableFactorLabels
    allvarfacs = getNeighborhood(dfg, variableFactorLabels, distance; solvable=solvable)

    variableLabels = intersect(listVariables(dfg), allvarfacs)
    factorLabels = intersect(listFactors(dfg), allvarfacs)
    # Copy the section of graph we want
    destDFG = deepcopyGraph(G, dfg, variableLabels, factorLabels; sessionId=sessionId, kwargs...)
    return destDFG
end

function buildSubgraph(dfg::AbstractDFG,
                       variableFactorLabels::Vector{Symbol},
                       distance::Int=0;
                       kwargs...)
    return buildSubgraph(LocalDFG, dfg, variableFactorLabels, distance; kwargs...)
end

"""
    $(SIGNATURES)
Merger sourceDFG to destDFG given an optional list of variables and factors and distance.
Notes:
- Nodes already in the destination graph are updated from sourceDFG.
- Orphaned factors (where the subgraph does not contain all the related variables) are not included.
Related:
- [`copyGraph!`](@ref)
- [`buildSubgraph`](@ref)
- [`getNeighborhood`](@ref)
- [`deepcopyGraph`](@ref)
"""
function mergeGraph!(destDFG::AbstractDFG,
                     sourceDFG::AbstractDFG,
                     variableLabels::Vector{Symbol} = ls(sourceDFG),
                     factorLabels::Vector{Symbol} = lsf(sourceDFG),
                     distance::Int = 0;
                     solvable::Int = 0,
                     kwargs...)

    # find neighbors at distance to add
    allvarfacs = getNeighborhood(sourceDFG, union(variableLabels, factorLabels), distance; solvable=solvable)

    sourceVariables = intersect(listVariables(sourceDFG), allvarfacs)
    sourceFactors = intersect(listFactors(sourceDFG), allvarfacs)

    copyGraph!(destDFG, sourceDFG, sourceVariables, sourceFactors; deepcopyNodes=true, overwriteDest=true, kwargs...)

    return destDFG
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
function mergeVariableData!(dfg::AbstractDFG, sourceVariable::AbstractDFGVariable)

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

Notes
- Returns `::Nothing`
"""
function mergeGraphVariableData!(destDFG::H, sourceDFG::G, varSyms::Vector{Symbol}) where {G <: AbstractDFG, H <: AbstractDFG}
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
Note:
- rather use getBiadjacencyMatrix
- Returns either of `::Matrix{Union{Nothing, Symbol}}`
"""
function getAdjacencyMatrixSymbols(dfg::AbstractDFG; solvable::Int=0)
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

Notes
-  Returns `::NamedTuple{(:B, :varLabels, :facLabels), Tuple{SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}}`
"""
function getBiadjacencyMatrix(dfg::AbstractDFG; solvable::Int=0)
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
## DOT Files, falls back to LightDFG dot functions
##==============================================================================
"""
    $(SIGNATURES)
Produces a dot-format of the graph for visualization.

Notes
- Returns `::String`
"""
function toDot(dfg::AbstractDFG)
    #convert to LightDFG
    ldfg = LightDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg))
    return toDot(ldfg)
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
function toDotFile(dfg::AbstractDFG, fileName::String="/tmp/dfg.dot")

    #convert to LightDFG
    ldfg = LightDFG{NoSolverParams}()
    copyGraph!(ldfg, dfg, listVariables(dfg), listFactors(dfg))

    return toDotFile(ldfg, fileName)
end

##==============================================================================
## Summaries
##==============================================================================

"""
    $(SIGNATURES)
Get a summary of the graph (first-class citizens of variables and factors).
Returns a DFGSummary.

Notes
- Returns `::DFGSummary`
"""
function getSummary(dfg::G) where {G <: AbstractDFG}
    vars = map(v -> DFGVariableSummary(v), getVariables(dfg))
    facts = map(f -> DFGFactorSummary(f), getFactors(dfg))
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

Notes
- this is a copy of the original.
- Returns `::LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}`
"""
function getSummaryGraph(dfg::G) where {G <: AbstractDFG}
    summaryDfg = LightDFG{NoSolverParams, DFGVariableSummary, DFGFactorSummary}(
        description="Summary of $(getDescription(dfg))",
        userId=dfg.userId,
        robotId=dfg.robotId,
        sessionId=dfg.sessionId)
    deepcopyGraph!(summaryDfg, dfg)
    # for v in getVariables(dfg)
    #     newV = addVariable!(summaryDfg, DFGVariableSummary(v))
    # end
    # for f in getFactors(dfg)
    #     addFactor!(summaryDfg, getNeighbors(dfg, f), DFGFactorSummary(f))
    # end
    return summaryDfg
end
