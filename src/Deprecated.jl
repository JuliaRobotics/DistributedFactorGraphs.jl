##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.8
##==============================================================================

#TODO alias or deprecate
@deprecate getVariableIds(dfg::AbstractDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0) listVariables(dfg, regexFilter, tags=tags, solvable=solvable)

@deprecate getFactorIds(dfg, regexFilter=nothing; solvable=0) listFactors(dfg, regexFilter, solvable=solvable)

@deprecate listPPE(args...) listPPEs(args...)

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

@deprecate getAdjacencyMatrixSparse(dfg::AbstractDFG; solvable::Int=0) getBiadjacencyMatrix(dfg, solvable=solvable)


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

  Base.getproperty(x::DFGVariable,f::Symbol) = begin
      # if f == :estimateDict
      #     @warn "estimateDict is deprecated, use ppeDict instead"
          # getfield(x, :ppeDict)
      if f == :solvable
          getfield(x,:_dfgNodeParams).solvable
      elseif f == :_internalId
          getfield(x,:_dfgNodeParams)._internalId
      else
          getfield(x,f)
      end
    end

  Base.setproperty!(x::DFGVariable,f::Symbol, val) = begin
      # if f == :estimateDict
      #     error("estimateDict is deprecated, use ppeDict instead")
      if f == :solvable
          getfield(x,:_dfgNodeParams).solvable = val
      elseif f == :_internalId
          getfield(x,:_dfgNodeParams)._internalId = val
      else
          setfield!(x,f,val)
      end
    end


#
