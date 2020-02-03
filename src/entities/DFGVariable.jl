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
    tags::Set{Symbol}
    """Dictionary of parametric point estimates keyed by solverDataDict keys
    Accessors: `addPPE!`, `updatePPE!`, and `deletePPE!`"""
    ppeDict::Dict{Symbol, <: AbstractPointParametricEst}
    """Dictionary of solver data. May be a subset of all solutions if a solver key was specified in the get call.
    Accessors: `addVariableSolverData!`, `updateVariableSolverData!`, and `deleteVariableSolverData!`"""
    solverDataDict::Dict{Symbol, VariableNodeData{T}}
    """Dictionary of small data associated with this variable.
    Accessors: `addSmallData!`, `updateSmallData!`, and `deleteSmallData!`"""
    smallData::Dict{String, String}#Ref{Dict{String, String}} #why was Ref here?
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
end

"""
    $SIGNATURES
The default DFGVariable constructor.
"""
DFGVariable(label::Symbol, softtype::T;
            tags::Set{Symbol}=Set{Symbol}(),
            estimateDict::Dict{Symbol, <: AbstractPointParametricEst}=Dict{Symbol, MeanMaxPPE}(),
            solverDataDict::Dict{Symbol, VariableNodeData{T}}=Dict{Symbol, VariableNodeData{T}}(:default => VariableNodeData{T}()),
            smallData::Dict{String, String}=Dict{String, String}(),
            bigData::Dict{Symbol, AbstractBigDataEntry}=Dict{Symbol,AbstractBigDataEntry}(),
            solvable::Int=1,
            _internalId::Int64=0) where {T <: InferenceVariable} =
    DFGVariable{T}(label, now(), tags, estimateDict, solverDataDict, smallData, bigData, DFGNodeParams(solvable, _internalId))

function Base.copy(o::DFGVariable)::DFGVariable
    return DFGVariable(o.label, getSofttype(o)(), tags=copy(o.tags), estimateDict=copy(o.estimateDict),
                        solverDataDict=copy(o.solverDataDict), smallData=copy(o.smallData),
                        bigData=copy(o.bigData), solvable=getSolvable(o), _internalId=getInternalId(o))
end
