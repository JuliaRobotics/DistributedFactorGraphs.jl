
"""
    $(SIGNATURES)
Abstract parent struct for DFG variables and factors.
"""
abstract type DFGNode
end

"""
    $(SIGNATURES)
Abstract parent struct for a DFG graph.
"""
abstract type AbstractDFG
end

abstract type AbstractParams end

mutable struct NoSolverParams <: AbstractParams
end
