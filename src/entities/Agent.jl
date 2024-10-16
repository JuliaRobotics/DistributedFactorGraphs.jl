struct Agent
    label::String
    description::String
    tags::Vector{String}
    metadata::Dict{Symbol, SmallDataTypes}
    blobEntries::OrderedDict{Symbol, BlobEntry}
end
