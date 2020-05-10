##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.9
##==============================================================================

include("../attic/GraphsDFG/GraphsDFG.jl")
@reexport using .GraphsDFGs

@deprecate getInternalId(args...) error("getInternalId is no longer in use")

@deprecate loadDFG(source::String, iifModule::Module, dest::AbstractDFG) loadDFG!(dest, source)


# leave a bit longer
export buildSubgraphFromLabels!
function buildSubgraphFromLabels!(dfg::AbstractDFG,
                                  syms::Vector{Symbol};
                                  subfg::AbstractDFG=LightDFG(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )
  error("""buildSubgraphFromLabels! is deprecated
        NOTE buildSubgraphFromLabels! does not have a 1-1 replacement in DFG
        - if you have a set of variables and factors use copyGraph
        - if you want neighbors automatically included use buildSubgraph
        - if you want a clique subgraph use buildCliqueSubgraph! from IIF
        """)

end

## TODO: I think these are handy, so move to Factor and Variable
Base.getproperty(x::DFGFactor,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGFactor,f::Symbol, val) = begin
    if f == :solvable
        setfield!(x,f,val)
        getfield(x,:_dfgNodeParams).solvable = val
    else
        setfield!(x,f,val)
    end
end

Base.getproperty(x::DFGVariable,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable = val
    else
        setfield!(x,f,val)
    end
end
