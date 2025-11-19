
# TODO consider enforcing the full structure.
# This is not explicitly inforced, but surves as extra information of how the structure is put together.
# AbstractDFGNode are all nodes that make up a DFG, including Agent, Graph, Variable, Factor, Blobstore, Blobentry etc.
# abstract type AbstractDFGNode end
# any DFGNode shall have a label. 
# abstract type AbstractGraphNode end <: AbstractDFGNode
# the rest of the nodes are also AbstractDFGNodes, eg.
# Agent <: AbstractDFGNode
# Graphroot <: AbstractDFGNode

"""
$(TYPEDEF)
Abstract parent struct for DFG variables and factors.
"""
abstract type AbstractGraphNode end
const GraphNode = AbstractGraphNode

"""
$(TYPEDEF)
An abstract DFG variable.
"""
abstract type AbstractGraphVariable <: AbstractGraphNode end
const GraphVariable = AbstractGraphVariable

"""
$(TYPEDEF)
An abstract DFG factor.
"""
abstract type AbstractGraphFactor <: AbstractGraphNode end
const GraphFactor = AbstractGraphFactor

"""
$(TYPEDEF)
Abstract parent struct for a DFG graph.
"""
abstract type AbstractDFG{V <: AbstractGraphVariable, F <: AbstractGraphFactor} end
#const DFG clashes with module DFG. 

"""
$(TYPEDEF)
Abstract parent struct for solver parameters.
"""
abstract type AbstractDFGParams end
const DFGParams = AbstractDFGParams

"""
$(TYPEDEF)
Empty structure for solver parameters.
"""
struct NoSolverParams <: AbstractDFGParams end

function StructUtils.lower(::StructUtils.StructStyle, p::AbstractDFGParams)
    return StructUtils.lower(Packed(p))
end
@choosetype AbstractDFGParams resolvePackedType
