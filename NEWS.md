Listing news on any major breaking changes in DFG.  For regular changes, see integrated Github.com project milestones for DFG.

# v0.18.0

- Unpack of GenericFactorNodeData now get `dfg::AbstractDFG` and `varOrder::Vector{Symbol}`, deprecating previous use of `convert` without the graph context (#832).
- Switch to GraphsDFG, deprecating archived LightGraphs.jl (#826).
- Workaround: packed factor data `.fnc` encoded as base64 to avoid escape character problems (#834).
- Towards distributions serialized via JSON, getting away from custom strings.
- `LocalDFG` replaces `DefaultDFG` (#844).
- Optimized creation of CGDFG / `createDfgSessionIfNotExist` (#839, #815).
- `plotDFG` replaces `dfgplot` (#841, #844).
- `Neo4jDFG` replaces `CloudGraphsDFG` (#836).

# v0.16.0

- `{Packed}VariableNodeData.infoPerCoord::Vector{Float64}` replaces previous `.inferdim::Float64`.  The change should have legacy support to help facilitate the transition.  This datastore is likely to only become part of critical computations downstream in IncrementalInference.jl v0.26, even though the previous `.inferdim` data values are being populated there.  (#804)