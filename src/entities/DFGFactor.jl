"""
Data stored in a factor in the factor graph.
"""
mutable struct GenericFunctionNodeData{T, S}
  fncargvID::Array{Int,1}
  eliminated::Bool
  potentialused::Bool
  edgeIDs::Vector{Int64}
  frommodule::S #Union{Symbol, AbstractString}
  fnc::T
  GenericFunctionNodeData{T, S}() where {T, S} = new()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5, x6) where {T, S} = new(x1, x2, x3, x4, x5, x6)
end

"""
A single factor comprised of data and an undirected set of edge IDs.
"""
mutable struct DFGFactor <: DFGNode
    id::Int64
    label::String
    edgeIds::Vector{Int64}
    nodeData::GenericFunctionNodeData
    DFGFactor(label::String, factorFunction::R) where {R <: Union{FunctorInferenceType, InferenceType}} = new(-1, label, Vector{Int64}(), factorFunction)
    DFGFactor(label::String, edgeIds::Vector{Int64}, factorFunction::R) where {R <: Union{FunctorInferenceType, InferenceType}} = new(-1, label, edgeIds, factorFunction)
end

FunctionNodeData{T <: Union{InferenceType, FunctorInferenceType}} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData() = GenericFunctionNodeData{T, Symbol}()
FunctionNodeData(x1, x2, x3, x4, x5, x6) = GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6)

# typealias PackedFunctionNodeData{T <: PackedInferenceType} GenericFunctionNodeData{T, AbstractString}
PackedFunctionNodeData{T <: PackedInferenceType} = GenericFunctionNodeData{T, AbstractString}
PackedFunctionNodeData() = GenericFunctionNodeData{T, AbstractString}()
PackedFunctionNodeData(x1, x2, x3, x4, x5, x6) = GenericFunctionNodeData{T, AbstractString}(x1, x2, x3, x4, x5, x6)

# heavy use of multiple dispatch for converting between packed and original data types during DB usage
function convert{T <: InferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{T}}, d::PackedFunctionNodeData{P})
  return FunctionNodeData{T}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          Symbol(d.frommodule), convert(T, d.fnc))
end
function convert{P <: PackedInferenceType, T <: InferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return PackedFunctionNodeData{P}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc))
end


# Functor version -- TODO, abstraction can be improved here
# function convert{T <: FunctorInferenceType, P <: PackedInferenceType}(::Type{FunctionNodeData{GenericWrapParam{T}}}, d::PackedFunctionNodeData{P})
#   usrfnc = convert(T, d.fnc)
#   gwpf = prepgenericwrapper(Graphs.ExVertex[], usrfnc, getSample)
#   return FunctionNodeData{GenericWrapParam{T}}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
#           Symbol(d.frommodule), gwpf) #{T}
# end
function convert{P <: PackedInferenceType, T <: FunctorInferenceType}(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T})
  return PackedFunctionNodeData{P}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc.usrfnc!))
end

# Compare FunctionNodeData
function compare{T,S}(a::GenericFunctionNodeData{T,S},b::GenericFunctionNodeData{T,S})
  # TODO -- beef up this comparison to include the gwp
  TP = true
  TP = TP && a.fncargvID == b.fncargvID
  TP = TP && a.eliminated == b.eliminated
  TP = TP && a.potentialused == b.potentialused
  TP = TP && a.edgeIDs == b.edgeIDs
  TP = TP && a.frommodule == b.frommodule
  TP = TP && typeof(a.fnc) == typeof(b.fnc)
  return TP
end

function =={T,S}(a::GenericFunctionNodeData{T,S},b::GenericFunctionNodeData{T,S}, nt::Symbol=:var)
  return IncrementalInference.compare(a,b)
end

# Find a better place for this

# function addGraphsVert!(fgl::FactorGraph,
#             exvert::Graphs.ExVertex;
#             labels::Vector{<:AbstractString}=String[])
#   #
#   Graphs.add_vertex!(fgl.g, exvert)
# end
#
# function getVertNode(fgl::FactorGraph, id::Int; nt::Symbol=:var, bigData::Bool=false)
#   return fgl.g.vertices[id] # check equivalence between fgl.v/f[i] and fgl.g.vertices[i]
#   # return nt == :var ? fgl.v[id] : fgl.f[id]
# end
# function getVertNode(fgl::FactorGraph, lbl::Symbol; nt::Symbol=:var, bigData::Bool=false)
#   return getVertNode(fgl, (nt == :var ? fgl.IDs[lbl] : fgl.fIDs[lbl]), nt=nt, bigData=bigData)
# end
# getVertNode{T <: AbstractString}(fgl::FactorGraph, lbl::T; nt::Symbol=:var, bigData::Bool=false) = getVertNode(fgl, Symbol(lbl), nt=nt, bigData=bigData)
#
#
#
# # excessive function, needs refactoring
# function updateFullVertData!(fgl::FactorGraph,
#     nv::Graphs.ExVertex;
#     updateMAPest::Bool=false )
#   #
#
#   # not required, since we using reference -- placeholder function CloudGraphs interface
#   # getVertNode(fgl, nv.index).attributes["data"] = nv.attributes["data"]
#   nothing
# end
#
#
# function makeAddEdge!(fgl::FactorGraph, v1::Graphs.ExVertex, v2::Graphs.ExVertex; saveedgeID::Bool=true)
#   edge = Graphs.make_edge(fgl.g, v1, v2)
#   Graphs.add_edge!(fgl.g, edge)
#   if saveedgeID push!(getData(v2).edgeIDs,edge.index) end #.attributes["data"]
#   edge
# end
#
# function graphsOutNeighbors(fgl::FactorGraph, vert::Graphs.ExVertex; ready::Int=1,backendset::Int=1, needdata::Bool=false)
#   Graphs.out_neighbors(vert, fgl.g)
# end
# function graphsOutNeighbors(fgl::FactorGraph, exVertId::Int; ready::Int=1,backendset::Int=1, needdata::Bool=false)
#   graphsOutNeighbors(fgl.g, getVert(fgl,exVertId), ready=ready, backendset=backendset, needdata=needdata)
# end
#
# function graphsGetEdge(fgl::FactorGraph, id::Int)
#   nothing
# end
#
# function graphsDeleteVertex!(fgl::FactorGraph, vert::Graphs.ExVertex)
#   warn("graphsDeleteVertex! -- not deleting Graphs.jl vertex id=$(vert.index)")
#   nothing
# end
