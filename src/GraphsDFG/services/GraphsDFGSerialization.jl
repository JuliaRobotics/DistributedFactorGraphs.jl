
@kwdef struct PackedGraphsDFG
    description::String
    userLabel::String
    robotLabel::String
    sessionLabel::String
    userData::Dict{Symbol, SmallDataTypes}
    robotData::Dict{Symbol, SmallDataTypes}
    sessionData::Dict{Symbol, SmallDataTypes}
    userBlobEntries::OrderedDict{Symbol, BlobEntry}
    robotBlobEntries::OrderedDict{Symbol, BlobEntry}
    sessionBlobEntries::OrderedDict{Symbol, BlobEntry}
    addHistory::Vector{Symbol}
    #TODO
    # solverParams::Dict{Symbol, Any}
    # blobStores::Dict{Symbol, AbstractBlobStore}
end

##
"""
    $(SIGNATURES)
Packing function to serialize DFG metadata from.
"""
function packDFGMetadata(fg::GraphsDFG)
    commonfields = intersect(fieldnames(PackedGraphsDFG), fieldnames(GraphsDFG))
    props = (k => getproperty(fg, k) for k in commonfields)
    return PackedGraphsDFG(;props...)
end

function unpackDFGMetadata(packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))
    props = (k => getproperty(packed, k) for k in commonfields)
    GraphsDFG(;props...)
end

function unpackDFGMetadata!(dfg::GraphsDFG, packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))
    props = (k => getproperty(packed, k) for k in commonfields)
    foreach(props) do (k,v)
        setproperty!(dfg, k, v)
    end    
    return dfg
end