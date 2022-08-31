# Very simple initial sentinel structure for Graff elements in DFG.
# TODO: Need to flesh out further in next release.

export User, Robot, Session

abstract type AbstractCGNode
end

mutable struct User <: AbstractCGNode
    id::Symbol
    name::String
    description::String
    data::Dict{Symbol, String}
    createdTimestamp::String
    lastUpdatedTimestamp::String
    User(id::Symbol,
          name::String,
          description::String,
          data::Dict{Symbol, String},
          createdTimestamp::String=string(now(UTC)),
          lastUpdatedTimestamp::String=string(now(UTC))) =
          new(id, name, description, data, createdTimestamp, lastUpdatedTimestamp)
end

mutable struct Robot <: AbstractCGNode
    id::Symbol
    userId::Symbol
    name::String
    description::String
    data::Dict{Symbol, String}
    createdTimestamp::String
    lastUpdatedTimestamp::String
    Robot(id::Symbol,
          userId::Symbol,
          name::String,
          description::String,
          data::Dict{Symbol, String},
          createdTimestamp::String=string(now(UTC)),
          lastUpdatedTimestamp::String=string(now(UTC))) =
          new(id, userId, name, description, data, createdTimestamp, lastUpdatedTimestamp)
end

mutable struct Session <: AbstractCGNode
    id::Symbol
    robotId::Symbol
    userId::Symbol
    name::String
    description::String
    data::Dict{Symbol, String}
    createdTimestamp::String
    lastUpdatedTimestamp::String
    Session(id::Symbol,
          robotId::Symbol,
          userId::Symbol,
          name::String,
          description::String,
          data::Dict{Symbol, String},
          createdTimestamp::String=string(now(UTC)),
          lastUpdatedTimestamp::String=string(now(UTC))) =
          new(id, robotId,userId, name, description, data, createdTimestamp, lastUpdatedTimestamp)

end
