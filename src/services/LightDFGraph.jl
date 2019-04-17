module GraphsJlAPI
    using MetaGraphs
    using DistributedFactorGraphs
    using Base.show

    """
    Initialize the state of the system
    """
    function initConfiguration(configSettings::Any)::AbstractGraph
        return simple_graph(0)
    end

    function addV!(d::DFGAPI, v::DFGVariable)::DFGVariable
        info(" - Adding variable in Graphs.jl...")
        return v
    end

    function addF!(d::DFGAPI, f::DFGFactor)::DFGFactor
        return f
    end

    function getV(d::DFGAPI, vId::Int64)::DFGVariable
        return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
    end

    function getV(d::DFGAPI, vLabel::Symbol)::DFGVariable
        return getV(d, String(vLabel))
    end

    function getV(d::DFGAPI, vLabel::String)::DFGVariable
        return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
    end

    function getVs(d::DFGAPI, regExp::String; onlySummary=true)::Vector{DFGVariable}
        return [DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())]
    end

    function getF(d::DFGAPI, fId::Int64)::DFGFactor
        return DFGFactor(fId, "x0f0", [], GenericFunctionNodeData{Int64, Symbol}())
    end

    # How do I use this?
    function getF(d::DFGAPI, fLabel::String)::DFGFactor
        return DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())
    end

    function getFs(d::DFGAPI, regExp::String; onlySummary=true)::Vector{DFGFactor}
        return [DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())]
    end

    function updateV!(d::DFGAPI, v::DFGVariable)::DFGVariable
        return v
    end

    function updateF!(d::DFGAPI, f::DFGFactor)::DFGFactor
        return f
    end

    function deleteV!(d::DFGAPI, vId::Int64)::DFGVariable
        return DFGVariable(vId, "x0", VariableNodeData(), Vector{String}(), Dict{String, Any}())
    end
    function deleteV!(d::DFGAPI, vLabel::String)::DFGVariable
        return DFGVariable(0, vLabel, VariableNodeData(), Vector{String}(), Dict{String, Any}())
    end
    function deleteV!(d::DFGAPI, v::DFGVariable)::DFGVariable
        return v
    end

    function deleteF!(d::DFGAPI, fId::Int64)::DFGFactor
        return DFGFactor(fId, "x0f0", [0], GenericFunctionNodeData{Int64, Symbol}())
    end
    function deleteF!(d::DFGAPI, fLabel::String)::DFGFactor
        return DFGFactor(1, fLabel, [0], GenericFunctionNodeData{Int64, Symbol}())
    end
    function deleteF!(d::DFGAPI, f::DFGFactor)::DFGFactor
        return f
    end

    # Are we going to return variables related to this variable? TODO: Confirm
    function neighbors(d::DFGAPI, v::DFGVariable)::Dict{String, DFGVariable}
        return Dict{String, DFGVariable}()
    end

    # Returns a flat dictionary of the vertices, keyed by ID.
    # Assuming only variables here for now - think maybe not, should be variables+factors?
    function ls(d::DFGAPI)::Dict{Int64, DFGVariable}
        return Dict{Int64, DFGVariable}()
    end

    # Returns a flat dictionary of the vertices around v, keyed by ID.
    # Assuming only variables here for now - think maybe not, should be variables+factors?
    function ls(d::DFGAPI, v::DFGVariable, variableDistance=1)::Dict{Int64, DFGVariable}
        return Dict{Int64, DFGVariable}()
    end

    # Returns a flat dictionary of the vertices around v, keyed by ID.
    # Assuming only variables here for now - think maybe not, should be variables+factors?
    function ls(d::DFGAPI, vId::Int64, variableDistance=1)::Dict{Int64, DFGVariable}
        return Dict{Int64, DFGVariable}()
    end

    function subGraph(d::DFGAPI, vIds::Vector{Int64})::Dict{Int64, DFGVariable}
        return Dict{Int64, DFGVariable}()
    end

    function adjacencyMatrix(d::DFGAPI)::Matrix{DFGNode}
        return Matrix{DFGNode}(0,0)
    end

    function getAPI()::DFGAPI
        graphsJlAPI = DFGAPI(
            initConfiguration(nothing),
            "In-memory Graphs.jl-based API for Distributed Factor Graphs",
            dfgApi -> dfgApi.configuration != nothing,
            GraphsJlAPI.addV!,
            GraphsJlAPI.addF!,
            GraphsJlAPI.getV,
            GraphsJlAPI.getVs,
            GraphsJlAPI.getF,
            GraphsJlAPI.getFs,
            GraphsJlAPI.updateV!,
            GraphsJlAPI.updateF!,
            GraphsJlAPI.deleteV!,
            GraphsJlAPI.deleteF!,
            GraphsJlAPI.neighbors,
            GraphsJlAPI.ls,
            GraphsJlAPI.subGraph,
            GraphsJlAPI.adjacencyMatrix,
            Dict{String, Any}()
        )
    end
end
