
##==============================================================================
## DFG Variables
##==============================================================================

##------------------------------------------------------------------------------
## VariableCompute
##------------------------------------------------------------------------------
# The Variable information packed in a way that accomdates multi-lang using json.

variable_timestamp_note = """
!!! note    
    This single timestamp does not represent the temporal uncertainty of non-parametric beliefs.
    A single timestamp value cannot capture the distribution of temporal 
    information across all particles/points in a belief. For problems where time is a state variable 
    requiring inference (e.g., `SGal3` which includes temporal components), include time as part of 
    your state type rather than relying on this metadata field.
"""

#TODO move solvable to State, and update filters
"""
$(TYPEDEF)
Complete variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
@kwdef struct VariableDFG{T <: StateType, P} <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable event timestamp (UTC-based) with timezone support.    
    $variable_timestamp_note
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone = now_tdz() #NOTE changed to TimeDateZone in v0.29
    # """Nanoseconds since a user-understood epoch (e.g unix epoch, robot boot time, etc.)"""
    # nstime::String = "0" #NOTE deprecated field in v0.29
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
    """Dictionary of state data. May be a subset of all solutions if a solver label was specified in the get call.
    Accessors: [`addState!`](@ref), [`mergeState!`](@ref), and [`deleteState!`](@ref)"""
    states::OrderedDict{Symbol, State{T, P}} = OrderedDict{Symbol, State{T, P}}() #NOTE field renamed from solverDataDict in v0.29
    """Dictionary of small data associated with this variable.
    Accessors: [`getBloblet`](@ref), [`addBloblet!`](@ref)"""
    bloblets::Bloblets = Bloblets() #NOTE changed from smallData in v0.29
    """Dictionary of large data associated with this variable.
    Accessors: [`addBlobentry!`](@ref), [`getBlobentry`](@ref), [`mergeBlobentry!`](@ref), and [`deleteBlobentry!`](@ref)"""
    blobentries::Blobentries = Blobentries() #NOTE renamed from dataDict in v0.29
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int} = Ref{Int}(1) #& (lower = getindex,)
    statekind::T = T()
    """ DFG types serialization format version."""
    version::VersionNumber = DFG.DFG_TYPES_VERSION
end
refStates(v::VariableDFG) = v.states

#NOTE fielddefaults and fieldtags not through @kwarg macro due to error with State{T, P, N}
function StructUtils.fielddefaults(
    ::StructUtils.StructStyle,
    ::Type{VariableDFG{T, P}},
) where {T, P}
    return (
        timestamp = now_tdz(),
        tags = Set{Symbol}(),
        states = OrderedDict{Symbol, State{T, P}}(),
        bloblets = Bloblets(),
        blobentries = Blobentries(),
        solvable = Ref(1),
        version = DFG.DFG_TYPES_VERSION,
    )
end

# function StructUtils.fieldtags(::StructUtils.StructStyle, ::Type{<:VariableDFG})
#     return (
#         solvable = (lower = getindex,),
#     )
# end

function resolveVariableDFGType(lazyobj)
    statekind = liftStateKind(lazyobj.statekind[])
    return VariableDFG{typeof(statekind), getPointType(statekind)}
end

@choosetype VariableDFG resolveVariableDFGType

# JSON.omit_empty(::DistributedFactorGraphs.DFGJSONStyle, ::Type{<:VariableDFG}) = true

const VariableCompute = VariableDFG #TODO deprecated in v0.29
##------------------------------------------------------------------------------
## Constructors

"""
    $SIGNATURES
The default VariableDFG constructor.
"""
#IIF like contruction helper for VariableDFG
function VariableDFG(
    label::Symbol,
    ::Union{T, Type{T}}; # statekind
    tags::Union{Set{Symbol}, Vector{Symbol}} = Set{Symbol}(),
    timestamp::Union{TimeDateZone, ZonedDateTime} = now_tdz(),
    solvable::Union{Int, Base.RefValue{Int}} = Ref{Int}(1),
    nanosecondtime = nothing,
    smalldata = nothing,
    kwargs...,
) where {T <: StateType}
    if timestamp isa ZonedDateTime
        # TODO @warn
        timestamp = TimeDateZone(timestamp)
    end
    if !isnothing(nanosecondtime)
        Base.depwarn(
            "nanosecondtime kwarg is deprecated, use `timestamp` or `bloblets` instead",
            :VariableDFG,
        )
    end
    if !isnothing(smalldata)
        Base.depwarn("smalldata kwarg is deprecated, use bloblets instead", :VariableDFG)
        #TODO convert smalldata to bloblets
    end
    if solvable isa Int
        solvable = Ref(solvable)
    end
    tags = tags isa Set ? tags : Set{Symbol}(tags)
    union!(tags, [:VARIABLE])

    P = getPointType(T)
    return VariableDFG{T, P}(; label, solvable, tags, timestamp, kwargs...)
end

function VariableDFG(label::Symbol, state::State; kwargs...)
    return VariableDFG(
        label,
        getStateKind(state);
        states = OrderedDict(state.label => state),
        kwargs...,
    )
end

# Base.getproperty(x::VariableCompute, f::Symbol) = begin
#     if f == :solvable
#         getfield(x, f)[]
#     else
#         getfield(x, f)
#     end
# end

# Base.setproperty!(x::VariableCompute, f::Symbol, val) = begin
#     if f == :solvable
#         getfield(x, f)[] = val
#     else
#         setfield!(x, f, val)
#     end
# end

"""
    $SIGNATURES

Merge the contents of `src` into `dest` by only patching child collections/containers.
Notes:
- Cascades into collections (`tags`, `states`, `blobentries`, `bloblets`).
- Assumes `label`, `timestamp`, and `statekind` are immutable and does not update them.
"""
function patch!(dest::VariableDFG{T}, src::VariableDFG{T}) where {T}
    dest === src && return dest # avoid unnecessary work if same object

    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    dest.timestamp != src.timestamp && throw(
        MergeConflictError(
            "Variables has different timestamps: $(dest.timestamp) vs $(src.timestamp).",
        ),
    )
    # you will get a method error if statekind is different, so maybe we don't need to check that here.

    union!(dest.tags, src.tags)
    merge!(dest.states, src.states)
    merge!(dest.blobentries, src.blobentries)
    merge!(dest.bloblets, src.bloblets)

    dest.solvable[] = src.solvable[]

    return dest
end

##------------------------------------------------------------------------------
## VariableSummary lv1
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Summary variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
@tags struct VariableSummary <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable event timestamp.
    $variable_timestamp_note
    Accessors: [`getTimestamp`](@ref)"""
    timestamp::TimeDateZone
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol}
    """Solvable flag for the variable.
    Accessors: [`getSolvable`](@ref), [`setSolvable!`](@ref)"""
    solvable::Base.RefValue{Int}
    """Symbol for the state type for the underlying variable."""
    statekind::AbstractStateType
end

##------------------------------------------------------------------------------
## VariableSkeleton.jl
##------------------------------------------------------------------------------

"""
$(TYPEDEF)
Skeleton variable structure for a DistributedFactorGraph variable.

  ---
Fields:
$(TYPEDFIELDS)
"""
Base.@kwdef struct VariableSkeleton <: AbstractGraphVariable
    """Variable label, e.g. :x1.
    Accessor: [`getLabel`](@ref)"""
    label::Symbol
    """Variable tags, e.g [:POSE, :VARIABLE, and :LANDMARK].
    Accessors: [`listTags`](@ref), [`mergeTags!`](@ref), and [`deleteTags!`](@ref)"""
    tags::Set{Symbol} = Set{Symbol}()
end

function VariableSkeleton(label::Symbol, tags = Set{Symbol}();)
    return VariableSkeleton(label, tags)
end

##==============================================================================
## Conversion constructors
##==============================================================================

function VariableSummary(v::VariableDFG{T}) where {T}
    return VariableSummary(v.label, v.timestamp, copy(v.tags), deepcopy(v.solvable), T())
end

function VariableSkeleton(v::AbstractGraphVariable)
    return VariableSkeleton(v.label, copy(v.tags))
end

##==============================================================================
## patch! for Summary/Skeleton types
##==============================================================================

function patch!(dest::VariableSummary, src::VariableSummary)
    dest === src && return dest
    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    dest.timestamp != src.timestamp && throw(
        MergeConflictError(
            "Variables has different timestamps: $(dest.timestamp) vs $(src.timestamp).",
        ),
    )
    dest.statekind !== src.statekind && throw(
        MergeConflictError(
            "Variables has different statekinds: $(dest.statekind) vs $(src.statekind).",
        ),
    )

    union!(dest.tags, src.tags)
    dest.solvable[] = src.solvable[]

    return dest
end

function patch!(dest::VariableSkeleton, src::VariableSkeleton)
    dest === src && return dest
    dest.label !== src.label && throw(
        MergeConflictError("Variables has different labels: $(dest.label) vs $(src.label)"),
    )
    union!(dest.tags, src.tags)
    return dest
end

function Base.show(io::IO, ::MIME"text/plain", v::VariableDFG)
    return printVariable(io, v; short = true, limit = false)
end

# ==============================================================================
# State(::VariableDFG,...) operations
# ==============================================================================

function addState!(v::VariableDFG, state::State)
    if haskey(refStates(v), state.label)
        throw(LabelExistsError("State", state.label))
    end
    refStates(v)[state.label] = state
    return state
end

function getState(v::VariableDFG, label::Symbol)
    !haskey(refStates(v), label) && throw(LabelNotFoundError("State", label))
    return refStates(v)[label]
end

function mergeState!(v::VariableDFG, vnd::State)
    if !haskey(v.states, vnd.label)
        addState!(v, vnd)
    else
        v.states[vnd.label] = vnd
    end
    return 1
end

function deleteState!(v::VariableDFG, label::Symbol)
    !haskey(v.states, label) && return 0
    delete!(v.states, label)
    return 1
end

function listStates(v::VariableDFG; whereLabel::Union{Nothing, Function} = nothing)
    labels = collect(keys(v.states))
    return filterDFG!(labels, whereLabel)
end
