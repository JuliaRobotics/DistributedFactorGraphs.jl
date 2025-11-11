
function stringVariableType(varT::AbstractStateType{N}) where {N}
    T = typeof(varT)
    if N == Any
        return string(parentmodule(T), ".", nameof(T))
    elseif N isa Integer
        return string(parentmodule(T), ".", nameof(T), "{", join(N, ","), "}")
    else
        throw(
            SerializationError(
                "Serializing Variable State type only supports an integer parameter, got '$(T)'.",
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

##==============================================================================
## State Packing and unpacking
##==============================================================================

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
        # d.BayesNetOutVertIDs,
        # d.eliminated,
        # d.BayesNetVertID,
        d.separator,
        stringVariableType(getVariableType(d)),
        d.initialized,
        d.infoPerCoord,
        d.ismargin,
        d.dontmargin,
        # d.solveInProgress,
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
        # BayesNetOutVertIDs = Symbol.(d.BayesNetOutVertIDs),
        # eliminated = d.eliminated,
        # BayesNetVertID = Symbol(d.BayesNetVertID),
        separator = Symbol.(d.separator),
        initialized = d.initialized,
        infoPerCoord = d.infoPerCoord,
        ismargin = d.ismargin,
        dontmargin = d.dontmargin,
        # solveInProgress = d.solveInProgress,
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
    includeSolveData::Bool = true,
    includeDataEntries::Bool = true,
)
    return VariableDFG(;
        id = v.id,
        label = v.label,
        timestamp = v.timestamp,
        nstime = string(v.nstime.value),
        tags = collect(v.tags), # Symbol.()
        solverData = packState.(collect(values(v.solverDataDict))),
        metadata = base64encode(JSON.json(v.smallData)),
        solvable = getSolvable(v),
        variableType = stringVariableType(DFG.getVariableType(v)),
        blobEntries = collect(values(v.dataDict)),
        _version = _getDFGVersion(),
    )
end

function packVariable(
    v::VariableDFG;
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

    N = getDimension(variableType)
    solverDict = Dict{Symbol, State{variableType, pointType, N}}(
        map(sd -> sd.solveKey, variable.solverData) .=>
            map(sd -> DFG.unpackState(sd), variable.solverData),
    )
    dataDict = Dict{Symbol, Blobentry}(
        map(de -> de.label, variable.blobEntries) .=> variable.blobEntries,
    )
    metadata = JSON.parse(base64decode(variable.metadata), Dict{Symbol, DFG.MetadataTypes})

    return VariableCompute(
        variable.label,
        variableType;
        id = variable.id,
        timestamp = variable.timestamp,
        nstime = Nanosecond(variable.nstime),
        tags = Set(variable.tags),
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
