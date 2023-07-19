
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
Abstract parent struct for solver parameters.
"""
abstract type AbstractParams end

"""
$(TYPEDEF)
Abstract parent struct for a DFG graph.
    """
abstract type AbstractDFG{T<:AbstractParams} end

"""
$(TYPEDEF)
Empty structure for solver parameters.
"""
@kwdef struct NoSolverParams <: AbstractParams
    d::Int = 0#FIXME JSON3.jl error MethodError: no method matching read(::StructTypes.SingletonType, ...
end

StructTypes.StructType(::NoSolverParams) = StructTypes.Struct()

"""
Types valid for small data.
"""
const SmallDataTypes = Union{Int, Float64, String, Bool, Vector{Int}, Vector{Float64}, Vector{String}, Vector{Bool}}
