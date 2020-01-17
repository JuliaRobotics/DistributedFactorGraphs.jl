
"""
    $(SIGNATURES)
Save a DFG to a folder. Will create/overwrite folder if it exists.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. GraphsDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# ... Add stuff to graph using either IIF or DFG:
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE], solvable=0)
# Now save it:
saveDFG(dfg, "/tmp/saveDFG")
```
"""
function saveDFG(dfg::AbstractDFG, folder::String; compress::Symbol=:gzip)
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

    # compress newly saved folder, skip if not supported format
    !(compress in [:gzip]) && return
    savepath = folder[end] == '/' ? folder[1:end-1] : folder
    savedir = dirname(savepath)
    savename = splitpath(string(savepath))[end]
    @assert savename != ""
    # temporarily change working directory to get correct zipped path
    run( pipeline(`tar -zcf - -C $savedir $savename`, stdout="$savepath.tar.gz") )
    Base.rm(joinpath(savedir,savename), recursive=true)
end

"""
    $(SIGNATURES)
Load a DFG from a saved folder. Always provide the IIF module as the second
parameter.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. GraphsDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# Load the graph
loadDFG("/tmp/savedgraph.tar.gz", IncrementalInference, dfg)
loadDFG("/tmp/savedgraph", IncrementalInference, dfg) # alternative
# Use the DFG as you do normally.
ls(dfg)
```
"""
function loadDFG(dst::String, iifModule, dfgLoadInto::G; loaddir=joinpath("/","tmp","caesar","random")) where G <: AbstractDFG
    # Check if zipped destination (dst) by first doing fuzzy search from user supplied dst
    folder = dst  # working directory for fileDFG variable and factor operations
    dstname = dst # path name could either be legacy FileDFG dir or .tar.gz file of FileDFG files.
    unzip = false
    # add if doesn't have .tar.gz extension
    lastdirname = splitpath(dstname)[end]
    if !isdir(dst)
        unzip = true
        sdst = split(lastdirname, '.')
        if sdst[end] != "gz" #  length(sdst) == 1 &&
            dstname *= ".tar.gz"
            lastdirname *= ".tar.gz"
        end
    end
    # do actual unzipping
    if unzip
        @show sfolder = split(dstname, '.')
        Base.mkpath(loaddir)
        folder = joinpath(loaddir, lastdirname[1:(end-length(".tar.gz"))]) #splitpath(string(sfolder[end-2]))[end]
        @info "loadDFG detected a gzip $dstname -- unpacking via $loaddir now..."
        Base.rm(folder, recursive=true, force=true)
        # unzip the tar file
        run(`tar -zxf $dstname -C $loaddir`)
    end
    # extract the factor graph from fileDFG folder
    variables = DFGVariable[]
    factors = DFGFactor[]
    varFolder = "$folder/variables"
    factorFolder = "$folder/factors"
    # Folder preparations
    !isdir(folder) && error("Can't load DFG graph - folder '$folder' doesn't exist")
    !isdir(varFolder) && error("Can't load DFG graph - folder '$varFolder' doesn't exist")
    !isdir(factorFolder) && error("Can't load DFG graph - folder '$factorFolder' doesn't exist")

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
    # TODO: Remove in future
    map(f->solverData(f).fncargvID = f._variableOrderSymbols, getFactors(dfgLoadInto))

    return dfgLoadInto
end
