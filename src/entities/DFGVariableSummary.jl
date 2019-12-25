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
    Accessors: `getLabels`, `addLabels!`, and `deleteLabels!`"""
    tags::Vector{Symbol}
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: `getLabels`, `addLabels`, and `deleteLabels`"""
    estimateDict::Dict{Symbol, <:AbstractPointParametricEst}
    """Symbol for the softtype for the underlying variable.
    Accessor: `getSofttype`"""
    softtypename::Symbol
    """Dictionary of large data associated with this variable.
    Accessors: `addSmallData!`, `updateSmallData!`, and `deleteSmallData!`"""
    bigData::Dict{Symbol, AbstractBigDataEntry}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
end
