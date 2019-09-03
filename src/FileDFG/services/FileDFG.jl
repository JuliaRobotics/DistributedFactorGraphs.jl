
function _packVariable(dfg::G, v::DFGVariable)::Dict{String, Any} where G <: AbstractDFG
    props = Dict{String, Any}()
    props["label"] = string(v.label)
    props["timestamp"] = string(v.timestamp)
    props["tags"] = JSON2.write(v.tags)
    props["estimateDict"] = JSON2.write(v.estimateDict)
    props["solverDataDict"] = JSON2.write(Dict(keys(v.solverDataDict) .=> map(vnd -> pack(dfg, vnd), values(v.solverDataDict))))
    props["smallData"] = JSON2.write(v.smallData)
    props["ready"] = v.ready
    props["backendset"] = v.backendset
    return props
end

function _unpackVariable(dfg::G, packedProps::Dict{String, Any})::DFGVariable where G <: AbstractDFG
    label = Symbol(packedProps["label"])
    timestamp = DateTime(packedProps["timestamp"])
    tags =  JSON2.read(packedProps["tags"], Vector{Symbol})
    estimateDict = JSON2.read(packedProps["estimateDict"], Dict{Symbol, VariableEstimate})
    smallData = nothing
    smallData = JSON2.read(packedProps["smallData"], Dict{String, String})

    packed = JSON2.read(packedProps["solverDataDict"], Dict{String, PackedVariableNodeData})
    solverData = Dict(Symbol.(keys(packed)) .=> map(p -> unpack(dfg, p), values(packed)))

    # Rebuild DFGVariable
    variable = DFGVariable(Symbol(packedProps["label"]))
    variable.timestamp = timestamp
    variable.tags = tags
    variable.estimateDict = estimateDict
    variable.solverDataDict = solverData
    variable.smallData = smallData
    variable.ready = packedProps["ready"]
    variable.backendset = packedProps["backendset"]

    return variable
end

function _packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["tags"] = JSON2.write(f.tags)
    # Pack the node data
    fnctype = f.data.fnc.usrfnc!
    try
        packtype = getfield(_getmodule(fnctype), Symbol("Packed$(_getname(fnctype))"))
        packed = convert(PackedFunctionNodeData{packtype}, f.data)
        props["data"] = JSON2.write(packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while packing '$(f.label)' as '$fnctype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end
    # Include the type
    props["fnctype"] = String(_getname(fnctype))
    props["_variableOrderSymbols"] = JSON2.write(f._variableOrderSymbols)
    props["backendset"] = f.backendset
    props["ready"] = f.ready

    return props
end


function _unpackFactor(dfg::G, packedProps::Dict{String, Any}, iifModule)::DFGFactor where G <: AbstractDFG
    label = packedProps["label"]
    tags = JSON2.read(packedProps["tags"], Vector{Symbol})

    data = packedProps["data"]
    @debug "Decoding $label..."
    datatype = packedProps["fnctype"]
    packtype = getfield(Main, Symbol("Packed"*datatype))
    packed = nothing
    fullFactor = nothing
    try
        packed = JSON2.read(data, GenericFunctionNodeData{packtype,String})
        fullFactor = iifModule.decodePackedType(dfg, packed)
    catch ex
        io = IOBuffer()
        showerror(io, ex, catch_backtrace())
        err = String(take!(io))
        msg = "Error while unpacking '$label' as '$datatype', please check the unpacking/packing converters for this factor - \r\n$err"
        error(msg)
    end

    # Include the type
    _variableOrderSymbols = JSON2.read(packedProps["_variableOrderSymbols"], Vector{Symbol})
    backendset = packedProps["backendset"]
    ready = packedProps["ready"]

    # Rebuild DFGVariable
    factor = DFGFactor{typeof(fullFactor.fnc), Symbol}(Symbol(label))
    factor.tags = tags
    factor.data = fullFactor
    factor._variableOrderSymbols = _variableOrderSymbols
    factor.ready = ready
    factor.backendset = backendset

    # GUARANTEED never to bite us in the ass in the future...
    # ... TODO: refactor if changed: https://github.com/JuliaRobotics/IncrementalInference.jl/issues/350
    factor.data.fncargvID = deepcopy(_variableOrderSymbols)

    # Note, once inserted, you still need to call IIF.rebuildFactorMetadata!
    return factor
end

function saveDFG(dfg::G, folder::String) where G <: AbstractDFG
    variables = getVariables(dfg)
    factors = getFactors(dfg)
    varFolder = "$folder/variables"
    factorFolder = "$folder/factors"
    # Folder preparations
    if !isdir(folder)
        @info "Folder '$folder' doesn't exist, creating..."
        mkpath(folder)
    end
    !isdir(varFolder) && mkpath(varFolder)
    !isdir(factorFolder) && mkpath(factorFolder)
    # Clearing out the folders
    map(f -> rm("$varFolder/$f"), readdir(varFolder))
    map(f -> rm("$factorFolder/$f"), readdir(factorFolder))
    # Variables
    for v in variables
        vPacked = _packVariable(dfg, v)
        io = open("$varFolder/$(v.label).json", "w")
        JSON2.write(io, vPacked)
        close(io)
    end
    # Factors
    for f in factors
        fPacked = _packFactor(dfg, f)
        io = open("$folder/factors/$(f.label).json", "w")
        JSON2.write(io, fPacked)
        close(io)
    end
end

function loadDFG(folder::String,
                 iifModule,
                 dfgLoadInto::G=GraphsDFG{NoSolverParams}()) where G <: AbstractDFG
    #
    variables = DFGVariable[]
    factors = DFGFactor[]
    varFolder = "$folder/variables"
    factorFolder = "$folder/factors"
    # Folder preparations
    !isdir(folder) && error("Can't load DFG graph - folder '$folder' doesn't exist")
    !isdir(varFolder) && error("Can't load DFG graph - folder '$folder' doesn't exist")
    !isdir(factorFolder) && error("Can't load DFG graph - folder '$folder' doesn't exist")

    varFiles = readdir(varFolder)
    factorFiles = readdir(factorFolder)
    for varFile in varFiles
        io = open("$varFolder/$varFile")
        packedData = JSON2.read(io, Dict{String, Any})
        push!(variables, _unpackVariable(dfgLoadInto, packedData))
    end
    @info "Loaded $(length(variables)) variables - $(map(v->v.label, variables))"
    @info "Inserting variables into graph..."
    # Adding variables
    map(v->addVariable!(dfgLoadInto, v), variables)

    for factorFile in factorFiles
        io = open("$factorFolder/$factorFile")
        packedData = JSON2.read(io, Dict{String, Any})
        push!(factors, _unpackFactor(dfgLoadInto, packedData, iifModule))
    end
    @info "Loaded $(length(variables)) factors - $(map(f->f.label, factors))"
    @info "Inserting factors into graph..."
    # # Adding factors
    map(f->addFactor!(dfgLoadInto, f._variableOrderSymbols, f), factors)

    # Finally, rebuild the CCW's for the factors to completely reinflate them
    @info "Rebuilding CCW's for the factors..."
    for factor in factors
        iifModule.rebuildFactorMetadata!(dfgLoadInto, factor)
    end

    # PATCH - To update the fncargvID for factors, it's being cleared somewhere in rebuildFactorMetadata.
    # TEMPORARY
    # TODO: Remove
    map(f->getData(f).fncargvID = f._variableOrderSymbols, getFactors(dfgLoadInto))


    return dfgLoadInto
end
