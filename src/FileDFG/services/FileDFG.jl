
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

function _packFactor(dfg::G, f::DFGFactor)::Dict{String, Any} where G <: AbstractDFG
    # Construct the properties to save
    props = Dict{String, Any}()
    props["label"] = string(f.label)
    props["tags"] = JSON2.write(f.tags)
    # Pack the node data
    fnctype = f.data.fnc.usrfnc!
    packtype = getfield(_getmodule(fnctype), Symbol("Packed$(_getname(fnctype))"))
    packed = convert(PackedFunctionNodeData{packtype}, f.data)
    props["data"] = JSON2.write(packed)
    # Include the type
    props["fnctype"] = String(_getname(fnctype))
    props["_variableOrderSymbols"] = JSON2.write(f._variableOrderSymbols)
    props["backendset"] = f.backendset
    props["ready"] = f.ready

    return props
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

function loadDFG(folderName::String, dfgLoadInto::G=GraphsDFG{NoSolverParams}()) where G <: AbstractDFG
    return dfgLoadInto
end
