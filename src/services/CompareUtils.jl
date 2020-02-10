## @generated compare
# Reference https://github.com/JuliaLang/julia/issues/4648

import Base.==

#=
For now abstract `InferenceVariable`s are considered equal if they are the same type, dims, and manifolds (abels are deprecated)
If your implentation has aditional properties such as `DynPose2` with `ut::Int64` (microsecond time) or support different manifolds
implement compare if needed.
=#
==(a::InferenceVariable,b::InferenceVariable) = typeof(a) == typeof(b) && a.dims == b.dims && a.manifolds == b.manifolds

==(a::ConvolutionObject, b::ConvolutionObject) = typeof(a) == typeof(b)

==(a::FunctorInferenceType, b::FunctorInferenceType) = typeof(a) == typeof(b)

# TestCCW1{TestFunctorInferenceType1}

# Generate compares automatically for all in this union
const GeneratedCompareUnion = Union{MeanMaxPPE, VariableNodeData, DFGNodeParams,
                              DFGVariable, DFGVariableSummary, SkeletonDFGVariable,
                              GenericFunctionNodeData,
                              DFGFactor, DFGFactorSummary, SkeletonDFGFactor}

@generated function ==(x::T, y::T) where T <: GeneratedCompareUnion
    mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
end


##

function compareField(Allc, Bllc, syms)::Bool
    (!isdefined(Allc, syms) && !isdefined(Bllc, syms)) && return true
    !isdefined(Allc, syms) && return false
    !isdefined(Bllc, syms) && return false
    return eval(:($Allc.$syms == $Bllc.$syms))
end

"""
    $(SIGNATURES)

Compare the all fields of T that are not in `skip` for objects `Al` and `Bl`.

TODO > add to func_ref.md
"""
function compareFields(Al::T,
                       Bl::T;
                       show::Bool=true,
                       skip::Vector{Symbol}=Symbol[]  )::Bool where {T}
  for field in fieldnames(T)
    (field in skip) && continue
    tp = compareField(Al, Bl, field)
    show && @debug("  $tp : $field")==nothing
    !tp && return false
  end
  return true
end

function compareFields(Al::T,
                       Bl::T;
                       show::Bool=true,
                       skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Union{Number, AbstractString}}
  #
  return Al == Bl
end

function compareAll(Al::T,
                    Bl::T;
                    show::Bool=true,
                    skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Union{AbstractString,Symbol}}
  #
  return Al == Bl
end

function compareAll(Al::T,
                    Bl::T;
                    show::Bool=true,
                    skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Union{Array{<:Number}, Number}}
  #
  (length(Al) != length(Bl)) && return false
  return norm(Al - Bl) < 1e-6
end

function compareAll(Al::T,
                    Bl::T;
                    show::Bool=true,
                    skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Array}
  #
  (length(Al) != length(Bl)) && return false
  for i in 1:length(Al)
    !compareAll(Al[i],Bl[i], show=false) && return false
  end
  return true
end


"""
    $(SIGNATURES)

Recursively compare the all fields of T that are not in `skip` for objects `Al` and `Bl`.

TODO > add to func_ref.md
"""
function compareAll(Al::T,
                    Bl::T;
                    show::Bool=true,
                    skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Tuple}
  #
  length(Al) != length(Bl) && return false
  for i in 1:length(Al)
    !compareAll(Al[i], Bl[i], show=show, skip=skip) && return false
  end
  return true
end

function compareAll(Al::T,
                    Bl::T;
                    show::Bool=true,
                    skip::Vector{Symbol}=Symbol[]  )::Bool where {T <: Dict}
  #
  (length(Al) != length(Bl)) && return false
  for (id, val) in Al
    (Symbol(id) in skip) && continue
    !compareAll(val, Bl[id], show=show, skip=skip) && return false
  end
  return true
end

function compareAll(Al::T, Bl::T; show::Bool=true, skip::Vector{Symbol}=Symbol[])::Bool where T
  @debug "Comparing types $T:"
  @debug "  Al = $Al"
  @debug "  Bl = $Bl"
  !compareFields(Al, Bl, show=show, skip=skip) && return false
  for field in fieldnames(T)
    field in skip && continue
    @debug("  Checking field: $field")
    (!isdefined(Al, field) && !isdefined(Al, field)) && return true
    !isdefined(Al, field) && return false
    !isdefined(Bl, field) && return false
    Ad = eval(:($Al.$field))
    Bd = eval(:($Bl.$field))
    !compareAll(Ad, Bd, show=show, skip=skip) && return false
  end
  return true
end

#Compare VariableNodeData
function compare(a::VariableNodeData, b::VariableNodeData)
    a.val != b.val && @debug("val is not equal")==nothing && return false
    a.bw != b.bw && @debug("bw is not equal")==nothing && return false
    a.BayesNetOutVertIDs != b.BayesNetOutVertIDs && @debug("BayesNetOutVertIDs is not equal")==nothing && return false
    a.dimIDs != b.dimIDs && @debug("dimIDs is not equal")==nothing && return false
    a.dims != b.dims && @debug("dims is not equal")==nothing && return false
    a.eliminated != b.eliminated && @debug("eliminated is not equal")==nothing && return false
    a.BayesNetVertID != b.BayesNetVertID && @debug("BayesNetVertID is not equal")==nothing && return false
    a.separator != b.separator && @debug("separator is not equal")==nothing && return false
    a.initialized != b.initialized && @debug("initialized is not equal")==nothing && return false
    abs(a.inferdim - b.inferdim) > 1e-14 && @debug("inferdim is not equal")==nothing && return false
    a.ismargin != b.ismargin && @debug("ismargin is not equal")==nothing && return false
    a.dontmargin != b.dontmargin && @debug("dontmargin is not equal")==nothing && return false
    a.solveInProgress != b.solveInProgress && @debug("solveInProgress is not equal")==nothing && return false
    typeof(a.softtype) != typeof(b.softtype) && @debug("softtype is not equal")==nothing && return false
    return true
end

"""
    $SIGNATURES

Compare that all fields are the same in a `::FactorGraph` variable.
"""
function compareVariable(A::DFGVariable,
                         B::DFGVariable;
                         skip::Vector{Symbol}=Symbol[],
                         show::Bool=true,
                         skipsamples::Bool=true  )::Bool
  #
  skiplist = union([:attributes;:solverDataDict;:_internalId;:createdTimestamp;:lastUpdatedTimestamp],skip)
  TP = compareAll(A, B, skip=skiplist, show=show)
  varskiplist = skipsamples ? [:val; :bw] : Symbol[]
  skiplist = union([:softtype;],varskiplist)
  union!(skiplist, skip)
  TP = TP && compareAll(A.solverDataDict, B.solverDataDict, skip=skiplist, show=show)

  Ad = getSolverData(A)
  Bd = getSolverData(B)

  # TP = TP && compareAll(A.attributes, B.attributes, skip=[:softtype;], show=show)
  varskiplist = union(varskiplist, [:softtype;:_internalId])
  union!(varskiplist, skip)
  TP = TP && compareAll(Ad, Bd, skip=varskiplist, show=show)
  TP = TP && typeof(Ad.softtype) == typeof(Bd.softtype)
  TP = TP && compareAll(Ad.softtype, Bd.softtype, show=show, skip=skip)
  return TP
end

function compareAllSpecial(A::T1,
                           B::T2;
                           skip=Symbol[],
                           show::Bool=true) where {T1 <: GenericFunctionNodeData, T2 <: GenericFunctionNodeData}
  if T1 != T2
    return false
  else
    return compareAll(A, B, skip=skip, show=show)
  end
end


# Compare FunctionNodeData
function compare(a::GenericFunctionNodeData{T1,S},b::GenericFunctionNodeData{T2,S}) where {T1, T2, S}
  # TODO -- beef up this comparison to include the gwp
  TP = true
  TP = TP && a.fncargvID == b.fncargvID
  TP = TP && a.eliminated == b.eliminated
  TP = TP && a.potentialused == b.potentialused
  TP = TP && a.edgeIDs == b.edgeIDs
  TP = TP && a.frommodule == b.frommodule
  # TP = TP && typeof(a.fnc) == typeof(b.fnc)
  return TP
end

"""
    $SIGNATURES

Compare that all fields are the same in a `::FactorGraph` factor.
"""
function compareFactor(A::DFGFactor,
                       B::DFGFactor;
                       show::Bool=true,
                       skip::Vector{Symbol}=Symbol[],
                       skipsamples::Bool=true,
                       skipcompute::Bool=true  )
  #
  TP =  compareAll(A, B, skip=union([:attributes;:solverData;:_variableOrderSymbols;:_internalId],skip), show=show)
  # TP = TP & compareAll(A.attributes, B.attributes, skip=[:data;], show=show)
  TP = TP & compareAllSpecial(getSolverData(A), getSolverData(B), skip=union([:fnc;:_internalId], skip), show=show)
  TP = TP & compareAllSpecial(getSolverData(A).fnc, getSolverData(B).fnc, skip=union([:cpt;:measurement;:params;:varidx;:threadmodel], skip), show=show)
  TP = TP & (skipsamples || compareAll(getSolverData(A).fnc.measurement, getSolverData(B).fnc.measurement, show=show, skip=skip))
  TP = TP & (skipcompute || compareAll(getSolverData(A).fnc.params, getSolverData(B).fnc.params, show=show, skip=skip))
  TP = TP & (skipcompute || compareAll(getSolverData(A).fnc.varidx, getSolverData(B).fnc.varidx, show=show, skip=skip))

  return TP
end
  # Ad = getSolverData(A)
  # Bd = getSolverData(B)
  # TP =  compareAll(A, B, skip=[:attributes;:data], show=show)
  # TP &= compareAll(A.attributes, B.attributes, skip=[:data;], show=show)
  # TP &= compareAllSpecial(getSolverData(A).fnc, getSolverData(B).fnc, skip=[:cpt;], show=show)
  # TP &= compareAll(getSolverData(A).fnc.cpt, getSolverData(B).fnc.cpt, show=show)


"""
    $SIGNATURES

Compare all variables in both `::FactorGraph`s A and B.

Notes
- A and B should all the same variables and factors.

Related:

`compareFactorGraphs`, `compareSimilarVariables`, `compareVariable`, `ls`
"""
function compareAllVariables(fgA::G1,
                             fgB::G2;
                             skip::Vector{Symbol}=Symbol[],
                             show::Bool=true,
                             skipsamples::Bool=true )::Bool where {G1 <: AbstractDFG, G2 <: AbstractDFG}
  # get all the variables in A or B
  xlA =  listVariables(fgA)
  xlB =  listVariables(fgB)
  vars = union(xlA, xlB)

  # compare all variables exist in both A and B
  TP = length(xlA) == length(xlB)
  for xla in xlA
    TP &= xla in xlB
  end
  # slightly redundant, but repeating opposite direction anyway
  for xlb in xlB
    TP &= xlb in xlA
  end

  # compare each variable is the same in both A and B
  for var in vars
    TP = TP && compareVariable(getVariable(fgA, var), getVariable(fgB, var), skipsamples=skipsamples, skip=skip)
  end

  # return comparison result
  return TP
end

"""
    $SIGNATURES

Compare similar labels between `::FactorGraph`s A and B.

Notes
- At least one variable label should exist in both A and B.

Related:

`compareFactorGraphs`, `compareAllVariables`, `compareSimilarFactors`, `compareVariable`, `ls`.
"""
function compareSimilarVariables(fgA::G1,
                                 fgB::G2;
                                 skip::Vector{Symbol}=Symbol[],
                                 show::Bool=true,
                                 skipsamples::Bool=true )::Bool where {G1 <: AbstractDFG, G2 <: AbstractDFG}
  #
  xlA = listVariables(fgA)
  xlB = listVariables(fgB)

  # find common variables
  xlAB = intersect(xlA, xlB)
  TP = length(xlAB) > 0

  # compare the common set
  for var in xlAB
    @info var
    TP &= compareVariable(getVariable(fgA, var), getVariable(fgB, var), skipsamples=skipsamples, skip=skip)
  end

  # return comparison result
  return TP
end

"""
    $SIGNATURES

Compare similar factors between `::FactorGraph`s A and B.

Related:

`compareFactorGraphs`, `compareSimilarVariables`, `compareAllVariables`, `ls`.
"""
function compareSimilarFactors(fgA::G1,
                               fgB::G2;
                               skipsamples::Bool=true,
                               skipcompute::Bool=true,
                               show::Bool=true  )::Bool where {G1 <: AbstractDFG, G2 <: AbstractDFG}
  #
  xlA = listFactors(fgA)
  xlB = listFactors(fgB)

  # find common variables
  xlAB = intersect(xlA, xlB)
  TP = length(xlAB) > 0

  # compare the common set
  for var in xlAB
    TP = TP && compareFactor(getFactor(fgA, var), getFactor(fgB, var), skipsamples=skipsamples, skipcompute=skipcompute, show=show)
  end

  # return comparison result
  return TP
end

"""
    $SIGNATURES

Compare and return if two factor graph objects are the same, by comparing similar variables and factors.

Notes:
- Default items to skip with `skipsamples`, `skipcompute`.
- User defined fields to skip can be specified with `skip::Vector{Symbol}`.

Related:

`compareSimilarVariables`, `compareSimilarFactors`, `compareAllVariables`, `ls`.
"""
function compareFactorGraphs(fgA::G1,
                             fgB::G2;
                             skipsamples::Bool=true,
                             skipcompute::Bool=true,
                             skip::Vector{Symbol}=Symbol[],
                             show::Bool=true  )::Bool where {G1 <: AbstractDFG, G2 <: AbstractDFG}
  #
  skiplist = Symbol[:g;:bn;:IDs;:fIDs;:id;:nodeIDs;:factorIDs;:fifo;:solverParams]
  skiplist = union(skiplist, skip)
  @warn "compareFactorGraphs will skip comparisons on: $skiplist"

  TP = compareAll(fgA, fgB, skip=skiplist, show=show)
  TP = TP && compareSimilarVariables(fgA, fgB, skipsamples=skipsamples, show=show, skip=skiplist )
  TP = TP && compareSimilarFactors(fgA, fgB, skipsamples=skipsamples, skipcompute=skipcompute, show=show )
  TP = TP && compareAll(fgA.solverParams, fgB.solverParams, skip=skiplist)

  return TP
end
