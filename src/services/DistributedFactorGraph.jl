
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

function addF!(dfg::DistributedFactorGraph, labelVariables::Vector{Symbol}, factorFunc::R)::DFGFactor where {R <: Union{FunctorInferenceType, InferenceType}}
    variables = map(label -> gtV(dfg, label), labelVariables)
    factName = _constructFactorName(dfg, labelVariables)
    f = DFGFactor(-1, factName, map(v -> v.id, variables), factorFunc)
    return f
end

function getV(vId::Int64)::DFGVariable
    return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

function getV(d::DFGAPI, vLabel::String)::DFGVariable
    _validate(dfg)
    return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

function getF(d::DFGAPI, fId::Int64)::DFGFactor
    _validate(dfg)
    return DFGFactor(fId, "x0f0", [], GenericFunctionNodeData{Int64, Symbol}())
end

function getF(d::DFGAPI, fLabel::String)::DFGFactor
    _validate(dfg)
    return DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())
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
