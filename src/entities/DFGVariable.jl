include("DFGVariable/PackedVariableNodeData.jl")
include("DFGVariable/PointParametricEst.jl")
include("DFGVariable/VariableNodeData.jl")

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
    tags::Vector{Symbol}
    """Dictionary of estimates keyed by solverDataDict keys
    Accessors: `addEstimate!`, `updateEstimate!`, and `deleteEstimate!`"""
    estimateDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: `addVariableSolverData!`, `updateVariableSolverData!`, and `deleteVariableSolverData!`"""
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: `addSmallData!`, `updateSmallData!`, and `deleteSmallData!`"""
    smallData::Dict{String, String}
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Solvable flag for the variable.
    Accessors: `getSolvable`, `setSolvable!`
    TODO: Switch to `DFGNodeParams`"""
    solvable::Int
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
end

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
DFGVariable(label::Symbol, softtype::T;
            tags::Vector{Symbol}=Symbol[],
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T}}=Dict{Symbol, VariableNodeData{T}}(:default => VariableNodeData{T}()),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, now(), tags, estimateDict, solverDataDict, smallData, bigData, solvable, DFGNodeParams(solvable, _internalId))

"""
    $SIGNATURES
DFGVariable constructors.
"""
function DFGVariable(label::Symbol, _internalId::Int64 = 0) #where {T <:InferenceVariable}
    st = stacktrace()
    @warn "DFGVariable(label::Symbol, _internalId::Int64 = 0) is deprecated please use DFGVariable(label::Symbol, softtype::T, _internalId::Int64 = 0) where T <: InferenceVariable. Enable DEBUG logging for the stack trace."
    @debug st
    T = InferenceVariable
    DFGVariable(label, now(), Symbol[],
                  Dict{Symbol, MeanMaxPPE}(),
                  Dict{Symbol, VariableNodeData{T}}(:default => VariableNodeData()),
                  Dict{String, String}(),
                  Dict{Symbol,AbstractBigDataEntry}(), 0, _internalId)
end
DFGVariable(label::Symbol, softtype::T, _internalId::Int64 = 0) where {T <: InferenceVariable}  =
    DFGVariable(label, now(), Symbol[],
              Dict{Symbol, MeanMaxPPE}(),
              Dict{Symbol, VariableNodeData{T}}(:default => VariableNodeData{T}()),
              Dict{String, String}(),
              Dict{Symbol,AbstractBigDataEntry}(), 0, _internalId)

"""
    $(SIGNATURES)
Structure for first-class citizens of a DFGVariable.
"""
mutable struct DFGVariableSummary <: AbstractDFGVariable
    label::Symbol
    timestamp::DateTime
    tags::Vector{Symbol}
    estimateDict::Dict{Symbol, <:AbstractPointParametricEst}
    softtypename::Symbol
    _internalId::Int64
end


# SKELETON DFG
"""
    $(TYPEDEF)
Skeleton variable with essentials.
"""
struct SkeletonDFGVariable <: AbstractDFGVariable
    label::Symbol
    tags::Vector{Symbol}
end

SkeletonDFGVariable(label::Symbol) = SkeletonDFGVariable(label, Symbol[])


# Accessors

const VariableDataLevel0 = Union{DFGVariable, DFGVariableSummary, SkeletonDFGVariable}
const VariableDataLevel1 = Union{DFGVariable, DFGVariableSummary}
const VariableDataLevel2 = Union{DFGVariable}


"""
$SIGNATURES

Return the estimates for a variable.
"""
getEstimates(v::VariableDataLevel1) = v.estimateDict

"""
    $SIGNATURES

Return the estimates for a variable.

DEPRECATED, estimates -> getEstimates
"""
function estimates(v::VariableDataLevel1)
    @warn "Deprecated estimates, use getEstimates instead."
    getEstimates(v)
end

"""
    $SIGNATURES

Return a keyed estimate (default is :default) for a variable.
"""
getEstimate(v::VariableDataLevel1, key::Symbol=:default) = haskey(v.estimateDict, key) ? v.estimateDict[key] : nothing

"""
$SIGNATURES

Return a keyed estimate (default is :default) for a variable.
"""
function estimate(v::VariableDataLevel1, key::Symbol=:default)
    @warn "DEPRECATED estimate, use getEstimate instead."
    getEstimate(v, key)
end


"""
    $SIGNATURES

Get the parametric point estimate (PPE) for a variable in the factor graph.

Notes
- Defaults on keywords `solveKey` and `method`

Related

getMeanPPE, getMaxPPE, getKDEMean, getKDEFit
"""
function getVariablePPE(vari::DFGVariable; solveKey::Symbol=:default, method::Function=getSuggestedPPE)
  getEstimates(vari)[solveKey] |> getSuggestedPPE
end

getVariablePPE(dfg::AbstractDFG, vsym::Symbol; solveKey::Symbol=:default, method::Function=getSuggestedPPE) = getVariablePPE(getVariable(dfg,vsym), solveKey=solveKey, method=method)

"""
   $(SIGNATURES)

Variable nodes softtype information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Related

getVariableType
"""
function getSofttype(vnd::VariableNodeData)
  return vnd.softtype
end
function getSofttype(v::DFGVariable; solveKey::Symbol=:default)
  return getSofttype(solverData(v, solveKey))
