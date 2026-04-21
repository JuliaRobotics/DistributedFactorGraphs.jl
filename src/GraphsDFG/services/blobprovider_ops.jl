##==============================================================================
## AbstractBlobprovider  CRUD
##==============================================================================
# AbstractBlobprovider should have label or overwrite getLabel

DFG.refBlobproviders(dfg::GraphsDFG) = dfg.blobproviders

function DFG.getBlobprovider(dfg::GraphsDFG, label::Symbol)
    store = get(refBlobproviders(dfg), label, nothing)
    if isnothing(store)
        available = collect(keys(refBlobproviders(dfg)))
        isempty(available) && @info(
            "Blobprovider '$(label)' not found — no Blobproviders configured. " *
            "Hint: addBlobprovider!(dfg, FolderBlobprovider(\"path/to/store\"))"
        )
        throw(LabelNotFoundError("Blobprovider", label, available))
    end
    return store
end

function DFG.getBlobproviders(dfg::GraphsDFG)
    stores = map(listBlobproviders(dfg)) do label
        return getBlobprovider(dfg, label)
    end
    return isempty(stores) ? AbstractBlobprovider[] : stores
end

function DFG.addBlobprovider!(dfg::GraphsDFG, provider::AbstractBlobprovider)
    label = getLabel(provider)
    if haskey(refBlobproviders(dfg), label)
        length(refBlobproviders(dfg)) == 1 && @info(
            "Blobprovider label '$(label)' is already in use. " *
            "Hint: Use unique labels, e.g. addBlobprovider!(dfg, MyProvider(; label=:remote)). " *
            "For write-through caching on the same label, use CachedBlobprovider(local, remote)."
        )
        throw(LabelExistsError("Blobprovider", label))
    end
    push!(refBlobproviders(dfg), label => provider)
    return provider
end

# TODO edge api is a work in progress and only internal 
function DFG.mergeBlobprovider!(dfg::GraphsDFG, provider::AbstractBlobprovider)
    label = getLabel(provider)
    if hasBlobprovider(dfg, label)
        existing = getBlobprovider(dfg, label)
        if existing != provider
            throw(MergeConflictError("Merge conflict for Blobprovider with label $(label)"))
        else
            return 0 # no merge needed, they are the same provider
        end
    else
        push!(refBlobproviders(dfg), label => provider)
    end
    return 1
end

function DFG.deleteBlobprovider!(dfg::GraphsDFG, key::Symbol)
    !haskey(refBlobproviders(dfg), key) && return 0
    pop!(refBlobproviders(dfg), key)
    return 1
end
DFG.listBlobproviders(dfg::GraphsDFG) = collect(keys(DFG.refBlobproviders(dfg)))

function DFG.mergeBlobproviders!(
    destDFG::GraphsDFG,
    providers::Vector{<:AbstractBlobprovider},
)
    count = 0
    for provider in providers
        count += DFG.mergeBlobprovider!(destDFG, provider)
    end
    return count
end

function DFG.hasBlobprovider(dfg::GraphsDFG, label::Symbol)
    return haskey(refBlobproviders(dfg), label)
end
