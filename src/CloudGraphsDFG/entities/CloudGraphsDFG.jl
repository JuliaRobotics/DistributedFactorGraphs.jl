mutable struct Neo4jInstance
  connection::Neo4j.Connection
  graph::Neo4j.Graph
end

mutable struct CloudGraphsDFG <: AbstractDFG
    neo4jInstance::Neo4jInstance
    description::String
    userId::String
    robotId::String
    sessionId::String
    encodePackedTypeFunc
    getPackedTypeFunc
    decodePackedTypeFunc
    labelDict::Dict{Symbol, Int64}
    variableCache::Dict{Symbol, DFGVariable}
    factorCache::Dict{Symbol, DFGFactor}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::Any # Solver parameters
end
