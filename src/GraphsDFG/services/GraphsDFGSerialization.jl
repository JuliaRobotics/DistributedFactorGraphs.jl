using InteractiveUtils

@kwdef struct PackedGraphsDFG{T <: AbstractParams}
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
    solverParams_type::String = string(nameof(typeof(solverParams)))
    # TODO remove Union.Nothing in DFG v0.24
    typePackedVariable::Union{Nothing, Bool} = false # Are variables packed or full
    typePackedFactor::Union{Nothing, Bool} = false # Are factors packed or full
    blobStores::Union{Nothing, Dict{Symbol, FolderStore{Vector{UInt8}}}}
end

StructTypes.StructType(::Type{PackedGraphsDFG}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{PackedGraphsDFG}) = :solverParams_type
#TODO look at StructTypes.@register_struct_subtype when new StructTypes.jl is tagged (for type field)

function StructTypes.subtypes(::Type{PackedGraphsDFG})
    subs = subtypes(AbstractParams)
    return NamedTuple(map(s -> nameof(s) => PackedGraphsDFG{s}, subs))
end

_variablestype(fg::GraphsDFG{<:AbstractParams, T, <:AbstractDFGFactor}) where {T} = T
_factorstype(fg::GraphsDFG{<:AbstractParams, <:AbstractDFGVariable, T}) where {T} = T

##
"""
    $(SIGNATURES)
Packing function to serialize DFG metadata from.
"""
function packDFGMetadata(fg::GraphsDFG)
    commonfields = intersect(fieldnames(PackedGraphsDFG), fieldnames(GraphsDFG))

    setdiff!(commonfields, [:blobStores])
    blobStores = Dict{Symbol, FolderStore{Vector{UInt8}}}()
    foreach(values(fg.blobStores)) do store
        if store isa FolderStore{Vector{UInt8}}
            blobStores[store.key] = store
        else
            @warn "BlobStore $(store.key) of type $(typeof(store)) is not supported yet and will not be saved"
        end
    end

    props = (k => getproperty(fg, k) for k in commonfields)
    return PackedGraphsDFG(;
        typePackedVariable = _variablestype(fg) == Variable,
        typePackedFactor = _factorstype(fg) == PackedFactor,
        blobStores,
        props...,
    )
end

function unpackDFGMetadata(packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    #FIXME Deprecate remove in DFG v0.24
    setdiff!(commonfields, [:blobStores])
    blobStores = Dict{Symbol, AbstractBlobStore}()

    !isnothing(packed.blobStores) && merge!(blobStores, packed.blobStores)

    _isfolderstorepath(s) = false
    _isfolderstorepath(s::FolderStore) = ispath(s.folder)
    # FIXME escalate to keyword
    for (ks, bs) in blobStores
        if !_isfolderstorepath(bs)
            delete!(blobStores, ks)
            @warn("Unable to load blobstore, $ks")
        end
    end

    props = (k => getproperty(packed, k) for k in commonfields)

    VT = if isnothing(packed.typePackedVariable) || !packed.typePackedVariable
        DFGVariable
    else
        Variable
    end
    FT = if isnothing(packed.typePackedFactor) || !packed.typePackedFactor
        DFGFactor
    else
        PackedFactor
    end
    # VT = isnothing(packed.typePackedVariable) || packed.typePackedVariable ? Variable : DFGVariable 
    # FT = isnothing(packed.typePackedFactor) || packed.typePackedFactor ? PackedFactor : DFGFactor
    return GraphsDFG{typeof(packed.solverParams), VT, FT}(; blobStores, props...)
end

function unpackDFGMetadata!(dfg::GraphsDFG, packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    #FIXME Deprecate remove Nothing union in DFG v0.24
    setdiff!(commonfields, [:blobStores])
    !isnothing(packed.blobStores) && merge!(dfg.blobStores, packed.blobStores)

    props = (k => getproperty(packed, k) for k in commonfields)
    foreach(props) do (k, v)
        return setproperty!(dfg, k, v)
    end
    return dfg
end
