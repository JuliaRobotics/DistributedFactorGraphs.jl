# deprecation staging area

## quick deprecation handle
import Base: propertynames, getproperty

# this hides all the propertynames and makes it hard to work with.
# Base.propertynames(x::VariableDataLevel1, private::Bool=false) = private ? (:estimateDict, :ppeDict) : (:ppeDict,)

## REMOVE in 0.6.1 #TODO look what should already be removed

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

@deprecate getEstimates(v::VariableDataLevel1) getPPEDict(v)

@deprecate estimates(v::VariableDataLevel1) getPPEDict(v)

@deprecate getVariablePPEs(v::VariableDataLevel1) getPPEDict(v)

@deprecate getVariablePPE(args...) getPPE(args...)
#FIXME SORT UIT en deprecate, too many aliases


"""
    $SIGNATURES

Return dictionary with Parametric Point Estimates (PPE) values.

Notes:
- Equivalent to `getVariablePPEs`.
"""
#TODO deprecate, maar gebruik dalk naam om vector te kry soos getVariables/getFactors
getPPEs(vari::VariableDataLevel1)::Dict = getVariablePPEs(vari)


@deprecate getEstimate(v::VariableDataLevel1, key::Symbol=:default) getVariablePPE(v, key)

@deprecate estimate(v::VariableDataLevel1, key::Symbol=:default) getVariablePPE(v, key)

@deprecate softtype(v::VariableDataLevel1) getSofttype(v)

@deprecate label(v::DataLevel0) getLabel(v)

@deprecate tags(v::DataLevel0) getTags(v)

#TODO doesn't look like this existed
# @deprecate timestamp(v) getTimestamp(v)

@deprecate getData(v::DFGVariable; solveKey::Symbol=:default) getSolverData(v, solveKey)

@deprecate getData(f::DFGFactor) getSolverData(f)

@deprecate setSolverData(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) setSolverData!(v, data, key)


@deprecate data(f::DFGFactor) getSolverData(f)

@deprecate setSolverParams(args...) setSolverParams!(args...)

@deprecate setDescription(args...) setDescription!(args...)

@deprecate getAdjacencyMatrixSparse(dfg::AbstractDFG; solvable::Int=0) getBiadjacencyMatrix(dfg, solvable=solvable)

@deprecate solverData(f::DFGFactor) getSolverData(f)

@deprecate solverData(v::DFGVariable, key::Symbol=:default) getSolverData(v, key)

@deprecate solverDataDict(args...) getSolverDataDict(args...)

@deprecate internalId(args...) getInternalId(args...)

#FIXME TODO based on API definition of merge, in some cases the Noun is really not needed.
# @deprecate mergeUpdateVariableSolverData!(args...) mergeVariableSolverData!(args...)

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

# NOTE Fully depcrecate nodeCounter and labelDict from LightGraphs
# Base.propertynames(x::LightDFG, private::Bool=false) =
#     (:g, :description, :userId, :robotId, :sessionId, :nodeCounter, :labelDict, :addHistory, :solverParams)
#         # (private ? fieldnames(typeof(x)) : ())...)
#
# Base.getproperty(x::LightDFG,f::Symbol) = begin
#     if f == :nodeCounter
#         @error "Field nodeCounter deprecated. returning number of nodes"
#         nv(x.g)
#     elseif f == :labelDict
#         @error "Field labelDict deprecated. Consider using exists(dfg,label) or getLabelDict(dfg) instead. Returning internals copy"
#         copy(x.g.labels.sym_int)
#     else
#         getfield(x,f)
#     end
# end
