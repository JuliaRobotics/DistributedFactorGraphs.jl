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
_getPriorType(_type::Type{<:InferenceVariable}) = getfield(_type.name.module, Symbol(:Prior, _type.name.name))


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

setTimestamp(f::AbstractDFGFactor, ts::DateTime, timezone=localzone()) = setTimestamp(f, ZonedDateTime(ts,  timezone))
setTimestamp(f::DFGFactor, ts::ZonedDateTime) = DFGFactor(f.label, ts, f.nstime, f.tags, f.solverData, f.solvable, getfield(f,:_variableOrderSymbols); id=f.id)
setTimestamp(f::DFGFactorSummary, ts::ZonedDateTime) = DFGFactorSummary(f.id, f.label, f.tags, f._variableOrderSymbols, ts)
setTimestamp(f::DFGFactorSummary, ts::DateTime) = DFGFactorSummary(f, ZonedDateTime(ts, localzone()))

function setTimestamp(v::PackedFactor, timestamp::ZonedDateTime)
  return PackedFactor(;(key => getproperty(v, key) for key in fieldnames(PackedFactor))..., timestamp)
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
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

##------------------------------------------------------------------------------
## solverData
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Retrieve solver data structure stored in a factor.
"""
function getSolverData(f::F) where F <: DFGFactor
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
  isPrior(getFactorType(fco))
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
