"""
    $(TYPEDEF)
GeneralDataEntry is a generic multipurpose data entry that creates a unique
reproducible key using userId_robotId_sessionId_variableId_key.
"""
mutable struct GeneralDataEntry <: AbstractDataEntry
    key::Symbol
    storeKey::Symbol # Could swap this to string, but using it as an index later, so better as a symbol I believe.
    createdTimestamp::DateTime
    lastUpdatedTimestamp::DateTime
    mimeType::String
end

"""
    $(SIGNATURES)
Internal function to generate a unique key for the entry - userId_robotId_sessionId_variable_key.
Simple symbol.
"""
function _uniqueKey(dfg::G, v::V, key::Symbol)::Symbol where {G <: AbstractDFG, V <: AbstractDFGVariable}
    key = join(String.([dfg.userId, dfg.robotId, dfg.sessionId, getLabel(v), String(key)]), "_")
    return Symbol(key)
end


GeneralDataEntry(key::Symbol, storeKey::Symbol;
                    mimeType::String="application/octet-stream") =
                    GeneralDataEntry(key, storeKey, now(), now(), mimeType)

function GeneralDataEntry(dfg::G, var::V, key::Symbol;
                             mimeType::String="application/octet-stream") where {G <: AbstractDFG, V <: AbstractDFGVariable}
    return GeneralDataEntry(key, _uniqueKey(dfg, var, key), mimeType=mimeType)
end

"""
    $(TYPEDEF)
Data Entry in MongoDB.
"""
struct MongodbDataEntry <: AbstractDataEntry
    key::Symbol
    oid::NTuple{12, UInt8} #mongodb object id
    #maybe other fields such as:
    #flags::Bool ready, valid, locked, permissions
    #MIMEType::String
end


"""
    $(TYPEDEF)
Data Entry in a file.
"""
struct FileDataEntry <: AbstractDataEntry
    key::Symbol
    filename::String
end
