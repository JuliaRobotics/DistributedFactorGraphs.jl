using InteractiveUtils

@kwdef struct PackedGraphsDFG{T <: AbstractParams}
    description::String
    addHistory::Vector{Symbol}
    solverParams::T
    solverParams_type::String = string(nameof(typeof(solverParams)))
    typePackedVariable::Bool = false # Are variables packed or full
    typePackedFactor::Bool = false # Are factors packed or full
    blobStores::Union{Nothing, Dict{Symbol, FolderStore{Vector{UInt8}}}}
    graphLabel::Symbol
    graphTags::Vector{Symbol}
    graphMetadata::Dict{Symbol, SmallDataTypes}
    graphBlobEntries::OrderedDict{Symbol, Blobentry}
    agent::Agent
end

StructTypes.StructType(::Type{PackedGraphsDFG}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{PackedGraphsDFG}) = :solverParams_type
#TODO look at StructTypes.@register_struct_subtype when new StructTypes.jl is tagged (for type field)

function StructTypes.subtypes(::Type{PackedGraphsDFG})
    subs = subtypes(AbstractParams)
    return NamedTuple(map(s -> nameof(s) => PackedGraphsDFG{s}, subs))
end

getTypeDFGVariables(fg::GraphsDFG{<:AbstractParams, T, <:AbstractDFGFactor}) where {T} = T
getTypeDFGFactors(fg::GraphsDFG{<:AbstractParams, <:AbstractDFGVariable, T}) where {T} = T

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
            blobStores[getLabel(store)] = store
        else
            @warn "Blobstore $(getLabel(store)) of type $(typeof(store)) is not supported yet and will not be saved"
        end
    end

    props = (k => getproperty(fg, k) for k in commonfields)
    return PackedGraphsDFG(;
        typePackedVariable = getTypeDFGVariables(fg) == VariableDFG,
        typePackedFactor = getTypeDFGFactors(fg) == FactorDFG,
        blobStores,
        props...,
    )
end

function unpackDFGMetadata(packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    setdiff!(commonfields, [:blobStores])
    blobStores = packed.blobStores

    #TODO add 'CanSerialize' trait to blobstores and also serialize NvaBlobStores
    _isfolderstorepath(s) = false
    _isfolderstorepath(s::FolderStore) = ispath(s.folder)
    # FIXME escalate to keyword
    for (ks, bs) in blobStores
        if !_isfolderstorepath(bs)
            delete!(blobStores, ks)
            @warn("Unable to load blobstore, $ks from $(bs.folder)")
        end
    end

    props = (k => getproperty(packed, k) for k in commonfields)

    VT = if isnothing(packed.typePackedVariable) || !packed.typePackedVariable
        VariableCompute
    else
        VariableDFG
    end
    FT = if isnothing(packed.typePackedFactor) || !packed.typePackedFactor
        FactorCompute
    else
        FactorDFG
    end
    # VT = isnothing(packed.typePackedVariable) || packed.typePackedVariable ? Variable : VariableCompute 
    # FT = isnothing(packed.typePackedFactor) || packed.typePackedFactor ? FactorDFG : FactorCompute

    props = filter!(collect(props)) do (k, v)
        return !isnothing(v)
    end

    return GraphsDFG{typeof(packed.solverParams), VT, FT}(; blobStores, props...)
end

function unpackDFGMetadata!(dfg::GraphsDFG, packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    setdiff!(commonfields, [:blobStores])
    !isnothing(packed.blobStores) && merge!(dfg.blobStores, packed.blobStores)

    props = (k => getproperty(packed, k) for k in commonfields)
    foreach(props) do (k, v)
        return setproperty!(dfg, k, v)
    end
    return dfg
end
