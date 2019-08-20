

"""
    $(SIGNATURES)
Get an adjacency matrix for the DFG, returned as a tuple: adjmat::SparseMatrixCSC{Int}, var_labels::Vector{Symbol) fac_labels::Vector{Symbol).
Rows are the factors, columns are the variables, with the corresponding labels in fac_labels,var_labels.
"""
getAdjacencyMatrixSparse(dfg::AbstractDFG) =  error("getAdjacencyMatrixSparse not implemented for $(typeof(dfg))")
