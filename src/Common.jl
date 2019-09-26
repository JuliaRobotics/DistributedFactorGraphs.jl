
export sortVarNested, sortDFG
export isPrior, lsfPriors
export getVariableType, getSofttype
export getFactorType, getfnctype
export lsTypes, lsfTypes
export lsWho, lsfWho

## Utility functions for getting type names and modules (from IncrementalInference)
function _getmodule(t::T) where T
  T.name.module
end
function _getname(t::T) where T
  T.name.name
end

"""
    $(SIGNATURES)
Test if all elements of the string is a number:  Ex, "123" is true, "1_2" is false.
"""
allnums(str::S) where {S <: AbstractString} = occursin(Regex(string(["[0-9]" for j in 1:length(str)]...)), str)
# occursin(r"_+|,+|-+", node_idx)

isnestednum(str::S; delim='_') where {S <: AbstractString} = occursin(Regex("[0-9]+$(delim)[0-9]+"), str)

function sortnestedperm(strs::Vector{<:AbstractString}; delim='_')
  str12 = split.(strs, delim)
  sp1 = sortperm(parse.(Int,getindex.(str12,2)))
  sp2 = sortperm(parse.(Int,getindex.(str12,1)[sp1]))
  return sp1[sp2]
end

function getFirstNumericalOffset(st::AS) where AS <: AbstractString
  i = 1
  while !allnums(st[i:i])  i+=1; end
  return i
end

"""
    $SIGNATURES

Sort a variable list which may have nested structure such as `:x1_2` -- does not sort for alphabetic characters.
"""
function sortVarNested(vars::Vector{Symbol})::Vector{Symbol}
	# whos nested and first numeric character offset
	sv = string.(vars)
	offsets = getFirstNumericalOffset.(sv)
	masknested = isnestednum.(sv)
	masknotnested = true .⊻ masknested

	# strip alphabetic characters from front
	msv = sv[masknotnested]
	msvO = offsets[masknotnested]
	nsv = sv[masknested]
	nsvO = offsets[masknested]

	# do nonnested list separately
	nnreducelist = map((s,o) -> s[o:end], msv, msvO)
	nnintlist = parse.(Int, nnreducelist)
	nnp = sortperm(nnintlist)
	nnNums = nnintlist[nnp] # used in mixing later
	nonnested = msv[nnp]
	smsv = vars[masknotnested][nnp]

	# do nested list separately
	nestedreducelist = map((s,o) -> s[o:end], nsv, nsvO)
	nestedp = sortnestedperm(nestedreducelist)
	nesNums = parse.(Int, getindex.(split.(nestedreducelist[nestedp], '_'),1)) # used in mixing later
	nested = nsv[nestedp]
	snsv = vars[masknested][nestedp]

	# mix back together, pick next sorted item from either pile
	retvars = Vector{Symbol}(undef, length(vars))
	nni = 1
	nesi = 1
	lsmsv = length(smsv)
	lsnsv = length(snsv)
	MAXMAX = 999999999999
	for i in 1:length(vars)
	  # inner ifs to ensure bounds and correct sorting at end of each list
	  if (nni<=lsmsv ? nnNums[nni] : MAXMAX) <= (nesi<=lsnsv ? nesNums[nesi] : MAXMAX)
	    retvars[i] = smsv[nni]
		nni += 1
	  else
		retvars[i] = snsv[nesi]
		nesi += 1
	  end
	end
	return retvars
end

"""
    $SIGNATURES

Sort variable (factor) lists in a meaningful way, for example `[:april;:x1_3;:x1_6;]`

Notes
- Not fool proof, but does better than native sort.

Example

`sortDFG(ls(dfg))`

Related

ls, lsf
"""
sortDFG(vars::Vector{Symbol})::Vector{Symbol} = sortVarNested(vars)

"""
    $SIGNATURES

Return the factor type used in a `::DFGFactor`.

Notes:
- OBSOLETE, use newer getFactorType instead.

Related

getFactorType
"""
function getfnctype(data::GenericFunctionNodeData)
  # TODO what is this?
  if typeof(data).name.name == :VariableNodeData
    return VariableNodeData
  end

  # this looks right
  return data.fnc.usrfnc!
end
function getfnctype(fact::DFGFactor; solveKey::Symbol=:default)
  data = getData(fact) # TODO , solveKey=solveKey)
  return getfnctype(data)
end
function getfnctype(dfg::T, lbl::Symbol; solveKey::Symbol=:default) where T <: AbstractDFG
  getfnctype(getFactor(dfg, exvertid))
end

"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(data::GenericFunctionNodeData) = data.fnc.usrfnc!
getFactorType(fct::DFGFactor) = getFactorType(getData(fct))
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
   $(SIGNATURES)

Variable nodes softtype information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Related

getVariableType
"""
function getSofttype(vnd::VariableNodeData)
  return vnd.softtype
end
function getSofttype(v::DFGVariable; solveKey::Symbol=:default)
  return getSofttype(getData(v, solveKey=solveKey))
end

"""
    $SIGNATURES

Return the DFGVariable softtype in factor graph `dfg<:AbstractDFG` and label `::Symbol`.
"""
getVariableType(var::DFGVariable; solveKey::Symbol=:default) = getSofttype(var, solveKey=solveKey)
function getVariableType(dfg::G, lbl::Symbol; solveKey::Symbol=:default) where G <: AbstractDFG
  getVariableType(getVariable(dfg, lbl), solveKey=solveKey)
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


function ls(dfg::G, ::Type{T}; solveKey::Symbol=:default) where {G <: AbstractDFG, T <: InferenceVariable}
  xx = getVariables(dfg)
  mask = getVariableType.(xx, solveKey=solveKey) .|> typeof .== T
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
function lsWho(dfg::AbstractDFG, type::Symbol; solveKey::Symbol=:default)::Vector{Symbol}
    vars = getVariables(dfg)
	labels = Symbol[]
    for v in vars
		varType = typeof(getVariableType(v, solveKey=solveKey)).name |> Symbol
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
