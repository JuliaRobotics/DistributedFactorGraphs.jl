"""
$(TYPEDEF)
Structure for a graph summary.
"""
struct DFGSummary
    variables::Dict{Symbol, DFGVariableSummary}
    factors::Dict{Symbol, DFGFactorSummary}
    userLabel::String
    robotLabel::String
    sessionLabel::String
end
