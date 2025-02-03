"""
    DFGLabelError(label)

Label not found.
"""
struct DFGLabelError <: Exception
    label::Any
    available::Any
end

DFGLabelError(key::T) where {T} = DFGLabelError(key, T[])

function Base.showerror(io::IO, ex::DFGLabelError)
    print(io, "DFGLabelError: label ", ex.label, " not found.")
    if !isempty(ex.available)
        println(io, " Available labels:")
        show(io, ex.available)
    end
end
