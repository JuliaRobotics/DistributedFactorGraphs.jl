"""
    $(SIGNATURES)
Structure for a graph summary.
"""
struct AbstractDFGSummary
  variables::Dict{Symbol, DFGVariableSummary}
  factors::Dict{Symbol, DFGFactorSummary}
  userId::String
  robotId::String
  sessionId::String
end
