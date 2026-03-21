#TODO maybe mutable
@kwdef mutable struct Agent
    label::Symbol = :DefaultAgent
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::Blobentries = Blobentries()
end

@kwdef mutable struct Graphroot
    label::Symbol = :DefaultFactorgraph
    description::String = ""
    tags::Set{Symbol} = Set{Symbol}()
    bloblets::Bloblets = Bloblets()
    blobentries::Blobentries = Blobentries()
end

# Patching (for merge!)
# standard patch description merging
function patch(dest::String, src::String)
    # 1. Quick exits
    (src == "" || src == dest) && return dest
    dest == "" && return src
    dest === src && return dest

    separator = " | "
    # 2. Combine: Split into parts and combine uniquely for idempotent merging.
    # This prevents "Graph" from being swallowed by "FactorGraph"
    dest_parts = split(dest, separator)
    src_parts = split(src, separator)
    return join(unique(vcat(dest_parts, src_parts)), separator)
end

function patch!(dest::T, src::T) where {T <: Union{Agent, Graphroot}}
    dest === src && return dest # avoid unnecessary work if same object

    dest.label !== src.label &&
        throw(ArgumentError("Nodes has different labels: $(dest.label) vs $(src.label)"))

    dest.description = patch(dest.description, src.description)

    union!(dest.tags, src.tags)
    merge!(dest.blobentries, src.blobentries)
    merge!(dest.bloblets, src.bloblets)

    return dest
end

#TODO should we make agent immutable and only allow adding? complex ACID?
# reason for is once an agent's config is used in a graph it should not be modified.
mergeAgent!(dest::Agent, src::Agent) = patch!(dest, src)
