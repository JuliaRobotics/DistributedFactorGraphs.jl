"""
    $(TYPEDEF)
Simple file data store with a specified data type and a specified key type.
"""
struct FileDataStore <: AbstractDataStore{UInt8}
    folder::String
    FileDataStore(folder::String) = begin
        if !isdir(folder)
            @warn "Folder '$folder' doesn't exist - creating."
            mkpath(folder)
        end
        return new(folder)
    end
end
