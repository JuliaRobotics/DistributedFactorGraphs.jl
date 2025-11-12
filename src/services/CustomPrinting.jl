##==============================================================================
## Printing Variables and Factors
##==============================================================================

printVariable(vert::VariableCompute; kwargs...) = printVariable(stdout::IO, vert; kwargs...)

function printVariable(
    io::IO,
    vert::VariableCompute;
    short::Bool = false,
    compact::Bool = true,
    limit::Bool = true,
    skipfields::Vector{Symbol} = Symbol[],
    solveKeys::Vector{Symbol} = Symbol[],
)
    ioc = IOContext(io, :limit => limit, :compact => compact)

    if short
        # opmemt = (getVariableType(vert) |> typeof ).name
        vari = getStateType(vert) |> typeof
        printstyled(ioc, nameof((typeof(vert))), "{"; bold = true)
        printstyled(ioc, vari; bold = true, color = :blue)
        printstyled(ioc, "...}"; bold = true)
        println(ioc, "")
        # printstyled(ioc, summary(vert),"\n", bold=true)

        try
            print(ioc, "  manifold:   ")
            show(ioc, getManifold(vert))
            println(ioc, "")
        catch e
        end
        vnd = if hasState(vert, :default)
            getState(vert, :default)
        else
            nothing
        end
        println(ioc, "  timestamp:  ", vert.timestamp)
        isnothing(vert.steadytime) || println(ioc, "  steadytime: ", vert.steadytime)
        print(ioc, "  label:      ")
        printstyled(ioc, vert.label; bold = true)
        println(ioc)
        println(ioc, "  solvable:   ", getSolvable(vert))
        println(ioc, "  tags:       ", getTags(vert))
        solk = listStates(vert)
        lsolk = length(solk)
        smsk = lsolk > 0 ? (rand(1:lsolk, 100) |> unique)[1:minimum([4, lsolk])] : nothing
        # list the marginalization status
        ismarg = solk .|> x -> isMarginalized(vert, x)
        isinit = solk .|> x -> isInitialized(vert, x)
        printstyled(ioc, "  # states:    ($(lsolk))"; bold = true)
        println(ioc, "")
        printstyled(ioc, "  # initialized:      "; bold = true)
        println(ioc, "(true=", sum(isinit), ",false=", length(isinit) - sum(isinit), ")")
        printstyled(ioc, "  # marginalized:     "; bold = true)
        println(ioc, "(true=", sum(ismarg), ",false=", length(ismarg) - sum(ismarg), ")")

        if vnd !== nothing
            println(ioc, "    :default <-- State")
            println(ioc, "      initialized:        ", isInitialized(vert, :default))
            println(ioc, "      marginalized:      ", isMarginalized(vert, :default))
            println(ioc, "      size bel. samples: ", size(vnd.val))
            print(ioc, "      kde bandwidths:    ")
            0 < length(vnd.bw) ? println(ioc, round.(vnd.bw[1]; digits = 4)) : nothing
            printstyled(ioc, "     VNDs: "; bold = true)
            println(ioc, solk[smsk], 4 < lsolk ? "..." : "")
        end
        println(ioc, "  # Blobentries:      (", length(listBlobentries(vert)), ")")
        printstyled(ioc, "  VariableType: "; color = :blue, bold = true)
        println(ioc, vari)
        # println(ioc, "kde max: $(round.(getKDEMax(getBelief(vnd)),digits=4))")
        # println(ioc, "kde max: $(round.(getKDEMax(getBelief(vnd)),digits=4))")
    else
        printstyled(ioc, summary(vert); bold = true, color = :blue)
        println(ioc, "")

        :solver in skipfields && push!(skipfields, :solverDataDict)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f, ":"; color = :blue)
            println(ioc, "")
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
    return nothing
end

printFactor(vert::FactorDFG; kwargs...) = printFactor(stdout::IO, vert; kwargs...)
function printFactor(
    io::IO,
    vert::FactorDFG;
    short::Bool = false,
    compact::Bool = true,
    limit::Bool = true,
    skipfields::Vector{Symbol} = Symbol[],
)
    ioc = IOContext(io, :limit => limit, :compact => compact)

    if short
        fct = getObservation(vert)
        fctt = fct |> typeof
        printstyled(ioc, summary(vert); bold = true)
        println()
        println(ioc, "  timestamp:     ", vert.timestamp)
        print(ioc, "  label:         ")
        printstyled(ioc, vert.label; bold = true)
        println(ioc)
        println(ioc, "  solvable:      ", getSolvable(vert))
        println(ioc, "  VariableOrder: ", vert.variableorder)
        println(ioc, "  multihypo:     ", getFactorState(vert).multihypo) # FIXME #477
        println(ioc, "  nullhypo:      ", getFactorState(vert).nullhypo)
        println(ioc, "  tags:          ", vert.tags)
        printstyled(ioc, "  FactorType: "; bold = true, color = :blue)
        println(ioc, fctt)
        # show(ioc, fctt)
        for f in setdiff(fieldnames(fctt), skipfields)
            printstyled(ioc, f, ": "; color = :magenta)
            show(ioc, typeof(getproperty(fct, f)))
            println(ioc)
        end
    else
        printstyled(ioc, summary(vert); bold = true, color = :blue)
        println(ioc)

        :solver in skipfields && push!(skipfields, :solverData)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f, ":"; color = :blue)
            println(ioc)
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
    return nothing
end

"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
function printFactor(dfg::AbstractDFG, sym::Symbol; kwargs...)
    return printFactor(getFactor(dfg, sym); kwargs...)
end

"""
   $SIGNATURES

Display the content of `State` to console for a given factor graph and variable tag`::Symbol`.

Dev Notes
- TODO split as two show macros between AMP and DFG
"""
function printVariable(dfg::AbstractDFG, sym::Symbol; kwargs...)
    return printVariable(getVariable(dfg, sym); kwargs...)
end

function printNode(dfg::AbstractDFG, sym::Symbol; kwargs...)
    if isVariable(dfg, sym)
        return printVariable(dfg, sym; kwargs...)
    else
        return printFactor(dfg, sym; kwargs...)
    end
end

##==============================================================================
## Overloading show
##==============================================================================
# Base.show_default(io, v)
function Base.show(io::IO, ::MIME"text/plain", v::VariableCompute)
    return printVariable(io, v; short = true, limit = false)
end

function Base.show(io::IO, ::MIME"text/plain", f::FactorDFG)
    return printFactor(io, f; short = true, limit = false)
end

function Base.show(io::IO, ::MIME"text/plain", dfg::AbstractDFG)
    summary(io, dfg)
    println(io, "  AgentLabel: ", getAgentLabel(dfg))
    println(io, "  FactorgraphLabel: ", getGraphLabel(dfg))
    println(io, "  Description: ", getDescription(dfg))
    println(io, "  Nr variables: ", length(ls(dfg)))
    println(io, "  Nr factors: ", length(lsf(dfg)))
    # println(io, "  Agent Metadata: ", keys(getAgentMetadata(dfg)))#FIXME use Bloblets
    # println(io, "  Graph Metadata: ", keys(getGraphMetadata(dfg)))#FIXME use Bloblets
    return
end

#default for Atom/Juno
function Base.show(
    io::IO,
    ::MIME"application/prs.juno.inline",
    x::Union{AbstractDFG, VariableCompute, FactorDFG},
)
    return show(io, x)
end
