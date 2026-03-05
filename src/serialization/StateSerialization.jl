
function lowerStateKind(varT::AbstractStateType{N}) where {N}
    typemeta = TypeMetadata(typeof(varT))
    if N == Any
        return typemeta
        # return string(parentmodule(T), ".", nameof(T))
    elseif N isa Integer
        return TypeMetadata(
            typemeta.pkg,
            Symbol(typemeta.name, "{", N, "}"),
            typemeta.version,
        )
        # return string(parentmodule(T), ".", nameof(T), "{", join(N, ","), "}")
    else
        throw(
            SerializationError(
                "Serializing Variable State type only supports an integer parameter, got '$(N)'.",
            ),
        )
    end
end

#NOTE Cannot resolve with `resolveType` because of the N parameter
# tried resolveType(JSON.Object(:type=>obj))
function liftStateKind(type::DFG.JSON.Object)
    pkg = Base.require(Main, Symbol(type.pkg))
    if !isdefined(Main, Symbol(type.pkg))
        throw(SerializationError("Module $(pkg) is available, but not loaded in `Main`."))
    end
    m = match(r"{(\d+)}", type.name)
    if !isnothing(m) #parameters in type
        param = parse(Int, m[1])
        typeString = type.name[1:(m.offset - 1)]
        return getfield(pkg, Symbol(typeString)){param}()
    else
        typeString = type.name
        return getfield(pkg, Symbol(typeString))()
    end
end

StructUtils.structlike(::Type{<:AbstractStateType}) = false
StructUtils.lower(T::AbstractStateType) = lowerStateKind(T)
StructUtils.lift(::Type{AbstractStateType}, s) = liftStateKind(s)

##==============================================================================
## OLD State Packing and unpacking - Deprecated v0.29 - kept for migration
##==============================================================================

function parseStateKind(_typeString::AbstractString)
    m = match(r"{(\d+)}", _typeString)
    if !isnothing(m) #parameters in type
        param = parse(Int, m[1])
        typeString = _typeString[1:(m.offset - 1)]
    else
        param = nothing
        typeString = _typeString
    end

    split_typeSyms = Symbol.(split(typeString, "."))

    subtype = nothing

    if length(split_typeSyms) == 1
        @warn "Module not found in variable '$typeString'." maxlog = 1
        subtype = getfield(Main, split_typeSyms[1]) # no module specified, use Main
    #FIXME interm fallback for backwards compatibility in IIFTypes and RoMETypes
    elseif split_typeSyms[1] in Symbol.(values(Base.loaded_modules))
        m = getfield(Main, split_typeSyms[1])
        subtype = getfield(m, split_typeSyms[end])
    else
        @warn "Module not found in Main, using Main for type '$typeString'." maxlog = 1
        subtype = getfield(Main, split_typeSyms[end])
    end

    if isnothing(subtype)
        throw(SerializationError("Unable to deserialize type $(_typeString), not found"))
    end

    if isnothing(param)
        # no parameters, just return the type
        return subtype()
    else
        # return the type with parameters
        return subtype{param}()
    end
end

# Old PackedState struct fields
# id::Union{UUID, Nothing}
# vecval::Vector{Float64}
# dimval::Int
# vecbw::Vector{Float64}
# dimbw::Int
# BayesNetOutVertIDs::Vector{Symbol}
# dimIDs::Vector{Int}
# dims::Int
# eliminated::Bool
# BayesNetVertID::Symbol
# separator::Vector{Symbol}
# variableType::String
# initialized::Bool
# infoPerCoord::Vector{Float64}
# ismargin::Bool
# dontmargin::Bool
# solvedCount::Int
# solveKey::Symbol
# covar::Vector{Float64}
# _version::VersionNumber = _getDFGVersion()

function unpackOldState(d)
    @debug "Dispatching conversion packed variable -> variable for type $(string(d.variableType))"
    # Figuring out the variableType
    statekind = parseStateKind(d.variableType)
    T = typeof(statekind)
    
    r3 = d.dimval
    c3 = r3 > 0 ? floor(Int, length(d.vecval) / r3) : 0
    M3 = reshape(d.vecval, r3, c3)
    @cast val_[j][i] := M3[i, j]
    vals = Vector{getPointType(T)}(undef, length(val_))
    # vals = getPoint.(T, val_)
    for (i, v) in enumerate(val_)
        vals[i] = getPoint(T, v)
    end

    r4 = d.dimbw
    c4 = r4 > 0 ? floor(Int, length(d.vecbw) / r4) : 0
    BW = reshape(d.vecbw, r4, c4)

    # 
    label = Symbol(d.solveKey)
    !isempty(d.covar) && error("covar field is not supported")
    if label == :parametric
        belief =
            BeliefRepresentation(GaussianDensityKind(), statekind; means = vals, covariances = [BW])
    else
        belief = BeliefRepresentation(
            NonparametricDensityKind(),
            statekind;
            points = vals,
            bandwidth = BW,
        )
    end
    return State{T, getPointType(T)}(;
        label,
        belief,
        separator = Symbol.(d.separator),
        initialized = d.initialized,
        observability = d.infoPerCoord,
        marginalized = d.ismargin,
        solves = d.solvedCount,
    )
end
