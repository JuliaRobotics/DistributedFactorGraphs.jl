Listing news on any major breaking changes in DFG.  For regular changes, see integrated Github.com project milestones for DFG.

# v0.29
- `AbstractPointParametricEst` (`MeanMaxPPE`) and related `PPE` functions are obsolete, see #1133.
- Rename filter keyword arguments to `where`-prefixed form:
  - `solvableFilter` -> `whereSolvable`
  - `labelFilter` -> `whereLabel`
  - `tagsFilter` -> `whereTags`
  - `typeFilter` -> `whereType`
  - `blobidFilter` -> `whereBlobid`
  - `variableLabelFilter` -> `whereVariableLabel`

- The Blob system was redesigned and refactored to a Content-Addressable Storage (CAS) model with Multihash keys, and renamed to Blobprovider to better reflect the abstraction. See #1157 for full discussion and design details.
  - Renamed Blobstore → Blobprovider
  - `AbstractBlobStore` → `AbstractBlobprovider`; concrete types renamed accordingly (`FolderBlobprovider`, `MemoryBlobprovider`, `CachedBlobprovider`).
  - All CRUD helpers renamed: `addBlobstore!` → `addBlobprovider!`, `getBlobstore` → `getBlobprovider`, `deleteBlobstore!` → `deleteBlobprovider!`, etc.
  - `putBlob!` now returns a `Multihash` and `fetchBlob` / `purgeBlob!` take a `Multihash` key.
  - Layer 1 verbs renamed: `getBlob(provider, hash)` → `fetchBlob` (returns `nothing` on miss), `deleteBlob!` → `purgeBlob!`.
  - `checkHash` decodes multihash to verify blob integrity.
  - `saveBlob_Variable!` → `saveVariableBlob!`, `loadBlob_Variable` → `loadVariableBlob`
  - Same pattern for Factor, Graph, Agent variants.
  - Old names kept as `const` aliases for backward compatibility.
  - `deleteBlob_Variable` and similar wrappers no longer exist. Use `deleteVariableBlobentry!` (metadata) and `purgeBlob!(provider, multihash)` (physical) directly. Warning: be carefull when deleting blobs to make sure they are no longer in use anywhere because the multihash id can be shared by multiple blobs.

# v0.28
- Reading or deserialzing of factor graphs created prior to v0.25 are no longer suppoted with the complete removal of User/Robot/Session
- Deprecated AbstractRelativeMinimize and AbstractManifoldsMinimize
- Rename `VariableState` -> `State`
- @defVariable -> @defStateType
- All deprecated and unstable function exports have been removed. Use the new macro `@usingDFG true` to import all exports. In the future, stable but non-exported functions will be marked as `public`.
- Rename SmallDataTypes -> MetadataTypes

Abstract Types Standardized, see #1153: 
- AbstractParams -> [Abstract]DFGParams
- DFGNode -> [Abstract]GraphNode
- AbstractDFGVariable -> [Abstract]GraphVariable
- AbstractDFGFactor -> [Abstract]GraphFactor
- AbstractPackedFactorObservation -> [Abstract]PackedObservation
- AbstractFactorObservation -> [Abstract]Observation
- AbstractPrior -> [Abstract]PriorObservation
- AbstractRelative -> [Abstract]RelativeObservation
- FactorSolverCache -> [Abstract]FactorCache
- VariableStateType -> [Abstract]StateType

# v0.27
- `delete` returns number of nodes deleted and no longer the object that was deleted.
- Deprecate `updateVariable!` for `mergeVariable!`, note `merge` returns number of nodes updated/added.
- Deprecate `updateFactor!` for `mergeFactor!`, note `merge` returns number of nodes updated/added.
- Rename BlobEntry to Blobentry, see #1123.
- Rename BlobStore to Blobstore, see #1124.
- Refactor the Factor solver data structure, see #1127:
    - Deprecated GenericFunctionNodeData, PackedFunctionNodeData, FunctionNodeData, and all functions related factor.solverData.
    - Replaced by 3 seperete types: Observation, State, and Cache
    - This is used internally be the solver and should not affect the average user of DFG.
    - Rename FactorOperationalMemory -> FactorSolverCache
    - Rename AbstractFactor -> AbstractFactorObservation (keeping both around)
- Deprecate VariableNodeData -> VariableState
- Deprecate getVariableSolverData -> getVariableState
- Deprecate addVariableSolverData! -> addVariableState!
- Deprecate deleteVariableSolverData! -> deleteVariableState!
- Deprecate listVariableSolverData -> listVariableStates
- Deprecate getVariableSolverDataAll -> getVariableStates
- Deprecate getSolverData -> getVariableState/getFactorState
- Deprecate getBlobentryFirst -> getfirstBlobentry, see #1114
- OrderedDict is no longer exported
- FolderStore path now includes the store label.
- Standardized error types and behaviour.

# v0.26
- Graph structure plotting now uses GraphMakie.jl instead of GraphPlot.jl. Update by replacing `using GraphPlot` with `using GraphMakie`.

# v0.25
- Deprecated nouns:
    SessionBlobEntry -> GraphBlobEntry
    RobotBlobEntry -> AgentBlobEntry
    UserBlobEntry -> AgentBlobEntry
    RobotData -> AgentMetadata
    SessionData -> GraphMetadata
    UserLabel -> AgentLabel
    RobotLabel -> AgentLabel
    SessionLabel -> GraphLabel

Variables and Factors are renamed and aliased to the old names, see #1109.
- Factor-level noun-adjectives
    SkeletonDFGFactor -> FactorSkeleton
    DFGFactorSummary -> FactorSummary
    DFGFactor -> FactorCompute
    PackedFactor/Factor -> FactorDFG

- Variable-level noun-adjectives
    SkeletonDFGVariable -> VariableSkeleton
    DFGVariableSummary -> VariableSummary
    DFGVariable -> VariableCompute
    PackedVariable/Variable -> VariableDFG

- v0.24 FileDFGs can be loaded with v0.25 with the exception of the User[Label/Data/BlobEntries]

# v0.24

- Remove `FolderStore` `.dat` legacy extension. To upgrade a legacy FolderStore remove extention with something like: `foreach(f->mv(f,split(f,".")[1]), files)`

# v0.23

- save/loadDFG now users Tar.jl and CodecZlib.jl #351.
- save/loadDFG now preserves meta fields #921.
- Deprecate getNeighbors for listNeighbors.
- Dropped AbstractRelativeRoots.

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
