##==============================================================================
## Abstract Types
##==============================================================================

abstract type InferenceVariable end

##==============================================================================
## VariableNodeData
##==============================================================================

"""
$(TYPEDEF)
Data container for solver-specific data.

  ---
Fields:
$(TYPEDFIELDS)
"""
mutable struct VariableNodeData{T<:InferenceVariable}
    val::Array{Float64,2}
    bw::Array{Float64,2}
    BayesNetOutVertIDs::Array{Symbol,1}
    dimIDs::Array{Int,1} # Likely deprecate
    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol #  Union{Nothing, }
    separator::Array{Symbol,1}
    softtype::T
    initialized::Bool
    inferdim::Float64
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    VariableNodeData{T}() where {T <:InferenceVariable} =
    new{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], T(), false, 0.0, false, false, 0, 0)
    VariableNodeData{T}(val::Array{Float64,2},
                        bw::Array{Float64,2},
                        BayesNetOutVertIDs::Array{Symbol,1},
                        dimIDs::Array{Int,1},
                        dims::Int,eliminated::Bool,
                        BayesNetVertID::Symbol,
                        separator::Array{Symbol,1},
                        softtype::T,
                        initialized::Bool,
                        inferdim::Float64,
                        ismargin::Bool,
                        dontmargin::Bool,
                        solveInProgress::Int=0,
                        solvedCount::Int=0) where T <: InferenceVariable =
                            new{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                   eliminated,BayesNetVertID,separator,
                                   softtype::T,initialized,inferdim,ismargin,
                                   dontmargin, solveInProgress, solvedCount)
end

##------------------------------------------------------------------------------
## Constructors

VariableNodeData(val::Array{Float64,2},
                 bw::Array{Float64,2},
                 BayesNetOutVertIDs::Array{Symbol,1},
                 dimIDs::Array{Int,1},
                 dims::Int,eliminated::Bool,
                 BayesNetVertID::Symbol,
                 separator::Array{Symbol,1},
                 softtype::T,
                 initialized::Bool,
                 inferdim::Float64,
                 ismargin::Bool,
                 dontmargin::Bool,
                 solveInProgress::Int=0,
                 solvedCount::Int=0) where T <: InferenceVariable =
                   VariableNodeData{T}(val,bw,BayesNetOutVertIDs,dimIDs,dims,
                                       eliminated,BayesNetVertID,separator,
                                       softtype::T,initialized,inferdim,ismargin,
                                       dontmargin, solveInProgress, solvedCount)


VariableNodeData(softtype::T) where T <: InferenceVariable =
    VariableNodeData{T}(zeros(1,1), zeros(1,1), Symbol[], Int[], 0, false, :NOTHING, Symbol[], softtype, false, 0.0, false, false, 0, 0)

##==============================================================================
## PackedVariableNodeData.jl
##==============================================================================

"""
$(TYPEDEF)
Packed VariabeNodeData structure for serializing DFGVariables.

  ---
Fields:
$(TYPEDFIELDS)
"""
mutable struct PackedVariableNodeData
    vecval::Array{Float64,1}
    dimval::Int
    vecbw::Array{Float64,1}
    dimbw::Int
    BayesNetOutVertIDs::Array{Symbol,1} # Int
    dimIDs::Array{Int,1}
    dims::Int
    eliminated::Bool
    BayesNetVertID::Symbol # Int
    separator::Array{Symbol,1} # Int
    softtype::String
    initialized::Bool
    inferdim::Float64
    ismargin::Bool
    dontmargin::Bool
    solveInProgress::Int
    solvedCount::Int
    PackedVariableNodeData() = new()
    PackedVariableNodeData(x1::Vector{Float64},
                         x2::Int,
                         x3::Vector{Float64},
                         x4::Int,
                         x5::Vector{Symbol}, # Int
                         x6::Vector{Int},
                         x7::Int,
                         x8::Bool,
                         x9::Symbol, # Int
                         x10::Vector{Symbol}, # Int
                         x11::String,
                         x12::Bool,
                         x13::Float64,
                         x14::Bool,
                         x15::Bool,
                         x16::Int,
                         solvedCount::Int) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16, solvedCount)
end

##==============================================================================
## PointParametricEst
##==============================================================================

##------------------------------------------------------------------------------
## AbstractPointParametricEst interface
##------------------------------------------------------------------------------

abstract type AbstractPointParametricEst end

##------------------------------------------------------------------------------
## MeanMaxPPE
##------------------------------------------------------------------------------
"""
    $TYPEDEF

Data container to store Parameteric Point Estimate (PPE) for mean and max.
"""
struct MeanMaxPPE <: AbstractPointParametricEst
    solverKey::Symbol #repeated because of Sam's request
    suggested::Vector{Float64}
    max::Vector{Float64}
    mean::Vector{Float64}
    lastUpdatedTimestamp::DateTime
end
##------------------------------------------------------------------------------
## Constructors

MeanMaxPPE(solverKey::Symbol, suggested::Vector{Float64}, max::Vector{Float64},mean::Vector{Float64}) = MeanMaxPPE(solverKey, suggested, max, mean, now())

## Accessors
##------------------------------------------------------------------------------

getMaxPPE(est::AbstractPointParametricEst) = est.max
getMeanPPE(est::AbstractPointParametricEst) = est.mean
getSuggestedPPE(est::AbstractPointParametricEst) = est.suggested
getLastUpdatedTimestamp(est::AbstractPointParametricEst) = est.lastUpdatedTimestamp

##==============================================================================
## DFG Variables
##==============================================================================

##------------------------------------------------------------------------------
## DFGVariable lv2
##------------------------------------------------------------------------------
"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct DFGVariable{T<:InferenceVariable} <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: `addPPE!`, `updatePPE!`, and `deletePPE!`"""
    ppeDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: `addVariableSolverData!`, `updateVariableSolverData!`, and `deleteVariableSolverData!`"""
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: [`getSmallData!`](@ref), [`setSmallData!`](@ref)"""
    smallData::Dict{String, String}#Ref{Dict{String, String}} #why was Ref here?
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
end

##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
DFGVariable(label::Symbol, softtype::T;
            timestamp::DateTime=now(),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T}}=Dict{Symbol, VariableNodeData{T}}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, tags, estimateDict, solverDataDict, smallData, bigData, DFGNodeParams(solvable, _internalId))


DFGVariable(label::Symbol,
            solverData::VariableNodeData{T};
            timestamp::DateTime=now(),
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, timestamp, tags, estimateDict, Dict{Symbol, VariableNodeData{T}}(:default=>solverData), smallData, bigData, DFGNodeParams(solvable, _internalId))

##------------------------------------------------------------------------------
function Base.copy(o::DFGVariable)::DFGVariable
    return DFGVariable(o.label, getSofttype(o)(), tags=copy(o.tags), estimateDict=copy(o.estimateDict),
                        solverDataDict=copy(o.solverDataDict), smallData=copy(o.smallData),
                        bigData=copy(o.bigData), solvable=getSolvable(o), _internalId=getInternalId(o))
end

##------------------------------------------------------------------------------
## DFGVariableSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Summary variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct DFGVariableSummary <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: `addPPE!`, `updatePPE!`, and `deletePPE!`"""
    ppeDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the softtype for the underlying variable.
    Accessor: `getSofttype`"""
    softtypename::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
end

##------------------------------------------------------------------------------
## SkeletonDFGVariable.jl
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct SkeletonDFGVariable <: AbstractDFGVariable
    """Variable label, e.g. :x1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(label, Set{Symbol}())


##==============================================================================
# Define variable levels
##==============================================================================
const VariableDataLevel0 = Union{DFGVariable, DFGVariableSummary, SkeletonDFGVariable}
const VariableDataLevel1 = Union{DFGVariable, DFGVariableSummary}
const VariableDataLevel2 = Union{DFGVariable}



function Base.convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getSofttype(v))), v.bigData, v._internalId)
end

#TODO Test
function Base.convert(::Type{SkeletonDFGVariable}, v::VariableDataLevel1)
    return SkeletonDFGVariable(v.label, deepcopy(v.tags))
end


##==============================================================================
## Accessors
##==============================================================================

"""
$SIGNATURES

Set the timestamp of a DFGVariable object returning a new DFGVariable.
Note:
Since `timestamp` is not mutable `setTimestamp` returns a new variable with the updated timestamp.
Use `updateVariable!` to update it in the factor graph.
"""
function setTimestamp(v::DFGVariable, ts::DateTime)
    return DFGVariable(v.label, ts, v.tags, v.ppeDict, v.solverDataDict, v.smallData, v.bigData, v._dfgNodeParams)
end

function setTimestamp(v::DFGVariableSummary, ts::DateTime)
    return DFGVariableSummary(v.label, ts, v.tags, v.estimateDict, v.softtypename, v.bigData, v._internalId)
end


"""
   $(SIGNATURES)

Variable nodes softtype information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Related

getVariableType
"""
function getSofttype(vnd::VariableNodeData)
  return vnd.softtype
end
function getSofttype(v::DFGVariable, solvekey::Symbol=:default)
  return v.solverDataDict[solvekey].softtype # Get instantiated form of the parameter for the DFGVariable
end

"""
    $SIGNATURES

Retrieve the soft type name symbol for a DFGVariableSummary. ie :Point2, Pose2, etc.
TODO, DO NOT USE v.softtypename in DFGVariableSummary
"""
getSofttype(v::DFGVariableSummary)::Symbol = v.softtypename


"""
    $SIGNATURES

Retrieve solver data structure stored in a variable.
"""
function getSolverData(v::DFGVariable, key::Symbol=:default)
    #TODO this does not fit in with some of the other error behaviour. but its used so added @error
    vnd =  haskey(v.solverDataDict, key) ? v.solverDataDict[key] : (@error "Variable does not have solver data $(key)"; nothing)
    return vnd
end

"""
    $SIGNATURES

Set solver data structure stored in a variable.
"""
#TODO Repeated functionality?
setSolverData!(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) = v.solverDataDict[key] = data

"""
    $SIGNATURES

Get solver data dictionary for a variable.
"""
getSolverDataDict(v::DFGVariable) = v.solverDataDict

"""
    $SIGNATURES

Get the PPE dictionary for a variable. Its use is not recomended.
"""
getPPEDict(v::VariableDataLevel1) = v.ppeDict


#TODO FIXME don't know if this should exist, should rather always update with fg object to simplify inmem vs cloud
"""
    $SIGNATURES

Get the parametric point estimate (PPE) for a variable in the factor graph.

Notes
- Defaults on keywords `solveKey` and `method`

Related

getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getPPE(vari::VariableDataLevel1, solveKey::Symbol=:default)
    return  getPPEs(vari)[solveKey]
    # return haskey(ppeDict, solveKey) ? ppeDict[solveKey] : nothing
end



"""
$SIGNATURES

Get the small data for a variable.
"""
getSmallData(v::DFGVariable)::Dict{String, String} = v.smallData

"""
$SIGNATURES

Set the small data for a variable.
This will overwrite old smallData.
"""
function setSmallData!(v::DFGVariable, smallData::Dict{String, String})::Dict{String, String}
    empty!(v.smallData)
    merge!(v.smallData, smallData)
end


"""
$SIGNATURES

Get the variable ordering for this factor.
Should be equivalent to getNeighbors unless something was deleted in the graph.
"""
getVariableOrder(fct::DFGFactor)::Vector{Symbol} = fct._variableOrderSymbols
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

"""
    $SIGNATURES

Get the number of times a variable has been inferred -- i.e. `solvedCount`.

Related

isSolved, setSolvedCount!
"""
getSolvedCount(v::VariableNodeData) = v.solvedCount
getSolvedCount(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> getSolvedCount
getSolvedCount(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = getSolvedCount(getVariable(dfg, sym), solveKey)

"""
    $SIGNATURES

Boolean on whether the variable has been solved.

Related

getSolved, setSolved!
"""
isSolved(v::VariableNodeData) = 0 < v.solvedCount
isSolved(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> isSolved
isSolved(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = isSolved(getVariable(dfg, sym), solveKey)


"""
    $SIGNATURES

Update/set the `solveCount` value.

Related

getSolved, isSolved
"""
setSolvedCount!(v::VariableNodeData, val::Int) = v.solvedCount = val
setSolvedCount!(v::VariableDataLevel2, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getSolverData(v, solveKey), val)
setSolvedCount!(dfg::AbstractDFG, sym::Symbol, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getVariable(dfg, sym), val, solveKey)

"""
    $SIGNATURES

Returns state of vertex data `.initialized` flag.

Notes:
- used by both factor graph variable and Bayes tree clique logic.
"""
function isInitialized(var::DFGVariable, key::Symbol=:default)::Bool
      data = getSolverData(var, key)
      if data == nothing
          #TODO we still have a mixture of 2 error behaviours
        return false
      else
          return data.initialized
    end
end

function isInitialized(dfg::AbstractDFG, label::Symbol, key::Symbol=:default)::Bool
  return isInitialized(getVariable(dfg, label), key)
end

"""
    $SIGNATURES

Return the DFGVariable softtype in factor graph `dfg<:AbstractDFG` and label `::Symbol`.
"""
getVariableType(var::DFGVariable) = getSofttype(var)
function getVariableType(dfg::G, lbl::Symbol) where G <: AbstractDFG
  getVariableType(getVariable(dfg, lbl))
end
