
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
        vPacked = packVariable(dfg, v)
        io = open("$varFolder/$(v.label).json", "w")
        JSON2.write(io, vPacked)
        close(io)
    end
    # Factors
    for f in factors
        fPacked = packFactor(dfg, f)
        io = open("$folder/factors/$(f.label).json", "w")
        JSON2.write(io, fPacked)
        close(io)
    end
end

function loadDFG(folder::String, iifModule, dfgLoadInto::G=GraphsDFG{NoSolverParams}()) where G <: AbstractDFG
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
        push!(variables, unpackVariable(dfgLoadInto, packedData))
    end
    @info "Loaded $(length(variables)) variables - $(map(v->v.label, variables))"
    @info "Inserting variables into graph..."
    # Adding variables
    map(v->addVariable!(dfgLoadInto, v), variables)

    for factorFile in factorFiles
        io = open("$factorFolder/$factorFile")
        packedData = JSON2.read(io, Dict{String, Any})
        push!(factors, unpackFactor(dfgLoadInto, packedData, iifModule))
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
