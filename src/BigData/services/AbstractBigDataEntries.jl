import Base: ==

function ==(a::GeneralBigDataEntry, b::GeneralBigDataEntry)
    return a.key == b.key &&
        a.storeKey == b.storeKey &&
        a.mimeType == b.mimeType &&
        Dates.value(a.createdTimestamp - b.createdTimestamp) < 1000 &&
        Dates.value(a.lastUpdatedTimestamp - b.lastUpdatedTimestamp) < 1000 #1 second
end

function ==(a::MongodbBigDataEntry, b::MongodbBigDataEntry)
    return a.key == b.key && a.oid == b.oid
end

function ==(a::FileBigDataEntry, b::FileBigDataEntry)
    return a.key == b.key && a.filename == b.filename
end
