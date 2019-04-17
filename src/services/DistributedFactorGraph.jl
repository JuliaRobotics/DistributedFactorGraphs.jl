
function _validate(dfg::DistributedFactorGraph)::Void
    #TODO: Erm WTH? This fails with error
    # if _api == nothing
    #     error("The API is not set, please set API with setAPI() call.")
    # end
    if !dfg.api.validateConfig(dfg.api)
        error("The principal API indicated that it is not configured - please configure your API first.")
    end
    for mirror in dfg.mirrors
        if !mirror.validateConfig(mirror)
            error("The mirror API '$(string(typeof(mirror)))' indicated that it is not configured - please configure your API first.")
        end
    end
end

function getV(dfg::DistributedFactorGraph, vId::Int64)::DFGVariable
    return DFGVariable("x0")
end

function getV(dfg::DistributedFactorGraph, vLabel::String)::DFGVariable
    _validate(dfg)
    return DFGVariable(vLabel)
end

function getVs(dfg::DistributedFactorGraph, regex::String)::Vector{DFGVariable}
    _validate(dfg)
    return [DFGVariable("x0")]
end

function getF(dfg::DistributedFactorGraph, fId::Int64)::DFGFactor
    _validate(dfg)
    return DFGFactor(fId, "x0f0", [], GenericFunctionNodeData{Int64, Symbol}())
end

function getF(dfg::DistributedFactorGraph, fLabel::String)::DFGFactor
    _validate(dfg)
    return DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())
end

function getFs(dfg::DistributedFactorGraph, regex::String)::Vector{DFGFactor}
    _validate(dfg)
    return [DFGFactor("x0x1f0", [0, 1], GenericFunctionNodeData{Int64, Symbol}())]
end


function addV!(dfg::DistributedFactorGraph, v::DFGVariable)::DFGVariable
    _validate(dfg)
    # Principal
    v = dfg.api.addV!(dfg.api, v)
    # Mirrors #TODO Consider async call here.
    map(api -> api.addV!(api, v), dfg.mirrors)
    return v
end

function addV!(dfg::DistributedFactorGraph, label::Symbol, softtype::T)::DFGVariable where {T <: DistributedFactorGraphs.InferenceVariable}
    _validate(dfg)

    v = DFGVariable(String(label))
    v.nodeData.softtype = softtype
    v = addV!(dfg, v)
    return v
end

"""
Constructs x0x1f1 from [x0; x1] and check for duplicates.
"""
function _constructFactorName(dfg::DistributedFactorGraph, labelVariables::Vector{Symbol})::String
    factorName = join(map(label -> String(label), labelVariables))*"f"
    # Get the maximum prioir number e.g. f5 using efficient call to get all factor summaries.
    duplicates = getFs(dfg, "($factorName[0-9]+)")
    newVal = length(duplicates) > 0 ? 0 : maximum(map(f -> parse(Int, replace(f.label, factorName, "")), duplicates)) + 1
    return "$factorName$newVal"
end

function addF!(dfg::DistributedFactorGraph, f::DFGFactor)::DFGFactor
    _validate(dfg)
    # Principal
    f = dfg.api.addF!(dfg.api, f)
    # Mirrors #TODO Consider async call here.
    map(api -> api.addF!(api, f), dfg.mirrors)
    return f
end

function parseusermultihypo(multihypo::Union{Tuple,Vector{Float64}})
  mh = nothing
  if multihypo != nothing
    multihypo2 = Float64[multihypo...]
    # verts = Symbol.(multihypo[1,:])
    for i in 1:length(multihypo)
      if multihypo[i] > 0.999999
        multihypo2[i] = 0.0
      end
    end
    mh = Categorical(Float64[multihypo2...] )
  end
  return mh
end

function addF!(
        dfg::DistributedFactorGraph,
        labelVariables::Vector{Symbol},
        factorFunc::R;
        multihypo::Union{Nothing,Tuple,Vector{Float64}}=nothing)::DFGFactor
        where {R <: Union{FunctorInferenceType, InferenceType}}
    variables = map(label -> getV(dfg, String(label)), labelVariables)
    factName = _constructFactorName(dfg, labelVariables)

    # Create the FunctionNodeData
    ftyp = typeof(factorFunc) # maybe this can be T
    # @show "setDefaultFactorNode!", usrfnc, ftyp, T
    mhcat = parseusermultihypo(multihypo)
    # gwpf = prepgenericwrapper(Xi, usrfnc, getSample, multihypo=mhcat)
    ccw = prepgenericconvolution(Xi, usrfnc, multihypo=mhcat, threadmodel=threadmodel)

    m = Symbol(ftyp.name.module)

    # experimental wip
    data_ccw = FunctionNodeData{CommonConvWrapper{T}}(Int[], false, false, Int[], m, ccw)

    f = DFGFactor(-1, factName, map(v -> v.id, variables), data_ccw)
    return f
end

function updateV!(d::DFGAPI, v::DFGVariable)::DFGVariable
    _validate(dfg)
    return v
end

function updateF!(d::DFGAPI, f::DFGFactor)::DFGFactor
    _validate(dfg)
    return f
end

function deleteV!(d::DFGAPI, vId::Int64)::DFGVariable
    _validate(dfg)
    return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
end
function deleteV!(d::DFGAPI, vLabel::String)::DFGVariable
    _validate(dfg)
    return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
end
function deleteV!(d::DFGAPI, v::DFGVariable)::DFGVariable
    _validate(dfg)
    return v
end

function deleteF!(d::DFGAPI, fId::Int64)::DFGFactor
    _validate(dfg)
    return DFGFactor(fId, "x0f0", [0], GenericFunctionNodeData{Int64, Symbol}())
end
function deleteF!(d::DFGAPI, fLabel::String)::DFGFactor
    _validate(dfg)
    return DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())
end
function deleteF!(d::DFGAPI, f::DFGFactor)::DFGFactor
    _validate(dfg)
    return f
end

# Are we going to return variables related to this variable? TODO: Confirm
function neighbors(d::DFGAPI, v::DFGVariable)::Dict{String, DFGVariable}
    _validate(dfg)
    return Dict{String, DFGVariable}()
end

# Returns a flat dictionary of the vertices, keyed by ID.
# Assuming only variables here for now - think maybe not, should be variables+factors?
function ls(d::DFGAPI)::Dict{Int64, DFGVariable}
    _validate(dfg)
    return Dict{Int64, DFGVariable}()
end

# Returns a flat dictionary of the vertices around v, keyed by ID.
# Assuming only variables here for now - think maybe not, should be variables+factors?
function ls(d::DFGAPI, v::DFGVariable, variableDistance=1)::Dict{Int64, DFGVariable}
    _validate(dfg)
    return Dict{Int64, DFGVariable}()
end

# Returns a flat dictionary of the vertices around v, keyed by ID.
# Assuming only variables here for now - think maybe not, should be variables+factors?
function ls(d::DFGAPI, vId::Int64, variableDistance=1)::Dict{Int64, DFGVariable}
    _validate(dfg)
    return Dict{Int64, DFGVariable}()
end

function subGraph(d::DFGAPI, vIds::Vector{Int64})::Dict{Int64, DFGVariable}
    _validate(dfg)
    return Dict{Int64, DFGVariable}()
end

function adjacencyMatrix(d::DFGAPI)::Matrix{DFGNode}
    _validate(dfg)
    return Matrix{DFGNode}(0,0)
end
