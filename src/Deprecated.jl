##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.8
##==============================================================================

#TODO alias or deprecate
@deprecate getVariableIds(dfg::AbstractDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) listVariables(dfg, regexFilter, tags=tags, solvable=solvable)

@deprecate getFactorIds(dfg, regexFilter=nothing; solvable=0) listFactors(dfg, regexFilter, solvable=solvable)

@deprecate listPPE(args...) listPPEs(args...)

export getLabelDict
getLabelDict(dfg::AbstractDFG) = error("getLabelDict is deprecated, consider using listing functions")

export getAdjacencyMatrix
"""
    $(SIGNATURES)
Get a matrix indicating relationships between variables and factors. Rows are
all factors, columns are all variables, and each cell contains either nothing or
the symbol of the relating factor. The first row and first column are factor and
variable headings respectively.
"""
function getAdjacencyMatrix(dfg::AbstractDFG; solvable::Int=0)::Matrix{Union{Nothing, Symbol}}
    error("Deprecated function, please use getBiadjacencyMatrix")
end

@deprecate getAdjacencyMatrixSparse(dfg::AbstractDFG; solvable::Int=0) getBiadjacencyMatrix(dfg, solvable=solvable)


Base.getproperty(x::DFGFactor,f::Symbol) = begin
  if f == :solvable
      getfield(x,:_dfgNodeParams).solvable
  elseif f == :_internalId
      getfield(x,:_dfgNodeParams)._internalId
  elseif f == :data
      Base.depwarn("DFGFactor get: data field is deprecated, use getSolverData", :getproperty)
      getfield(x, :solverData)
  else
      getfield(x,f)
  end
end

Base.setproperty!(x::DFGFactor,f::Symbol, val) = begin
    if f == :solvable
        setfield!(x,f,val)
        getfield(x,:_dfgNodeParams).solvable = val
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId = val
    elseif f == :data
        Base.depwarn("DFGFactor set: data field is deprecated, use getSolverData", :getproperty)
        setfield!(x,:solverData, val)
    else
        setfield!(x,f,val)
    end
  end

  Base.getproperty(x::DFGVariable,f::Symbol) = begin
      # if f == :estimateDict
      #     @warn "estimateDict is deprecated, use ppeDict instead"
          # getfield(x, :ppeDict)
      if f == :solvable
          getfield(x,:_dfgNodeParams).solvable
      elseif f == :_internalId
          getfield(x,:_dfgNodeParams)._internalId
      else
          getfield(x,f)
      end
    end

  Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
      # if f == :estimateDict
      #     error("estimateDict is deprecated, use ppeDict instead")
      if f == :solvable
          getfield(x,:_dfgNodeParams).solvable = val
      elseif f == :_internalId
          getfield(x,:_dfgNodeParams)._internalId = val
      else
          setfield!(x,f,val)
      end
    end


#NOTE deprecate in favor of constructors because its not lossless: https://docs.julialang.org/en/v1/manual/conversion-and-promotion/#Conversion-vs.-Construction-1
function Base.convert(::Type{DFGVariableSummary}, v::DFGVariable)
    Base.depwarn("convert to type DFGVariableSummary is deprecated use the constructor", :convert)
    return DFGVariableSummary(v)
end

function Base.convert(::Type{SkeletonDFGVariable}, v::VariableDataLevel1)
    Base.depwarn("convert to type SkeletonDFGVariable is deprecated use the constructor", :convert)
    return SkeletonDFGVariable(v)
end

function Base.convert(::Type{DFGFactorSummary}, f::DFGFactor)
    Base.depwarn("convert to type DFGFactorSummary is deprecated use the constructor", :convert)
    return DFGFactorSummary(f)
end

function Base.convert(::Type{SkeletonDFGFactor}, f::FactorDataLevel1)
    Base.depwarn("convert to type SkeletonDFGFactor is deprecated use the constructor", :convert)
    return SkeletonDFGFactor(f)
end


@deprecate hasOrphans(dfg) !isConnected(dfg)
@deprecate isFullyConnected(dfg) isConnected(dfg)

##==============================================================================
## WIP on consolidated subgraph functions, aim to remove in 0.8
##==============================================================================
# Deprecate in favor of buildSubgraph, mergeGraph
export getSubgraph, getSubgraphAroundNode
export buildSubgraphFromLabels!

"""
    $(SIGNATURES)
Common function for copying nodes from one graph into another graph.
This is overridden in specialized implementations for performance.
NOTE: copyGraphMetadata not supported yet.
"""
function _copyIntoGraph!(sourceDFG::G, destDFG::H, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false; copyGraphMetadata::Bool=false)::Nothing where {G <: AbstractDFG, H <: AbstractDFG}
    # Split into variables and factors
    Base.depwarn("_copyIntoGraph! is deprecated use copyGraph/deepcopyGraph[!]", :_copyIntoGraph!)

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

"""
    $(SIGNATURES)
Retrieve a deep subgraph copy around a given variable or factor.
Optionally provide a distance to specify the number of edges should be followed.
Optionally provide an existing subgraph addToDFG, the extracted nodes will be copied into this graph. By default a new subgraph will be created.
Note: By default orphaned factors (where the subgraph does not contain all the related variables) are not returned. Set includeOrphanFactors to return the orphans irrespective of whether the subgraph contains all the variables.
Note: Always returns the node at the center, but filters around it if solvable is set.
"""
function getSubgraphAroundNode(dfg::AbstractDFG, node::DFGNode, distance::Int=1, includeOrphanFactors::Bool=false, addToDFG::AbstractDFG=_getDuplicatedEmptyDFG(dfg); solvable::Int=0)::AbstractDFG

    Base.depwarn("getSubgraphAroundNode is deprecated use buildSubgraph", :getSubgraphAroundNode)

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

    Base.depwarn("getSubgraph is deprecated use buildSubgraph", :getSubgraph)

    for label in variableFactorLabels
        if !exists(dfg, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end


# TODO needsahome: home should be in IIF, calling just deepcopyGraph, or copyGraph
#                  Into, Labels, Subgraph are all implied from the parameters.
#                  can alies names but like Sam suggested only on copy is needed.


"""
    $SIGNATURES
Construct a new factor graph object as a subgraph of `dfg <: AbstractDFG` based on the
variable labels `syms::Vector{Symbols}`.

SamC: Can we not just use _copyIntoGraph! for this? Looks like a small refactor to make it work.
Will paste in as-is for now and we can figure it out as we go.
  DF: Absolutely agree that subgraph functions should use `DFG._copyIntoGraph!` as a single dependency in the code base.  There have been a repeated new rewrites of IIF.buildSubGraphFromLabels (basic wrapper is fine) but nominal should be to NOT duplicate DFG functionality in IIF -- rather use/improve the existing features in DFG. FYI, I have repeatedly refactored this function over and over to use DFG properly but somehow this (add/delete/Variable/Factor) version keeps coming back without using `_copyIntoGraph`!!???  See latest effort commented out below `buildSubgraphFromLabels!_SPECIAL`...

Notes
- Slighly messy internals, but gets the job done -- some room for performance improvement.
- Defaults to GraphDFG, but likely to change to LightDFG in future.
  - since DFG v0.6 LightDFG is the default.

DevNotes
- TODO: still needs to be consolidated with `DFG._copyIntoGraph`

Related

listVariables, _copyIntoGraph!
"""
function buildSubgraphFromLabels!(dfg::G,
                                  syms::Vector{Symbol};
                                  subfg::AbstractDFG=(G <: InMemoryDFGTypes ? G : GraphsDFG)(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )::AbstractDFG where G <: AbstractDFG
  #
  Base.depwarn("buildSubgraphFromLabels! is deprecated use copyGraph, buildSubgraph or buildCliqueSubgraph!(IIF)", :buildSubgraphFromLabels!)
  # add a little too many variables (since we need the factors)
  for sym in syms
    if solvable <= getSolvable(dfg, sym)
      getSubgraphAroundNode(dfg, getVariable(dfg, sym), 2, false, subfg, solvable=solvable)
    end
  end

  # remove excessive variables that were copied by neighbors distance 2
  currVars = listVariables(subfg)
  toDelVars = setdiff(currVars, syms)
  for dv in toDelVars
    # delete any neighboring factors first
    for fc in lsf(subfg, dv)
      deleteFactor!(subfg, fc)
    end

    # and the variable itself
    deleteVariable!(subfg, dv)
  end

  # delete any factors not in the allowed list
  if allowedFactors != nothing
    delFcts = setdiff(lsf(subfg), allowedFactors)
    for dfct in delFcts
      deleteFactor!(subfg, dfct)
    end
  end

  # orphaned variables are allowed, but not orphaned factors

  return subfg
end
