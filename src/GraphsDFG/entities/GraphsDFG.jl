
"""
    $(SIGNATURES)

An in-memory DistributedFactorGraph based on Graphs.jl with parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
mutable struct GraphsDFG{T <: AbstractParams, V <: AbstractDFGVariable, F <:AbstractDFGFactor} <: AbstractDFG{T}
    g::FactorGraph{Int, V, F}
    description::String
    userLabel::String
    robotLabel::String
    sessionLabel::String
    userData::OrderedDict{Symbol, String}
    robotData::OrderedDict{Symbol, String}
    sessionData::OrderedDict{Symbol, String}
    userBlobEntries::OrderedDict{Symbol, BlobEntry}
    robotBlobEntries::OrderedDict{Symbol, BlobEntry}
    sessionBlobEntries::OrderedDict{Symbol, BlobEntry}
    addHistory::Vector{Symbol} #TODO: Discuss more - is this an audit trail?
    solverParams::T # Solver parameters
    blobStores::Dict{Symbol, <:AbstractBlobStore}
end

"""
    $(SIGNATURES)

Create an in-memory GraphsDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function GraphsDFG{T,V,F}(
    g::FactorGraph{Int,V,F}=FactorGraph{Int,V,F}();
    description::String="Graphs.jl implementation",
    userLabel::String="DefaultUser",
    robotLabel::String="DefaultRobot",
    sessionLabel::String="Session_$(string(uuid4())[1:6])",
    userData::OrderedDict{Symbol, SmallDataTypes} = OrderedDict{Symbol, SmallDataTypes}(),
    robotData::OrderedDict{Symbol, SmallDataTypes} = OrderedDict{Symbol, SmallDataTypes}(),
    sessionData::OrderedDict{Symbol, SmallDataTypes} = OrderedDict{Symbol, SmallDataTypes}(),
    userBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    robotBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    sessionBlobEntries::OrderedDict{Symbol, BlobEntry} = OrderedDict{Symbol, BlobEntry}(),
    solverParams::T=T(),
    blobstores=Dict{Symbol, AbstractBlobStore}(),
) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor}
    # Validate the userLabel, robotLabel, and sessionLabel
    !isValidLabel(userLabel) && error("'$userLabel' is not a valid User label")
    !isValidLabel(robotLabel) && error("'$robotLabel' is not a valid Robot label")
    !isValidLabel(sessionLabel) && error("'$sessionLabel' is not a valid Session label")

    return GraphsDFG{T,V,F}(
        g,
        description,
        userLabel,
        robotLabel,
        sessionLabel,
        userData,
        robotData,
        sessionData,
        userBlobEntries,
        robotBlobEntries,
        sessionBlobEntries,
        Symbol[],
        solverParams,
        blobstores
    )
end

# GraphsDFG{T}(; kwargs...) where T <: AbstractParams = GraphsDFG{T,DFGVariable,DFGFactor}(;kwargs...)

"""
    $(SIGNATURES)

Create an in-memory GraphsDFG with the following parameters:
- T: Solver parameters (defaults to `NoSolverParams()`)
- V: Variable type
- F: Factor type
"""
function GraphsDFG{T}(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                     kwargs...) where T <: AbstractParams
    return GraphsDFG{T,DFGVariable,DFGFactor}(g; kwargs...)
end

function GraphsDFG(g::FactorGraph{Int,DFGVariable,DFGFactor}=FactorGraph{Int,DFGVariable,DFGFactor}();
                  solverParams::T=NoSolverParams(), kwargs...) where T
    return GraphsDFG{T,DFGVariable,DFGFactor}(g; solverParams, kwargs...)
end


GraphsDFG(description::String,
         userLabel::String,
         robotLabel::String,
         sessionLabel::String,
         userData::OrderedDict{Symbol, SmallDataTypes},
         robotData::OrderedDict{Symbol, SmallDataTypes},
         sessionData::OrderedDict{Symbol, SmallDataTypes},
         solverParams::AbstractParams,
         blobstores=Dict{Symbol, AbstractBlobStore}()) =
         GraphsDFG(FactorGraph{Int,DFGVariable,DFGFactor}(), description, userLabel, robotLabel, sessionLabel, userData, robotData, sessionData, Symbol[], solverParams, blobstores)


GraphsDFG{T,V,F}(description::String,
                userLabel::String,
                robotLabel::String,
                sessionLabel::String,
                userData::OrderedDict{Symbol, SmallDataTypes},
                robotData::OrderedDict{Symbol, SmallDataTypes},
                sessionData::OrderedDict{Symbol, SmallDataTypes},
                solverParams::T,
                blobstores=Dict{Symbol, AbstractBlobStore}()) where {T <: AbstractParams, V <:AbstractDFGVariable, F<:AbstractDFGFactor} =
                GraphsDFG(FactorGraph{Int,V,F}(), description, userLabel, robotLabel, sessionLabel, userData, robotData, sessionData, Symbol[], solverParams, blobstores)
