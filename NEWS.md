Listing news on any major breaking changes in DFG.  For regular changes, see integrated Github.com project milestones for DFG.

# v0.20

- Throw `KeyError` if `getBlobEntry` is not found, previously was `ErrorException`.
- Change return type on `addData!` convenience wrappers to only return new `BlobEntry`.
- Fix `addBlob!` calls for `FolderStore` and `InMemoryBlobStore` to use `BlobEntry.originId` and not previous bug `entry.id`.
- Close long running serialization redo (#590) using only JSON3.jl and StructTypes.jl going forward.
- Standardize BlobEntry=>Blob naming of functions, and keeping convenience wrappers `{get,add,update,delete}Data[!]`.
- Consolidate to only one `BlobEntry` definition, dropping use of `AbstractBlobEntry`.
- Include type field `VariableNodeData.covar`.
- Drop minimum Julia compat to 1.8.

# v0.19

- Add ids and metadata to data types.
- Use `Base.@kwdef` on stuct types for default values and serialization.
- Dropped dependency on Unmarshal.jl.
- Note src/Serialization.jl was refactored and currently contains lots of legacy code for DFG v0.18 compat, and much will be deleted in DFG v0.20 to standardize serialization around JSON3.jl, see #590.
- `Neo4jDFG` has been removed.
- `LightDFG` has been removed, and `GraphsDFG` is not the standard in-memory driver for alias `LocalDFG`.
- Standardize all timestamp fields to `ZonedDateTime` from previous `DateTime` so that time zones will always be available.
- internal `getDFGVersion()` function now returns a `::VersionNumber`.
- Use `userLabel, robotLabel, sessionLabel` instead of legacy `userId, robotId, sessionId`.

# v0.18.0

- Unpack of GenericFactorNodeData with `reconstrFactorData` now gets `dfg::AbstractDFG` and `varOrder::Vector{Symbol}`, deprecating previous use of `convert` without the graph context (#832).
- Switch to GraphsDFG, deprecating archived LightGraphs.jl (#826).
- Workaround: packed factor data `.fnc` encoded as base64 to avoid escape character problems (#834).
- Towards distributions serialized via JSON, getting away from custom strings (#848).
- `LocalDFG` replaces `DefaultDFG` (#844).
- Optimized creation of CGDFG / `createDfgSessionIfNotExist` (#839, #815).
- `plotDFG` replaces `dfgplot` (#841, #844).
- `Neo4jDFG` replaces `CloudGraphsDFG` (#836).

# v0.16.0

- `{Packed}VariableNodeData.infoPerCoord::Vector{Float64}` replaces previous `.inferdim::Float64`.  The change should have legacy support to help facilitate the transition.  This datastore is likely to only become part of critical computations downstream in IncrementalInference.jl v0.26, even though the previous `.inferdim` data values are being populated there.  (#804)
