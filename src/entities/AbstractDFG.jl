# TODO consider enforcing the full structure.
# This is not explicitly enforced, but serves as extra information of how the structure is put together.
# AbstractDFGNode are all nodes that make up a DFG, including Agent, Graph, Variable, Factor, Blobprovider, Blobentry etc.
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

##==============================================================================
## AbstractDFG
##==============================================================================
##------------------------------------------------------------------------------
## Broadcasting
##------------------------------------------------------------------------------
# to allow stuff like `getObservation.(dfg, [:x1x2f1;:x10l3f2])`
# https://docs.julialang.org/en/v1/manual/interfaces/#
Base.Broadcast.broadcastable(dfg::AbstractDFG) = Ref(dfg)

# ------------------------------------------------------------------------------
# References to containers
# ------------------------------------------------------------------------------

refTags(node) = node.tags
refBlobentries(node) = node.blobentries
refBloblets(node) = node.bloblets
refSolvable(node) = node.solvable

"""
    $(SIGNATURES)
"""
function refAgents end
function refGraph end

# =============================================================================

"""
    $(SIGNATURES)
Get the label of the node.
"""
getLabel(node) = node.label

"""
$SIGNATURES

Get the timestamp of a AbstractGraphNode.
"""
getTimestamp(node) = node.timestamp

"""
    $(SIGNATURES)
"""
getDescription(node) = node.description

function Base.show(io::IO, ::MIME"text/plain", dfg::AbstractDFG)
    summary(io, dfg)
    println(io)
    println(io, "  GraphLabel: ", getGraphLabel(dfg))
    println(io, "  Description: ", getDescription(dfg))
    println(io, "  Nr variables: ", length(ls(dfg)))
    println(io, "  Nr factors: ", length(lsf(dfg)))
    println(io, "  Graph Bloblets: ", listGraphBloblets(dfg))
    println(io, "  Agents: ", listAgents(dfg))
    println(io, "  Blobproviders: ", listBlobproviders(dfg))
    return
end

# ==============================================================================
# Validation of labels.
# ==============================================================================

"""
$(SIGNATURES)

Returns true if the label is valid for node.
"""
function isValidLabel(label::Union{Symbol, String})
    validLabelRegex::Regex = r"^[a-zA-Z][\w]*$"
    return occursin(validLabelRegex, string(label))
end
