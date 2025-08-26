##==============================================================================
## Accessors
##==============================================================================

function getMetadata(f::FactorDFG)
    return JSON3.read(base64decode(f.metadata), Dict{Symbol, SmallDataTypes})
end

## COMMON
# getSolveInProgress
# isSolveInProgress

#TODO  getFactorFunction = getFactorType
"""
    $SIGNATURES

Return reference to the user factor in `<:AbstractDFG` identified by `::Symbol`.
"""
getFactorFunction(fc::FactorCompute) = getObservation(fc)
getFactorFunction(dfg::AbstractDFG, fsym::Symbol) = getFactorFunction(getFactor(dfg, fsym))

"""
    $SIGNATURES

Return user factor type from factor graph identified by label `::Symbol`.

Notes
- Replaces older `getfnctype`.
"""
getFactorType(fct::FactorCompute) = getObservation(fct)
getFactorType(f::FactorDFG) = getTypeFromSerializationModule(f.fnctype)() # TODO find a better way to do this that does not rely on empty constructor
getFactorType(dfg::AbstractDFG, lbl::Symbol) = getFactorType(getFactor(dfg, lbl))

"""
    $SIGNATURES

Return factor state from factor graph.
"""
getFactorState(f::AbstractGraphFactor) = f.state
getFactorState(dfg::AbstractDFG, lbl::Symbol) = getFactorState(getFactor(dfg, lbl))

"""
    $SIGNATURES

Return the observation of a factor, which is the user-defined data structure
that contains the information about the factor, such as the measurement, prior, or relative pose.
"""
getObservation(f::FactorCompute) = f.observation
function getObservation(f::FactorDFG)
    #FIXME completely refactor to not need getTypeFromSerializationModule and just use StructTypes

    if contains(f.fnctype, ".")
        # packed factor contains a module name, just extracting type and ignoring module
        fnctype = split(f.fnctype, ".")[end]
    else
        fnctype = f.fnctype
    end

    packtype = DFG.getTypeFromSerializationModule("Packed" * fnctype)
    return packtype(; JSON3.read(f.observJSON)...)
    # return packtype(JSON3.read(f.observJSON))
end

getObservation(dfg::AbstractDFG, lbl::Symbol) = getObservation(getFactor(dfg, lbl))

"""
    $SIGNATURES
    
Return the solver cache for a factor, which is used to store intermediate results
during the solving process. This is useful for caching results that can be reused
across multiple solves, such as Jacobians or other computed values.
"""
function getCache(f::FactorCompute)
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
setCache!(f::FactorCompute, solvercache::FactorCache) = f.solvercache[] = solvercache

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
function _getPriorType(_type::Type{<:StateType})
    return getfield(_type.name.module, Symbol(:Prior, _type.name.name))
end

##==============================================================================
## Default Factors Function Macro
##==============================================================================

function pack end
function unpack end
function packDistribution end
function unpackDistribution end

StructTypes.StructType(::Type{<:PackedBelief}) = StructTypes.UnorderedStruct()

#TODO remove, rather use StructTypes.jl properly
function Base.convert(::Type{<:PackedBelief}, nt::Union{NamedTuple, JSON3.Object})
    distrType = getTypeFromSerializationModule(nt._type)
    return distrType(; nt...)
end

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
    packedstructname = Symbol("Packed", structname)
    return esc(
        quote
            # user manifold must be a <:Manifold
            @assert ($manifold isa AbstractManifold) "@defObservationType manifold (" *
                                                     string($manifold) *
                                                     ") is not an `AbstractManifold`"

            @assert ($factortype <: AbstractObservation) "@defObservationType factortype (" *
                                                         string($factortype) *
                                                         ") is not an `AbstractObservation`"

            Base.@__doc__ struct $structname{T} <: $factortype
                Z::T
            end

            #TODO should this be $packedstructname{T <: PackedBelief}
            Base.@__doc__ struct $packedstructname <: AbstractPackedObservation
                Z::PackedBelief
            end

            # $structname(; Z) = $structname(Z)                                                     
            $packedstructname(; Z) = $packedstructname(Z)
            DFG.getManifold(::Type{<:$structname}) = $manifold
            DFG.pack(d::$structname) = $packedstructname(DFG.packDistribution(d.Z))
            DFG.unpack(d::$packedstructname) = $structname(DFG.unpackDistribution(d.Z))
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

function setTimestamp(f::AbstractGraphFactor, ts::DateTime, timezone = localzone())
    return setTimestamp(f, ZonedDateTime(ts, timezone))
end
function setTimestamp(f::FactorCompute, ts::ZonedDateTime)
    return FactorCompute(
        f.label,
        getfield(f, :_variableOrderSymbols),
        f.observation,
        f.state;
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
