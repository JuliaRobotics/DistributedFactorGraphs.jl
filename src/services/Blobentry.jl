function getVariableBlobentry(dfg::InMemoryDFGTypes, varLabel::Symbol, label::Symbol)
    return getBlobentry(getVariable(dfg, varLabel), label)
end

function addVariableBlobentry!(dfg::InMemoryDFGTypes, vLbl::Symbol, entry::Blobentry)
    return addBlobentry!(getVariable(dfg, vLbl), entry)
end

function mergeVariableBlobentry!(dfg::InMemoryDFGTypes, label::Symbol, bde::Blobentry)
    return mergeBlobentry!(getVariable(dfg, label), bde)
end

function deleteVariableBlobentry!(dfg::InMemoryDFGTypes, label::Symbol, key::Symbol)
    return deleteBlobentry!(getVariable(dfg, label), key)
end
