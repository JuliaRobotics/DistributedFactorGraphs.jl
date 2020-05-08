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

@deprecate buildSubgraphFromLabels!(dfg::AbstractDFG, varList::Vector{Symbol}) buildSubgraph(dfg, varList, 1)


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
