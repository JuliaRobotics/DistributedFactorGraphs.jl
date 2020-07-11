"""
    $(TYPEDEF)
Simple file data store with a specified data type and a specified key type.
"""
struct FileDataStore{T} <: AbstractDataStore{T}
    folder::String
end

function FileDataStore(folder::String)
    if !isdir(folder)
        @warn "Folder '$folder' doesn't exist - creating."
        # create new folder
        mkpath(folder)
    end

    return FileDataStore{UInt8}(folder)
end

# if !isfile(joinpath(folder,"datatable.csv"))
#     # create new datatable.csv
#     @info "Creating new datatable.csv file"
#     df = DataFrame(userId = String[], robotId = String[], sessionId = String[],
#                    varLabel = Symbol[], dataLabel = Symbol[], dataId = UUID[])
#     CSV.write(joinpath(folder,"datatable.csv"), df)
# else
#     @info "Existing datatable.csv found."
# end
