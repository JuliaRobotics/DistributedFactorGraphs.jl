# Very simple initial sentinel structure for Graff elements in DFG.
# TODO: Need to flesh out further in next release.

export User, Robot, Session

abstract type AbstractCGNode
end

mutable struct User <: AbstractCGNode
    id::Symbol
    name::String
    description::String
    # labels::Vector{Symbol}
    data::Dict{Symbol, String}
end

mutable struct Robot <: AbstractCGNode
    id::Symbol
    userId::Symbol
    name::String
    description::String
    # labels::Vector{Symbol}
    data::Dict{Symbol, String}
end

mutable struct Session <: AbstractCGNode
    id::Symbol
    robotId::Symbol
    userId::Symbol
    name::String
    description::String
    # labels::Vector{Symbol}
    data::Dict{Symbol, String}
end
