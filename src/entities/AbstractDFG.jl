
"""
$(TYPEDEF)
Abstract parent struct for DFG variables and factors.
"""
abstract type DFGNode
end

"""
$(TYPEDEF)
An abstract DFG variable.
"""
abstract type AbstractDFGVariable <: DFGNode
end

"""
$(TYPEDEF)
An abstract DFG factor.
"""
abstract type AbstractDFGFactor <: DFGNode
end

"""
$(TYPEDEF)
The common node parameters for variables and factors.
"""
mutable struct DFGNodeParams
    solvable::Int
    _internalId::Int64
    DFGNodeParams() = new(0, 0)
    DFGNodeParams(solvable::Int, _internalId::Int64) = new(solvable, _internalId)
end

"""
$(TYPEDEF)
Abstract parent struct for a DFG graph.
"""
abstract type AbstractDFG
end

"""
$(TYPEDEF)
Abstract parent struct for solver parameters.
"""
abstract type AbstractParams end

"""
$(TYPEDEF)
Empty structure for solver parameters.
"""
struct NoSolverParams <: AbstractParams
end

"""
$(TYPEDEF)
Abstract parent struct for big data entry.
"""
abstract type AbstractBigDataEntry end
