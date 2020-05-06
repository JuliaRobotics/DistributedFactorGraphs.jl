##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.9
##==============================================================================

@deprecate buildSubgraphFromLabels!(dfg::AbstractDFG, varList::Vector{Symbol}) buildSubgraph(dfg, varList, 1)

Base.getproperty(x::DFGFactor,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGFactor,f::Symbol, val) = begin
    if f == :solvable
        setfield!(x,f,val)
        getfield(x,:_dfgNodeParams).solvable = val
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId = val
    else
        setfield!(x,f,val)
    end
end

Base.getproperty(x::DFGVariable,f::Symbol) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId
    else
        getfield(x,f)
    end
end

Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
    if f == :solvable
        getfield(x,:_dfgNodeParams).solvable = val
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId = val
    else
        setfield!(x,f,val)
    end
end
