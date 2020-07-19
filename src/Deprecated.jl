##==============================================================================
# deprecation staging area
##==============================================================================


##==============================================================================
## Remove in 0.10
##==============================================================================

# temporary promote with warning
Base.promote_rule(::Type{DateTime}, ::Type{ZonedDateTime}) = DateTime
function Base.convert(::Type{DateTime}, ts::ZonedDateTime)
    @warn "DFG now uses ZonedDateTime, temporary promoting and converting to DateTime local time"
    return DateTime(ts, Local)
end

export listSolvekeys

@deprecate listSolvekeys(x...) listSolveKeys(x...)

export InferenceType
export FunctorSingleton, FunctorPairwise, FunctorPairwiseMinimize

abstract type InferenceType end

# These will become AbstractPrior, AbstractRelativeFactor, and AbstractRelativeFactorMinimize in 0.9.
abstract type FunctorSingleton <: FunctorInferenceType end
abstract type FunctorPairwise <: FunctorInferenceType end
abstract type FunctorPairwiseMinimize <: FunctorInferenceType end

# I don't know how to deprecate this, any suggestions?
const AbstractBigDataEntry = AbstractDataEntry

@deprecate GeneralBigDataEntry(args...; kwargs...) GeneralDataEntry(args...; kwargs...)
@deprecate MongodbBigDataEntry(args...)  MongodbDataEntry(args...)
@deprecate FileBigDataEntry(args...)  FileDataEntry(args...)

# TODO entities/DFGVariable.jl DFGVariableSummary.bigData getproperty and setproperty!
# TODO entities/DFGVariable.jl DFGVariable.bigData getproperty and setproperty!
@deprecate getBigData(args...) getDataBlob(args...)
@deprecate addBigData!(args...) addDataBlob!(args...)
@deprecate updateBigData!(args...) updateDataBlob!(args...)
@deprecate deleteBigData!(args...) deleteDataBlob!(args...)
@deprecate listStoreEntries(args...) listDataBlobs(args...)
@deprecate hasBigDataEntry(args...) hasDataEntry(args...)


@deprecate getBigDataEntry(args...) getDataEntry(args...)
@deprecate addBigDataEntry!(args...)  addDataEntry!(args...)
@deprecate updateBigDataEntry!(args...) updateDataEntry!(args...)
@deprecate deleteBigDataEntry!(args...) deleteDataEntry!(args...)
@deprecate getBigDataKeys(args...) listDataEntries(args...)
@deprecate getBigDataEntries(args...) getDataEntries(args...)
@deprecate getDataEntryElement(args...) getDataEntryBlob(args...)
