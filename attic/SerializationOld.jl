
# TODO dev and debugging, used by some of the DFG drivers
export _packSolverData

# For all types that pack their type into their own structure (e.g. PPE)
const TYPEKEY = "_type"

## Custom serialization
using JSON
import JSON.show_json
import JSON.Writer: StructuralContext, JSONContext, show_json
import JSON.Serializations: CommonSerialization, StandardSerialization
function JSON.show_json(io::JSONContext, serialization::CommonSerialization, uuid::UUID)
    return print(io.io, "\"$uuid\"")
end

## Version checking
# FIXME return VersionNumber
function _getDFGVersion()
    if haskey(Pkg.dependencies(), Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04"))
        return string(
            Pkg.dependencies()[Base.UUID("b5cc3c7e-6572-11e9-2517-99fb8daf2f04")].version,
        ) |> VersionNumber
    else
        # This is arguably slower, but needed for Travis.
        return Pkg.TOML.parse(
            read(joinpath(dirname(pathof(@__MODULE__)), "..", "Project.toml"), String),
        )["version"] |> VersionNumber
    end
end

function _versionCheck(props::Dict{String, Any})
    if haskey(props, "_version")
        if VersionNumber(props["_version"]) < _getDFGVersion()
            @warn "This data was serialized using DFG $(props["_version"]) but you have $(_getDFGVersion()) installed, there may be deserialization issues." maxlog =
                10
        end
    else
        error(
            "There isn't a version tag in this data so it's older than v0.10, deserialization expected to fail.",
        )
    end
end

## Utility functions for ZonedDateTime

# Regex parser that converts clauses like ":59.82-" to well formatted ":59.820-"
function _fixSubseconds(a)
    length(a) == 4 && return a[1:3] * ".000" * a[4]
    frac = a[5:(length(a) - 1)]
    frac = length(frac) > 3 ? frac[1:3] : frac * '0'^(3 - length(frac))
    return a[1:4] * frac * a[length(a)]
end

function getStandardZDTString(stringTimestamp::String)
    # Additional check+fix for the ultraweird "2020-08-12T12:00Z"
    ts = replace(stringTimestamp, r"T(\d\d):(\d\d)(Z|z|\+|-)" => s"T\1:\2:00.000\3")

    # This is finding :59Z or :59.82-05:00 and fixing it to always have 3 subsecond digits.
    # Temporary fix until TimeZones.jl gets an upstream fix.
    return replace(ts, r":\d\d(\.\d+)?(Z|z|\+|-)" => _fixSubseconds)
    # if occursin(r".*\:\d\d\+", packedProps["timestamp"]) 
    #     ZonedDateTime(packedProps["timestamp"], "yyyy-mm-ddTHH:MM:SSzzzz")
    # elseif occursin(r".*\:\d\d\.", packedProps["timestamp"])
    #     ZonedDateTime(packedProps["timestamp"], "yyyy-mm-ddTHH:MM:SS.sss+zzzz")
    # else
    #     ZonedDateTime(packedProps["timestamp"])
    # end
end

# Corrects any `::ZonedDateTime` fields of T in corresponding `interm::Dict` as `dateformat"yyyy-mm-ddTHH:MM:SS.ssszzz"`
function standardizeZDTStrings!(T, interm::Dict)
    for (name, typ) in zip(fieldnames(T), T.types)
        if typ <: ZonedDateTime && haskey(interm, name)
            namestr = string(name)
            interm[namestr] = getStandardZDTString(interm[namestr])
        end
    end
    return nothing
end

# variableType module.type string functions
function typeModuleName(variableType::InferenceVariable)
    io = IOBuffer()
    ioc = IOContext(io, :module => DistributedFactorGraphs)
    show(ioc, typeof(variableType))
    return String(take!(io))
end

typeModuleName(varT::Type{<:InferenceVariable}) = typeModuleName(varT())

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

## =============================================================================
## Transcoding / Unmarshal types helper
## =============================================================================

"""
    $SIGNATURES
Should be a highly reusable function for any transcoding of intermediate type (or dict) to a desired output type.

Notes:
- Using Base.@kwdef and JSON3.jl probably has better conversion logic than this function.
- This function was written to reduce dependency on Unmarshal.jl which was becoming stale.

DevNotes
- See if this function just be deprecated to use JSON3 or similar.
- Do better with Union{Nothing, T} types (if this function is not replaced by JSON3)

examples
```julia
Base.@kwdef struct HardType
    name::String
    time::DateTime = now(UTC)
    val::Float64 = 0.0
end

# slight human overhead for each type to ignore extraneous field construction
# TODO, devnote drop this requirement with filter of _names in transcodeType
HardType(;
    name::String,
    time::DateTime = now(UTC),
    val::Float64 = 0.0,
    ignorekws...
) = HardType(name,time,val)

# somehow one gets an intermediate type
imt = IntermediateType(
    v"1.0",
    "NotUsedYet",
    "test",
    now(UTC),
    1.0
)
# or dict (testing string keys)
imd = Dict(
    "_version" => v"1.0",
    "_type" => "NotUsedYet",
    "name" => "test",
    "time" => now(UTC),
    "val" => 1.0
)
# ordered dict (testing symbol keys)
iod = OrderedDict(
    :_version => v"1.0",
    :_type => "NotUsedYet",
    :name => "test",
    :time => now(UTC),
    # :val => 1.0
)

# do the transcoding to a slighly different hard type
T1 = transcodeType(HardType, imt)
T2 = transcodeType(HardType, imd)
T3 = transcodeType(HardType, iod)
```
"""
function transcodeType(::Type{T}, inObj) where {T}
    #
    # specializations as inner functions (don't have to be inners)
    # these few special cases came up with examples below, note recursions
    _instance(S::Type, x) = S(x)
    _instance(S::Type{Union{Nothing, UUID}}, x::String) = UUID(x) # special case
    _instance(_::Type{S}, x::S) where {S} = x # if ambiguous, delete and do alternative `_instance(S::Type, x) = S===Any ? x : S(x)`
    _instance(S::Type{I}, x::AbstractString) where {I <: Number} = Base.parse(I, x)
    function _instance(S::Type{E}, x::AbstractVector) where {E <: AbstractVector}
        return _instance.(eltype(E), x)
    end
    function _instance(S::Type{<:AbstractDict{K, V}}, x::AbstractDict) where {K, V}
        return (tup = (Symbol.(keys(x)) .=> _instance.(V, values(x))); S(tup...))
    end

    # what the struct wants
    _types = fieldtypes(T)
    _names = fieldnames(T)
    # (closure) resolve random ordering problem
    _getIdx(s::Symbol) = findfirst(x -> x == s, _names)
    # (closure) create an instance of a field
    makething(k::Symbol, v) = begin
        idx = _getIdx(k)
        if !isnothing(idx)
            # this field is in the output type and should be included
            k => _instance(_types[_getIdx(k)], v)
        else
            # this field should be ignored in the output type
            Symbol(:VOID_, rand(1:1000000)) => nothing
        end
    end
    # zip together keys/fields and values for either dict or intermediate type
    _srckeys(s::AbstractDict) = keys(s)
    _srckeys(s) = fieldnames(typeof(s))
    _srcvals(s::AbstractDict) = values(s)
    _srcvals(s) = map(k -> getproperty(s, k), _srckeys(s))
    # NOTE, improvement, filter extraneous fields not in _names
    arr = [makething(Symbol(k), v) for (k, v) in zip(_srckeys(inObj), _srcvals(inObj))]
    filter!(s -> s[1] in _names, arr)
    # create dict provided fields into a NamedTuple as a type stable "pre-struct"
    nt = (; arr...)
    # use keyword constructors provided by Base.@kwdef to resolve random ordering, incomplete dicts, and defaults
    return T(; nt...)
end

##==============================================================================
## Variable Packing and unpacking
##==============================================================================
function packVariable(v::VariableCompute)
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = v.timestamp
    props["nstime"] = v.nstime.value
    props["tags"] = v.tags
    props["ppeDict"] = v.ppeDict
    props["solverDataDict"] = (Dict(
        keys(v.solverDataDict) .=>
            map(vnd -> packVariableNodeData(vnd), values(v.solverDataDict)),
    ))
    props["metadata"] = v.smallData
    props["solvable"] = v.solvable
    props["variableType"] = typeModuleName(getVariableType(v))
    props["dataEntry"] = (Dict(keys(v.dataDict) .=> values(v.dataDict))) # map(bde -> JSON.json(bde), values(v.dataDict))))  
    props["dataEntryType"] =
        (Dict(keys(v.dataDict) .=> map(bde -> typeof(bde), values(v.dataDict))))
    props["_version"] = string(_getDFGVersion())
    return props #::Dict{String, Any}
end

"""
$(SIGNATURES)

Common unpack a Dict{String, Any} into a PPE.
"""
function _unpackPPE(
    packedPPE::Dict{String, Any};
    _type = pop!(packedPPE, "_type"), # required for generic use
)
    # !haskey(packedPPE, "_type") && error("Cannot find type key '_type' in packed PPE data")
    if (_type === nothing || _type == "")
        @warn "Cannot deserialize PPE, unknown type key, trying DistributedFactorGraphs.MeanMaxPPE" _type
        _type = "DistributedFactorGraphs.MeanMaxPPE"
    end
    ppeType = getTypeFromSerializationModule(_type)

    pee = transcodeType.(ppeType, packedPPE) # from Dict to hard type
    # ppe = Unmarshal.unmarshal(
    #     ppeType,
    #     packedPPE
    # )

    return ppe
end

"""
    $SIGNATURES
Returns a VariableCompute.

DevNotes
- v0.19 packVariable fixed nested JSON bug on these fields, see #867:
  - `tags`, `ppeDict`, `solverDataDict`, `smallData`, `dataEntry`, `dataEntryType`
"""
function unpackVariable(
    dfg::AbstractDFG,
    packedProps::Dict{String, Any};
    unpackPPEs::Bool = true,
    unpackSolverData::Bool = true,
    unpackBigData::Bool = haskey(packedProps, "dataEntryType") &&
                          haskey(packedProps, "dataEntry"),
    skipVersionCheck::Bool = false,
)
    #
    @debug "Unpacking variable:\r\n$packedProps"
    # Version checking.
    !skipVersionCheck && _versionCheck(packedProps)
    id = if haskey(packedProps, "id")
        UUID(packedProps["id"])
    else
        nothing
    end
    label = Symbol(packedProps["label"])
    # Make sure that the timestamp is correctly formatted with subseconds
    packedProps["timestamp"] = getStandardZDTString(packedProps["timestamp"])
    # Parse it
    timestamp = ZonedDateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))

    # FIXME, drop nested packing, see DFG #867
    #   string serialization using packVariable and CGDFG serialization (Vector{String})
    tags_ = if packedProps["tags"] isa String
        Symbol.(JSON2.read(packedProps["tags"], Vector{String}))
    else
        Symbol.(packedProps["tags"])
    end

    # FIXME, drop nested packing, see DFG #867
    ppeDict = if unpackPPEs && haskey(packedProps, "ppesDict")
        JSON2.read(packedProps["ppeDict"], Dict{Symbol, MeanMaxPPE})
    elseif unpackPPEs &&
           haskey(packedProps, "ppes") &&
           packedProps["ppes"] isa AbstractVector
        # these different cases are not well covered in tests, but first fix #867
        # TODO dont hardcode the ppeType (which is already discovered for each entry in _updatePPE)
        ppedict = Dict{Symbol, MeanMaxPPE}()
        for pd in packedProps["ppes"]
            _type = get(pd, "_type", "DistributedFactorGraphs.MeanMaxPPE")
            ppedict[Symbol(pd["solveKey"])] = _unpackPPE(pd; _type)
        end
        ppedict
    else
        Dict{Symbol, MeanMaxPPE}()
    end

    smallData = if haskey(packedProps, "metadata")
        if packedProps["metadata"] isa String
            JSON2.read(packedProps["metadata"], Dict{Symbol, SmallDataTypes})
        elseif packedProps["metadata"] isa Dict
            Dict{Symbol, SmallDataTypes}(
                Symbol.(keys(packedProps["metadata"])) .=>
                    values(packedProps["metadata"]),
            )
            # packedProps["metadata"]
        else
            @warn "unknown metadata deserialization on $label, type $(typeof(packedProps["metadata"]))" maxlog =
                10
            Dict{Symbol, SmallDataTypes}()
        end
    else
        Dict{Symbol, SmallDataTypes}()
    end

    variableTypeString = packedProps["variableType"]

    variableType = getTypeFromSerializationModule(variableTypeString)
    isnothing(variableType) &&
        error("Cannot deserialize variableType '$variableTypeString' in variable '$label'")
    pointType = getPointType(variableType)

    function _unpackSolverData(packedSolverData; oldkeys = false)
        _ensureid!(s::Dict) = begin
            s["id"] = haskey(s, "id") ? s["id"] : nothing
        end
        _ensureid!(s::PackedVariableNodeData) = s
        packed = if packedSolverData isa String
            # JSON2.read(packedSolverData, Dict{String, PackedVariableNodeData})
            # JSON3.read(packedSolverData, Dict{String, PackedVariableNodeData})
            jdc = JSON.parse(packedSolverData)
            jpvd = Dict{String, PackedVariableNodeData}()
            for (k, v) in jdc
                _ensureid!(v)
                jpvd[k] = transcodeType(PackedVariableNodeData, v)
            end
            jpvd
        else
            packedSolverData
        end
        packedvals = values(packed)
        _ensureid!.(packedvals)
        # @show keys(packed)
        # TODO deprecate, this is for DFG18 compat only
        packed_ = transcodeType.(PackedVariableNodeData, packedvals) # from Dict to hard type
        unpacked_ = map(p -> unpackVariableNodeData(p), packed_)
        keys_ = oldkeys ? Symbol.(keys(packed_)) : map(s -> s.solveKey, unpacked_)
        return Dict{Symbol, VariableNodeData{variableType, pointType}}(keys_ .=> unpacked_)
    end

    # FIXME, drop nested packing, see DFG #867
    solverData = if unpackSolverData && haskey(packedProps, "solverDataDict")
        _unpackSolverData(packedProps["solverDataDict"]; oldkeys = false)
    elseif unpackSolverData && haskey(packedProps, "solverData")
        _unpackSolverData(packedProps["solverData"])
    else
        Dict{Symbol, VariableNodeData{variableType, pointType}}()
    end
    # Rebuild VariableCompute using the first solver variableType in solverData
    # @info "dbg Serialization 171" variableType Symbol(packedProps["label"]) timestamp nstime ppeDict solverData smallData Dict{Symbol,AbstractBlobEntry}() Ref(packedProps["solvable"])
    # variable = VariableCompute{variableType}(Symbol(packedProps["label"]), timestamp, nstime, Set(tags), ppeDict, solverData,  smallData, Dict{Symbol,AbstractBlobEntry}(), Ref(packedProps["solvable"]))

    variable = VariableCompute{variableType}(;
        id,
        label = Symbol(packedProps["label"]),
        # variableType = variableType, 
        timestamp,
        nstime,
        tags = Set{Symbol}(tags_),
        ppeDict,
        solverDataDict = solverData,
        smallData = smallData,
        dataDict = Dict{Symbol, AbstractBlobEntry}(),
        solvable = Ref(Int(packedProps["solvable"])),
    )
    #

    # Now rehydrate complete DataEntry type.
    if unpackBigData
        #TODO Deprecate - for backward compatibility between v0.8 and v0.9, remove in v0.10
        dataElemTypes = if packedProps["dataEntryType"] isa String
            JSON2.read(packedProps["dataEntryType"], Dict{Symbol, String})
        else
            # packedProps["dataEntryType"]
            Dict{Symbol, String}(
                Symbol.(keys(packedProps["dataEntryType"])) .=>
                    values(packedProps["dataEntryType"]),
            )
        end
        for (k, name) in dataElemTypes
            val = split(string(name), '.')[end]
            dataElemTypes[k] = val
        end

        dataIntermed = if packedProps["dataEntry"] isa String
            JSON2.read(packedProps["dataEntry"], Dict{Symbol, String})
        elseif packedProps["dataEntry"] isa NamedTuple
            # case where JSON2 did unpacking of all fields as hard types (no longer String)
            # Dict{Symbol, String}( Symbol.(keys(packedProps["dataEntry"])) .=> values(packedProps["dataEntry"]) )
            for i = 1:length(packedProps["dataEntry"])
                k = keys(packedProps["dataEntry"])[i]
                bdeInter = values(packedProps["dataEntry"])[i]
                objType = getfield(DistributedFactorGraphs, Symbol(dataElemTypes[k]))
                # standardizeZDTStrings!(objType, bdeInter)
                # fullVal = Unmarshal.unmarshal(objType, bdeInter)
                variable.dataDict[k] = objType(; bdeInter...)
            end
            # forcefully skip, since variabe.dataDict already populated here
            Dict{Symbol, String}()
        else
            Dict(Symbol.(keys(packedProps["dataEntry"])) .=>
                    values(packedProps["dataEntry"]))
        end

        _doparse(s) = s
        _doparse(s::String) = JSON.parse(s)

        for (k, bdeInter) in dataIntermed
            interm = _doparse(bdeInter) # JSON.parse(bdeInter) # bdeInter
            objType = getfield(DistributedFactorGraphs, Symbol(dataElemTypes[k]))
            standardizeZDTStrings!(objType, interm)
            fullVal = transcodeType(objType, interm)
            # fullVal = Unmarshal.unmarshal(objType, interm)
            variable.dataDict[k] = fullVal
        end
    end

    return variable
end

# returns a PackedVariableNodeData
function packVariableNodeData(d::VariableNodeData{T}) where {T <: InferenceVariable}
    @debug "Dispatching conversion variable -> packed variable for type $(string(d.variableType))"
    castval = if 0 < length(d.val)
        precast = getCoordinates.(T, d.val)
        @cast castval[i, j] := precast[j][i]
        castval
    else
        zeros(1, 0)
    end
    _val = castval[:]
    return PackedVariableNodeData(
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
        typeModuleName(d.variableType),
        d.initialized,
        d.infoPerCoord,
        d.ismargin,
        d.dontmargin,
        d.solveInProgress,
        d.solvedCount,
        d.solveKey,
        string(_getDFGVersion()),
    )
end

function unpackVariableNodeData(d::PackedVariableNodeData)
    @debug "Dispatching conversion packed variable -> variable for type $(string(d.variableType))"
    # Figuring out the variableType
    # TODO deprecated remove in v0.11 - for backward compatibility for saved variableTypes. 
    ststring = string(split(d.variableType, "(")[1])
    T = getTypeFromSerializationModule(ststring)
    isnothing(T) && error(
        "The variable doesn't seem to have a variableType. It needs to set up with an InferenceVariable from IIF. This will happen if you use DFG to add serialized variables directly and try use them. Please use IncrementalInference.addVariable().",
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
    return VariableNodeData{T, getPointType(T)}(
        d.id,
        vals,
        BW,
        Symbol.(d.BayesNetOutVertIDs),
        d.dimIDs,
        d.dims,
        d.eliminated,
        Symbol(d.BayesNetVertID),
        Symbol.(d.separator),
        T(),
        d.initialized,
        d.infoPerCoord,
        d.ismargin,
        d.dontmargin,
        d.solveInProgress,
        d.solvedCount,
        Symbol(d.solveKey),
        Dict{Symbol, Threads.Condition}(),
    )
end

##==============================================================================
## Factor Packing and unpacking
##==============================================================================

function _packSolverData(f::FactorCompute, fnctype::AbstractFactor)
    #
    packtype = convertPackedType(fnctype)
    try
        packed = convert(PackedFunctionNodeData{packtype}, getSolverData(f))
        packedJson = packed
        return packedJson
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end
end

# returns ::Dict{String, <:Any}
function packFactor(dfg::AbstractDFG, f::FactorCompute)
    # Construct the properties to save
    props = Dict{String, Any}()
    props["id"] = f.id !== nothing ? string(f.id) : nothing
    props["label"] = string(f.label)
    props["timestamp"] = string(f.timestamp)
    props["nstime"] = f.nstime.value
    props["tags"] = f.tags
    props["metadata"] = f.smallData
    # Pack the node data
    fnctype = getSolverData(f).fnc.usrfnc!
    props["data"] = _packSolverData(f, fnctype)
    # Include the type
    props["fnctype"] = String(_getname(fnctype))
    props["_variableOrderSymbols"] = f._variableOrderSymbols # JSON2.write(f._variableOrderSymbols)
    props["solvable"] = getSolvable(f)
    props["_version"] = string(_getDFGVersion())
    return props
end

function reconstFactorData() end

function decodePackedType(
    dfg::AbstractDFG,
    varOrder::AbstractVector{Symbol},
    ::Type{T},
    packeddata::GenericFunctionNodeData{PT},
) where {T <: FactorOperationalMemory, PT}
    #
    # TODO, to solve IIF 1424
    # variables = map(lb->getVariable(dfg, lb), varOrder)

    # Also look at parentmodule
    usrtyp = convertStructType(PT)
    fulltype = DFG.FunctionNodeData{T{usrtyp}}
    factordata = reconstFactorData(dfg, varOrder, fulltype, packeddata)
    return factordata
end

# function Base.convert(::Type{PF}, nt::NamedTuple) where {PF <: AbstractPackedFactor}
#     # Here we define a convention, must provide PackedType(;kw...) constructor, easiest is just use Base.@kwdef
#     PF(;nt...)
# end

# function Base.convert(::Type{GenericFunctionNodeData{P}}, nt::NamedTuple) where P
#     GenericFunctionNodeData{P}(
#         nt.eliminated,
#         nt.potentialused,
#         nt.edgeIDs,
#         convert(P,nt.fnc),
#         nt.multihypo,
#         nt.certainhypo,
#         nt.nullhypo,
#         nt.solveInProgress,
#         nt.inflation,
#     )
# end

# TODO: REFACTOR THIS AS A JSON3 STRUCT DESERIALIZER.
function fncStringToData(
    packtype::Type{<:AbstractPackedFactor},
    data::Union{String, <:NamedTuple},
)
    # Convert string to Named Tuples for kwargs
    fncData = data isa AbstractString ? JSON2.read(data) : data

    packed = GenericFunctionNodeData{packtype}(
        fncData.eliminated,
        fncData.potentialused,
        fncData.edgeIDs,
        # NamedTuple args become kwargs with the splat
        packtype(; fncData.fnc...),
        fncData.multihypo,
        fncData.certainhypo,
        fncData.nullhypo,
        fncData.solveInProgress,
        fncData.inflation,
    )
    return packed
end
function fncStringToData(
    ::Type{T},
    data::PackedFunctionNodeData{T},
) where {T <: AbstractPackedFactor}
    return data
end
function fncStringToData(
    fncType::String,
    data::PackedFunctionNodeData{T},
) where {T <: AbstractPackedFactor}
    packtype = DFG.getTypeFromSerializationModule("Packed" * fncType)
    if packtype == T
        data
    else
        error(
            "Unknown type conversion\n$(fncType)\n$packtype\n$(PackedFunctionNodeData{T})",
        )
    end
end

function fncStringToData(fncType::String, data::T) where {T <: AbstractPackedFactor}
    packtype = DFG.getTypeFromSerializationModule("Packed" * fncType)
    if packtype == T # || T <: packtype
        data
    else
        fncStringToData(packtype, data)
    end
end
function fncStringToData(fncType::String, data::Union{String, <:NamedTuple})
    packtype = DFG.getTypeFromSerializationModule("Packed" * fncType)
    return fncStringToData(packtype, data)
end

# Returns `::FactorCompute`
function unpackFactor(
    dfg::G,
    packedProps::Dict{String, Any};
    skipVersionCheck::Bool = false,
) where {G <: AbstractDFG}
    # Version checking.
    !skipVersionCheck && _versionCheck(packedProps)

    id = if haskey(packedProps, "id") && packedProps["id"] !== nothing
        UUID(packedProps["id"])
    else
        nothing
    end
    label = packedProps["label"]

    # various formats in which the timestamp might be stored
    packedProps["timestamp"] = getStandardZDTString(packedProps["timestamp"])
    timestamp = ZonedDateTime(packedProps["timestamp"])
    nstime = Nanosecond(get(packedProps, "nstime", 0))

    # Get the stored tags and variable order
    @assert !(packedProps["tags"] isa String) "unpackFactor expecting JSON only data, packed `tags` should be a vector of strings (not a single string of elements)."
    @assert !(packedProps["_variableOrderSymbols"] isa String) "unpackFactor expecting JSON only data, packed `_variableOrderSymbols` should be a vector of strings (not a single string of elements)."
    tags = Symbol.(packedProps["tags"])
    _variableOrderSymbols = Symbol.(packedProps["_variableOrderSymbols"])

    data = packedProps["data"]
    if (data isa AbstractString)
        data = JSON2.read(data)
    end
    datatype = packedProps["fnctype"]
    @debug "DECODING factor type = '$(datatype)' for factor '$label'"
    # packtype = getTypeFromSerializationModule("Packed"*datatype)

    # FIXME type instability from nothing to T
    packed = nothing
    fullFactorData = nothing

    try
        packed = fncStringToData(datatype, data) #convert(GenericFunctionNodeData{packtype}, data) 
        decodeType = getFactorOperationalMemoryType(dfg)
        fullFactorData = decodePackedType(dfg, _variableOrderSymbols, decodeType, packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while unpacking '$label' as '$datatype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end

    solvable = packedProps["solvable"]

    smallData = if haskey(packedProps, "metadata")
        Dict{Symbol, SmallDataTypes}(
            Symbol.(keys(packedProps["metadata"])) .=> values(packedProps["metadata"]),
        )
    else
        Dict{Symbol, SmallDataTypes}()
    end

    # Rebuild FactorCompute
    #TODO use constuctor to create factor
    factor = FactorCompute(
        Symbol(label),
        timestamp,
        nstime,
        Set(tags),
        fullFactorData,
        solvable,
        Tuple(_variableOrderSymbols);
        id = id,
        smallData = smallData,
    )
    #

    # Note, once inserted, you still need to call rebuildFactorMetadata!
    return factor
end

##==============================================================================
## Serialization
##==============================================================================
