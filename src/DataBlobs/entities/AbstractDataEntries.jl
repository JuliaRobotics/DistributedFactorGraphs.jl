"""
    $(TYPEDEF)
GeneralDataEntry is a generic multipurpose data entry that creates a unique
reproducible key using userId_robotId_sessionId_variableId_key.
"""
mutable struct GeneralDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    createdTimestamp::ZonedDateTime
    lastUpdatedTimestamp::ZonedDateTime
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

GeneralDataEntry(label::Symbol, id::UUID=uuid4();
                    mimeType::String="application/octet-stream") =
                    GeneralDataEntry(label, id, now(localzone()), now(localzone()), mimeType)

function GeneralDataEntry(dfg::AbstractDFG, var::AbstractDFGVariable, key::Symbol;
                             mimeType::String="application/octet-stream")
    return GeneralDataEntry(key, uuid4(), mimeType=mimeType)
end


"""
    $(TYPEDEF)
Data Entry in MongoDB.
"""
struct MongodbDataEntry <: AbstractDataEntry
    label::Symbol
    id::UUID
    oid::NTuple{12, UInt8} #mongodb object id - TODO Not needed with id::UUID unique, but perhaps usefull
    hash::String
    createdTimestamp::ZonedDateTime
    # mongodb
    # mongoConfig::MongoConfig
    #maybe other fields such as:
    #flags::Bool ready, valid, locked, permissions
    #MIMEType::String
end
