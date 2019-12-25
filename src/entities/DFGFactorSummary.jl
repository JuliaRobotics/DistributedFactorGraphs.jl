"""
$(TYPEDEF)
Summary factor structure for a DistributedFactorGraph factor.

  ---
Fields:
$(TYPEDFIELDS)
"""
struct DFGFactorSummary <: AbstractDFGFactor
    """Factor label, e.g. :x1f1.
    Accessor: `getLabel`"""
    label::Symbol
    """Factor tags, e.g [:FACTOR].
    Accessors: `getLabels`, `addLabels!`, and `deleteLabels!`"""
    tags::Vector{Symbol}
    """Internal ID used by some of the DFG drivers. We don't suggest using this outside of DFG."""
    _internalId::Int64
    """Internal cache of the ordering of the neighbor variables. Rather use getNeighbors to get the list as this is an internal value.
    Accessors: `getVariableOrder`"""
    _variableOrderSymbols::Vector{Symbol}
end
