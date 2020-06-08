
"""
    $(SIGNATURES)
Save a DFG to a folder. Will create/overwrite folder if it exists.

DevNotes:
- TODO remove `compress` kwarg.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. LightDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# ... Add stuff to graph using either IIF or DFG:
v1 = addVariable!(dfg, :a, ContinuousScalar, labels = [:POSE], solvable=0)
# Now save it:
saveDFG(dfg, "/tmp/saveDFG.tar.gz")
```
"""
function saveDFG( dfg::AbstractDFG, folder::AbstractString )

    # TODO: Deprecate the folder functionality in v0.6.1

    # Clean up save path if a file is specified
    savepath = folder[end] == '/' ? folder[1:end-1] : folder
    savepath = splitext(splitext(savepath)[1])[1] # In case of .tar.gz

    variables = getVariables(dfg)
    factors = getFactors(dfg)
    varFolder = "$savepath/variables"
    factorFolder = "$savepath/factors"
    # Folder preparations
    if !isdir(savepath)
        @info "Folder '$savepath' doesn't exist, creating..."
        mkpath(savepath)
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
        io = open("$factorFolder/$(f.label).json", "w")
        JSON2.write(io, fPacked)
        close(io)
    end

    savedir = dirname(savepath) # is this a path of just local name? #344 -- workaround with unique names
    savename = basename(string(savepath))
    @assert savename != ""
    destfile = joinpath(savedir, savename*".tar.gz")
    if length(savedir) != 0
      run( pipeline(`tar -zcf - -C $savedir $savename`, stdout="$destfile"))
    else
      run( pipeline(`tar -zcf - $savename`, stdout="$destfile"))
    end
    Base.rm(joinpath(savedir,savename), recursive=true)
end

"""
    $(SIGNATURES)
Load a DFG from a saved folder. Always provide the IIF module as the second
parameter.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. LightDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# Load the graph
loadDFG("/tmp/savedgraph.tar.gz", IncrementalInference, dfg)
# Use the DFG as you do normally.
ls(dfg)
```
"""
function loadDFG!(dfgLoadInto::AbstractDFG, dst::AbstractString)


    #
    # loaddir gets deleted so needs to be unique
    loaddir=joinpath("/","tmp","caesar","random", string(uuid1()))
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
    # check the file actually exists
    @assert isfile(dstname) "cannot find file $dstname"
    # TODO -- what if it is not a tar.gz but classic folder instead?
    # do actual unzipping
    filename = lastdirname[1:(end-length(".tar.gz"))] |> string
    if unzip
        @show sfolder = split(dstname, '.')
        Base.mkpath(loaddir)
        folder = joinpath(loaddir, filename) #splitpath(string(sfolder[end-2]))[end]
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
        open("$varFolder/$varFile") do io
            packedData = JSON2.read(io, Dict{String, Any})
            push!(variables, unpackVariable(dfgLoadInto, packedData))
        end
    end
    @info "Loaded $(length(variables)) variables - $(map(v->v.label, variables))"
    @info "Inserting variables into graph..."
    # Adding variables
    map(v->addVariable!(dfgLoadInto, v), variables)

    for factorFile in factorFiles
        open("$factorFolder/$factorFile") do io
            packedData = JSON2.read(io, Dict{String, Any})
            push!(factors, unpackFactor(dfgLoadInto, packedData))
        end
    end
    @info "Loaded $(length(variables)) factors - $(map(f->f.label, factors))"
    @info "Inserting factors into graph..."
    # # Adding factors
    map(f->addFactor!(dfgLoadInto, f), factors)

    # Finally, rebuild the CCW's for the factors to completely reinflate them
    @info "Rebuilding CCW's for the factors..."
    for factor in factors
        rebuildFactorMetadata!(dfgLoadInto, factor)
    end

    # remove the temporary unzipped file
    if unzip
      @info "DFG.loadDFG is deleting a temp folder created during unzip, $loaddir"
      # need this because the number of files created in /tmp/caesar/random is becoming redonkulous.
      Base.rm(loaddir, recursive=true, force=true)
    end

    return dfgLoadInto
end
