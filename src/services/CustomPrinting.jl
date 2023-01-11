##==============================================================================
## Printing Variables and Factors
##==============================================================================

printVariable(vert::DFGVariable; kwargs...) = printVariable(stdout::IO, vert; kwargs...)

function printVariable( io::IO, vert::DFGVariable;
                        short::Bool=false,
                        compact::Bool=true,
                        limit::Bool=true,
                        skipfields::Vector{Symbol}=Symbol[],
                        solveKeys::Vector{Symbol}=Symbol[])

    ioc = IOContext(io, :limit=>limit, :compact=>compact)

    if short
        # opmemt = (getVariableType(vert) |> typeof ).name
        vari = getVariableType(vert) |> typeof
        printstyled(ioc, typeof(vert).name.name, "{",bold=true)
        printstyled(ioc, vari.name.name, bold=true, color=:blue)
        printstyled(ioc,"...}", bold=true)
        println(ioc, "")
        # printstyled(ioc, summary(vert),"\n", bold=true)

        try
            print(ioc, "  manifold:   ")
            show(ioc, getManifold(vert))
            println(ioc, "")
        catch e
        end
        vnd = haskey(vert.solverDataDict, :default) ? getSolverData(vert, :default) : nothing
        println(ioc, "  timestamp:  ", vert.timestamp)
        println(ioc, "   nstime:    ", vert.nstime)
        print(ioc,   "  label:      ")
        printstyled(ioc, vert.label, bold=true)
        println(ioc)
        println(ioc, "  solvable:   ", getSolvable(vert))
        println(ioc, "  tags:       ", getTags(vert))
        solk = listSolveKeys(vert) |> collect
        lsolk = length(solk)
        smsk = lsolk > 0 ? (rand(1:lsolk,100) |> unique)[1:minimum([4,lsolk])] : nothing
        # list the marginalization status
        ismarg = solk .|> x->isMarginalized(vert, x)
        isinit = solk .|> x->isInitialized(vert, x)
        printstyled(ioc, "  # VND solveKeys=    ($(lsolk))", bold=true)
        println(ioc, "")
        printstyled(ioc, "  # initialized:      ", bold=true)
        println(ioc, "(true=", sum(isinit), ",false=", length(isinit) - sum(isinit), ")" )
        printstyled(ioc, "  # marginalized:     ", bold=true)
        println(ioc, "(true=", sum(ismarg), ",false=", length(ismarg) - sum(ismarg), ")" )
        
        if vnd !== nothing
            println(ioc, "    :default <-- VariableNodeData")
            println(ioc, "      initilized:        ", isInitialized(vert, :default))
            println(ioc, "      marginalized:      ", isMarginalized(vert, :default))
            println(ioc, "      size bel. samples: ", size(vnd.val))
            print(ioc, "      kde bandwidths:    ")
            0 < length(vnd.bw) ? println(ioc, round.(vnd.bw[1], digits=4)) : nothing
            printstyled(ioc, "     VNDs: ",bold=true)
            println(ioc, solk[smsk], 4<lsolk ? "..." : "")
        end
        printstyled(ioc, "  # PPE solveKeys=    ($(length(getPPEDict(vert))))", bold=true)
        println(ioc, "")
        if haskey(getPPEDict(vert), :default)
            print(ioc, "    :default ")
            println(ioc, "<-- .suggested:    ", round.(getPPE(vert, :default).suggested,digits=4) )
        end
        maxkeys = 4
        for (key, ppe) in getPPEDict(vert)
            key == :default && continue # skip as default is done separately
            maxkeys -= 1
            maxkeys == 0 && break
            print(ioc, "    :$key ")
            println(ioc, "<-- .suggested:  ", round.(ppe.suggested,digits=4) )
        end
        printstyled(ioc, "  VariableType: ", color=:blue, bold=true)
        println(ioc, vari)
        # println(ioc, "kde max: $(round.(getKDEMax(getBelief(vnd)),digits=4))")
        # println(ioc, "kde max: $(round.(getKDEMax(getBelief(vnd)),digits=4))")
    else

        printstyled(ioc, summary(vert), bold=true, color=:blue)
        println(ioc, "")

        :solver in skipfields && push!(skipfields, :solverDataDict)
        :ppe in skipfields && push!(skipfields, :ppeDict)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f,":", color=:blue)
            println(ioc, "")
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
    nothing
end

printFactor(vert::DFGFactor; kwargs...) = printFactor(stdout::IO, vert; kwargs...)
function printFactor(   io::IO, vert::DFGFactor;
                        short::Bool=false,
                        compact::Bool=true,
                        limit::Bool=true,
                        skipfields::Vector{Symbol}=Symbol[])

    ioc = IOContext(io, :limit=>limit, :compact=>compact)

    if short
        opmemt = (getSolverData(vert).fnc |> typeof).name.name
        fct = getFactorType(vert)
        fctt = fct |> typeof
        printstyled(ioc, typeof(vert).name.name, "{",opmemt,"{",bold=true)
        printstyled(ioc, fctt.name.name,bold=true, color=:blue)
        printstyled(ioc, "...}}", bold=true)
        println(ioc)
        println(ioc, "  timestamp:     ", vert.timestamp)
        println(ioc, "   nstime:       ", vert.nstime)
        print(ioc,   "  label:         ")
        printstyled(ioc, vert.label, bold=true)
        println(ioc)
        println(ioc, "  solvable:      ", vert.solvable)
        println(ioc, "  VariableOrder: ", vert._variableOrderSymbols)
        println(ioc, "  multihypo:     ", getSolverData(vert).multihypo) # FIXME #477
        println(ioc, "  nullhypo:      ", getSolverData(vert).nullhypo)
        println(ioc, "  tags:          ", vert.tags)
        printstyled(ioc, "  FactorType: ", bold=true, color=:blue)
        println(ioc, fctt)
        # show(ioc, fctt)
        for f in setdiff(fieldnames(fctt), skipfields)
            printstyled(ioc, f,":", color=:magenta)
            println(ioc)
            show(ioc, getproperty(fct, f))
            println(ioc)
        end
    else

        printstyled(ioc, summary(vert), bold=true, color=:blue)
        println(ioc)

        :solver in skipfields && push!(skipfields, :solverData)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f,":", color=:blue)
            println(ioc)
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
    nothing
end


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
printFactor(dfg::AbstractDFG, sym::Symbol; kwargs...) = printFactor(getFactor(dfg, sym); kwargs...)

"""
   $SIGNATURES

Display the content of `VariableNodeData` to console for a given factor graph and variable tag`::Symbol`.

Dev Notes
- TODO split as two show macros between AMP and DFG
"""
printVariable(dfg::AbstractDFG, sym::Symbol; kwargs...) = printVariable(getVariable(dfg, sym); kwargs...)

printNode(dfg::AbstractDFG, sym::Symbol; kwargs...) = isVariable(dfg,sym) ? printVariable(dfg, sym; kwargs...) : printFactor(dfg, sym; kwargs...)


##==============================================================================
## Overloading show
##==============================================================================
# Base.show_default(io, v)
Base.show(io::IO, ::MIME"text/plain", v::DFGVariable) = printVariable(io, v, short=true, limit=false)

Base.show(io::IO, ::MIME"text/plain", f::DFGFactor) = printFactor(io, f, short=true, limit=false)

function Base.show(io::IO, dfg::AbstractDFG)
    summary(io, dfg)
    println(io, "\n  UserId: ", dfg.userId)
    println(io, "  RobotId: ", dfg.robotId)
    println(io, "  SessionId: ", dfg.sessionId)
    println(io, "  Description: ", dfg.description)
    println(io, "  Nr variables: ", length(ls(dfg)))
    println(io, "  Nr factors: ",length(lsf(dfg)))
    println(io, "  User Data: ", keys(getUserData(dfg)))
    println(io, "  Robot Data: ", keys(getRobotData(dfg)))
    println(io, "  Session Data: ", keys(getSessionData(dfg)))
end

Base.show(io::IO, ::MIME"text/plain", dfg::AbstractDFG) = show(io, dfg)

#default for Atom/Juno
Base.show(io::IO, ::MIME"application/prs.juno.inline", x::Union{AbstractDFG, DFGVariable, DFGFactor}) = show(io, x)
