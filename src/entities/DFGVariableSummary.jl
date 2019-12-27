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
    tags::Vector{Symbol}
    """Dictionary of estimates keyed by solverDataDict keys
    Accessors: `addEstimate!`, `updateEstimate!`, and `deleteEstimate!`"""
    estimateDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the softtype for the underlying variable.
    Accessor: `getSofttype`"""
    softtypename::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: `addBigDataEntry!`, `getBigDataEntry`, `updateBigDataEntry!`, and `deleteBigDataEntry!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
end
