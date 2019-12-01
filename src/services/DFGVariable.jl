import Base: ==, convert

function packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
    props["tags"] = JSON2.write(v.tags)
    props["estimateDict"] = JSON2.write(v.estimateDict)
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
    estimateDict = JSON2.read(packedProps["estimateDict"], Dict{Symbol, MeanMaxPPE})
    smallData = nothing
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})
    bigDataElemTypes = JSON2.read(packedProps["bigDataElemType"], Dict{Symbol, Symbol})
    bigDataIntermed = JSON2.read(packedProps["bigData"], Dict{Symbol, String})

    packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
    solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(dfg, p), values(packed)))

    # Rebuild DFGVariable using the first solver softtype in solverData
    if length(solverData) > 0
        variable = DFGVariable(Symbol(packedProps["label"]), first(solverData)[2].softtype)
    else
        @warn "The variable $label in this file does not have any solver data. This will not be supported in the future, please add at least one solverData structure."
        variable = DFGVariable(Symbol(packedProps["label"]))
    end
    variable.timestamp = timestamp
    variable.tags = tags
    variable.estimateDict = estimateDict
    variable.solverDataDict = solverData
    variable.smallData = smallData
    variable.solvable = packedProps["solvable"]

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
                                d.solveInProgress)
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
    st, d.initialized, d.inferdim, d.ismargin, d.dontmargin, d.solveInProgress)
end

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
    $(SIGNATURES)
Equality check for VariableNodeData.
"""
function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return DistributedFactorGraphs.compare(a,b)
end

"""
    ==(x::T, y::T) where T <: AbstractPointParametricEst
Equality check for AbstractPointParametricEst.
"""
@generated function ==(x::T, y::T) where T <: AbstractPointParametricEst
    mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
end

@generated function Base.:(==)(x::T, y::T) where T <: Union{DFGFactorSummary, DFGVariableSummary, SkeletonDFGVariable, SkeletonDFGFactor}
    mapreduce(n -> :(x.$n == y.$n), (a,b)->:($a && $b), fieldnames(x))
end

"""
    $(SIGNATURES)
Equality check for DFGVariable.
"""
function ==(a::DFGVariable, b::DFGVariable)::Bool
    return compareVariable(a, b)
end

"""
    $(SIGNATURES)
Convert a DFGVariable to a DFGVariableSummary.
"""
function convert(::Type{DFGVariableSummary}, v::DFGVariable)
    return DFGVariableSummary(v.label, v.timestamp, deepcopy(v.tags), deepcopy(v.estimateDict), Symbol(typeof(getSofttype(v))), v._internalId)
end

"""
    $(SIGNATURES)
Add Big Data Entry to a DFG variable
"""
function addBigDataEntry!(var::AbstractDFGVariable, bde::AbstractBigDataEntry)::AbstractDFGVariable
    haskey(var.bigData,bde.key) && @warn "$(bde.key) already exists in variable, overwriting!"
    var.bigData[bde.key] = bde
    return var
end

"""
    $(SIGNATURES)
Add Big Data Entry to distrubuted factor graph.
Should be extended if DFG variable is not returned by reference.
"""
function addBigDataEntry!(dfg::AbstractDFG, label::Symbol, bde::AbstractBigDataEntry)::AbstractDFGVariable
    return addBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Get big data entry
"""
function getBigDataEntry(var::AbstractDFGVariable, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    !haskey(var.bigData, key) && return nothing
    return var.bigData[key]
end
function getBigDataEntry(dfg::AbstractDFG, label::Symbol, key::Symbol)::Union{Nothing, AbstractBigDataEntry}
    return getBigDataEntry(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Update big data entry
"""
function updateBigDataEntry!(var::AbstractDFGVariable,  bde::AbstractBigDataEntry)::AbstractDFGVariable
    !haskey(var.bigData,bde.key) && (@error "$(bde.key) does not exist in variable!"; return false)
    var.bigData[bde.key] = bde
    return var
end
function updateBigDataEntry!(dfg::AbstractDFG, label::Symbol,  bde::AbstractBigDataEntry)::AbstractDFGVariable
    return updateBigDataEntry!(getVariable(dfg, label), bde)
end

"""
    $(SIGNATURES)
Delete big data entry
"""
function deleteBigDataEntry!(var::AbstractDFGVariable, key::Symbol)::AbstractBigDataEntry #users responsibility to delete big data in db before deleting entry
    bde = getBigDataEntry(var, key)
    delete!(var.bigData, key)
    return bde
end

function deleteBigDataEntry!(dfg::AbstractDFG, label::Symbol, key::Symbol)::AbstractBigDataEntry #users responsibility to delete big data in db before deleting entry
    deleteBigDataEntry!(getVariable(dfg, label), key)
end

"""
    $(SIGNATURES)
Get big data entries, Vector{AbstractBigDataEntry}
"""
function getBigDataEntries(var::AbstractDFGVariable)::Vector{AbstractBigDataEntry}
    #or should we return the iterator, Base.ValueIterator{Dict{Symbol,AbstractBigDataEntry}}?
    collect(values(var.bigData))
end
function getBigDataEntries(dfg::AbstractDFG, label::Symbol)::Vector{AbstractBigDataEntry}
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
function getBigDataKeys(dfg::AbstractDFG, label::Symbol)::Vector{Symbol}
    getBigDataKeys(getVariable(dfg, label))
end
