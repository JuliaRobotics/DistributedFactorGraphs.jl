##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.9
##==============================================================================

import Base: *

# FIXME remove! is it really needed? This is type piracy
function *(a::Symbol, b::AbstractString)
  @warn "product * on ::Symbol ::String has been deprecated, please use Symbol(string(a,b)) directly"
  Symbol(string(a,b))
end

setTimestamp!(f::FactorDataLevel1, ts::DateTime) = error("setTimestamp!(f::FactorDataLevel1, ts::DateTime) is deprecated")

include("../attic/GraphsDFG/GraphsDFG.jl")
@reexport using .GraphsDFGs

@deprecate getInternalId(args...) error("getInternalId is no longer in use")

@deprecate loadDFG(source::String, iifModule::Module, dest::AbstractDFG) loadDFG!(dest, source)

# leave a bit longer
export buildSubgraphFromLabels!
function buildSubgraphFromLabels!(dfg::AbstractDFG,
                                  syms::Vector{Symbol};
                                  subfg::AbstractDFG=LightDFG(solverParams=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )
  error("""buildSubgraphFromLabels! is deprecated
        NOTE buildSubgraphFromLabels! does not have a 1-1 replacement in DFG
        - if you have a set of variables and factors use copyGraph
        - if you want neighbors automatically included use buildSubgraph
        - if you want a clique subgraph use buildCliqueSubgraph! from IIF
        """)

end
