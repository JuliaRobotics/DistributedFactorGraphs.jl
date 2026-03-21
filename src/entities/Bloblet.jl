struct Bloblet
    label::Symbol
    val::String
end

function Bloblet(
    label::Symbol,
    val::Union{
        Int,
        Float64,
        Bool,
        Vector{Int},
        Vector{Float64},
        Vector{String},
        Vector{Bool},
        Missing,
        Nothing,
    },
)
    return Bloblet(label, JSON.json(val))
end

const Bloblets = LittleDict{Symbol, Bloblet}

StructUtils.structlike(::Type{Bloblets}) = false
StructUtils.arraylike(::Type{Bloblets}) = false
StructUtils.dictlike(::Type{Bloblets}) = false
StructUtils.noarg(::Type{Bloblets}) = false

function StructUtils.lower(bloblet::Bloblets)
    return map(collect(values(bloblet))) do (m)
        return (label = m.label, val = m.val)
    end
end

function StructUtils.lift(::Type{Bloblets}, json_vector::Vector)
    return Bloblets(
        Symbol(x["label"]) => Bloblet(Symbol(x["label"]), x["val"]) for x in json_vector
    )
end

##==============================================================================
## Node Bloblets
##==============================================================================
"""
    $(SIGNATURES)
"""
function getBloblet(node, label::Symbol)
    !haskey(refBloblets(node), label) && throw(LabelNotFoundError("Bloblet", label))
    return refBloblets(node)[label]
end

"""
    $(SIGNATURES)
"""
function getBloblets(node)
    return collect(values(refBloblets(node)))
end

"""
    $(SIGNATURES)
"""
function addBloblet!(node, bloblet::Bloblet)
    label = getLabel(bloblet)
    haskey(refBloblets(node), label) && throw(LabelExistsError("Bloblet", label))
    refBloblets(node)[label] = bloblet
    return bloblet
end

function addBloblets!(node, bloblets::Vector{Bloblet})
    foreach(bl -> addBloblet!(node, bl), bloblets)
    return bloblets
end

"""
    $(SIGNATURES)
"""
function mergeBloblet!(node, bloblet::Bloblet)
    refBloblets(node)[getLabel(bloblet)] = bloblet
    return 1
end

function mergeBloblets!(node, bloblets::Vector{Bloblet})
    mergeBloblet!.(node, bloblets)
    return length(bloblets)
end

"""
    $(SIGNATURES)
"""
function deleteBloblet!(node, label::Symbol)
    !haskey(refBloblets(node), label) && return 0
    pop!(refBloblets(node), label)
    return 1
end

function deleteBloblets!(node, labels::Vector{Symbol})
    return sum(deleteBloblet!.(node, labels))
end

"""
    $(SIGNATURES)
List all Bloblet keys for a variable `label` in `dfg`
"""
function listBloblets(node)
    return collect(keys(refBloblets(node)))
end
