Listing news on any major breaking changes in DFG.  For regular changes, see integrated Github.com project milestones for DFG.

# v0.16.0

- `{Packed}VariableNodeData.infoPerCoord::Vector{Float64}` replaces previous `.inferdim::Float64`.  The change should have legacy support to help facilitate the transition.  This datastore is likely to only become part of critical computations downstream in IncrementalInference.jl v0.26, even though the previous `.inferdim` data values are being populated there.  (#804)