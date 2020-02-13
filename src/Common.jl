
import Base: *

export sortDFG
#Natural less than defined for sorting
export natural_lt

export isPrior, lsfPriors
export getVariableType, getSofttype
export getFactorType, getfnctype
export lsTypes, lsfTypes
export lsWho, lsfWho
export *
export findClosestTimestamp, findVariableNearTimestamp
export addTags!
export hasTags, hasTagsNeighbors

# FIXME remove! is it really needed? This is type piracy
*(a::Symbol, b::AbstractString)::Symbol = Symbol(string(a,b))

## Utility functions for getting type names and modules (from IncrementalInference)
function _getmodule(t::T) where T
  T.name.module
end
function _getname(t::T) where T
  T.name.name
end

#TODO confirm this is only used in sortVarNested, then delete
# """
#     $(SIGNATURES)
# Test if all elements of the string is a number:  Ex, "123" is true, "1_2" is false.
# """
# allnums(str::S) where {S <: AbstractString} = occursin(Regex(string(["[0-9]" for j in 1:length(str)]...)), str)
# occursin(r"_+|,+|-+", node_idx)

# isnestednum(str::S; delim='_') where {S <: AbstractString} = occursin(Regex("[0-9]+$(delim)[0-9]+"), str)

# function sortnestedperm(strs::Vector{<:AbstractString}; delim='_')
#   str12 = split.(strs, delim)
#   sp1 = sortperm(parse.(Int,getindex.(str12,2)))
#   sp2 = sortperm(parse.(Int,getindex.(str12,1)[sp1]))
#   return sp1[sp2]
# end

# function getFirstNumericalOffset(st::AS) where AS <: AbstractString
#   i = 1
#   while !allnums(st[i:i])  i+=1; end
#   return i
# end
#
# """
#     $SIGNATURES
#
# Sort a variable list which may have nested structure such as `:x1_2` -- does not sort for alphabetic characters.
# """
# function sortVarNested(vars::Vector{Symbol})::Vector{Symbol}
#     # whos nested and first numeric character offset
#     sv = string.(vars)
#     offsets = getFirstNumericalOffset.(sv)
#     masknested = isnestednum.(sv)
#     masknotnested = true .⊻ masknested
#
#     # strip alphabetic characters from front
#     msv = sv[masknotnested]
#     msvO = offsets[masknotnested]
#     nsv = sv[masknested]
#     nsvO = offsets[masknested]
#
#     # do nonnested list separately
#     nnreducelist = map((s,o) -> s[o:end], msv, msvO)
#     nnintlist = parse.(Int, nnreducelist)
#     nnp = sortperm(nnintlist)
#     nnNums = nnintlist[nnp] # used in mixing later
#     nonnested = msv[nnp]
#     smsv = vars[masknotnested][nnp]
#
#     # do nested list separately
#     nestedreducelist = map((s,o) -> s[o:end], nsv, nsvO)
#     nestedp = sortnestedperm(nestedreducelist)
#     nesNums = parse.(Int, getindex.(split.(nestedreducelist[nestedp], '_'),1)) # used in mixing later
#     nested = nsv[nestedp]
#     snsv = vars[masknested][nestedp]
#
#     # mix back together, pick next sorted item from either pile
#     retvars = Vector{Symbol}(undef, length(vars))
#     nni = 1
#     nesi = 1
#     lsmsv = length(smsv)
#     lsnsv = length(snsv)
#     MAXMAX = 999999999999
#     for i in 1:length(vars)
#       # inner ifs to ensure bounds and correct sorting at end of each list
#       if (nni<=lsmsv ? nnNums[nni] : MAXMAX) <= (nesi<=lsnsv ? nesNums[nesi] : MAXMAX)
#         retvars[i] = smsv[nni]
#         nni += 1
#       else
#         retvars[i] = snsv[nesi]
#         nesi += 1
#       end
#     end
#     return retvars
# end
#END TODO confirm this is only used in sortVarNested, then delete


"""
    $SIGNATURES

Convenience wrapper for `Base.sort`.
Sort variable (factor) lists in a meaningful way (by `timestamp`, `label`, etc), for example `[:april;:x1_3;:x1_6;]`
Defaults to sorting by timestamp for variables and factors and using `natural_lt` for Symbols.
See Base.sort for more detail.

Notes
- Not fool proof, but does better than native sort.

Example

`sortDFG(ls(dfg))`
`sortDFG(ls(dfg), by=getLabel, lt=natural_lt)`

Related

ls, lsf
"""
sortDFG(vars::Vector{<:DFGNode}; by=getTimestamp, kwargs...) = sort(vars; by=by, kwargs...)
sortDFG(vars::Vector{Symbol}; lt=natural_lt, kwargs...)::Vector{Symbol} = sort(vars; lt=lt, kwargs...)


"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(data::GenericFunctionNodeData) = data.fnc.usrfnc!
getFactorType(fct::DFGFactor) = getFactorType(getSolverData(fct))
function getFactorType(dfg::G, lbl::Symbol) where G <: AbstractDFG
  getFactorType(getFactor(dfg, lbl))
end


"""
    $SIGNATURES

Return `::Bool` on whether given factor `fc::Symbol` is a prior in factor graph `dfg`.
"""
function isPrior(dfg::G, fc::Symbol)::Bool where G <: AbstractDFG
  fco = getFactor(dfg, fc)
  getfnctype(fco) isa FunctorSingleton
end

"""
    $SIGNATURES

Return vector of prior factor symbol labels in factor graph `dfg`.
"""
function lsfPriors(dfg::G)::Vector{Symbol} where G <: AbstractDFG
  priors = Symbol[]
  fcts = lsf(dfg)
  for fc in fcts
    if isPrior(dfg, fc)
      push!(priors, fc)
    end
  end
  return priors
end


"""
    $SIGNATURES

Return the DFGVariable softtype in factor graph `dfg<:AbstractDFG` and label `::Symbol`.
"""
getVariableType(var::DFGVariable) = getSofttype(var)
function getVariableType(dfg::G, lbl::Symbol) where G <: AbstractDFG
  getVariableType(getVariable(dfg, lbl))
end


"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{String}}` of all unique factor types in factor graph.
"""
function lsfTypes(dfg::G)::Dict{Symbol, Vector{String}} where G <: AbstractDFG
  alltypes = Dict{Symbol,Vector{String}}()
  for fc in lsf(dfg)
    Tt = typeof(getFactorType(dfg, fc))
    sTt = string(Tt)
    name = Symbol(Tt.name)
    if !haskey(alltypes, name)
      alltypes[name] = String[string(Tt)]
    else
      if sum(alltypes[name] .== sTt) == 0
        push!(alltypes[name], sTt)
      end
    end
  end
  return alltypes
end

"""
    $SIGNATURES

Return `::Dict{Symbol, Vector{String}}` of all unique variable types in factor graph.
"""
function lsTypes(dfg::G)::Dict{Symbol, Vector{String}} where G <: AbstractDFG
  alltypes = Dict{Symbol,Vector{String}}()
  for fc in ls(dfg)
    Tt = typeof(getVariableType(dfg, fc))
    sTt = string(Tt)
    name = Symbol(Tt.name)
    if !haskey(alltypes, name)
      alltypes[name] = String[string(Tt)]
    else
      if sum(alltypes[name] .== sTt) == 0
        push!(alltypes[name], sTt)
      end
    end
  end
  return alltypes
end


function ls(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: InferenceVariable}
  xx = getVariables(dfg)
  mask = getVariableType.(xx) .|> typeof .== T
  vxx = view(xx, mask)
  map(x->x.label, vxx)
end


function ls(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: FunctorInferenceType}
  xx = getFactors(dfg)
  names = getfield.(typeof.(getFactorType.(xx)), :name) .|> Symbol
  vxx = view(xx, names .== Symbol(T))
  map(x->x.label, vxx)
end

function lsf(dfg::G, ::Type{T}) where {G <: AbstractDFG, T <: FunctorInferenceType}
  ls(dfg, T)
end


"""
    $(SIGNATURES)
Gives back all factor labels that fit the bill:
    lsWho(dfg, :Pose3)

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsWho(dfg::AbstractDFG, type::Symbol)::Vector{Symbol}
    vars = getVariables(dfg)
    labels = Symbol[]
    for v in vars
        varType = typeof(getVariableType(v)).name |> Symbol
        varType == type && push!(labels, v.label)
    end
    return labels
end


"""
    $(SIGNATURES)
Gives back all factor labels that fit the bill:
    lsfWho(dfg, :Point2Point2)

Dev Notes
- Cloud versions will benefit from less data transfer
 - `ls(dfg::C, ::T) where {C <: CloudDFG, T <: ..}`

Related

ls, lsf, lsfPriors
"""
function lsfWho(dfg::AbstractDFG, type::Symbol)::Vector{Symbol}
    facs = getFactors(dfg)
    labels = Symbol[]
    for f in facs
        facType = typeof(getFactorType(f)).name |> Symbol
        facType == type && push!(labels, f.label)
    end
    return labels
end


"""
    $SIGNATURES

Find and return the closest timestamp from two sets of Tuples.  Also return the minimum delta-time (`::Millisecond`) and how many elements match from the two sets are separated by the minimum delta-time.
"""
function findClosestTimestamp(setA::Vector{Tuple{DateTime,T}},
                              setB::Vector{Tuple{DateTime,S}}) where {S,T}
  #
  # build matrix of delta times, ranges on rows x vars on columns
  DT = Array{Millisecond, 2}(undef, length(setA), length(setB))
  for i in 1:length(setA), j in 1:length(setB)
    DT[i,j] = setB[j][1] - setA[i][1]
  end

  DT .= abs.(DT)

  # absolute time differences
  # DTi = (x->x.value).(DT) .|> abs

  # find the smallest element
  mdt = minimum(DT)
  corrs = findall(x->x==mdt, DT)

  # return the closest timestamp, deltaT, number of correspondences
  return corrs[1].I, mdt, length(corrs)
end

"""
    $SIGNATURES

Find and return nearest variable labels per delta time.  Function will filter on `regexFilter`, `tags`, and `solvable`.

DevNotes:
- TODO `number` should allow returning more than one for k-nearest matches.
- Future versions likely will require some optimization around the internal `getVariable` call.
  - Perhaps a dedicated/efficient `getVariableTimestamp` for all DFG flavors.

Related

ls, listVariables, findClosestTimestamp
"""
function findVariableNearTimestamp(dfg::AbstractDFG,
                                   timest::DateTime,
                                   regexFilter::Union{Nothing, Regex}=nothing;
                                   tags::Vector{Symbol}=Symbol[],
                                   solvable::Int=0,
                                   warnDuplicate::Bool=true,
                                   number::Int=1  )::Vector{Tuple{Vector{Symbol}, Millisecond}}
  #
  # get the variable labels based on filters
  # syms = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
  syms = listVariables(dfg, regexFilter, tags=tags, solvable=solvable)
  # compile timestamps with label
  # vars = map( x->getVariable(dfg, x), syms )
  timeset = map(x->(getTimestamp(getVariable(dfg,x)), x), syms)
  mask = BitArray{1}(undef, length(syms))
  fill!(mask, true)

  RET = Vector{Tuple{Vector{Symbol},Millisecond}}()
  SYMS = Symbol[]
  CORRS = 1
  NUMBER = number
  while 0 < CORRS + NUMBER
    # get closest
    link, mdt, corrs = findClosestTimestamp([(timest,0)], timeset[mask])
    push!(SYMS, syms[link[2]])
    mask[link[2]] = false
    CORRS = corrs-1
    # last match, done with this delta time
    if corrs == 1
      NUMBER -=  1
      push!(RET, (deepcopy(SYMS),mdt))
      SYMS = Symbol[]
    end
  end
  # warn if duplicates found
  # warnDuplicate && 1 < corrs ? @warn("getVariableNearTimestamp found more than one variable at $timestamp") :   nothing

  return RET
end


#TAGS as a set, list, merge, remove, empty
"""
$SIGNATURES

Return the tags for a variable or factor.
"""
function listTags(dfg::InMemoryDFGTypes, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  getTags(getFnc(dfg, sym))
end
#alias for completeness
listTags(f::DataLevel0) = getTags(f)

"""
    $SIGNATURES

Merge add tags to a variable or factor (union)
"""
function mergeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  union!(getTags(getFnc(dfg, sym)), tags)
end
mergeTags!(f::DataLevel0, tags::Vector{Symbol}) = union!(f.tags, tags)


"""
$SIGNATURES

Remove the tags from the node (setdiff)
"""
function removeTags!(dfg::InMemoryDFGTypes, sym::Symbol, tags::Vector{Symbol})
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  setdiff!(getTags(getFnc(dfg, sym)), tags)
end
removeTags!(f::DataLevel0, tags::Vector{Symbol}) = setdiff!(f.tags, tags)

"""
$SIGNATURES

Empty all tags from the node (empty)
"""
function emptyTags!(dfg::InMemoryDFGTypes, sym::Symbol)
  getFnc = isVariable(dfg,sym) ? getVariable : getFactor
  empty!(getTags(getFnc(dfg, sym)))
end
emptyTags!(f::DataLevel0) = empty!(f.tags)





"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTags(dfg::InMemoryDFGTypes,
                 sym::Symbol,
                 tags::Vector{Symbol};
                 matchAll::Bool=true  )::Bool
  #
  alltags = listTags(dfg, sym)
  length(filter(x->x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end


"""
    $SIGNATURES

Determine if the variable or factor neighbors have the `tags:;Vector{Symbol}`, and `matchAll::Bool`.
"""
function hasTagsNeighbors(dfg::InMemoryDFGTypes,
                          sym::Symbol,
                          tags::Vector{Symbol};
                          matchAll::Bool=true  )::Bool
  #
  # assume only variables or factors are neighbors
  getNeiFnc = isVariable(dfg, sym) ? getFactor : getVariable
  alltags = union( (ls(dfg, sym) .|> x->getTags(getNeiFnc(dfg,x)))... )
  length(filter(x->x in alltags, tags)) >= (matchAll ? length(tags) : 1)
end



#Natural Sorting
# Adapted from https://rosettacode.org/wiki/Natural_sorting
# split at digit to not digit change
splitbynum(x::AbstractString) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
#parse to Int
numstringtonum(arr::Vector{<:AbstractString}) = [(n = tryparse(Int, e)) != nothing ? n : e for e in arr]
#natural less than
function natural_lt(x::T, y::T) where T <: AbstractString
    xarr = numstringtonum(splitbynum(x))
    yarr = numstringtonum(splitbynum(y))
    for i in 1:min(length(xarr), length(yarr))
        if typeof(xarr[i]) != typeof(yarr[i])
            return isa(xarr[i], Int)
        elseif xarr[i] == yarr[i]
            continue
        else
            return xarr[i] < yarr[i]
        end
    end
    return length(xarr) < length(yarr)
end

natural_lt(x::Symbol, y::Symbol) = natural_lt(string(x),string(y))
