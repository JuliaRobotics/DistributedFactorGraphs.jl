@kwdef struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Vector{Symbol} = Symbol[]
    metadata::Dict{Symbol, SmallDataTypes} = Dict{Symbol, SmallDataTypes}()
    blobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}()
end
