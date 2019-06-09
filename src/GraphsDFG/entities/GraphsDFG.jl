"""
$(SIGNATURES)
Encapsulation structure for a DFGNode (Variable or Factor) in Graphs.jl graph.
"""
mutable struct GraphsNode
    index::Int
    dfgNode::DFGNode
end
const FGType = Graphs.GenericIncidenceList{GraphsNode,Graphs.Edge{GraphsNode},Dict{Int,GraphsNode},Dict{Int,Array{Graphs.Edge{GraphsNode},1}}}

"""
$(SIGNATURES)
Container for a GraphsDFG graph. Contains the in-memory graph and associated data.
"""
mutable struct GraphsDFG <: AbstractDFG
    g::FGType
    description::String
    nodeCounter::Int64
    labelDict::Dict{Symbol, Int64}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::Any # Solver parameters
end
