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
    return print(
        io,
        "LabelExistsError: ",
        ex.name,
        " label '",
        ex.label,
        "' already exists.",
    )
end

"""
    IdNotFoundError(id, available)

Error thrown when a requested id is not found.
"""
struct IdNotFoundError{T} <: Exception
    name::String
    id::T
    available::Vector{T}
end

IdNotFoundError(name::String, id::T) where {T} = IdNotFoundError(name, id, T[])
IdNotFoundError(id::T) where {T} = IdNotFoundError("Node", id, T[])

function Base.showerror(io::IO, ex::IdNotFoundError)
    print(io, "IdNotFoundError: ", ex.name, " id '", ex.id, "' not found.")
    if !isempty(ex.available)
        println(io, " Available ids:")
        show(io, ex.available)
    end
end

"""
    IdExistsError(id)

Error thrown when attempting to add an id that already exists in the collection.
"""
struct IdExistsError{T} <: Exception
    name::String
    id::T
end

IdExistsError(id) = IdExistsError("Node", id)

function Base.showerror(io::IO, ex::IdExistsError)
    return print(io, "IdExistsError: ", ex.name, " id '", ex.id, "' already exists.")
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

#http error 409
"""
    MergeConflictError(msg)

Error thrown when a merge conflict occurs.
"""
struct MergeConflictError <: Exception
    msg::String
end

function Base.showerror(io::IO, ex::MergeConflictError)
    return print(io, "MergeConflictError: ", ex.msg)
end

"""
    LinkConstraintError(msg)

Error thrown when an operation violates a structural dependency,
e.g., deleting a graph that is still in use by a model.
"""
struct LinkConstraintError <: Exception
    msg::String
end

function Base.showerror(io::IO, ex::LinkConstraintError)
    return print(io, "LinkConstraintError: ", ex.msg)
end

struct ValidationError{T} <: Exception
    property::Symbol  # e.g., :crc32csum, :multihash, :variable_label
    expected::T
    computed::T
end

function Base.showerror(io::IO, e::ValidationError)
    print(io, "ValidationError: Integrity check failed for property '", e.property, "'. ")
    return print(io, "Expected ", e.expected, " but computed ", e.computed, ".")
end
