@kwdef struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Vector{Symbol} = Symbol[]
    metadata::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    blobEntries::OrderedDict{Symbol, Blobentry} = OrderedDict{Symbol, Blobentry}()
end
