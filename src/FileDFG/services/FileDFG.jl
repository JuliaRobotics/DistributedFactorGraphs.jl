
"""
    $(SIGNATURES)
Save a DFG to a folder. Will create/overwrite folder if it exists.

DevNotes:
- TODO remove `compress` kwarg.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. GraphsDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# ... Add stuff to graph using either IIF or DFG:
v1 = addVariable!(dfg, :a, ContinuousScalar, tags = [:POSE], solvable=0)
# Now save it:
saveDFG(dfg, "/tmp/saveDFG.tar.gz")
```
"""
function saveDFG(folder::AbstractString, dfg::AbstractDFG; saveMetadata::Bool=true)

    # TODO: Deprecate the folder functionality

    # Clean up save path if a file is specified
    savepath = folder[end] == '/' ? folder[1:end-1] : folder
    savepath = splitext(splitext(savepath)[1])[1] # In case of .tar.gz

    variables = getVariables(dfg)
    factors = getFactors(dfg)
    varFolder = "$savepath/variables"
    factorFolder = "$savepath/factors"
    # Folder preparations
    if !isdir(savepath)
        @debug "Folder '$savepath' doesn't exist, creating..."
        mkpath(savepath)
    end
    !isdir(varFolder) && mkpath(varFolder)
    !isdir(factorFolder) && mkpath(factorFolder)
    # Clearing out the folders
    map(f -> rm("$varFolder/$f"), readdir(varFolder))
    map(f -> rm("$factorFolder/$f"), readdir(factorFolder))
    # Variables
    @showprogress "saving variables" for v in variables
        vPacked = packVariable(v)
        JSON3.write("$varFolder/$(v.label).json", vPacked)
    end
    # Factors
    @showprogress "saving factors" for f in factors
        fPacked = packFactor(f)
        JSON3.write("$factorFolder/$(f.label).json", fPacked)
    end
    #GraphsDFG metadata
    if saveMetadata
        @assert isa(dfg, GraphsDFG) "only metadata for GraphsDFG are supported"
        @info "saving dfg metadata"
        fgPacked = GraphsDFGs.packDFGMetadata(dfg)
        JSON3.write("$savepath/dfg.json", fgPacked)
    end

    savedir = dirname(savepath) # is this a path of just local name? #344 -- workaround with unique names
    savename = basename(string(savepath))
    @assert savename != ""
    destfile = joinpath(savedir, savename*".tar.gz")
    
    #create Tarbal using Tar.jl #351
    tar_gz = open(destfile, write=true)
    tar = CodecZlib.GzipCompressorStream(tar_gz)
    Tar.create(joinpath(savedir,savename), tar)
    close(tar)
    #not compressed version
    # Tar.create(joinpath(savedir,savename), destfile)

    Base.rm(joinpath(savedir,savename), recursive=true)
end
# support both argument orders, #581
saveDFG(dfg::AbstractDFG, folder::AbstractString) = saveDFG(folder, dfg)

#TODO  loadDFG(dst::AbstractString) to load an equivalent dfg, but defined in IIF

"""
    $(SIGNATURES)
Load a DFG from a saved folder.

# Example
```julia
using DistributedFactorGraphs, IncrementalInference
# Create a DFG - can make one directly, e.g. GraphsDFG{NoSolverParams}() or use IIF:
dfg = initfg()
# Load the graph
loadDFG!(dfg, "/tmp/savedgraph.tar.gz")
# Use the DFG as you do normally.
ls(dfg)
```
"""
function loadDFG!(dfgLoadInto::AbstractDFG, dst::AbstractString; overwriteDFGMetadata::Bool=false)

    #
    # loaddir gets deleted so needs to be unique
    loaddir=split(joinpath("/","tmp","caesar","random", string(uuid1())), '-')[1]
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
        @info "loadDFG! detected a gzip $dstname -- unpacking via $loaddir now..."
        Base.rm(folder, recursive=true, force=true)
        # unzip the tar file

        tar_gz = open(dstname)
        tar = CodecZlib.GzipDecompressorStream(tar_gz)
        Tar.extract(tar, folder)
        close(tar)

        #or for non-compressed
        # Tar.extract(dstname, folder)
    end

    #GraphsDFG metadata
    if overwriteDFGMetadata 
        @assert isa(dfgLoadInto, GraphsDFG) "Only GraphsDFG metadata are supported"
        @info "loading dfg metadata"
        jstr = read("$folder/dfg.json", String)
        fgPacked = JSON3.read(jstr, GraphsDFGs.PackedGraphsDFG)
        GraphsDFGs.unpackDFGMetadata!(dfgLoadInto, fgPacked)
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

    varFiles = sort(readdir(varFolder; sort=false); lt=natural_lt)
    factorFiles = sort(readdir(factorFolder; sort=false); lt=natural_lt)
    @showprogress 1 "loading variables" for varFile in varFiles
        jstr = read("$varFolder/$varFile", String)
        try
            packedData = JSON3.read(jstr, PackedVariable)
            push!(variables, unpackVariable(packedData))
        catch ex
            @error("JSON3 is having trouble reading $varFolder/$varFile into a PackedVariable")
            @show jstr
            throw(ex)
        end
    end
    @info "Loaded $(length(variables)) variables - $(map(v->v.label, variables))"
    @info "Inserting variables into graph..."
    # Adding variables
    map(v->addVariable!(dfgLoadInto, v), variables)

    @showprogress 1 "loading factors" for factorFile in factorFiles
        jstr = read("$factorFolder/$factorFile", String)
        try
            packedData = JSON3.read(jstr, PackedFactor)
            push!(factors, unpackFactor(dfgLoadInto, packedData))
        catch ex
            @error("JSON3 is having trouble reading $factorFolder/$factorFile into a PackedFactor")
            @show jstr
            throw(ex)
        end
    end
    @info "Loaded $(length(variables)) factors - $(map(f->f.label, factors))"
    @info "Inserting factors into graph..."
    # # Adding factors
    map(f->addFactor!(dfgLoadInto, f), factors)

    # Finally, rebuild the CCW's for the factors to completely reinflate them
    # NOTE CREATES A NEW DFGFactor IF  CCW TYPE CHANGES
    @info "Rebuilding CCW's for the factors..."
    @showprogress 1 "build factor operational memory" for factor in factors
        rebuildFactorMetadata!(dfgLoadInto, factor)
    end

    # remove the temporary unzipped file
    if unzip
        @info "DFG.loadDFG! is deleting a temp folder created during unzip, $loaddir"
        # need this because the number of files created in /tmp/caesar/random is becoming redonkulous.
        Base.rm(loaddir, recursive=true, force=true)
    end

    return dfgLoadInto
end

# to be extended by users with particular choices in dispatch.
function loadDFG end