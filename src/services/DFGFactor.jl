##==============================================================================
## Accessors
##==============================================================================

function getMetadata(f::FactorDFG)
    return JSON3.read(base64decode(f.metadata), Dict{Symbol, SmallDataTypes})
end

##==============================================================================
## GenericFunctionNodeData
##==============================================================================

## COMMON
# getSolveInProgress
# isSolveInProgress

#TODO  getFactorFunction = getFactorType
"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fcd::GenericFunctionNodeData) = fcd.fnc.usrfnc!
getFactorFunction(fc::FactorCompute) = getObservation(fc)
getFactorFunction(dfg::AbstractDFG, fsym::Symbol) = getFactorFunction(getFactor(dfg, fsym))

"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
function getFactorType(data::GenericFunctionNodeData{<:FactorOperationalMemory})
    #TODO deprecated in v0.27
    Base.depwarn("getFactorType(::GenericFunctionNodeData) is deprecated", :getFactorType)
    return data.fnc.usrfnc!
end
function getFactorType(data::GenericFunctionNodeData{<:AbstractFactor})
    #TODO deprecated in v0.27
    Base.depwarn("getFactorType(::GenericFunctionNodeData) is deprecated", :getFactorType)
    return data.fnc
end
getFactorType(fct::FactorCompute) = getObservation(fct)
getFactorType(f::FactorDFG) = getTypeFromSerializationModule(f.fnctype)() # TODO find a better way to do this that does not rely on empty constructor
getFactorType(dfg::AbstractDFG, lbl::Symbol) = getFactorType(getFactor(dfg, lbl))

getState(f::AbstractDFGFactor) = f.state

getFactorState(f::AbstractDFGFactor) = f.state
getFactorState(dfg::AbstractDFG, lbl::Symbol) = getFactorState(getFactor(dfg, lbl))

getObservation(f::FactorCompute) = f.observation
function getObservation(f::FactorDFG)
    #FIXME completely refactor to not need getTypeFromSerializationModule and just use StructTypes
    packtype = DFG.getTypeFromSerializationModule("Packed" * f.fnctype)
    return packtype(; JSON3.read(f.observJSON)...)
    # return packtype(JSON3.read(f.observJSON))
end

function getWorkmem(f::FactorCompute)
    if isassigned(f.workmem)
        return f.workmem[]
    else
        return nothing
    end
end
setWorkmem!(f::FactorCompute, workmem::FactorOperationalMemory) = f.workmem[] = workmem

"""
    $SIGNATURES

If you know a variable is `::Type{<:Pose2}` but want to find its default prior `::Type{<:PriorPose2}`.

Assumptions
- The prior type will be defined in the same module as the variable type.
- Not exported per default, but can be used with knowledge of the caveats.

Example
```julia
using RoME
@assert RoME.PriorPose2 == DFG._getPriorType(Pose2)
```
"""
function _getPriorType(_type::Type{<:InferenceVariable})
    return getfield(_type.name.module, Symbol(:Prior, _type.name.name))
end

##==============================================================================
## Default Factors Function Macro
##==============================================================================
export PackedSamplableBelief

function pack end
function unpack end
function packDistribution end
function unpackDistribution end

abstract type PackedSamplableBelief end
StructTypes.StructType(::Type{<:PackedSamplableBelief}) = StructTypes.UnorderedStruct()

#TODO remove, rather use StructTypes.jl properly
function Base.convert(::Type{<:PackedSamplableBelief}, nt::Union{NamedTuple, JSON3.Object})
    distrType = getTypeFromSerializationModule(nt._type)
    return distrType(; nt...)
end

"""
    @defFactorType StructName factortype<:AbstractFactor manifolds<:AbstractManifold

A macro to create a new factor function with name `StructName` and manifold. Note that
the `manifold` is an object and *must* be a subtype of `ManifoldsBase.AbstractManifold`.
See documentation in [Manifolds.jl on making your own](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html). 

Example:
```
DFG.@defFactorType Pose2Pose2 AbstractManifoldMinimize SpecialEuclidean(2)
```
"""
macro defFactorType(structname, factortype, manifold)
    packedstructname = Symbol("Packed", structname)
    return esc(
        quote
            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "@defFactorType manifold (" *
                                                     string($manifold) *
                                                     ") is not an `AbstractManifold`"

            @assert ($factortype <: AbstractFactor) "@defFactorType factortype (" *
                                                    string($factortype) *
                                                    ") is not an `AbstractFactor`"

            Base.@__doc__ struct $structname{T} <: $factortype
                Z::T
            end

            #TODO should this be $packedstructname{T <: PackedSamplableBelief}
            Base.@__doc__ struct $packedstructname <: AbstractPackedFactor
                Z::PackedSamplableBelief
            end

            # $structname(; Z) = $structname(Z)                                                     
            $packedstructname(; Z) = $packedstructname(Z)
            DFG.getManifold(::Type{$structname}) = $manifold
            DFG.pack(d::$structname) = $packedstructname(DFG.packDistribution(d.Z))
            DFG.unpack(d::$packedstructname) = $structname(DFG.unpackDistribution(d.Z))
        end,
    )
end

##==============================================================================
## Factors
##==============================================================================
# |                   | label | tags | timestamp | solvable | solverData |
# |-------------------|:-----:|:----:|:---------:|:--------:|:----------:|
# | FactorSkeleton |   X   |   x  |           |          |            |
# | FactorSummary  |   X   |   X  |     X     |          |            |
# | FactorCompute         |   X   |   X  |     X     |     X    |      X     |

##------------------------------------------------------------------------------
## label
##------------------------------------------------------------------------------

## COMMON
# getLabel

##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------

## COMMON
# getTags
# setTags!

##------------------------------------------------------------------------------
## timestamp
##------------------------------------------------------------------------------

## COMMON
# getTimestamp

function setTimestamp(f::AbstractDFGFactor, ts::DateTime, timezone = localzone())
    return setTimestamp(f, ZonedDateTime(ts, timezone))
end
function setTimestamp(f::FactorCompute, ts::ZonedDateTime)
    return FactorCompute(
        f.label,
        getfield(f, :_variableOrderSymbols),
        f.solverData;
        timestamp = ts,
        nstime = f.nstime,
        tags = f.tags,
        solvable = f.solvable,
        id = f.id,
    )
end
function setTimestamp(f::FactorSummary, ts::ZonedDateTime)
    return FactorSummary(f.id, f.label, f.tags, f._variableOrderSymbols, ts)
end
function setTimestamp(f::FactorSummary, ts::DateTime)
    return FactorSummary(f, ZonedDateTime(ts, localzone()))
end

function setTimestamp(v::FactorDFG, timestamp::ZonedDateTime)
    return FactorDFG(;
        (key => getproperty(v, key) for key in fieldnames(FactorDFG))...,
        timestamp,
    )
end

##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

## COMMON
# getSolvable
# setSolvable!
# isSolvable

##------------------------------------------------------------------------------
## solvable
##------------------------------------------------------------------------------

## COMMON

##------------------------------------------------------------------------------
## _variableOrderSymbols
##------------------------------------------------------------------------------

#TODO perhaps making _variableOrderSymbols imutable (NTuple) will be a save option
"""
$SIGNATURES

Get the variable ordering for this factor.
Should be equivalent to listNeighbors unless something was deleted in the graph.
"""
getVariableOrder(fct::FactorCompute) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(fct::FactorDFG) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

##------------------------------------------------------------------------------
## utility
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Return `::Bool` on whether given factor `fc::Symbol` is a prior in factor graph `dfg`.
"""
function isPrior(dfg::AbstractDFG, fc::Symbol)
    fco = getFactor(dfg, fc)
    return isPrior(getFactorType(fco))
end

function isPrior(::AbstractPrior)
    return true
end

function isPrior(::AbstractRelative)
    return false
end

##==============================================================================
## Layer 2 CRUD (none) and Sets
##==============================================================================

##==============================================================================
## TAGS - See CommonAccessors
##==============================================================================
