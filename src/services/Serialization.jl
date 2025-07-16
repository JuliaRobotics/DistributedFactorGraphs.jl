## Version checking
#NOTE fixed really bad function but kept similar as fallback #TODO upgrade to use pkgversion(m::Module)
function _getDFGVersion()
    return pkgversion(DistributedFactorGraphs)
end

function _versionCheck(node::Union{<:VariableDFG, <:FactorDFG})
    if node._version.minor < _getDFGVersion().minor
        @warn "This data was serialized using DFG $(node._version) but you have $(_getDFGVersion()) installed, there may be deserialization issues." maxlog =
            10
    end
end

function stringVariableType(varT::StateType)
    T = typeof(varT)
    #FIXME maybe don't use .parameters
    Tparams = T.parameters
    if length(Tparams) == 0
        return string(parentmodule(T), ".", nameof(T))
    elseif length(Tparams) == 1 && Tparams[1] isa Integer
        return string(parentmodule(T), ".", nameof(T), "{", join(Tparams, ","), "}")
    else
        throw(
            SerializationError(
                "Serializing Variable State type only supports 1 integer parameter, got '$(T)'.",
            ),
        )
    end
end

function parseVariableType(_typeString::AbstractString)
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
        return nothing
    end

    if isnothing(param)
        # no parameters, just return the type
        return subtype
    else
        # return the type with parameters
        return subtype{param}
    end
end

"""
    $(SIGNATURES)
Get a type from the serialization module.
"""
function getTypeFromSerializationModule(_typeString::AbstractString)
    @debug "DFG converting type string to Julia type" _typeString
    try
        # split the type at last `.`
        split_st = split(_typeString, r"\.(?!.*\.)")
        #if module is specified look for the module in main, otherwise use Main        
        if length(split_st) == 2
            m = getfield(Main, Symbol(split_st[1]))
        else
            m = Main
        end
        noparams = split(split_st[end], r"{")
        ret = if 1 < length(noparams)
            # fix #671, but does not work with specific module yet
            bidx = findfirst(r"{", split_st[end])[1]
            Core.eval(m, Base.Meta.parse("$(noparams[1])$(split_st[end][bidx:end])"))
            # eval(Base.Meta.parse("Main.$(noparams[1])$(split_st[end][bidx:end])"))
        else
            getfield(m, Symbol(split_st[end]))
        end

        return ret

    catch ex
        @error "Unable to deserialize type $(_typeString)"
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        @error(err)
    end
    return nothing
end

# returns a PackedState
function packState(d::State{T}) where {T <: StateType}
    @debug "Dispatching conversion variable -> packed variable for type $(string(getVariableType(d)))"
    castval = if 0 < length(d.val)
        precast = getCoordinates.(T, d.val)
        @cast castval[i, j] := precast[j][i]
        castval
    else
        zeros(1, 0)
    end
    _val = castval[:]

    length(d.covar) > 1 && @warn(
        "Packing of more than one parametric covariance is NOT supported yet, only packing first."
    )

    return PackedState(
        d.id,
        _val,
        size(castval, 1),
        d.bw[:],
        size(d.bw, 1),
        d.BayesNetOutVertIDs,
        d.dimIDs,
        d.dims,
        d.eliminated,
        d.BayesNetVertID,
        d.separator,
        stringVariableType(getVariableType(d)),
        d.initialized,
        d.infoPerCoord,
        d.ismargin,
        d.dontmargin,
        d.solveInProgress,
        d.solvedCount,
        d.solveKey,
        isempty(d.covar) ? Float64[] : vec(d.covar[1]),
        _getDFGVersion(),
    )
end

function unpackState(d::PackedState)
    @debug "Dispatching conversion packed variable -> variable for type $(string(d.variableType))"
    # Figuring out the variableType
    # TODO deprecated remove in v0.11 - for backward compatibility for saved variableTypes. 
    ststring = string(split(d.variableType, "(")[1])
    T = parseVariableType(ststring)
    isnothing(T) && error(
        "The variable doesn't seem to have a variableType. It needs to set up with an StateType from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().",
    )

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
    N = getDimension(T)
    return State{T, getPointType(T), N}(;
        id = d.id,
        val = vals,
        bw = BW,
        #TODO only one covar is currently supported in packed VND
        covar = isempty(d.covar) ? SMatrix{N, N, Float64}[] : [d.covar],
        BayesNetOutVertIDs = Symbol.(d.BayesNetOutVertIDs),
        dimIDs = d.dimIDs,
        dims = d.dims,
        eliminated = d.eliminated,
        BayesNetVertID = Symbol(d.BayesNetVertID),
        separator = Symbol.(d.separator),
        initialized = d.initialized,
        infoPerCoord = d.infoPerCoord,
        ismargin = d.ismargin,
        dontmargin = d.dontmargin,
        solveInProgress = d.solveInProgress,
        solvedCount = d.solvedCount,
        solveKey = Symbol(d.solveKey),
        events = Dict{Symbol, Threads.Condition}(),
    )
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================

function packVariable(
    v::VariableCompute;
    includePPEs::Bool = true,
    includeSolveData::Bool = true,
    includeDataEntries::Bool = true,
)
    return VariableDFG(;
        id = v.id,
        label = v.label,
        timestamp = v.timestamp,
        nstime = string(v.nstime.value),
        tags = collect(v.tags), # Symbol.()
        ppes = collect(values(v.ppeDict)),
        solverData = packState.(collect(values(v.solverDataDict))),
        metadata = base64encode(JSON3.write(v.smallData)),
        solvable = v.solvable,
        variableType = stringVariableType(DFG.getVariableType(v)),
        blobEntries = collect(values(v.dataDict)),
        _version = _getDFGVersion(),
    )
end

function packVariable(
    v::VariableDFG;
    includePPEs::Bool = true,
    includeSolveData::Bool = true,
    includeDataEntries::Bool = true,
)
    return v
end

function unpackVariable(variable::VariableDFG; skipVersionCheck::Bool = false)
    !skipVersionCheck && _versionCheck(variable)

    # Variable and point type
    variableType = parseVariableType(variable.variableType)
    isnothing(variableType) && error(
        "Cannot deserialize variableType '$(variable.variableType)' in variable '$(variable.label)'",
    )
    pointType = DFG.getPointType(variableType)

    ppeDict =
        Dict{Symbol, MeanMaxPPE}(map(p -> p.solveKey, variable.ppes) .=> variable.ppes)

    N = getDimension(variableType)
    solverDict = Dict{Symbol, State{variableType, pointType, N}}(
        map(sd -> sd.solveKey, variable.solverData) .=>
            map(sd -> DFG.unpackState(sd), variable.solverData),
    )
    dataDict = Dict{Symbol, Blobentry}(
        map(de -> de.label, variable.blobEntries) .=> variable.blobEntries,
    )
    metadata = JSON3.read(base64decode(variable.metadata), Dict{Symbol, DFG.SmallDataTypes})

    return VariableCompute(
        variable.label,
        variableType;
        id = variable.id,
        timestamp = variable.timestamp,
        nstime = Nanosecond(variable.nstime),
        tags = Set(variable.tags),
        ppeDict = ppeDict,
        solverDataDict = solverDict,
        smallData = metadata,
        dataDict = dataDict,
        solvable = variable.solvable,
    )
end

VariableCompute(v::VariableCompute) = v
VariableCompute(v::VariableDFG) = unpackVariable(v)
VariableDFG(v::VariableDFG) = v
VariableDFG(v::VariableCompute) = packVariable(v)

##==============================================================================
## Factor Packing and unpacking
##==============================================================================

# returns FactorDFG
function packFactor(f::FactorCompute)
    obstype = typeof(getObservation(f))
    fnctype = string(parentmodule(obstype), ".", nameof(obstype))

    return FactorDFG(;
        id = f.id,
        label = f.label,
        tags = f.tags,
        _variableOrderSymbols = f._variableOrderSymbols,
        timestamp = f.timestamp,
        nstime = string(f.nstime.value),
        #TODO fully test include module name in factor fnctype, see #1140
        # fnctype = String(_getname(getObservation(f))),
        fnctype,
        solvable = getSolvable(f),
        metadata = base64encode(JSON3.write(f.smallData)),
        # Pack the node data
        _version = _getDFGVersion(),
        state = f.state,
        observJSON = JSON3.write(packObservation(f)),
    )
    return props
end

packFactor(f::FactorDFG) = f

function unpackObservation(factor::FactorDFG)
    try
        return unpack(getObservation(factor))
    catch e
        if e isa MethodError && e.f == unpack
            Base.depwarn(
                """$e\nPlease implement pack and unpack methods for the factor type '$(typeof(getObservation(factor)))'.
                Falling back to deprecated convert method.""",
                :unpackObservation,
            )
            #FIXME completely refactor to not need getTypeFromSerializationModule and just use StructTypes
            #TODO change to unpack: observ = unpack(observpacked)
            # currently the observation type is stored in the factor and this complicates unpacking of seperate observations
            observpacked = getObservation(factor)
            return convert(convertStructType(typeof(observpacked)), observpacked)
        else
            rethrow()
        end
    end
end

packObservation(f::FactorCompute) = packObservation(getObservation(f))
function packObservation(observ::AbstractObservation)
    try
        return pack(observ)
    catch e
        if e isa MethodError
            Base.depwarn(
                "$e\nPlease implement pack and unpack methods for the factor type '$(typeof(observ))'.
                \nFalling back to deprecated convert method.",
                :packObservation,
            )
            packtype = convertPackedType(observ)
            return convert(packtype, observ)
        else
            rethrow()
        end
    end
end

function unpackFactor(factor::FactorDFG; skipVersionCheck::Bool = false)
    #
    @debug "DECODING factor type = '$(factor.fnctype)' for factor '$(factor.label)'"
    !skipVersionCheck && _versionCheck(factor)

    local observation
    try
        observation = unpackObservation(factor) #TODO maybe getObservation(factor)
    catch
        @error "Error while unpacking '$(factor.label)' as '$(factor.fnctype)', please check the unpacking/packing converters for this factor"
        rethrow()
    end

    return FactorCompute(
        factor.id,
        factor.label,
        factor.tags,
        Tuple(factor._variableOrderSymbols),
        factor.timestamp,
        Nanosecond(factor.nstime),
        Ref(factor.solvable),
        getMetadata(factor),
        observation,
        factor.state,
        Ref{FactorCache}(),
    )
end

FactorCompute(f::FactorCompute) = f
FactorCompute(f::FactorDFG) = unpackFactor(f)
FactorDFG(f::FactorDFG) = f
FactorDFG(f::FactorCompute) = packFactor(f)
