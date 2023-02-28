

##==============================================================================
## BlobEntry Blob CRUD - dit lyk nie of dit gebruik moet word nie
##==============================================================================

#  FIXME cannot overwrite regular getBlob etc functions
# getBlob(dfg::AbstractDFG, entry::BlobEntry) = (@error("Inmemory blobstore is not working"); return nothing) ## entry.data
# addBlob!(dfg::AbstractDFG, entry::BlobEntry, blob) = error("Not suported")#entry.blob
# updateBlob!(dfg::AbstractDFG, entry::BlobEntry, blob) = error("Not suported")#entry.blob
# deleteBlob!(dfg::AbstractDFG, entry::BlobEntry) = (@error("Inmemory blobstore is not working"); return nothing) ## entry.data



##==============================================================================
## BlobEntry CRUD Helpers
##==============================================================================
