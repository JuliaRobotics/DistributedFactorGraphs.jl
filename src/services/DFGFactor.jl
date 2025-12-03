##==============================================================================
## Accessors
##==============================================================================

## COMMON
# getSolveInProgress
# isSolveInProgress

"""
    $SIGNATURES

Return factor recipe state from factor graph.
"""
getRecipestate(f::AbstractGraphFactor) = f.state
getRecipestate(dfg::AbstractDFG, lbl::Symbol) = getRecipestate(getFactor(dfg, lbl))

"""
    $SIGNATURES
Return the hyperparameters associated with a factor in the factor graph.
These hyperparameters may include settings such as multi-hypothesis handling,
null hypothesis thresholds, and inflation factors that influence the behavior of the factor during optimization.
"""
getRecipehyper(f::AbstractGraphFactor) = f.hyper
getRecipehyper(dfg::AbstractDFG, lbl::Symbol) = getRecipehyper(getFactor(dfg, lbl))

"""
    $SIGNATURES

Return the observation of a factor, which is the user-defined data structure
that contains the information about the factor, such as the measurement, prior, or relative pose.
"""
getObservation(f::FactorDFG) = f.observation
getObservation(dfg::AbstractDFG, lbl::Symbol) = getObservation(getFactor(dfg, lbl))

"""
    $SIGNATURES
    
Return the solver cache for a factor, which is used to store intermediate results
during the solving process. This is useful for caching results that can be reused
across multiple solves, such as Jacobians or other computed values.
"""
function getCache(f::FactorDFG)
    if isassigned(f.solvercache)
        return f.solvercache[]
    else
        return nothing
    end
end

"""
    $SIGNATURES

Set the solver cache for a factor, which is used to store intermediate results
during the solving process. This is useful for caching results that can be reused
across multiple solves, such as Jacobians or other computed values.
"""
setCache!(f::FactorDFG, solvercache::FactorCache) = f.solvercache[] = solvercache

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
function _getPriorType(T::Type{<:StateType})
    return getfield(T.name.module, Symbol(:Prior, T.name.name))
end

##==============================================================================
## Default Factors Function Macro
##==============================================================================

"""
    @defObservationType StructName factortype<:AbstractObservation manifolds<:AbstractManifold

A macro to create a new factor function with name `StructName` and manifold. Note that
the `manifold` is an object and *must* be a subtype of `ManifoldsBase.AbstractManifold`.
See documentation in [Manifolds.jl on making your own](https://juliamanifolds.github.io/Manifolds.jl/stable/examples/manifold.html). 

Example:
```
DFG.@defObservationType Pose2Pose2 RelativeObservation SpecialEuclideanGroup(2)
```
"""
macro defObservationType(structname, factortype, manifold)
    # packedstructname = Symbol("Packed", structname)
    return esc(
        quote
            # user manifold must be a <:Manifold
            manifoldCheck = ($manifold isa AbstractManifold) || ($manifold isa Function)
            @assert manifoldCheck string($manifold) *
                                  " must be an `AbstractManifold` or a `Function` returning one."

            @assert ($factortype <: AbstractObservation) "@defObservationType factortype (" *
                                                         string($factortype) *
                                                         ") is not an `AbstractObservation`"

            Base.@__doc__ DFG.@tags struct $structname{T} <: $factortype
                Z::T & (lower = DFG.Packed, choosetype = DFG.resolvePackedType)
            end

            if $manifold isa AbstractManifold
                DFG.getManifold(::Type{<:$structname}) = $manifold
            elseif $manifold isa Function
                DFG.getManifold(obs::$structname) = $manifold(obs)
            end
        end,
    )
end

getManifold(obs::AbstractObservation) = getManifold(typeof(obs))
getManifold(f::AbstractGraphFactor) = getManifold(getObservation(f))

##==============================================================================
## Factors
##==============================================================================
# |                   | label | tags | timestamp | solvable | solverData |
# |-------------------|:-----:|:----:|:---------:|:--------:|:----------:|
# | FactorSkeleton |   X   |   x  |           |          |            |
# | FactorSummary  |   X   |   X  |     X     |          |            |
# | FactorDFG         |   X   |   X  |     X     |     X    |      X     |

##------------------------------------------------------------------------------
## label
##------------------------------------------------------------------------------

## COMMON
# getLabel

##------------------------------------------------------------------------------
## tags
##------------------------------------------------------------------------------

## COMMON

##------------------------------------------------------------------------------
## timestamp
##------------------------------------------------------------------------------

## COMMON

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
## variableorder
##------------------------------------------------------------------------------

#TODO perhaps making variableorder imutable (NTuple) will be a save option
"""
$SIGNATURES

Get the variable ordering for this factor.
Should be equivalent to listNeighbors unless something was deleted in the graph.
"""
getVariableOrder(fct::FactorDFG) = fct.variableorder
getVariableOrder(dfg::AbstractDFG, fct::Symbol) = getVariableOrder(getFactor(dfg, fct))

##------------------------------------------------------------------------------
## utility
##------------------------------------------------------------------------------

"""
    $SIGNATURES

Return `::Bool` on whether given factor `fc::Symbol` is a prior in factor graph `dfg`.
"""
function isPrior(::Type{T}) where {T <: AbstractObservation}
    return T <: AbstractPriorObservation
end

function isPrior(::T) where {T <: AbstractObservation}
    return isPrior(T)
end

isPrior(f::AbstractGraphFactor) = isPrior(getObservation(f))
isPrior(dfg::AbstractDFG, fl::Symbol) = isPrior(getFactor(dfg, fl))

##==============================================================================
## Layer 2 CRUD (none) and Sets
##==============================================================================

##==============================================================================
## TAGS - See CommonAccessors
##==============================================================================
