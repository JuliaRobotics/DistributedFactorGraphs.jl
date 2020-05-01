"""
$(TYPEDEF)
Structure for a graph summary.
"""

struct DFGSummary
  variables::Dict{Symbol, DFGVariableSummary}
  factors::Dict{Symbol, DFGFactorSummary}
  userId::String
  robotId::String
  sessionId::String
end
