##==============================================================================
## Accessors
##==============================================================================

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
getFactorFunction(fc::DFGFactor) = getFactorFunction(getSolverData(fc))
getFactorFunction(dfg::AbstractDFG, fsym::Symbol) = getFactorFunction(getFactor(dfg, fsym))

"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(data::GenericFunctionNodeData) = data.fnc.usrfnc!
getFactorType(fct::DFGFactor) = getFactorType(getSolverData(fct))
getFactorType(dfg::AbstractDFG, lbl::Symbol) = getFactorType(getFactor(dfg, lbl))

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
# export pack, unpack, packDistribution, unpackDistribution

function pack end
function unpack end
function packDistribution end
function unpackDistribution end

abstract type PackedSamplableBelief end
StructTypes.StructType(::Type{<:PackedSamplableBelief}) = StructTypes.UnorderedStruct()

"""
    @defFactorType StructName factortype<:AbstractFactor manifolds<:ManifoldsBase.AbstractManifold

A macro to create a new factor function with name `StructName` and manifolds.  Note that 
the `manifolds` is an object and *must* be a subtype of `ManifoldsBase.AbstractManifold`.
See documentation in [Manifolds.jl on making your own](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html). 

Example:
```
DFG.@defFactorType Pose2Pos2 AbstractManifoldMinimize SpecialEuclidean(2)
```
"""
macro defFactorType(structname, factortype, manifold)
    packedstructname = Symbol("Packed", structname)
    return esc(
        quote
            Base.@__doc__ struct $structname{T} <: $factortype
                Z::T
            end

            Base.@__doc__ struct $packedstructname{T<:PackedSamplableBelief} <: AbstractPackedFactor 
                Z::T
            end

            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "@defVariable of " *
                                                     string($structname) *
                                                     " requires that the " *
                                                     string($manifold) *
                                                     " be a subtype of `ManifoldsBase.AbstractManifold`"

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
# | SkeletonDFGFactor |   X   |   x  |           |          |            |
# | DFGFactorSummary  |   X   |   X  |     X     |          |            |
# | DFGFactor         |   X   |   X  |     X     |     X    |      X     |

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
function setTimestamp(f::DFGFactor, ts::ZonedDateTime)
    return DFGFactor(
        f.label,
        ts,
        f.nstime,
        f.tags,
        f.solverData,
        f.solvable,
        getfield(f, :_variableOrderSymbols);
        id = f.id,
    )
end
function setTimestamp(f::DFGFactorSummary, ts::ZonedDateTime)
    return DFGFactorSummary(f.id, f.label, f.tags, f._variableOrderSymbols, ts)
end
function setTimestamp(f::DFGFactorSummary, ts::DateTime)
    return DFGFactorSummary(f, ZonedDateTime(ts, localzone()))
end

function setTimestamp(v::PackedFactor, timestamp::ZonedDateTime)
    return PackedFactor(;
        (key => getproperty(v, key) for key in fieldnames(PackedFactor))...,
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
getVariableOrder(fct::DFGFactor) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(fct::PackedFactor) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

##------------------------------------------------------------------------------
## solverData
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getSolverData(f::F) where {F <: DFGFactor}
    return f.solverData
end

setSolverData!(f::DFGFactor, data::GenericFunctionNodeData) = f.solverData = data

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
