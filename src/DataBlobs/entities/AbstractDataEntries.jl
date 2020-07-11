"""
    $(TYPEDEF)
GeneralDataEntry is a generic multipurpose data entry that creates a unique
reproducible key using userId_robotId_sessionId_variableId_key.
"""
mutable struct GeneralDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID # Could swap this to string, but using it as an index later, so better as a symbol I believe.
    createdTimestamp::DateTime
    lastUpdatedTimestamp::DateTime
    mimeType::String
end

#TODO Deprecation - Remove in v0.10
Base.getproperty(x::GeneralDataEntry,f::Symbol) = begin
    if f == :key
        Base.depwarn("GeneralDataEntry field key is deprecated, use `label` instead", :getproperty)
        getfield(x,:label)
    elseif f == :storeKey
        Base.depwarn("GeneralDataEntry field storeKey is deprecated, use `id` instead", :getproperty)
        getfield(x,:id)
    else
        getfield(x,f)
    end
end

#TODO Deprecation - Remove in v0.10
Base.setproperty!(x::GeneralDataEntry, f::Symbol, val) = begin
    if f == :key
        Base.depwarn("GeneralDataEntry field `key` is deprecated, use `label` instead", :setproperty!)
        setfield(x, :label)
    elseif f == :storeKey
        Base.depwarn("GeneralDataEntry field `storeKey` is deprecated, use `id` instead", :setproperty!)
        setfield(x, :id)
    else
        setfield!(x,f,val)
    end
end


"""
    $(SIGNATURES)
Function to generate source string - userId|robotId|sessionId|varLabel
"""
buildSourceString(dfg::AbstractDFG, label::Symbol) =
    "$(dfg.userId)|$(dfg.robotId)|$(dfg.sessionId)|$label"


_uniqueKey(dfg::AbstractDFG, v::AbstractDFGVariable, key::Symbol)::Symbol =
    error("_uniqueKey is deprecated")


GeneralDataEntry(key::Symbol, storeKey::Symbol; mimeType::String="") = error("storeKey Deprecated, use UUID")

GeneralDataEntry(label::Symbol, id::UUID;
                    mimeType::String="application/octet-stream") =
                    GeneralDataEntry(label, uuid4(), now(UTC), now(UTC), mimeType)

function GeneralDataEntry(dfg::AbstractDFG, var::AbstractDFGVariable, key::Symbol;
                             mimeType::String="application/octet-stream")
    return GeneralDataEntry(key, uuid4(), mimeType=mimeType)
end


"""
    $(TYPEDEF)
Genaral Data Store Entry.
"""
struct DataStoreEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    datastorekey::Symbol #TODO
    hash::String # Probably https://docs.julialang.org/en/v1/stdlib/SHA
    source::String # E.g. user|robot|session|varlabel
    description::String
    mimeType::String
    createdTimestamp::DateTime
    # lastUpdatedTimestamp::DateTime # don't think this makes sense?
end

"""
    $(TYPEDEF)
Data Entry in MongoDB.
"""
struct MongodbDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    oid::NTuple{12, UInt8} #mongodb object id
    hash::String

    # mongodb
    # client::String
    # database::String
    # collection::String

    #maybe other fields such as:
    #flags::Bool ready, valid, locked, permissions
    #MIMEType::String
end


"""
    $(TYPEDEF)
Data Entry in a file.
"""
struct FileDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    folder::String
    hash::String #using bytes2hex or perhaps Vector{Uint8}?
    timestamp::DateTime

    function FileDataEntry(label, id, folder, hash, timestamp)
        if !isdir(folder)
            @warn "Folder '$folder' doesn't exist - creating."
            # create new folder
            mkpath(folder)
        end
        return new(label, id, folder, hash, timestamp)
      end
end
