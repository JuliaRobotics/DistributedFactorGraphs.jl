"""
$(TYPEDEF)
Structure for a graph summary.
"""
# TODO why is this called Abstract...
struct AbstractDFGSummary
  variables::Dict{Symbol, DFGVariableSummary}
  factors::Dict{Symbol, DFGFactorSummary}
  userId::String
  robotId::String
  sessionId::String
end
