##==============================================================================
# deprecation staging area
##==============================================================================

##==============================================================================
## Remove in 0.7
##==============================================================================

Base.getproperty(x::DFGVariable,f::Symbol) = begin
    if f == :estimateDict
        @warn "estimateDict is deprecated, use ppeDict instead"
        getfield(x, :ppeDict)
    elseif f == :solvable
        getfield(x,:_dfgNodeParams).solvable
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId
    else
        getfield(x,f)
    end
  end

Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
    if f == :estimateDict
        error("estimateDict is deprecated, use ppeDict instead")
    elseif f == :solvable
        getfield(x,:_dfgNodeParams).solvable = val
    elseif f == :_internalId
        getfield(x,:_dfgNodeParams)._internalId = val
    else
        setfield!(x,f,val)
    end
  end

Base.getproperty(x::DFGVariableSummary,f::Symbol) = begin
    if f == :estimateDict
        @warn "estimateDict is deprecated, use ppeDict instead"
        getfield(x, :ppeDict)
    else
        getfield(x,f)
    end
  end


Base.getproperty(x::DFGFactor,f::Symbol) = begin
  if f == :solvable
      getfield(x,:_dfgNodeParams).solvable
  elseif f == :_internalId
      getfield(x,:_dfgNodeParams)._internalId
  elseif f == :data

      if !(@isdefined getFactorDataWarnOnce)
          @warn "get: data field is deprecated, use getSolverData. Further warnings are suppressed"
          global getFactorDataWarnOnce = true
      end

      getfield(x, :solverData)
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
    elseif f == :data

        if !(@isdefined setFactorDataWarnOnce)
            @warn "set: data field is deprecated, use ...TODO? Further warnings are suppressed"
            global setFactorDataWarnOnce = true
        end

        setfield!(x,:solverData, val)
    else
        setfield!(x,f,val)
    end
  end

Base.getproperty(x::GenericFunctionNodeData,f::Symbol) = begin
  f == :fncargvID && Base.depwarn("GenericFunctionNodeData field fncargvID will be deprecated, use `getVariableOrder` instead",:getproperty)#@warn "fncargvID is deprecated, use `getVariableOrder` instead"

  getfield(x, f)

end

Base.setproperty!(x::GenericFunctionNodeData,f::Symbol, val) = begin
  f == :fncargvID && Base.depwarn("GenericFunctionNodeData field fncargvID will be deprecated, use `getVariableOrder` instead",:getproperty)#@warn "fncargvID is deprecated, use `getVariableOrder` instead"

  setfield!(x,f,val)

end

# update is implied, see API wiki
@deprecate mergeUpdateVariableSolverData!(dfg, sourceVariable) mergeVariableData!(dfg, sourceVariable)
@deprecate mergeUpdateGraphSolverData!(sourceDFG, destDFG, varSyms) mergeGraphVariableData!(destDFG, sourceDFG, varSyms)

#TODO alias or deprecate
@deprecate getVariableIds(dfg::AbstractDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) listVariables(dfg, regexFilter, tags=tags, solvable=solvable)

@deprecate getFactorIds(dfg, regexFilter=nothing; solvable=0) listFactors(dfg, regexFilter, solvable=solvable)


#TODO doesn't look like this existed
# @deprecate timestamp(v) getTimestamp(v)

@deprecate setSolverParams(args...) setSolverParams!(args...)

@deprecate setDescription(args...) setDescription!(args...)

@deprecate getAdjacencyMatrixSparse(dfg::AbstractDFG; solvable::Int=0) getBiadjacencyMatrix(dfg, solvable=solvable)

@deprecate solverData(f::DFGFactor) getSolverData(f)

@deprecate solverData(v::DFGVariable, key::Symbol=:default) getSolverData(v, key)

@deprecate solverDataDict(args...) getSolverDataDict(args...)

@deprecate internalId(args...) getInternalId(args...)

@deprecate pack(dfg::AbstractDFG, d::VariableNodeData) packVariableNodeData(dfg, d)
@deprecate unpack(dfg::AbstractDFG, d::PackedVariableNodeData) unpackVariableNodeData(dfg, d)

export getLabelDict
getLabelDict(dfg::AbstractDFG) = error("getLabelDict is deprecated, consider using listing functions")

export getAdjacencyMatrix
"""
    $(SIGNATURES)
Get a matrix indicating relationships between variables and factors. Rows are
all factors, columns are all variables, and each cell contains either nothing or
the symbol of the relating factor. The first row and first column are factor and
variable headings respectively.
"""
function getAdjacencyMatrix(dfg::AbstractDFG; solvable::Int=0)::Matrix{Union{Nothing, Symbol}}
    error("Deprecated function, please use getBiadjacencyMatrix")
end


export buildSubgraphFromLabels
function buildSubgraphFromLabels(dfg::G,
                                  syms::Vector{Symbol};
                                  subfg::AbstractDFG=(G <: InMemoryDFGTypes ? G : GraphsDFG)(params=getSolverParams(dfg)),
                                  solvable::Int=0,
                                  allowedFactors::Union{Nothing, Vector{Symbol}}=nothing  )::G where G <: AbstractDFG
  #
  @warn "Deprecated buildSubgraphFromLabels, use buildSubgraphFromLabels! instead."
  buildSubgraphFromLabels!(dfg, syms, subfg=subfg, solvable=solvable, allowedFactors=allowedFactors )
end

@deprecate sortVarNested(vars::Vector{Symbol}) sortDFG(vars)


#NOTE This one is still used in IIF so maybe leave a bit longer
@deprecate getfnctype(args...) getFactorType(args...)
