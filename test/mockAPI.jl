
function addV!(d::AFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function addF!(d::AFGAPI, f::DFGFactor)::DFGVariable
    return f
end

function getV(d::AFGAPI, vId::Int64)::DFGVariable
    return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

# How do I use this?
function getV(d::AFGAPI, vLabel::String)::DFGVariable
    return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

function getF(d::AFGAPI, fId::Int64)::DFGFactor
    return DFGFactor(fId, "x0f0", GenericFunctionNodeData())
end

# How do I use this?
function getF(d::AFGAPI, fLabel::String)::DFGFactor
    return DFGFactor(1, fLabel, [0], GenericFunctionNodeData())
end

function updateV!(d::AFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function updateF!(d::AFGAPI, f::DFGFactor)::DFGFactor
    return f
end

function deleteV!(d::AFGAPI, vId::Int64)::DFGVariable
    return v
end
function deleteV!(d::AFGAPI, vLabel::String)::DFGVariable
    return v
end
function deleteV!(d::AFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function deleteF!(d::AFGAPI, fId::Int64)::DFGFactor
    return f
end
function deleteF!(d::AFGAPI, fLabel::String)::DFGFactor
    return f
end
function deleteF!(d::AFGAPI, f::DFGFactor)::DFGFactor
    return f
end

# Are we going to return variables related to this variable? TODO: Confirm
function neighbors(d::AFGAPI, v::DFGVariable)::Dict{String, DFGVariable}
    return Dict{String, DFGVariable}()
end

# function ls(d::AFGAPI, v::DFGVariable)::Dict{String, DFGVariable}
#     return Dict{String, DFGVariable}()
# end
