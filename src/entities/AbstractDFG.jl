
# TODO consider enforcing the full structure.
# This is not explicitly inforced, but surves as extra information of how the structure is put together.
# AbstractDFGNode are all nodes that make up a DFG, including Agent, Graph, Variable, Factor, Blobstore, etc.
# abstract type AbstractDFGNode end
# any DFGNode shall have a label. 
# abstract type AbstractGraphNode end <: AbstractDFGNode
# the rest of the nodes are also AbstractDFGNodes, eg.
# Agent <: AbstractDFGNode
# FactorgraphRoot <: AbstractDFGNode

"""
$(TYPEDEF)
Abstract parent struct for DFG variables and factors.
"""
abstract type AbstractGraphNode end #✅
const GraphNode = AbstractGraphNode

"""
$(TYPEDEF)
An abstract DFG variable.
"""
abstract type AbstractGraphVariable <: AbstractGraphNode end #✅
const GraphVariable = AbstractGraphVariable

"""
$(TYPEDEF)
An abstract DFG factor.
"""
abstract type AbstractGraphFactor <: AbstractGraphNode end #✅
const GraphFactor = AbstractGraphFactor

"""
$(TYPEDEF)
Abstract parent struct for a DFG graph.
"""
abstract type AbstractDFG{V <: AbstractGraphVariable, F <: AbstractGraphFactor} end #✅
#const DFG clashes with module DFG. 

"""
$(TYPEDEF)
Abstract parent struct for solver parameters.
"""
abstract type AbstractDFGParams end #✅
const DFGParams = AbstractDFGParams

"""
$(TYPEDEF)
Empty structure for solver parameters.
"""
@kwdef struct NoSolverParams <: AbstractDFGParams
    d::Int = 0#FIXME JSON3.jl error MethodError: no method matching read(::StructTypes.SingletonType, ...
end

StructTypes.StructType(::NoSolverParams) = StructTypes.Struct()

"""
Types valid for small data.
"""
const SmallDataTypes = Union{
    Int,
    Float64,
    String,
    Bool,
    Vector{Int},
    Vector{Float64},
    Vector{String},
    Vector{Bool},
}
