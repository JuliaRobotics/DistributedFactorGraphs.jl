##==============================================================================
## Blob + Blobentry CRUD interface
##==============================================================================

"""
Convenience wrapper to load a Blob for a given variable and Blobentry label.

$(METHODLIST)
"""
function loadBlob_Variable end

"""
Convenience wrapper to save a Blob to a Blobstore and a Blobentry to a variable.
$(METHODLIST)
"""
function saveBlob_Variable! end

"""
Convenience wrapper to delete a Blob form a Blobstore and its Blobentry from a variable.
$(METHODLIST)
"""
function deleteBlob_Variable! end

"""
Convenience wrapper to load a Blob for a given graph and Blobentry label.

$(METHODLIST)
"""
function loadBlob_Graph end

"""
Convenience wrapper to save a Blob to a Blobstore and a Blobentry to a graph.

$(METHODLIST)
"""
function saveBlob_Graph! end

"""
Convenience wrapper to delete a Blob from a Blobstore and its Blobentry from a graph.

$(METHODLIST)
"""
function deleteBlob_Graph! end

"""
Convenience wrapper to load a Blob for a given agent and Blobentry label.

$(METHODLIST)
"""
function loadBlob_Agent end

"""
Convenience wrapper to save a Blob to a Blobstore and a Blobentry to an agent.

$(METHODLIST)
"""
function saveBlob_Agent! end

"""
Convenience wrapper to delete a Blob from a Blobstore and its Blobentry from an agent.

$(METHODLIST)
"""
function deleteBlob_Agent! end

function loadBlob_Variable(
    dfg::AbstractDFG,
    variable_label::Symbol,
    entry_label::Symbol;
    # hashfunction = sha256,
    # checkhash::Bool = true,
)
    entry = getBlobentry(dfg, variable_label, entry_label)
    blob = getBlob(dfg, entry)
    # checkhash && assertHash(de, db; hashfunction)
    return entry, blob
end

function saveBlob_Variable!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    blob::Vector{UInt8},
    entry::Blobentry,
)
    addBlobentry!(dfg, variable_label, entry)
    addBlob!(dfg, entry, blob)
    return entry
end

function saveBlob_Variable!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    blob::Vector{UInt8},
    entry_label::Symbol,
    blobstore::Symbol = :default;
    blobentry_kwargs...,
)
    entry = Blobentry(entry_label, blobstore; blobentry_kwargs...)
    return saveBlob_Variable!(dfg, variable_label, blob, entry)
end

function deleteBlob_Variable!(dfg::AbstractDFG, variable_label::Symbol, entry_label::Symbol)
    entry = getBlobentry(dfg, variable_label, entry_label)
    deleteBlobentry!(dfg, variable_label, entry_label)
    deleteBlob!(dfg, entry)
    return 2
end

function loadBlob_Graph(dfg::AbstractDFG, entry_label::Symbol;)
    entry = getGraphBlobentry(dfg, entry_label)
    blob = getBlob(dfg, entry)
    return entry, blob
end

function saveBlob_Graph!(dfg::AbstractDFG, blob::Vector{UInt8}, entry::Blobentry)
    addGraphBlobentry!(dfg, entry)
    addBlob!(dfg, entry, blob)
    return entry
end

function saveBlob_Graph!(
    dfg::AbstractDFG,
    blob::Vector{UInt8},
    entry_label::Symbol,
    blobstore::Symbol = :default;
    blobentry_kwargs...,
)
    entry = Blobentry(entry_label, blobstore; blobentry_kwargs...)
    return saveBlob_Graph!(dfg, blob, entry)
end

function deleteBlob_Graph!(dfg::AbstractDFG, entry_label::Symbol)
    entry = getGraphBlobentry(dfg, entry_label)
    deleteGraphBlobentry!(dfg, entry_label)
    deleteBlob!(dfg, entry)
    return 2
end

function loadBlob_Agent(dfg::AbstractDFG, entry_label::Symbol;)
    entry = getAgentBlobentry(dfg, entry_label)
    blob = getBlob(dfg, entry)
    return entry, blob
end

function saveBlob_Agent!(dfg::AbstractDFG, blob::Vector{UInt8}, entry::Blobentry)
    addAgentBlobentry!(dfg, entry)
    addBlob!(dfg, entry, blob)
    return entry
end

function saveBlob_Agent!(
    dfg::AbstractDFG,
    blob::Vector{UInt8},
    entry_label::Symbol,
    blobstore::Symbol = :default;
    blobentry_kwargs...,
)
    entry = Blobentry(entry_label, blobstore; blobentry_kwargs...)
    return saveBlob_Agent!(dfg, blob, entry)
end

function deleteBlob_Agent!(dfg::AbstractDFG, entry_label::Symbol)
    entry = getAgentBlobentry(dfg, entry_label)
    deleteAgentBlobentry!(dfg, entry_label)
    deleteBlob!(dfg, entry)
    return 2
end

function saveImage_Variable!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    img::AbstractMatrix,
    entry_label::Symbol,
    blobstore::Symbol = :default;
    entry_kwargs...,
)
    mimeType = get(entry_kwargs, :mimeType, MIME("image/png"))
    format = _MIMETypes[mimeType]

    blob, mimeType = packBlob(format, img)

    size = string(length(blob))
    entry = Blobentry(
        entry_label,
        blobstore;
        blobid = uuid4(),
        entry_kwargs...,
        size,
        mimeType = string(mimeType),
    )

    return saveBlob_Variable!(dfg, variable_label, blob, entry)
end

function loadImage_Variable(dfg::AbstractDFG, variable_label::Symbol, entry_label::Symbol)
    entry, blob = loadBlob_Variable(dfg, variable_label, entry_label)
    return entry, unpackBlob(entry, blob)
end
