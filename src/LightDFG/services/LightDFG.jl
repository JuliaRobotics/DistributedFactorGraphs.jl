

# Accessors
getLabelDict(dfg::LightDFG) = copy(dfg.g.labels.sym_int)
getDescription(dfg::LightDFG) = dfg.description
setDescription(dfg::LightDFG, description::String) = dfg.description = description
getAddHistory(dfg::LightDFG) = dfg.addHistory
getSolverParams(dfg::LightDFG) = dfg.solverParams

# setSolverParams(dfg::LightDFG, solverParams) = dfg.solverParams = solverParams
function setSolverParams(dfg::LightDFG, solverParams::P) where P <: AbstractParams
  dfg.solverParams = solverParams
end

function exists(dfg::LightDFG{P,V,F}, node::V) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, node.label)
end

function exists(dfg::LightDFG{P,V,F}, node::F) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, node.label)
end

exists(dfg::LightDFG, nId::Symbol) = haskey(dfg.g.labels, nId)

exists(dfg::LightDFG, node::DFGNode) = exists(dfg, node.label)

function isVariable(dfg::LightDFG{P,V,F}, sym::Symbol) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.variables, sym)
end

function isFactor(dfg::LightDFG{P,V,F}, sym::Symbol) where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    return haskey(dfg.g.factors, sym)
end


function addVariable!(dfg::LightDFG{<:AbstractParams, V, <:AbstractDFGFactor}, variable::V)::Bool where V <: AbstractDFGVariable
    #TODO should this be an error
    if haskey(dfg.g.variables, variable.label)
        error("Variable '$(variable.label)' already exists in the factor graph")
    end

    #NOTE Internal ID always set to zero as it is not needed?
    # variable._internalId = 0

    FactorGraphs.addVariable!(dfg.g, variable) || return false

    # Track insertion
    push!(dfg.addHistory, variable.label)

    return true
end

function addFactor!(dfg::LightDFG{<:AbstractParams, V, F}, variables::Vector{<:V}, factor::F)::Bool where {V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    # if haskey(dfg.g.metaindex[:label], factor.label)
    #     error("Factor '$(factor.label)' already exists in the factor graph")
    # end
    #TODO should this be an error
    if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end
    # for v in variables
    #     if !(v.label in keys(dfg.g.metaindex[:label]))
    #         error("Variable '$(v.label)' not found in graph when creating Factor '$(factor.label)'")
    #     end
    # end

    variableLabels = map(v->v.label, variables)

    resize!(factor._variableOrderSymbols, length(variableLabels))
    factor._variableOrderSymbols .= variableLabels
    # factor._variableOrderSymbols = copy(variableLabels)

    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end

function addFactor!(dfg::LightDFG{<:AbstractParams, <:AbstractDFGVariable, F}, variableLabels::Vector{Symbol}, factor::F)::Bool where F <: AbstractDFGFactor
    #TODO should this be an error
    if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end

    resize!(factor._variableOrderSymbols, length(variableLabels))
    factor._variableOrderSymbols .= variableLabels
    # factor._variableOrderSymbols = copy(variableLabels)

    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end


function addFactor!(dfg::LightDFG{<:AbstractParams, <:AbstractDFGVariable, F}, factor::F)::Bool where F <: AbstractDFGFactor
    if haskey(dfg.g.factors, factor.label)
        error("Factor '$(factor.label)' already exists in the factor graph")
    end

    return FactorGraphs.addFactor!(dfg.g, variableLabels, factor)
end

function getVariable(dfg::LightDFG, label::Symbol)::AbstractDFGVariable
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end

    return dfg.g.variables[label]
end

function getFactor(dfg::LightDFG, label::Symbol)::AbstractDFGFactor
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    return dfg.g.factors[label]
end

function updateVariable!(dfg::LightDFG, variable::V)::V where V <: AbstractDFGVariable
    if !haskey(dfg.g.variables, variable.label)
        error("Variable label '$(variable.label)' does not exist in the factor graph")
    end
    dfg.g.variables[variable.label] = variable
    return variable
end

function updateFactor!(dfg::LightDFG, factor::F)::F where F <: AbstractDFGFactor
    if !haskey(dfg.g.factors, factor.label)
        error("Factor label '$(factor.label)' does not exist in the factor graph")
    end
    dfg.g.factors[factor.label] = factor
    return factor
end

function deleteVariable!(dfg::LightDFG, label::Symbol)::AbstractDFGVariable
    if !haskey(dfg.g.variables, label)
        error("Variable label '$(label)' does not exist in the factor graph")
    end
    variable = dfg.g.variables[label]
    rem_vertex!(dfg.g, dfg.g.labels[label])

    return variable
end

function deleteFactor!(dfg::LightDFG, label::Symbol)::AbstractDFGFactor
    if !haskey(dfg.g.factors, label)
        error("Factor label '$(label)' does not exist in the factor graph")
    end
    factor = dfg.g.factors[label]
    variable = rem_vertex!(dfg.g,  dfg.g.labels[label])
    return factor
end

function getVariables(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{AbstractDFGVariable}

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    variables = collect(values(dfg.g.variables))
    if regexFilter != nothing
        variables = filter(v -> occursin(regexFilter, String(v.label)), variables)
    end
    if solvable != 0
        variables = filter(v -> _isSolvable(dfg, v.label, solvable), variables)
    end
    if length(tags) > 0
        mask = map(v -> length(intersect(v.tags, tags)) > 0, variables )
        return variables[mask]
    end
    return variables
end

function getVariableIds(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; tags::Vector{Symbol}=Symbol[], solvable::Int=0)::Vector{Symbol}

    # variables = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGVariable, vertices(dfg.g)))
    if length(tags) > 0
        return map(v -> v.label, getVariables(dfg, regexFilter, tags=tags, solvable=solvable))
    else
        variables = collect(keys(dfg.g.variables))
        regexFilter != nothing && (variables = filter(v -> occursin(regexFilter, String(v)), variables))
        solvable != 0 && (variables = filter(vId -> _isSolvable(dfg, vId, solvable), variables))
        return variables
    end
end

function getFactors(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{AbstractDFGFactor}
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    factors = collect(values(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f.label)), factors)
    end
    if solvable != 0
        factors = filter(f -> _isSolvable(dfg, f.label, solvable), factors)
    end
    return factors
end

function getFactorIds(dfg::LightDFG, regexFilter::Union{Nothing, Regex}=nothing; solvable::Int=0)::Vector{Symbol}
    # factors = map(v -> v.dfgNode, filter(n -> n.dfgNode isa DFGFactor, vertices(dfg.g)))
    factors = collect(keys(dfg.g.factors))
    if regexFilter != nothing
        factors = filter(f -> occursin(regexFilter, String(f)), factors)
    end
    if solvable != 0
        factors = filter(fId -> _isSolvable(dfg, fId, solvable), factors)
    end
    return factors
end

function isFullyConnected(dfg::LightDFG)::Bool
    return length(LightGraphs.connected_components(dfg.g)) == 1
end

function _isSolvable(dfg::LightDFG, label::Symbol, ready::Int)::Bool

    haskey(dfg.g.variables, label) && (return dfg.g.variables[label].solvable >= ready)
    haskey(dfg.g.factors, label) && (return dfg.g.factors[label].solvable >= ready)

    #TODO should this be a breaking error?
    @error "Node not in factor or variable"
    return false
end

function getNeighbors(dfg::LightDFG, node::DFGNode; solvable::Int=0)::Vector{Symbol}
    label = node.label
    if !exists(dfg, label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if typeof(node) <: AbstractDFGFactor
        order = intersect(node._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll
end


function getNeighbors(dfg::LightDFG, label::Symbol; solvable::Int=0)::Vector{Symbol}
    if !exists(dfg, label)
        error("Variable/factor with label '$(label)' does not exist in the factor graph")
    end

    neighbors_il =  FactorGraphs.outneighbors(dfg.g, dfg.g.labels[label])
    neighbors_ll = [dfg.g.labels[i] for i in neighbors_il]
    # Additional filtering
    solvable != 0 && filter!(lbl -> _isSolvable(dfg, lbl, solvable), neighbors_ll)

    # Variable sorting (order is important)
    if haskey(dfg.g.factors, label)
        order = intersect(dfg.g.factors[label]._variableOrderSymbols, neighbors_ll)#map(v->v.dfgNode.label, neighbors))
        return order
    end

    return neighbors_ll

end

function _copyIntoGraph!(sourceDFG::LightDFG{<:AbstractParams, V, F}, destDFG::LightDFG{<:AbstractParams, V, F}, ns::Vector{Int}, includeOrphanFactors::Bool=false)::Nothing where {V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    #kan ek die in bulk copy, soos graph en dan nuwe map maak
    # Add all variables first,
    labels = [sourceDFG.g.labels[i] for i in ns]

    for v in values(sourceDFG.g.variables)
        if v.label in labels
            exists(destDFG, v) ? (@warn "_copyIntoGraph $(v.label) exists, ignoring") : addVariable!(destDFG, deepcopy(v))
        end
    end

    # And then all factors to the destDFG.
    for f in values(sourceDFG.g.factors)
        if f.label in labels
            # Get the original factor variables (we need them to create it)
            neigh_ints = FactorGraphs.outneighbors(sourceDFG.g, sourceDFG.g.labels[f.label])

            neigh_labels = [sourceDFG.g.labels[i] for i in neigh_ints]
            # Find the labels and associated variables in our new subgraph
            factVariables = V[]
            for v_lab in neigh_labels
                if haskey(destDFG.g.variables, v_lab)
                    push!(factVariables, getVariable(destDFG, v_lab))
                    #otherwise ignore
                end
            end

            # Only if we have all of them should we add it (otherwise strange things may happen on evaluation)
            if includeOrphanFactors || length(factVariables) == length(neigh_labels)
                exists(destDFG, f.label) ? (@warn "_copyIntoGraph $(f.label) exists, ignoring") : addFactor!(destDFG, factVariables, deepcopy(f))
            end
        end
    end
    return nothing
end


function getSubgraphAroundNode(dfg::LightDFG{P,V,F}, node::DFGNode, distance::Int64=1, includeOrphanFactors::Bool=false, addToDFG::LightDFG=LightDFG{P,V,F}(); solvable::Int=0)::LightDFG where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    if !exists(dfg,node.label)
        error("Variable/factor with label '$(node.label)' does not exist in the factor graph")
    end

    # Get a list of all unique neighbors inside 'distance'
    ns = neighborhood(dfg.g, dfg.g.labels[node.label], distance)
    # Always return the center node, skip that if we're filtering.
    solvable != 0 && (filter!(id -> _isSolvable(dfg, dfg.g.labels[id], solvable) || dfg.g.labels[id] == node.label, ns))


    # Copy the section of graph we want
    _copyIntoGraph!(dfg, addToDFG, ns, includeOrphanFactors)
    return addToDFG

end
# dfg::LightDFG{P,V,F}
# where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}

function getSubgraph(dfg::LightDFG{P,V,F}, variableFactorLabels::Vector{Symbol}, includeOrphanFactors::Bool=false, addToDFG::LightDFG=LightDFG{P,V,F}())::LightDFG where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    for label in variableFactorLabels
        if !exists(dfg, label)
            error("Variable/factor with label '$(label)' does not exist in the factor graph")
        end
    end

    variableFactorInts = [dfg.g.labels[s] for s in variableFactorLabels]

    _copyIntoGraph!(dfg, addToDFG, variableFactorInts, includeOrphanFactors)
    return addToDFG
end

function getIncidenceMatrix(dfg::LightDFG; solvable::Int=0)::Matrix{Union{Nothing, Symbol}}
    #TODO Why does it need to be sorted?
    varLabels = sort(getVariableIds(dfg, solvable=solvable))#ort(map(v->v.label, getVariables(dfg)))
    factLabels = sort(getFactorIds(dfg, solvable=solvable))#sort(map(f->f.label, getFactors(dfg)))
    vDict = Dict(varLabels .=> [1:length(varLabels)...].+1)

    adjMat = Matrix{Union{Nothing, Symbol}}(nothing, length(factLabels)+1, length(varLabels)+1)
    # Set row/col headings
    adjMat[2:end, 1] = factLabels
    adjMat[1, 2:end] = varLabels
    for (fIndex, factLabel) in enumerate(factLabels)
        factVars = getNeighbors(dfg, getFactor(dfg, factLabel))
        map(vLabel -> adjMat[fIndex+1,vDict[vLabel]] = factLabel, factVars)
    end
    return adjMat
end

#TODO This is just way too strange to call a function  getIncidenceMatrix that calls adjacency_matrix internally,
# So I'm going with Biadjacency Matrix https://en.wikipedia.org/wiki/Adjacency_matrix#Of_a_bipartite_graph
function getBiadjacencyMatrixSparse(dfg::LightDFG; solvable::Int=0)::Tuple{LightGraphs.SparseMatrixCSC, Vector{Symbol}, Vector{Symbol}}
    varLabels = getVariableIds(dfg, solvable=solvable)
    factLabels = getFactorIds(dfg, solvable=solvable)
    varIndex = [dfg.g.labels[s] for s in varLabels]
    factIndex = [dfg.g.labels[s] for s in factLabels]

    adj = adjacency_matrix(dfg.g)

    adjvf = adj[factIndex, varIndex]
    return adjvf, varLabels, factLabels
end

function getAdjacencyMatrixSparse(dfg::LightDFG; solvable::Int=0)
    @warn "Deprecated function, please use getBiadjacencyMatrixSparse as this will be removed in v0.6.1"
    return getBiadjacencyMatrixSparse(dfg, solvable=solvable)
end

# this would be an incidence matrix
function getIncidenceMatrixSparse(dfg::LightDFG)
    return incidence_matrix(dfg.g)
end

"""
    $(SIGNATURES)
Gets an empty and unique LightDFG derived from an existing DFG.
"""
function _getDuplicatedEmptyDFG(dfg::LightDFG{P,V,F})::LightDFG where {P <: AbstractParams, V <: AbstractDFGVariable, F <: AbstractDFGFactor}
    newDfg = LightDFG{P,V,F}(;
        userId=dfg.userId, robotId=dfg.robotId, sessionId=dfg.sessionId,
        params=deepcopy(dfg.solverParams))
    newDfg.description ="(Copy of) $(dfg.description)"
    return newDfg
end


#TODO JT test.
"""
    $(SIGNATURES)
A replacement for to_dot that saves only hardcoded factor graph plotting attributes.
"""
function savedot_attributes(io::IO, dfg::LightDFG)
    write(io, "graph G {\n")

    for vl in getVariableIds(dfg)
        write(io, "$vl [color=red, shape=ellipse];\n")
    end
    for fl in getFactorIds(dfg)
        write(io, "$fl [color=blue, shape=box];\n")
    end

    for e in edges(dfg.g)
        write(io, "$(dfg.g.labels[src(e)]) -- $(dfg.g.labels[dst(e)])\n")
    end
    write(io, "}\n")
end

function toDotFile(dfg::LightDFG, fileName::String="/tmp/dfg.dot")::Nothing
    open(fileName, "w") do fid
        savedot_attributes(fid, dfg)
    end
    return nothing
end

function toDot(dfg::LightDFG)::String
    m = PipeBuffer()
    savedot_attributes(m, dfg)
    data = take!(m)
    close(m)
    return String(data)
end
