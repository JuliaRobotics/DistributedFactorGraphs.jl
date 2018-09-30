
const FGG = Graphs.GenericIncidenceList{Graphs.ExVertex,Graphs.Edge{Graphs.ExVertex},Array{Graphs.ExVertex,1},Array{Array{Graphs.Edge{Graphs.ExVertex},1},1}}
const FGGdict = Graphs.GenericIncidenceList{Graphs.ExVertex,Graphs.Edge{Graphs.ExVertex},Dict{Int,Graphs.ExVertex},Dict{Int,Array{Graphs.Edge{Graphs.ExVertex},1}}}



mutable struct FactorGraph
  g::FGGdict
  bn
  IDs::Dict{Symbol,Int}
  fIDs::Dict{Symbol,Int}
  id::Int
  nodeIDs::Array{Int,1} # TODO -- ordering seems improved to use adj permutation -- pending merge JuliaArchive/Graphs.jl/#225
  factorIDs::Array{Int,1}
  bnverts::Dict{Int,Graphs.ExVertex} # TODO -- not sure if this is still used, remove
  bnid::Int # TODO -- not sure if this is still used
  dimID::Int
  cg
  cgIDs::Dict{Int,Int} # cgIDs[exvid] = neoid
  sessionname::String
  robotname::String
  username::String
  reference::VoidUnion{Dict{Symbol, Tuple{Symbol, Vector{Float64}}}}
  stateless::Bool
  fifo::Vector{Symbol}
  qfl::Int # Quasi fixed length
  isfixedlag::Bool # true when adhering to qfl window size for solves
  FactorGraph() = new()
  FactorGraph(
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,
    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16
   ) = new(
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,
    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16,
    false,
    Symbol[],
    0,
    false  )
end

"""
    $(SIGNATURES)

Construct an empty FactorGraph object with the minimum amount of information / memory populated.
"""
function emptyFactorGraph(;reference::VoidUnion{Dict{Symbol, Tuple{Symbol, Vector{Float64}}}}=nothing)
    fg = FactorGraph(Graphs.incdict(Graphs.ExVertex,is_directed=false),
                     Graphs.incdict(Graphs.ExVertex,is_directed=true),
                    #  Dict{Int,Graphs.ExVertex}(),
                    #  Dict{Int,Graphs.ExVertex}(),
                     Dict{Symbol,Int}(),
                     Dict{Symbol,Int}(),
                     0,
                     [],
                     [],
                     Dict{Int,Graphs.ExVertex}(),
                     0,
                     0,
                     nothing,
                     Dict{Int,Int}(),
                     "",
                     "",
                     "",
                     reference  ) #evalPotential
    return fg
end

mutable struct VariableNodeData
  initval::Array{Float64,2} # TODO deprecate
  initstdev::Array{Float64,2} # TODO deprecate
  val::Array{Float64,2}
  bw::Array{Float64,2}
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1} # Likely deprecate
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  groundtruth::VoidUnion{ Dict{ Tuple{Symbol, Vector{Float64}} } } # not packed yet
  softtype
  initialized::Bool
  ismargin::Bool
  dontmargin::Bool
  VariableNodeData() = new()
  function VariableNodeData(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11)
    warn("Deprecated use of VariableNodeData(11 param), use 13 parameters instead")
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11, nothing, true, false, false) # TODO ensure this is initialized true is working for most cases
  end
  VariableNodeData(x1::Array{Float64,2},
                   x2::Array{Float64,2},
                   x3::Array{Float64,2},
                   x4::Array{Float64,2},
                   x5::Vector{Int},
                   x6::Vector{Int},
                   x7::Int,
                   x8::Bool,
                   x9::Int,
                   x10::Vector{Int},
                   x11::VoidUnion{ Dict{ Tuple{Symbol, Vector{Float64}} } },
                   x12,
                   x13::Bool,
                   x14::Bool,
                   x15::Bool) =
    new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15)
end

mutable struct FactorMetadata
  factoruserdata
  variableuserdata::Union{Vector, Tuple}
  variablesmalldata::Union{Vector, Tuple}
  solvefor::Union{Symbol, Void}
  variablelist::Union{Void, Vector{Symbol}}
  dbg::Bool
  FactorMetadata() = new() # [], []
  FactorMetadata(x1, x2::Union{Vector,Tuple},x3) = new(x1, x2, x3, nothing, nothing, false)
  FactorMetadata(x1, x2::Union{Vector,Tuple},x3,x4::Symbol) = new(x1, x2, x3, x4, nothing, false)
  FactorMetadata(x1, x2::Union{Vector,Tuple},x3,x4::Symbol,x5::Vector{Symbol};dbg::Bool=false) = new(x1, x2, x3, x4, x5, dbg)
end

mutable struct GenericFunctionNodeData{T, S}
  fncargvID::Array{Int,1}
  eliminated::Bool
  potentialused::Bool
  edgeIDs::Array{Int,1}
  frommodule::S #Union{Symbol, AbstractString}
  fnc::T
  multihypo::String # likely to moved when GenericWrapParam is refactored
  GenericFunctionNodeData{T, S}() where {T, S} = new{T,S}()
  GenericFunctionNodeData{T, S}(x1, x2, x3, x4, x5::S, x6::T, x7::String="") where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
  GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="") where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
  # GenericFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String) where {T, S} = new{T,S}(x1, x2, x3, x4, x5, x6, x7)
end


# where {T <: Union{InferenceType, FunctorInferenceType}}
const FunctionNodeData{T} = GenericFunctionNodeData{T, Symbol}
FunctionNodeData(x1, x2, x3, x4, x5::Symbol, x6::T, x7::String="") where {T <: Union{FunctorInferenceType, ConvolutionObject}}= GenericFunctionNodeData{T, Symbol}(x1, x2, x3, x4, x5, x6, x7)

# where {T <: PackedInferenceType}
const PackedFunctionNodeData{T} = GenericFunctionNodeData{T, <: AbstractString}
PackedFunctionNodeData(x1, x2, x3, x4, x5::S, x6::T, x7::String="") where {T <: PackedInferenceType, S <: AbstractString} = GenericFunctionNodeData(x1, x2, x3, x4, x5, x6, x7)



mutable struct PackedVariableNodeData
  vecinitval::Array{Float64,1}
  diminitval::Int
  vecinitstdev::Array{Float64,1}
  diminitdev::Int
  vecval::Array{Float64,1}
  dimval::Int
  vecbw::Array{Float64,1}
  dimbw::Int
  BayesNetOutVertIDs::Array{Int,1}
  dimIDs::Array{Int,1}
  dims::Int
  eliminated::Bool
  BayesNetVertID::Int
  separator::Array{Int,1}
  # groundtruth::NothingUnion{ Dict{ Tuple{Symbol, Vector{Float64}} } }
  softtype::String
  initialized::Bool
  ismargin::Bool
  dontmargin::Bool
  PackedVariableNodeData() = new()
  PackedVariableNodeData(x1::Vector{Float64},
                         x2::Int,
                         x3::Vector{Float64},
                         x4::Int,
                         x5::Vector{Float64},
                         x6::Int,
                         x7::Vector{Float64},
                         x8::Int,
                         x9::Vector{Int},
                         x10::Vector{Int},
                         x11::Int,
                         x12::Bool,
                         x13::Int,
                         x14::Vector{Int},
                         x15::String,
                         x16::Bool,
                         x17::Bool,
                         x18::Bool ) = new(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18)
end




function convert(::Type{PackedVariableNodeData}, d::VariableNodeData)
  return PackedVariableNodeData(d.initval[:],size(d.initval,1),
                                d.initstdev[:],size(d.initstdev,1),
                                d.val[:],size(d.val,1),
                                d.bw[:], size(d.bw,1),
                                d.BayesNetOutVertIDs,
                                d.dimIDs, d.dims, d.eliminated,
                                d.BayesNetVertID, d.separator,
                                string(d.softtype), d.initialized, d.ismargin, d.dontmargin)
end
function convert(::Type{VariableNodeData}, d::PackedVariableNodeData)

  r1 = d.diminitval
  c1 = r1 > 0 ? floor(Int,length(d.vecinitval)/r1) : 0
  M1 = reshape(d.vecinitval,r1,c1)

  r2 = d.diminitdev
  c2 = r2 > 0 ? floor(Int,length(d.vecinitstdev)/r2) : 0
  M2 = reshape(d.vecinitstdev,r2,c2)

  r3 = d.dimval
  c3 = r3 > 0 ? floor(Int,length(d.vecval)/r3) : 0
  M3 = reshape(d.vecval,r3,c3)

  r4 = d.dimbw
  c4 = r4 > 0 ? floor(Int,length(d.vecbw)/r4) : 0
  M4 = reshape(d.vecbw,r4,c4)

  # TODO -- allow out of module type allocation (future feature, not currently in use)
  st = IncrementalInference.ContinuousMultivariate # eval(parse(d.softtype))

  return VariableNodeData(M1,M2,M3,M4, d.BayesNetOutVertIDs,
    d.dimIDs, d.dims, d.eliminated, d.BayesNetVertID, d.separator,
    nothing, st, d.initialized, d.ismargin, d.dontmargin )
end



function compare(a::VariableNodeData,b::VariableNodeData)
    TP = true
    TP = TP && a.initval == b.initval
    TP = TP && a.initstdev == b.initstdev
    TP = TP && a.val == b.val
    TP = TP && a.bw == b.bw
    TP = TP && a.BayesNetOutVertIDs == b.BayesNetOutVertIDs
    TP = TP && a.dimIDs == b.dimIDs
    TP = TP && a.dims == b.dims
    TP = TP && a.eliminated == b.eliminated
    TP = TP && a.BayesNetVertID == b.BayesNetVertID
    TP = TP && a.separator == b.separator
    TP = TP && a.ismargin == b.ismargin
    return TP
end

function ==(a::VariableNodeData,b::VariableNodeData, nt::Symbol=:var)
  return IncrementalInference.compare(a,b)
end


function packmultihypo(fnc::CommonConvWrapper{T}) where {T<:FunctorInferenceType}
  fnc.hypotheses != nothing ? string(fnc.hypotheses) : ""
end
function parsemultihypostr(str::AS) where {AS <: AbstractString}
  mhcat=nothing
  if length(str) > 0
    mhcat = extractdistribution(str)
  end
  return mhcat
end


## packing converters-----------------------------------------------------------
# heavy use of multiple dispatch for converting between packed and original data types during DB usage

function convert(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T}) where {P <: PackedInferenceType, T <: FunctorInferenceType}
  # println("convert(::Type{PackedFunctionNodeData{$P}}, d::FunctionNodeData{$T})")
  warn("convert GenericWrapParam is deprecated, use CommonConvWrapper instead.")
  mhstr = packmultihypo(d.fnc)
  return PackedFunctionNodeData(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc.usrfnc!), mhstr)
end
function convert(::Type{PackedFunctionNodeData{P}}, d::FunctionNodeData{T}) where {P <: PackedInferenceType, T <: ConvolutionObject}
  # println("convert(::Type{PackedFunctionNodeData{$P}}, d::FunctionNodeData{$T})")
  mhstr = packmultihypo(d.fnc)
  return PackedFunctionNodeData(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          string(d.frommodule), convert(P, d.fnc.usrfnc!), mhstr)
end



## unpack converters------------------------------------------------------------


function convert(
            ::Type{IncrementalInference.GenericFunctionNodeData{IncrementalInference.CommonConvWrapper{F},Symbol}},
            d::IncrementalInference.GenericFunctionNodeData{P,String} ) where {F <: FunctorInferenceType, P <: PackedInferenceType}
  #
  # warn("Unpacking Option 2, F=$(F), P=$(P)")
  usrfnc = convert(F, d.fnc)
  # @show d.multihypo
  mhcat = parsemultihypostr(d.multihypo)
  # TODO store threadmodel=MutliThreaded,SingleThreaded in persistence layer
  ccw = prepgenericconvolution(Graphs.ExVertex[], usrfnc, multihypo=mhcat)
  return FunctionNodeData{CommonConvWrapper{typeof(usrfnc)}}(d.fncargvID, d.eliminated, d.potentialused, d.edgeIDs,
          Symbol(d.frommodule), ccw)
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



function convert(::Type{PT}, ::T) where {PT <: PackedInferenceType, T <:FunctorInferenceType}
  getfield(T.name.module, Symbol("Packed$(T.name.name)"))
end
function convert(::Type{T}, ::PT) where {T <: FunctorInferenceType, PT <: PackedInferenceType}
  getfield(PT.name.module, Symbol(string(PT.name.name)[7:end]))
end

function getmodule(t::T) where T
  T.name.module
end
function getname(t::T) where T
  T.name.name
end
function encodePackedType(topackdata::VariableNodeData)
  # error("IncrementalInference.encodePackedType(::VariableNodeData): Unknown packed type encoding of $(topackdata)")
  convert(IncrementalInference.PackedVariableNodeData, topackdata)
end
function encodePackedType(topackdata::GenericFunctionNodeData{CommonConvWrapper{T}, Symbol}) where {T <: FunctorInferenceType}
  # println("IncrementalInference.encodePackedType(::GenericFunctionNodeData{T,Symbol}): Unknown packed type encoding T=$(T) of $(topackdata)")
  fnctype = getfnctype(topackdata)
  fnc = getfield(getmodule(fnctype), Symbol("Packed$(getname(fnctype))"))
  convert(PackedFunctionNodeData{fnc}, topackdata)
end
function encodePackedType(topackdata::GenericFunctionNodeData{T, <:AbstractString}) where {T <: PackedInferenceType}
  error("IncrementalInference.encodePackedType(::FunctionNodeData{T, <:AbstractString}): Unknown packed type encoding T=$(T) of $(topackdata)")
  # @show T, typeof(topackdata)
  # warn("Yes, its packed!")
  # fnctype = getfnctype(topackdata)
  # @show fnc = getfield(getmodule(fnctype), Symbol("Packed$(getname(fnctype))"))
  # convert(PackedFunctionNodeData{T}, topackdata)
  topackdata
end

"""
    $(SIGNATURES)

Encode complicated function node type to related 'Packed<type>' format assuming a user supplied convert function .
"""
function convert2packedfunctionnode(fgl::FactorGraph,
                                    fsym::Symbol,
                                    api::DataLayerAPI=localapi  )
  #
  fid = fgl.fIDs[fsym]
  fnc = getfnctype(fgl, fid)
  usrtyp = convert(PackedInferenceType, fnc)
  cfnd = convert(PackedFunctionNodeData{usrtyp}, getData(fgl, fid, api=api) )
  return cfnd, usrtyp
end



# Variables
function decodePackedType(packeddata::PackedVariableNodeData,
                          typestring::String )
#TODO: typestring is unnecessary
  convert(IncrementalInference.VariableNodeData, packeddata)
end
# Factors
#TODO: typestring is unnecessary
function decodePackedType(packeddata::GenericFunctionNodeData{PT,<:AbstractString}, notused::String) where {PT}
  usrtyp = convert(FunctorInferenceType, packeddata.fnc)
  fulltype = FunctionNodeData{CommonConvWrapper{usrtyp}}
  return convert(fulltype, packeddata)
end

"""
    $(SIGNATURES)

Make a full memory copy of the graph and encode all composite function node
types -- assuming that convert methods for 'Packed<type>' formats exist.  The same converters
are used for database persistence with CloudGraphs.jl.
"""
function encodefg(fgl::FactorGraph;
      api::DataLayerAPI=localapi  )
  #
  fgs = deepcopy(fgl)
  fgs.cg = nothing
  fgs.registeredModuleFunctions = nothing
  fgs.g = Graphs.incdict(Graphs.ExVertex,is_directed=false)
  @showprogress 1 "Encoding variables..." for (vsym,vid) in fgl.IDs
    cpvert = deepcopy(getVert(fgl, vid, api=api))
    api.addvertex!(fgs, cpvert) #, labels=vnlbls)  # currently losing labels
  end

  @showprogress 1 "Encoding factors..." for (fsym,fid) in fgs.fIDs
    data,ftyp = convert2packedfunctionnode(fgl, fsym)
    # data = FunctionNodeData{ftyp}(Int[], false, false, Int[], m, gwpf)
    newvert = ExVertex(fid,string(fsym))
    for (key,val) in getVert(fgl,fid,api=api).attributes
      newvert.attributes[key] = val
    end
    ## losing fgl.fncargvID before setdata
    setData!(newvert, data)
    api.addvertex!(fgs, newvert)
  end
  fgs.g.inclist = typeof(fgl.g.inclist)()

  # iterated over all edges
  @showprogress 1 "Encoding edges..." for (eid, edges) in fgl.g.inclist
    fgs.g.inclist[eid] = Vector{typeof(edges[1])}()
    for ed in edges
      newed = Graphs.Edge(ed.index,
          fgs.g.vertices[ed.source.index],
          fgs.g.vertices[ed.target.index]  )
      push!(fgs.g.inclist[eid], newed)
    end
  end

  return fgs
end

# import IncrementalInference: decodefg, loadjld

veeCategorical(val::Categorical) = val.p
veeCategorical(val::Union{Nothing, Vector{Float64}}) = val


"""
    $(SIGNATURES)

Unpack PackedFunctionNodeData formats back to regular FunctonNodeData.
"""
function decodefg(fgs::FactorGraph; api::DataLayerAPI=localapi)
  fgu = deepcopy(fgs)
  fgu.cg = nothing # will be deprecated or replaced
  fgu.registeredModuleFunctions = nothing # TODO: obsolete
  fgu.g = Graphs.incdict(Graphs.ExVertex,is_directed=false)
  @showprogress 1 "Decoding variables..." for (vsym,vid) in fgs.IDs
    cpvert = deepcopy(getVert(fgs, vid, api=api))
    api.addvertex!(fgu, cpvert) #, labels=vnlbls)  # currently losing labels
  end

  @showprogress 1 "Decoding factors..." for (fsym,fid) in fgu.fIDs
    fdata = getData(fgs, fid)
    data = decodePackedType(fdata, "")

    # data = FunctionNodeData{ftyp}(Int[], false, false, Int[], m, gwpf)
    newvert = ExVertex(fid,string(fsym))
    for (key,val) in getVert(fgs,fid,api=api).attributes
      newvert.attributes[key] = val
    end
    setData!(newvert, data)
    api.addvertex!(fgu, newvert)
  end
  fgu.g.inclist = typeof(fgs.g.inclist)()

  # iterated over all edges
  @showprogress 1 "Decoding edges..." for (eid, edges) in fgs.g.inclist
    fgu.g.inclist[eid] = Vector{typeof(edges[1])}()
    for ed in edges
      newed = Graphs.Edge(ed.index,
          fgu.g.vertices[ed.source.index],
          fgu.g.vertices[ed.target.index]  )
      push!(fgu.g.inclist[eid], newed)
    end
  end

  # rebuild factormetadata
  @showprogress 1 "Rebuilding factor metadata..." for (fsym,fid) in fgu.fIDs
    varuserdata = []
    fcnode = getVert(fgu, fsym, nt=:fnc)
    # ccw = getData(fcnode)
    ccw_jld = deepcopy(getData(fcnode))
    allnei = Graphs.ExVertex[]
    for nei in out_neighbors(fcnode, fgu.g)
        push!(allnei, nei)
        data = IncrementalInference.getData(nei)
        push!(varuserdata, data.softtype)
    end
    setDefaultFactorNode!(fgu, fcnode, allnei, ccw_jld.fnc.usrfnc!, threadmodel=ccw_jld.fnc.threadmodel, multihypo=veeCategorical(ccw_jld.fnc.hypotheses))
    ccw_new = IncrementalInference.getData(fcnode)
    for i in 1:Threads.nthreads()
      ccw_new.fnc.cpt[i].factormetadata.variableuserdata = deepcopy(varuserdata)
    end
    ## Rebuild getData(fcnode).fncargvID, however, the list is order sensitive
    # out_neighbors does not gaurantee ordering -- i.e. why is it not being saved
    for field in fieldnames(ccw_jld)
      if field != :fnc
        setfield!(ccw_new, field, getfield(ccw_jld, field))
      end
    end
  end
  return fgu
end



function addGraphsVert!(fgl::FactorGraph,
            exvert::Graphs.ExVertex;
            labels::Vector{<:AbstractString}=String[])
  #
  Graphs.add_vertex!(fgl.g, exvert)
end

function getVertNode(fgl::FactorGraph, id::Int; nt::Symbol=:var, bigData::Bool=false)
  return fgl.g.vertices[id] # check equivalence between fgl.v/f[i] and fgl.g.vertices[i]
  # return nt == :var ? fgl.v[id] : fgl.f[id]
end
function getVertNode(fgl::FactorGraph, lbl::Symbol; nt::Symbol=:var, bigData::Bool=false)
  return getVertNode(fgl, (nt == :var ? fgl.IDs[lbl] : fgl.fIDs[lbl]), nt=nt, bigData=bigData)
end
getVertNode{T <: AbstractString}(fgl::FactorGraph, lbl::T; nt::Symbol=:var, bigData::Bool=false) = getVertNode(fgl, Symbol(lbl), nt=nt, bigData=bigData)



# excessive function, needs refactoring
function updateFullVertData!(fgl::FactorGraph,
    nv::Graphs.ExVertex;
    updateMAPest::Bool=false )
  #

  # not required, since we using reference -- placeholder function CloudGraphs interface
  # getVertNode(fgl, nv.index).attributes["data"] = nv.attributes["data"]
  nothing
end


function makeAddEdge!(fgl::FactorGraph, v1::Graphs.ExVertex, v2::Graphs.ExVertex; saveedgeID::Bool=true)
  edge = Graphs.make_edge(fgl.g, v1, v2)
  Graphs.add_edge!(fgl.g, edge)
  if saveedgeID push!(getData(v2).edgeIDs,edge.index) end #.attributes["data"]
  edge
end

function graphsOutNeighbors(fgl::FactorGraph, vert::Graphs.ExVertex; ready::Int=1,backendset::Int=1, needdata::Bool=false)
  Graphs.out_neighbors(vert, fgl.g)
end
function graphsOutNeighbors(fgl::FactorGraph, exVertId::Int; ready::Int=1,backendset::Int=1, needdata::Bool=false)
  graphsOutNeighbors(fgl.g, getVert(fgl,exVertId), ready=ready, backendset=backendset, needdata=needdata)
end

function graphsGetEdge(fgl::FactorGraph, id::Int)
  nothing
end

function graphsDeleteVertex!(fgl::FactorGraph, vert::Graphs.ExVertex)
  warn("graphsDeleteVertex! -- not deleting Graphs.jl vertex id=$(vert.index)")
  nothing
end
