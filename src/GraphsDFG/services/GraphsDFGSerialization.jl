using InteractiveUtils

@kwdef struct PackedGraphsDFG{T <: AbstractParams}
    description::String
    # ------ deprecated fields v0.25 ---------
    userLabel::Union{Nothing, String} = nothing
    robotLabel::Union{Nothing, String} = nothing
    sessionLabel::Union{Nothing, String} = nothing
    userData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing
    robotData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing
    sessionData::Union{Nothing, Dict{Symbol, SmallDataTypes}} = nothing
    userBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing
    robotBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing
    sessionBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}} = nothing
    # ---------------------------------
    addHistory::Vector{Symbol}
    solverParams::T
    solverParams_type::String = string(nameof(typeof(solverParams)))
    typePackedVariable::Bool = false # Are variables packed or full
    typePackedFactor::Bool = false # Are factors packed or full
    blobStores::Union{Nothing, Dict{Symbol, FolderStore{Vector{UInt8}}}}

    # new structure to replace URS
    #TODO remove union nothing after v0.25
    graphLabel::Union{Nothing, Symbol}
    graphTags::Union{Nothing, Vector{Symbol}}
    graphMetadata::Union{Nothing, Dict{Symbol, SmallDataTypes}}
    graphBlobEntries::Union{Nothing, OrderedDict{Symbol, BlobEntry}}
    agent::Union{Nothing, Agent}
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

    setdiff!(commonfields, [deprecatedDfgFields; :blobStores])
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
        typePackedVariable = getTypeDFGVariables(fg) == Variable,
        typePackedFactor = getTypeDFGFactors(fg) == PackedFactor,
        blobStores,
        props...,
    )
end

function unpackDFGMetadata(packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    #FIXME Deprecate remove in DFG v0.24
    # setdiff!(commonfields, [:blobStores])
    # blobStores = Dict{Symbol, AbstractBlobStore}()
    # !isnothing(packed.blobStores) && merge!(blobStores, packed.blobStores)

    setdiff!(commonfields, [deprecatedDfgFields; :blobStores])
    blobStores = packed.blobStores

    if isnothing(packed.agent)
        agentBlobEntries = nothing
        agentMetadata = nothing
        agentLabel = nothing
        graphBlobEntries = nothing
        graphMetadata = nothing
        graphLabel = nothing

        for f in deprecatedDfgFields
            if !isnothing(getproperty(packed, f))
                if f == :robotBlobEntries
                    agentBlobEntries = getproperty(packed, f)
                    @warn "Converting deprecated $f to agentBlobEntries"
                elseif f == :robotData
                    agentMetadata = getproperty(packed, f)
                    @warn "Converting deprecated $f to agentMetadata"
                elseif f == :robotLabel
                    agentLabel = Symbol(getproperty(packed, f))
                    @warn "Converting deprecated $f to agentLabel"
                elseif f == :sessionBlobEntries
                    graphBlobEntries = getproperty(packed, f)
                    @warn "Converting deprecated $f to graphBlobEntries"
                elseif f == :sessionData
                    graphMetadata = getproperty(packed, f)
                    @warn "onverting deprecated $f to graphMetadata"
                elseif f == :sessionLabel
                    graphLabel = Symbol(getproperty(packed, f))
                    @warn "Converting deprecated $f to graphLabel"
                else
                    @warn """
                    Field $f is deprecated as part of removing user/robot/session. Replace with Agent or Factorgraph [Label/Metadata/BlobEntries]
                        No conversion done for $f
                    """
                end
            end
        end

        agent = Agent(;
            label = agentLabel,
            blobEntries = agentBlobEntries,
            metadata = agentMetadata,
        )
    else
        agent = packed.agent
        graphBlobEntries = packed.graphBlobEntries
        graphMetadata = packed.graphMetadata
        graphLabel = packed.graphLabel
    end

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
        Variable
    end
    FT = if isnothing(packed.typePackedFactor) || !packed.typePackedFactor
        DFGFactor
    else
        PackedFactor
    end
    # VT = isnothing(packed.typePackedVariable) || packed.typePackedVariable ? Variable : VariableCompute 
    # FT = isnothing(packed.typePackedFactor) || packed.typePackedFactor ? PackedFactor : DFGFactor

    props = filter!(collect(props)) do (k, v)
        return !isnothing(v)
    end

    return GraphsDFG{typeof(packed.solverParams), VT, FT}(;
        blobStores,
        graphBlobEntries,
        graphMetadata,
        graphLabel,
        agent,
        props...,
    )
end

function unpackDFGMetadata!(dfg::GraphsDFG, packed::PackedGraphsDFG)
    commonfields = intersect(fieldnames(GraphsDFG), fieldnames(PackedGraphsDFG))

    #FIXME Deprecate remove Nothing union in DFG v0.24
    #FIXME also remove deprectedDFG fields depr in v0.25
    setdiff!(commonfields, [deprecatedDfgFields; :blobStores])
    !isnothing(packed.blobStores) && merge!(dfg.blobStores, packed.blobStores)

    props = (k => getproperty(packed, k) for k in commonfields)
    foreach(props) do (k, v)
        return setproperty!(dfg, k, v)
    end
    return dfg
end
