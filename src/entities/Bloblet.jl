struct Bloblet
    label::Symbol
    val::String
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
