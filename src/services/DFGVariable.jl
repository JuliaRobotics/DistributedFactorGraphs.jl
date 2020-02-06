import Base: ==, convert

function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
    props["tags"] = JSON2.write(v.tags)
    props["ppeDict"] = JSON2.write(v.ppeDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> pack(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["solvable"] = v.solvable
    props["bigData"] = JSON2.write(Dict(keys(v.bigData) .=> map(bde -> JSON2.write(bde), values(v.bigData))))
    props["bigDataElemType"] = JSON2.write(Dict(keys(v.bigData) .=> map(bde -> typeof(bde), values(v.bigData))))
    return props
end

function unpackVariable(dfg::G, packedProps::Dict{String, Any})::DFGVariable where G <: AbstractDFG
    label = Symbol(packedProps["label"])
    timestamp = DateTime(packedProps["timestamp"])
    tags =  JSON2.read(packedProps["tags"], Vector{Symbol})
    #TODO this will work for some time, but unpacking in an <: AbstractPointParametricEst would be lekker.
    ppeDict = JSON2.read(packedProps["ppeDict"], Dict{Symbol, MeanMaxPPE})
    smallData = nothing
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})
    bigDataElemTypes = JSON2.read(packedProps["bigDataElemType"], Dict{Symbol, Symbol})
    bigDataIntermed = JSON2.read(packedProps["bigData"], Dict{Symbol, String})

    packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
    solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(dfg, p), values(packed)))

    # Rebuild DFGVariable using the first solver softtype in solverData
    if length(solverData) > 0
        # variable = DFGVariable(Symbol(packedProps["label"]), first(solverData)[2].softtype)
        variable = DFGVariable(Symbol(packedProps["label"]), timestamp, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractBigDataEntry}(), DFGNodeParams(packedProps["solvable"],0))
    else
        @warn "The variable $label in this file does not have any solver data. This will not be supported in the future, please add at least one solverData structure."
        variable = DFGVariable(Symbol(packedProps["label"]), timestamp, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractBigDataEntry}(), DFGNodeParams(packedProps["solvable"],0))
    end

    # Now rehydrate complete bigData type.
    for (k,bdeInter) in bigDataIntermed
        fullVal = JSON2.read(bdeInter, getfield(DistributedFactorGraphs, bigDataElemTypes[k]))
        variable.bigData[k] = fullVal
    end

    return variable
end

function pack(dfg::G, d::VariableNodeData)::PackedVariableNodeData where G <: AbstractDFG
  @debug "Dispatching conversion variable -> packed variable for type $(string(d.softtype))"
  return PackedVariableNodeData(d.val[:],size(d.val,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                d.softtype != nothing ? string(d.softtype) : nothing,
                                d.initialized,
                                d.inferdim,
                                d.ismargin,
                                d.dontmargin,
                                d.solveInProgress,
                                d.solvedCount)
end

function unpack(dfg::G, d::PackedVariableNodeData)::VariableNodeData where G <: AbstractDFG
  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  @debug "Dispatching conversion packed variable -> variable for type $(string(d.softtype))"
  st = nothing #IncrementalInference.ContinuousMultivariate # eval(parse(d.softtype))
  mainmod = getSerializationModule(dfg)
  mainmod == nothing && error("Serialization module is null - please call setSerializationNamespace!(\"Main\" => Main) in your main program.")
  try
      if d.softtype != ""
          unpackedTypeName = split(d.softtype, "(")[1]
          unpackedTypeName = split(unpackedTypeName, '.')[end]
          @debug "DECODING Softtype = $unpackedTypeName"
          st = getfield(mainmod, Symbol(unpackedTypeName))()
      end
  catch ex
      @error "Unable to deserialize soft type $(d.softtype)"
      io = IOBuffer()
      showerror(io, ex, catch_backtrace())
      err = String(take!(io))
      @error err
  end
  @debug "Net conversion result: $st"

  if st == nothing
      error("The variable doesn't seem to have a softtype. It needs to set up with an InferenceVariable from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().")
  end

  return VariableNodeData{typeof(st)}(M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    st, d.initialized, d.inferdim, d.ismargin, d.dontmargin, d.solveInProgress, d.solvedCount)
end

# function compare(a::VariableNodeData, b::VariableNodeData)
#     a.val != b.val && @debug("val is not equal")==nothing && return false
#     a.bw != b.bw && @debug("bw is not equal")==nothing && return false
#     a.BayesNetOutVertIDs != b.BayesNetOutVertIDs && @debug("BayesNetOutVertIDs is not equal")==nothing && return false
#     a.dimIDs != b.dimIDs && @debug("dimIDs is not equal")==nothing && return false
#     a.dims != b.dims && @debug("dims is not equal")==nothing && return false
#     a.eliminated != b.eliminated && @debug("eliminated is not equal")==nothing && return false
#     a.BayesNetVertID != b.BayesNetVertID && @debug("BayesNetVertID is not equal")==nothing && return false
#     a.separator != b.separator && @debug("separator is not equal")==nothing && return false
#     a.initialized != b.initialized && @debug("initialized is not equal")==nothing && return false
#     abs(a.inferdim - b.inferdim) > 1e-14 && @debug("inferdim is not equal")==nothing && return false
#     a.ismargin != b.ismargin && @debug("ismargin is not equal")==nothing && return false
#     a.dontmargin != b.dontmargin && @debug("dontmargin is not equal")==nothing && return false
#     a.solveInProgress != b.solveInProgress && @debug("solveInProgress is not equal")==nothing && return false
#     typeof(a.softtype) != typeof(b.softtype) && @debug("softtype is not equal")==nothing && return false
#     return true
# end

#FIXME
# """
#     $(SIGNATURES)
# Equality check for VariableNodeData.
# """
# function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
#   return DistributedFactorGraphs.compare(a,b)
# end

# """
#     ==(x::T, y::T) where T <: AbstractPointParametricEst
# Equality check for AbstractPointParametricEst.
# """
# @generated function ==(x::T, y::T) where T <: AbstractPointParametricEst
#     mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
# end
#
# @generated function Base.:(==)(x::T, y::T) where T <: Union{DFGFactorSummary, DFGVariableSummary, SkeletonDFGVariable, SkeletonDFGFactor}
#     mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
# end

#FIXME
# """
#     $(SIGNATURES)
# Equality check for DFGVariable.
# """
# function ==(a::DFGVariable, b::DFGVariable)::Bool
#     return compareVariable(a, b)
# end

"""
    $(SIGNATURES)
Convert a DFGVariable to a DFGVariableSummary.
"""
function convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.ppeDict), Symbol(typeof(getSofttype(v))), v.bigData, v._internalId)
end

"""
    $(SIGNATURES)
Add Big Data Entry to a DFG variable
"""
function addBigDataEntry!(var::AbstractDFGVariable, bde::AbstractBigDataEntry)::AbstractBigDataEntry
    haskey(var.bigData,bde.key) && error("BigData entry $(bde.key) already exists in variable")
    var.bigData[bde.key] = bde
    return bde
end

"""
    $(SIGNATURES)
Add Big Data Entry to distributed factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addBigDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractBigDataEntry)::AbstractBigDataEntry
    return addBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Get big data entry
"""
function getBigDataEntry(var::AbstractDFGVariable, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    !haskey(var.bigData, key) && (error("BigData entry $(key) does not exist in variable"); return nothing)
    return var.bigData[key]
end

function getBigDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    return getBigDataEntry(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Update big data entry
"""
function updateBigDataEntry!(var::AbstractDFGVariable,  bde::AbstractBigDataEntry)::Union{Nothing, AbstractBigDataEntry}
    !haskey(var.bigData,bde.key) && (@warn "$(bde.key) does not exist in variable, adding")
    var.bigData[bde.key] = bde
    return bde
end
function updateBigDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractBigDataEntry)::Union{Nothing, AbstractBigDataEntry}
    # !isVariable(dfg, label) && return nothing
    return updateBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry from the factor graph.
Note this doesn't remove it from any data stores.
"""
function deleteBigDataEntry!(var::AbstractDFGVariable, key::Symbol)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    bde = getBigDataEntry(var, key)
    bde == nothing && return nothing
    delete!(var.bigData, key)
    return var
end
function deleteBigDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    !isVariable(dfg, label) && return nothing
    return deleteBigDataEntry!(getVariable(dfg, label), key)
end

function deleteBigDataEntry!(var::AbstractDFGVariable, entry::AbstractBigDataEntry)::Union{Nothing, AbstractDFGVariable} #users responsibility to delete big data in db before deleting entry
    return deleteBigDataEntry!(var, entry.key)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractBigDataEntry}
"""
function getBigDataEntries(var::AbstractDFGVariable)::Vector{AbstractBigDataEntry}
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    collect(values(var.bigData))
end
function getBigDataEntries(dfg::AbstractDFG, label::Symbol)::Union{Nothing, Vector{AbstractBigDataEntry}}
    !isVariable(dfg, label) && return nothing
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    getBigDataEntries(getVariable(dfg, label))
end


"""
    $(SIGNATURES)
getBigDataKeys
"""
function getBigDataKeys(var::AbstractDFGVariable)::Vector{Symbol}
    collect(keys(var.bigData))
end
function getBigDataKeys(dfg::AbstractDFG, label::Symbol)::Union{Nothing, Vector{Symbol}}
    !isVariable(dfg, label) && return nothing
    getBigDataKeys(getVariable(dfg, label))
end

# TODO: Temporary home
# Accessors

"""
    $SIGNATURES

Return dictionary with Parametric Point Estimates (PPE) values.

Notes:
- Equivalent to `getPPEs`.
"""
getVariablePPEs(vari::VariableDataLevel1)::Dict = vari.ppeDict

"""
    $SIGNATURES

Return dictionary with Parametric Point Estimates (PPE) values.

Notes:
- Equivalent to `getVariablePPEs`.
"""
getPPEs(vari::VariableDataLevel1)::Dict = getVariablePPEs(vari)


"""
    $SIGNATURES

Get the parametric point estimate (PPE) for a variable in the factor graph.

Notes
- Defaults on keywords `solveKey` and `method`

Related

getMeanPPE, getMaxPPE, getKDEMean, getKDEFit, getPPEs, getVariablePPEs
"""
function getVariablePPE(vari::VariableDataLevel1, solveKey::Symbol=:default)
    ppeDict = getVariablePPEs(vari)
    return haskey(ppeDict, solveKey) ? ppeDict[solveKey] : nothing
end

getVariablePPE(dfg::AbstractDFG, vsym::Symbol, solveKey::Symbol=:default) = getVariablePPE(getVariable(dfg,vsym), solveKey)

"""
   $(SIGNATURES)

Variable nodes softtype information holding a variety of meta data associated with the type of variable stored in that node of the factor graph.

Related

getVariableType
"""
function getSofttype(vnd::VariableNodeData)
  return vnd.softtype
end
function getSofttype(v::DFGVariable)
  return typeof(v).parameters[1]() # Get instantiated form of the parameter for the DFGVariable
end

"""
    $SIGNATURES

Retrieve the soft type name symbol for a DFGVariableSummary. ie :Point2, Pose2, etc.
TODO, DO NOT USE v.softtypename in DFGVariableSummary
"""
getSofttype(v::DFGVariableSummary)::Symbol = v.softtypename


"""
    $SIGNATURES

Retrieve solver data structure stored in a variable.
"""
function getSolverData(v::DFGVariable, key::Symbol=:default)
    return haskey(v.solverDataDict, key) ? v.solverDataDict[key] : nothing
end

"""
    $SIGNATURES

Set solver data structure stored in a variable.
"""
setSolverData!(v::DFGVariable, data::VariableNodeData, key::Symbol=:default) = v.solverDataDict[key] = data

"""
    $SIGNATURES

Get solver data dictionary for a variable.
"""
getSolverDataDict(v::DFGVariable) = v.solverDataDict

"""
    $SIGNATURES

Get the PPE dictionary for a variable. Its use is not recomended.
"""
getPPEDict(v::DFGVariable) = v.ppeDict

"""
$SIGNATURES

Get the small data for a variable.
"""
getSmallData(v::DFGVariable)::Dict{String, String} = v.smallData

"""
$SIGNATURES

Set the small data for a variable.
This will overwrite old smallData.
"""
function setSmallData!(v::DFGVariable, smallData::Dict{String, String})::Dict{String, String}
    empty!(v.smallData)
    merge!(v.smallData, smallData)
end

# WIP
# """
# $SIGNATURES
#
# Set the small data for a variable.
# """
# function addSmallData!(v::DFGVariable, smallData::Dict{String, String})::Dict{String, String}
#     v.smallData = smallData
# end
#
# function updateSmallData!()
# end
#
# function deleteSmallData!()
# end

"""
$SIGNATURES

Get the variable ordering for this factor.
Should be equivalent to getNeighbors unless something was deleted in the graph.
"""
getVariableOrder(fct::DFGFactor)::Vector{Symbol} = fct._variableOrderSymbols
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

"""
    $SIGNATURES

Get the number of times a variable has been inferred -- i.e. `solvedCount`.

Related

isSolved, setSolvedCount!
"""
getSolvedCount(v::VariableNodeData) = v.solvedCount
getSolvedCount(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> getSolvedCount
getSolvedCount(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = getSolvedCount(getVariable(dfg, sym), solveKey)

"""
    $SIGNATURES

Boolean on whether the variable has been solved.

Related

getSolved, setSolved!
"""
isSolved(v::VariableNodeData) = 0 < v.solvedCount
isSolved(v::VariableDataLevel2, solveKey::Symbol=:default) = getSolverData(v, solveKey) |> isSolved
isSolved(dfg::AbstractDFG, sym::Symbol, solveKey::Symbol=:default) = isSolved(getVariable(dfg, sym), solveKey)


"""
    $SIGNATURES

Update/set the `solveCount` value.

Related

getSolved, isSolved
"""
setSolvedCount!(v::VariableNodeData, val::Int) = v.solvedCount = val
setSolvedCount!(v::VariableDataLevel2, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getSolverData(v, solveKey), val)
setSolvedCount!(dfg::AbstractDFG, sym::Symbol, val::Int, solveKey::Symbol=:default) = setSolvedCount!(getVariable(dfg, sym), val, solveKey)
