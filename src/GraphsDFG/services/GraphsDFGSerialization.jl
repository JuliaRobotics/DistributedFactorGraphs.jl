using InteractiveUtils

@kwdef struct PackedGraphsDFG{T<:AbstractParams}
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
    solverParams::T
    solverParams_type::String = string(typeof(solverParams))
    #TODO
    # blobStores::Dict{Symbol, AbstractBlobStore}
end

StructTypes.StructType(::Type{PackedGraphsDFG}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{PackedGraphsDFG}) = :solverParams_type
#TODO look at StructTypes.@register_struct_subtype when new StructTypes.jl is tagged (for type field)

function StructTypes.subtypes(::Type{PackedGraphsDFG}) 
    subs = subtypes(AbstractParams)
    NamedTuple(map(s->Symbol(s)=>PackedGraphsDFG{s}, subs))
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