"""
    LabelNotFoundError(label, available)

Error thrown when a requested label is not found in the factor graph.
"""
struct LabelNotFoundError <: Exception
    name::String
    label::Symbol
    available::Vector{Symbol}
end

LabelNotFoundError(name::String, label::Symbol) = LabelNotFoundError(name, label, Symbol[])
LabelNotFoundError(label::Symbol) = LabelNotFoundError("Node", label, Symbol[])

function Base.showerror(io::IO, ex::LabelNotFoundError)
    print(io, "LabelNotFoundError: ", ex.name, " label '", ex.label, "' not found.")
    if !isempty(ex.available)
        println(io, " Available labels:")
        show(io, ex.available)
    end
end

"""
    LabelExistsError(label)

Error thrown when attempting to add a label that already exists in the collection.
"""
struct LabelExistsError <: Exception
    name::String
    label::Symbol
end

LabelExistsError(label::Symbol) = LabelExistsError("Node", label)

function Base.showerror(io::IO, ex::LabelExistsError)
    return print(io, "LabelExistsError: ", ex.name, " label '", ex.label, "' already exists.")
end

"""
    SerializationError(msg)

Error thrown when serialization or deserialization fails.
"""
struct SerializationError <: Exception
    msg::String
end

function Base.showerror(io::IO, ex::SerializationError)
    return print(io, "SerializationError: ", ex.msg)
end
