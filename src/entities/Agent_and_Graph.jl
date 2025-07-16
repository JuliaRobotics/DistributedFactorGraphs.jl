#TODO maybe mutable
@kwdef mutable struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Vector{Symbol} = Symbol[]
    metadata::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    blobEntries::OrderedDict{Symbol, Blobentry} = OrderedDict{Symbol, Blobentry}()
end

@kwdef mutable struct FactorgraphRoot
    label::Symbol = :DefaultFactorgraph
    description::String = ""
    tags::Vector{Symbol} = Symbol[]
    metadata::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    blobEntries::OrderedDict{Symbol, Blobentry} = OrderedDict{Symbol, Blobentry}()
end
