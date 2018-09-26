
function addV!(d::DFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function addF!(d::DFGAPI, f::DFGFactor)::DFGVariable
    return f
end

function getV(d::DFGAPI, vId::Int64)::DFGVariable
    return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

# How do I use overloaded functions?
function getV(d::DFGAPI, vLabel::String)::DFGVariable
    return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
end

function getF(d::DFGAPI, fId::Int64)::DFGFactor
    return DFGFactor(fId, "x0f0", GenericFunctionNodeData())
end

# How do I use this?
function getF(d::DFGAPI, fLabel::String)::DFGFactor
    return DFGFactor(1, fLabel, [0], GenericFunctionNodeData())
end

function updateV!(d::DFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function updateF!(d::DFGAPI, f::DFGFactor)::DFGFactor
    return f
end

function deleteV!(d::DFGAPI, vId::Int64)::DFGVariable
    return v
end
function deleteV!(d::DFGAPI, vLabel::String)::DFGVariable
    return v
end
function deleteV!(d::DFGAPI, v::DFGVariable)::DFGVariable
    return v
end

function deleteF!(d::DFGAPI, fId::Int64)::DFGFactor
    return f
end
function deleteF!(d::DFGAPI, fLabel::String)::DFGFactor
    return f
end
function deleteF!(d::DFGAPI, f::DFGFactor)::DFGFactor
    return f
end

# Are we going to return variables related to this variable? TODO: Confirm
function neighbors(d::DFGAPI, v::DFGVariable)::Dict{String, DFGVariable}
    return Dict{String, DFGVariable}()
end

# Returns a flat dictionary of the vertices, keyed by ID.
# Assuming only variables here - think maybe not, should be variables+factors?
function ls(d::DFGAPI, v::DFGVariable)::Dict{Int64, DFGVariable}
    return Dict{String, DFGVariable}()
end

function subGraph(d::DFGAPI, v::DFGVariable)::Dict{Int64, DFGNode}
    return Dict{Int64, DFGNode}()
end

function adjacencyMatrix(d::DFGAPI)::Matrix{DFGNode}()
    return Matrix{DFGNode}(0,0)
end
