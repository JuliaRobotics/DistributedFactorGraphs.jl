
"""
    $(SIGNATURES)
Abstract parent struct for DFG variables and factors.
"""
abstract type DFGNode
end

"""
    $(SIGNATURES)
An abstract DFG variable.
"""
abstract type AbstractDFGVariable <: DFGNode
end

"""
    $(SIGNATURES)
An abstract DFG factor.
"""
abstract type AbstractDFGFactor <: DFGNode
end

"""
    $(SIGNATURES)
Abstract parent struct for a DFG graph.
"""
abstract type AbstractDFG
end

"""
    $(SIGNATURES)
Abstract parent struct for solver parameters.
"""
abstract type AbstractParams end

"""
    $(SIGNATURES)
Empty structure for solver parameters.
"""
mutable struct NoSolverParams <: AbstractParams
end

"""
    $(TYPEDEF)
Abstract parent struct for big data entry.
"""
abstract type AbstractBigDataEntry end
