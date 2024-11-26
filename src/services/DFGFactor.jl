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
getFactorFunction(fc::FactorCompute) = getFactorFunction(getSolverData(fc))
getFactorFunction(dfg::AbstractDFG, fsym::Symbol) = getFactorFunction(getFactor(dfg, fsym))

"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(data::GenericFunctionNodeData) = data.fnc.usrfnc!
getFactorType(fct::FactorCompute) = getFactorType(getSolverData(fct))
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
        ts,
        f.nstime,
        f.tags,
        f.solverData,
        f.solvable,
        getfield(f, :_variableOrderSymbols);
        id = f.id,
    )
end
function setTimestamp(f::FactorSummary, ts::ZonedDateTime)
    return FactorSummary(f.id, f.label, f.tags, f._variableOrderSymbols, ts)
end
function setTimestamp(f::FactorSummary, ts::DateTime)
    return FactorSummary(f, ZonedDateTime(ts, localzone()))
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
getVariableOrder(fct::FactorCompute) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(fct::PackedFactor) = fct._variableOrderSymbols::Vector{Symbol}
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

##------------------------------------------------------------------------------
## solverData
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getSolverData(f::F) where {F <: FactorCompute}
    return f.solverData
end

setSolverData!(f::FactorCompute, data::GenericFunctionNodeData) = f.solverData = data

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
