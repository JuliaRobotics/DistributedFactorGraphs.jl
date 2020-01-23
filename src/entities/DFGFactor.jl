
abstract type InferenceType end
abstract type PackedInferenceType end

abstract type FunctorInferenceType <: Function end

abstract type InferenceVariable end
abstract type ConvolutionObject <: Function end

abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

"""
$(TYPEDEF)
"""
mutable struct GenericFunctionNodeData{T, S}
    fncargvID::Vector{Symbol}
    eliminated::Bool
    potentialused::Bool
    edgeIDs::Array{Int,1}
    frommodule::S #Union{Symbol, AbstractString}
    fnc::T
    multihypo::String # likely to moved when GenericWrapParam is refactored
    certainhypo::Vector{Int}
    solveInProgress::Int
    GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
    GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
    GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
    # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end

"""
$(TYPEDEF)
Complete factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
mutable struct DFGFactor{T, S} <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: `getLabel`"""
    label::Symbol
    """Variable timestamp.
    Accessors: `getTimestamp`, `setTimestamp!`"""
    timestamp::DateTime
    """Factor tags, e.g [:FACTOR].
    Accessors: `getTags`, `addTags!`, and `deleteTags!`"""
    tags::Set{Symbol}#Vector{Symbol} #TODO I propose we use a set since tags can't be repeated.
    """Solver data.
    Accessors: `getSolverData`, `setSolverData!`"""
    solverData::GenericFunctionNodeData{T, S}
    """Solvable flag for the factor.
    Accessors: `getSolvable`, `setSolvable!`
    TODO: Switch to `DFGNodeParams`"""
    solvable::Int #TODO we can go with DFGNodeParams or Reference the solvable field with getproperty overload
    """Mutable parameters for the variable. We suggest using accessors to get to this data.
    Accessors: `getSolvable`, `setSolvable!`"""
    _dfgNodeParams::DFGNodeParams
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: `getVariableOrder`"""
    _variableOrderSymbols::Vector{Symbol}
end

"""
$(SIGNATURES)

Construct a DFG factor given a label.
"""
#TODO _internalId?
DFGFactor{T, S}(label::Symbol, internalId::Int64=0, timestamp::DateTime=now()) where {T, S} =
                DFGFactor(label, timestamp, Symbol[], GenericFunctionNodeData{T, S}(), 0, DFGNodeParams(0, internalId), Symbol[])

DFGFactor(label::Symbol;
    timestamp::DateTime=now(),
    tags::Vector{Symbol}=Symbol[],
    data::GenericFunctionNodeData{T, S}=GenericFunctionNodeData{T, S}(),
    solvable::Int=0,
    _internalId::Int64=0,
    _variableOrderSymbols::Vector{Symbol}=Symbol[]) where {T, S} =
        DFGFactor{T,S}(label,timestamp,tags,data,solvable,DFGNodeParams(solvable, _internalId),_variableOrderSymbols)


# Simply for convenience - don't export
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, x7, x8, x9)
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="", x8::Vector{Int}=Int[], x9::Int=0) where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7, x8, x9)
