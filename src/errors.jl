"""
    DFGLabelNotFoundError(label, available)

Error thrown when a requested label is not found in the factor graph.

# Arguments
- `label`: The label that was not found.
- `available`: The list of available labels.
"""
struct DFGLabelNotFoundError <: Exception
    label::Any
    available::Any
end

DFGLabelNotFoundError(label::T) where {T} = DFGLabelNotFoundError(label, T[])

function Base.showerror(io::IO, ex::DFGLabelNotFoundError)
    print(io, "DFGLabelNotFoundError: label ", ex.label, " not found.")
    if !isempty(ex.available)
        println(io, " Available labels:")
        show(io, ex.available)
    end
end

"""
    DFGLabelExistsError(label)

Error thrown when attempting to add a label that already exists in the factor graph.

# Arguments
- `label`: The label that already exists.
"""
struct DFGLabelExistsError <: Exception
    label::Any
end

function Base.showerror(io::IO, ex::DFGLabelExistsError)
    return print(
        io,
        "DFGLabelExistsError: label ",
        ex.label,
        " already exists in the factor graph.",
    )
end

"""
    DFGSerializationError(msg)

Error thrown when serialization or deserialization fails.

# Arguments
- `msg`: Description of the serialization error.
"""
struct DFGSerializationError <: Exception
    msg::String
end

function Base.showerror(io::IO, ex::DFGSerializationError)
    return print(io, "DFGSerializationError: ", ex.msg)
end
