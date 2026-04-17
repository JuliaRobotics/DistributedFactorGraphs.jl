##==============================================================================
## Blob + Blobentry CRUD interface (Layer 3 — The VBS Router)
##
## API Pattern: [save|load] + [Node] + Blob
## No Layer 3 delete — users call deleteVariableBlobentry! etc. directly.
## Physical blob GC is handled separately.
##==============================================================================

"""
Load a Blob for a given variable and Blobentry label.

$(METHODLIST)
"""
function loadVariableBlob end

"""
Save a Blob to a Blobprovider and attach a Blobentry to a variable.
$(METHODLIST)
"""
function saveVariableBlob! end

"""
Load a Blob for a given graph and Blobentry label.

$(METHODLIST)
"""
function loadGraphBlob end

"""
Save a Blob to a Blobprovider and attach a Blobentry to a graph.

$(METHODLIST)
"""
function saveGraphBlob! end

"""
Load a Blob for a given agent and Blobentry label.

$(METHODLIST)
"""
function loadAgentBlob end

"""
Save a Blob to a Blobprovider and attach a Blobentry to an agent.

$(METHODLIST)
"""
function saveAgentBlob! end

"""
Load a Blob for a given factor and Blobentry label.

$(METHODLIST)
"""
function loadFactorBlob end

"""
Save a Blob to a Blobprovider and attach a Blobentry to a factor.

$(METHODLIST)
"""
function saveFactorBlob! end

# ==============================================================================
# Variable
# ==============================================================================

function loadVariableBlob(dfg::AbstractDFG, variable_label::Symbol, entry_label::Symbol)
    entry = getVariableBlobentry(dfg, variable_label, entry_label)
    blob = getBlob(dfg, entry)
    actual_crc = crc32c(blob)
    actual_crc == entry.crc32csum ||
        throw(ValidationError(:crc32csum, entry.crc32csum, actual_crc))
    return entry, blob
end

function saveVariableBlob!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    blob::Vector{UInt8},
    entry::Blobentry,
)
    m = putBlob!(getBlobprovider(dfg, entry.provider), blob)
    m == entry.multihash || throw(ValidationError(:multihash, entry.multihash, m))
    entry = Blobentry(entry; crc32csum = crc32c(blob), size = length(blob))
    addVariableBlobentry!(dfg, variable_label, entry)
    return entry
end

function saveVariableBlob!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    blob::Vector{UInt8},
    entry_label::Symbol,
    provider::Symbol = :default;
    blobentry_kwargs...,
)
    multihash = putBlob!(getBlobprovider(dfg, provider), blob)
    entry = Blobentry(entry_label, blob; multihash, provider, blobentry_kwargs...)
    addVariableBlobentry!(dfg, variable_label, entry)
    return entry
end

# ==============================================================================
# Graph
# ==============================================================================

function loadGraphBlob(dfg::AbstractDFG, entry_label::Symbol)
    entry = getGraphBlobentry(dfg, entry_label)
    blob = getBlob(dfg, entry)
    actual_crc = crc32c(blob)
    actual_crc == entry.crc32csum ||
        throw(ValidationError(:crc32csum, entry.crc32csum, actual_crc))
    return entry, blob
end

function saveGraphBlob!(dfg::AbstractDFG, blob::Vector{UInt8}, entry::Blobentry)
    m = putBlob!(getBlobprovider(dfg, entry.provider), blob)
    m == entry.multihash || throw(ValidationError(:multihash, entry.multihash, m))
    entry = Blobentry(entry; crc32csum = crc32c(blob), size = length(blob))
    addGraphBlobentry!(dfg, entry)
    return entry
end

function saveGraphBlob!(
    dfg::AbstractDFG,
    blob::Vector{UInt8},
    entry_label::Symbol,
    provider::Symbol = :default;
    blobentry_kwargs...,
)
    multihash = putBlob!(getBlobprovider(dfg, provider), blob)
    entry = Blobentry(entry_label, blob; multihash, provider, blobentry_kwargs...)
    addGraphBlobentry!(dfg, entry)
    return entry
end

# ==============================================================================
# Agent
# ==============================================================================

function loadAgentBlob(dfg::AbstractDFG, agentlabel::Symbol, entry_label::Symbol)
    entry = getAgentBlobentry(dfg, agentlabel, entry_label)
    blob = getBlob(dfg, entry)
    actual_crc = crc32c(blob)
    actual_crc == entry.crc32csum ||
        throw(ValidationError(:crc32csum, entry.crc32csum, actual_crc))
    return entry, blob
end

function saveAgentBlob!(
    dfg::AbstractDFG,
    agentlabel::Symbol,
    blob::Vector{UInt8},
    entry::Blobentry,
)
    m = putBlob!(getBlobprovider(dfg, entry.provider), blob)
    m == entry.multihash || throw(ValidationError(:multihash, entry.multihash, m))
    entry = Blobentry(entry; crc32csum = crc32c(blob), size = length(blob))
    addAgentBlobentry!(dfg, agentlabel, entry)
    return entry
end

function saveAgentBlob!(
    dfg::AbstractDFG,
    agentlabel::Symbol,
    blob::Vector{UInt8},
    entry_label::Symbol,
    provider::Symbol = :default;
    blobentry_kwargs...,
)
    multihash = putBlob!(getBlobprovider(dfg, provider), blob)
    entry = Blobentry(entry_label, blob; multihash, provider, blobentry_kwargs...)
    addAgentBlobentry!(dfg, agentlabel, entry)
    return entry
end

# ==============================================================================
# Factor
# ==============================================================================

function loadFactorBlob(dfg::AbstractDFG, factor_label::Symbol, entry_label::Symbol)
    entry = getFactorBlobentry(dfg, factor_label, entry_label)
    blob = getBlob(dfg, entry)
    actual_crc = crc32c(blob)
    actual_crc == entry.crc32csum ||
        throw(ValidationError(:crc32csum, entry.crc32csum, actual_crc))
    return entry, blob
end

function saveFactorBlob!(
    dfg::AbstractDFG,
    factor_label::Symbol,
    blob::Vector{UInt8},
    entry::Blobentry,
)
    m = putBlob!(getBlobprovider(dfg, entry.provider), blob)
    m == entry.multihash || throw(ValidationError(:multihash, entry.multihash, m))
    entry = Blobentry(entry; crc32csum = crc32c(blob), size = length(blob))
    addFactorBlobentry!(dfg, factor_label, entry)
    return entry
end

function saveFactorBlob!(
    dfg::AbstractDFG,
    factor_label::Symbol,
    blob::Vector{UInt8},
    entry_label::Symbol,
    provider::Symbol = :default;
    blobentry_kwargs...,
)
    multihash = putBlob!(getBlobprovider(dfg, provider), blob)
    entry = Blobentry(entry_label, blob; multihash, provider, blobentry_kwargs...)
    addFactorBlobentry!(dfg, factor_label, entry)
    return entry
end

# ==============================================================================
# Layer 4: Application Domain (Images)
# ==============================================================================

function saveImage_Variable!(
    dfg::AbstractDFG,
    variable_label::Symbol,
    img::AbstractMatrix,
    entry_label::Symbol,
    provider::Symbol = :default;
    entry_kwargs...,
)
    mimetype = get(entry_kwargs, :mimeType, MIME("image/png"))
    format = getDataFormat(mimetype)
    isnothing(format) &&
        throw(ArgumentError("Unsupported MIME type for image: $(mimetype)"))
    blob, mimetype = packBlob(format, img)

    multihash = putBlob!(getBlobprovider(dfg, provider), blob)
    entry = Blobentry(entry_label, blob; multihash, provider, mimetype, entry_kwargs...)
    addVariableBlobentry!(dfg, variable_label, entry)
    return entry
end

function loadImage_Variable(dfg::AbstractDFG, variable_label::Symbol, entry_label::Symbol)
    entry, blob = loadVariableBlob(dfg, variable_label, entry_label)
    return entry, unpackBlob(entry, blob)
end

# ==============================================================================
# Aliases for old names (Layer 3)
# ==============================================================================
const saveBlob_Variable! = saveVariableBlob!
const loadBlob_Variable = loadVariableBlob
const saveBlob_Factor! = saveFactorBlob!
const loadBlob_Factor = loadFactorBlob
const saveBlob_Graph! = saveGraphBlob!
const loadBlob_Graph = loadGraphBlob
const saveBlob_Agent! = saveAgentBlob!
const loadBlob_Agent = loadAgentBlob
