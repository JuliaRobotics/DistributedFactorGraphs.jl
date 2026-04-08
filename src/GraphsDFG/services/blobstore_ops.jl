##==============================================================================
## AbstractBlobstore  CRUD
##==============================================================================
# AbstractBlobstore should have label or overwrite getLabel

DFG.refBlobstores(dfg::GraphsDFG) = dfg.blobstores

function DFG.getBlobstore(dfg::GraphsDFG, storeLabel::Symbol)
    store = get(refBlobstores(dfg), storeLabel, nothing)
    if isnothing(store)
        isempty(refBlobstores(dfg)) &&
            @info "No blobstores in graph: `$(getGraphLabel(dfg))`. Use `addBlobstore!(dfg, FolderStore(\"path/to/store\"))` to add one."
        throw(
            LabelNotFoundError("Blobstore", storeLabel, collect(keys(refBlobstores(dfg)))),
        )
    end
    return store
end

function DFG.getBlobstores(dfg::GraphsDFG)
    stores = map(listBlobstores(dfg)) do label
        return getBlobstore(dfg, label)
    end
    return isempty(stores) ? AbstractBlobstore[] : stores
end

function DFG.addBlobstore!(dfg::GraphsDFG, store::AbstractBlobstore)
    label = getLabel(store)
    haskey(refBlobstores(dfg), label) && throw(LabelExistsError("Blobstore", label))
    return push!(refBlobstores(dfg), label => store)
end

# TODO edge api is a work in progress and only internal 
function DFG.mergeStorelink!(dfg::GraphsDFG, link_to_store::AbstractBlobstore)
    # we currently only have a label for a storelink, so we do not know if it is the same link
    # so we have to look at the Blobstore node to find out. we only merge if the label=>store matches
    # 
    label = getLabel(link_to_store) # the edge in this case is from the virtual dfg object to the Blobstore, so simply label.
    if hasBlobstore(dfg, label)
        existing_store = getBlobstore(dfg, label)
        if existing_store != link_to_store
            throw(MergeConflictError("Merge conflict for Blobstore with label $(label)"))
        else
            return 0 # no merge needed, they are the same store
        end
    else
        push!(refBlobstores(dfg), label => link_to_store)
    end
    return 1
end

function DFG.deleteBlobstore!(dfg::GraphsDFG, key::Symbol)
    !haskey(refBlobstores(dfg), key) && return 0
    pop!(refBlobstores(dfg), key)
    return 1
end
DFG.listBlobstores(dfg::GraphsDFG) = collect(keys(DFG.refBlobstores(dfg)))

function DFG.mergeStorelinks!(destDFG::GraphsDFG, blobstores::Vector{<:AbstractBlobstore})
    count = 0
    for store in blobstores
        count += DFG.mergeStorelink!(destDFG, store)
    end
    return count
end

function DFG.hasBlobstore(dfg::GraphsDFG, label::Symbol)
    return haskey(refBlobstores(dfg), label)
end

#TODO empty as verb or only `deleteNouns!`
# emptyBlobstore!(dfg::GraphsDFG) = empty!(refBlobstores(dfg))
