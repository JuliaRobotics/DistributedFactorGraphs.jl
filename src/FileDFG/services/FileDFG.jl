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
function saveDFG(folder::AbstractString, dfg::AbstractDFG)

    # TODO: Deprecate the folder functionality

    # Clean up save path if a file is specified
    savepath = folder[end] == '/' ? folder[1:(end - 1)] : folder
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
    @showprogress desc = "saving variables" for v in variables
        # vPacked = packVariable(v)
        JSON.json("$varFolder/$(v.label).json", v; style = DFGJSONStyle())
    end
    # Factors
    @showprogress desc = "saving factors" for f in factors
        JSON.json("$factorFolder/$(f.label).json", f; style = DFGJSONStyle())
    end

    #GraphsDFG nodes
    @assert isa(dfg, GraphsDFG) "only metadata for GraphsDFG are supported"
    p = Progress(4; desc = "Saving DFG Nodes")
    JSON.json("$savepath/graphroot.json", dfg.graph; style = DFGJSONStyle())
    next!(p)
    JSON.json("$savepath/agents.json", dfg.agents; style = DFGJSONStyle())
    next!(p)
    JSON.json("$savepath/solverparams.json", dfg.solverParams; style = DFGJSONStyle())
    next!(p)
    JSON.json("$savepath/blobstores.json", dfg.blobstores; style = DFGJSONStyle())
    next!(p)

    savedir = dirname(savepath) # is this a path of just local name? #344 -- workaround with unique names
    savename = basename(string(savepath))
    @assert savename != ""
    destfile = joinpath(savedir, savename * ".tar.gz")

    #create Tarbal using Tar.jl #351
    tar_gz = open(destfile; write = true)
    tar = CodecZlib.GzipCompressorStream(tar_gz)
    Tar.create(joinpath(savedir, savename), tar)
    close(tar)
    #not compressed version
    # Tar.create(joinpath(savedir,savename), destfile)

    return Base.rm(joinpath(savedir, savename); recursive = true)
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

See also: [`loadDFG`](@ref), [`saveDFG`](@ref)
"""
function loadDFG!(
    dfgLoadInto::AbstractDFG{V, F},
    file::AbstractString;
) where {V <: AbstractGraphVariable, F <: AbstractGraphFactor}
    # add if doesn't have .tar.gz extension
    if !contains(basename(file), ".tar.gz")
        file *= ".tar.gz"
    end
    # check the file actually exists
    @assert isfile(file) "cannot find file $file"

    # only extract the json files needed for the variables and factors
    tar_gz = open(file)
    tar = CodecZlib.GzipDecompressorStream(tar_gz)
    dfgnodenames = r"^(factors|variables)"
    loaddir = Tar.extract(hdr -> contains(hdr.path, dfgnodenames), tar)
    close(tar)

    # extract the factor graph from fileDFG folder
    variablefiles = readdir(joinpath(loaddir, "variables"); sort = false, join = true)

    # type instability on `variables` as either `::Vector{Variable}` or `::Vector{VariableDFG{<:}}` (vector of abstract)
    variables = @showprogress dt = 1 desc = "loading variables" asyncmap(
        variablefiles,
    ) do file
        v = JSON.parsefile(file, V; style = DFGJSONStyle())
        return addVariable!(dfgLoadInto, v)
    end

    @debug "Loaded $(length(variables)) variables"

    factorfiles = readdir(joinpath(loaddir, "factors"); sort = false, join = true)

    factors = @showprogress dt = 1 desc = "loading factors" asyncmap(factorfiles) do file
        f = JSON.parsefile(file, F; style = DFGJSONStyle())
        return addFactor!(dfgLoadInto, f)
    end

    @debug "Loaded $(length(factors)) factors"

    if isa(dfgLoadInto, GraphsDFG) && getTypeDFGFactors(dfgLoadInto) <: FactorDFG
        # Finally, rebuild the CCW's for the factors to completely reinflate them
        @showprogress dt = 1 desc = "Rebuilding factor solver cache" for factor in factors
            rebuildFactorCache!(dfgLoadInto, factor)
        end
    end

    Base.rm(loaddir; recursive = true, force = true)

    return dfgLoadInto
end

"""
    $SIGNATURES

Convenience graph loader into a default `LocalDFG`.

See also: [`loadDFG!`](@ref), [`saveDFG`](@ref)
"""
function loadDFG(file::AbstractString)

    # add if doesn't have .tar.gz extension
    if !contains(basename(file), ".tar.gz")
        file *= ".tar.gz"
    end
    # check the file actually exists
    @assert isfile(file) "cannot find file $file"

    # only extract the json files needed to rebuild DFG object
    tar_gz = open(file)
    tar = CodecZlib.GzipDecompressorStream(tar_gz)
    dfgnodenames = r"^(agents?\.json|blobstores\.json|graphroot\.json|solverparams\.json)$"
    loaddir = Tar.extract(hdr -> contains(hdr.path, dfgnodenames), tar)
    close(tar)

    progess = Progress(4; desc = "Loading DFG Nodes")
    agents = if isfile(joinpath(loaddir, "agents.json"))
        JSON.parsefile(
            joinpath(loaddir, "agents.json"),
            OrderedDict{Symbol, Agent};
            style = DFGJSONStyle(),
        )
    elseif isfile(joinpath(loaddir, "agent.json"))
        # backward compat: load old single-agent format
        agent = JSON.parsefile(joinpath(loaddir, "agent.json"), Agent; style = DFGJSONStyle())
        OrderedDict{Symbol, Agent}(agent.label => agent)
    else
        OrderedDict{Symbol, Agent}()
    end
    next!(progess)
    graph = JSON.parsefile(
        joinpath(loaddir, "graphroot.json"),
        Graphroot;
        style = DFGJSONStyle(),
    )
    next!(progess)
    solverParams = JSON.parsefile(
        joinpath(loaddir, "solverparams.json"),
        AbstractDFGParams;
        style = DFGJSONStyle(),
    )
    next!(progess)
    blobstores = JSON.parsefile(
        joinpath(loaddir, "blobstores.json"),
        Dict{Symbol, AbstractBlobstore};
        style = DFGJSONStyle(),
    )
    next!(progess)

    dfg = GraphsDFG(; agents, graph, solverParams, blobstores)

    @debug "DFG.loadDFG is deleting a temp folder created during unzip, $loaddir"
    # cleanup temporary folder
    Base.rm(loaddir; recursive = true, force = true)

    return loadDFG!(dfg, file)
end
