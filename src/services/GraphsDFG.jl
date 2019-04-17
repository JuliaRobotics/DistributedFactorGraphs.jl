
module GraphsJlAPI

using Graphs
using Requires
using DistributedFactorGraphs

"""
Encapsulation structure for a DFGNode (Variable or Factor) in Graphs.jl graph.
"""
mutable struct GraphsNode
    index::Int
    dfgNode::DFGNode
end
const FGType = Graphs.GenericIncidenceList{GraphsNode,Graphs.Edge{GraphsNode},Dict{Int,GraphsNode},Dict{Int,Array{Graphs.Edge{GraphsNode},1}}}

export GraphsDFG
export addVariable!
export addFactor!
export ls, lsf, getVariables, getFactors
export getVariable, getFactor
export updateVariable, updateFactor
export getAdjacencyMatrixDataFrame
export getNeighbors
export getSubgraphAroundNode
export getSubgraph
export isFullyConnected

mutable struct GraphsDFG <: AbstractDFG
    g::FGType
    description::String
    nodeCounter::Int64
    labelDict::Dict{Symbol, Int64}
    GraphsDFG() = new(Graphs.incdict(GraphsNode,is_directed=false), "Graphs.jl implementation", 0, Dict{Symbol, Int64}())
end

function addVariable!(dfg::GraphsDFG, variable::DFGVariable)::Bool
    if haskey(dfg.labelDict, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end
    dfg.nodeCounter += 1
    variable._internalId = dfg.nodeCounter
    v = GraphsNode(dfg.nodeCounter, variable)
    Graphs.add_vertex!(dfg.g, v)
    push!(dfg.labelDict, variable.label=>variable._internalId)
    return true
end

function addFactor!(dfg::GraphsDFG, factor::DFGFactor, variables::Vector{DFGVariable})::Bool
    if haskey(dfg.labelDict, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    for v in variables
        if !(v.label in keys(dfg.labelDict))
            error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
        end
    end
    dfg.nodeCounter += 1
    factor._internalId = dfg.nodeCounter
    fNode = GraphsNode(dfg.nodeCounter, factor)
    f = Graphs.add_vertex!(dfg.g, fNode)
    # Add index
    push!(dfg.labelDict, factor.label=>factor._internalId)
    # Add the edges...
    for variable in variables
        v = dfg.g.vertices[variable._internalId]
        edge = Graphs.make_edge(dfg.g, f, v)
        Graphs.add_edge!(dfg.g, edge)
    end
    return true
end

function getVariable(dfg::GraphsDFG, variableId::Int64)::DFGVariable
    @warn "This may be slow, rather use by getVariable(dfg, label)"
    #TODO: This may be slow (O(n)), can we make it better?
    if !(variableId in values(dfg.labelDict))
        error("Variable ID '$(variableId)' does not exist in the factor graph")
    end
    return dfg.g.vertices[variableId].dfgNode
end

function getVariable(dfg::GraphsDFG, label::Union{Symbol, String})::DFGVariable
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.vertices[dfg.labelDict[label]].dfgNode
end

function getFactor(dfg::GraphsDFG, factorId::Int64)::DFGFactor
    @warn "This may be slow, rather use by getFactor(dfg, label)"
    #TODO: This may be slow (O(n)), can we make it better?
    if !(factorId in values(dfg.labelDict))
        error("Factor ID '$(factorId)' does not exist in the factor graph")
    end
    return dfg.g.vertices[factorId].dfgNode
end

function getFactor(dfg::GraphsDFG, label::Union{Symbol, String})::DFGFactor
    if typeof(label) == String
        label = Symbol(label)
    end
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.vertices[dfg.labelDict[label]].dfgNode
end

function updateVariable(dfg::GraphsDFG, variable::DFGVariable)::DFGVariable
    if !haskey(dfg.labelDict, variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
    dfg.g.vertices[dfg.labelDict[variable.label]].dfgNode = variable
    return variable
end

function updateFactor(dfg::GraphsDFG, factor::DFGFactor)::DFGFactor
    if !haskey(dfg.labelDict, factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
    dfg.g.vertices[dfg.labelDict[factor.label]].dfgNode = factor
    return factor
end

function deleteVariable!(dfg::GraphsDFG, label::Symbol)::DFGVariable
    if !haskey(dfg.labelDict, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    @error "Delete is not supported in Graphs.jl implementation at present"
end

#Alias
deleteVariable!(dfg::GraphsDFG, variable::DFGVariable)::DFGVariable = deleteVariable(dfg, variable.label)

function deleteFactor!(dfg::GraphsDFG, label::Symbol)::DFGFactor
    if !haskey(dfg.labelDict, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    @error "Delete is not supported in Graphs.jl implementation at present"
end

# Alias
deleteFactor!(dfg::GraphsDFG, factor::DFGFactor)::DFGFactor = deleteFactor(dfg, factor.label)

# # Returns a flat vector of the vertices, keyed by ID.
# # Assuming only variables here for now - think maybe not, should be variables+factors?
function ls(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGVariable}
    variables = map(v -> v.dfgNode, filter(n -> typeof(n.dfgNode) == DFGVariable, collect(values(dfg.g.vertices))))
    if regexFilter != nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
    return variables
end

# Alias
getVariables(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGVariable} = ls(dfg, regexFilter)

function lsf(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor}
    factors = map(v -> v.dfgNode, filter(n -> typeof(n.dfgNode) == DFGFactor, collect(values(dfg.g.vertices))))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
    end
    return factors
end

# Alias
getFactors(dfg::GraphsDFG, regexFilter::Union{Nothing, Regex}=nothing)::Vector{DFGFactor} = lsf(dfg, regexFilter)

function isFullyConnected(dfg::GraphsDFG)::Bool
    return length(connected_components(dfg.g)) == 1
end

function getNeighbors(dfg::GraphsDFG, node::T)::Vector{Symbol}  where T <: DFGNode
    if !haskey(dfg.labelDict, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end
    vert = dfg.g.vertices[dfg.labelDict[node.label]]
    neighbors = in_neighbors(vert, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
    return map(n -> n.dfgNode.label, neighbors)
end

# Alias
function ls(dfg::GraphsDFG, node::T)::Vector{Symbol} where T <: DFGNode
    return getNeighbors(dfg, node)
end

function _copyIntoGraph!(sourceDFG::GraphsDFG, destDFG::GraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false)::Nothing
    # Split into variables and factors
    verts = map(id -> sourceDFG.g.vertices[sourceDFG.labelDict[id]], variableFactorLabels)
    sourceVariables = filter(n -> typeof(n.dfgNode) == DFGVariable, verts)
    sourceFactors = filter(n -> typeof(n.dfgNode) == DFGFactor, verts)

    # Now we have to add all variables first,
    for variable in sourceVariables
        if !haskey(destDFG.labelDict, variable.dfgNode.label)
            addVariable!(destDFG, deepcopy(variable.dfgNode))
        end
    end
    # And then all factors to the destDFG.
    for factor in sourceFactors
        if !haskey(destDFG.labelDict, factor.dfgNode.label)
            # Get the original factor variables (we need them to create it)
            variables = in_neighbors(factor, sourceDFG.g)
            # Find the labels and associated variables in our new subgraph
            factVariables = DFGVariable[]
            for variable in variables
                if haskey(destDFG.labelDict, variable.dfgNode.label)
                    push!(factVariables, getVariable(destDFG, variable.dfgNode.label))
                    #otherwise ignore
                end
            end

            # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
            if includeOrphanFactors || length(factVariables) == length(variables)
                addFactor!(destDFG, deepcopy(factor.dfgNode), factVariables)
            end
        end
    end
    return nothing
end

function getSubgraphAroundNode(dfg::GraphsDFG, node::T, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::GraphsDFG=GraphsDFG())::GraphsDFG where T <: DFGNode
    if !haskey(dfg.labelDict, node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    # Build a list of all unique neighbors inside 'distance'
    neighborList = Dict{Symbol, Any}()
    push!(neighborList, node.label => dfg.g.vertices[dfg.labelDict[node.label]])
    curList = Dict{Symbol, Any}(node.label => dfg.g.vertices[dfg.labelDict[node.label]])
    for dist in 1:distance
        newNeighbors = Dict{Symbol, Any}()
        for (key, node) in curList
            neighbors = in_neighbors(node, dfg.g) #Don't use out_neighbors! It enforces directiveness even if we don't want it
            for neighbor in neighbors
                if !haskey(neighborList, neighbor.dfgNode.label)
                    push!(neighborList, neighbor.dfgNode.label => neighbor)
                    push!(newNeighbors, neighbor.dfgNode.label => neighbor)
                end
            end
        end
        curList = newNeighbors
    end

    # Copy the section of graph we want
    _copyIntoGraph!(dfg, addToDFG, collect(keys(neighborList)), includeOrphanFactors)
    return addToDFG
end

function getSubGraph(dfg::GraphsDFG, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::GraphsDFG=GraphsDFG())::GraphsDFG
    for label in variableFactorLabels
        if !haskey(dfg.labelDict, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    _copyIntoGraph!(dfg, addToDFG, variableFactorLabels, includeOrphanFactors)
    return addToDFG
end
#


function __init__()
    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        if isdefined(Main, :DataFrames)
            export getAdjacencyMatrixDataFrame
            function getAdjacencyMatrixDataFrame(dfg::GraphsDFG)::Main.DataFrames.DataFrame
                colNames = map(n -> n.dfgNode.label, vertices(dfg.g))
                adjMat = adjacency_matrix(dfg.g)
                return Main.DataFrames.DataFrame(adjMat, colNames)
            end
        end
    end
end

end
