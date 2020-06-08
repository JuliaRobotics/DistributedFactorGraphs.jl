##==============================================================================
## Overloading show
##==============================================================================
# Base.show_default(io, v)
Base.show(io::IO, ::MIME"text/plain", v::DFGVariable) = show(IOContext(io, :limit=>true, :compact=>true), v)

function Base.show(io::IO, ::MIME"text/plain", f::DFGFactor)
  # show(IOContext(io, :limit=>true, :compact=>true), f)
  fctt = getFactorType(f)
  println(io, "$(typeof(f))")
  println(io, "  Name: $(f.label)")
  println(io, "  VariableOrder: $(getVariableOrder(f))")
  println(io, "  multihypo: $(getSolverData(f).multihypo)") # FIXME #477
  println(io, "  nullhypo: TBD")
  println(io, "  solvable: $(f.solvable)")
  println(io, "  timestamp: $(f.timestamp)")
  println(io, "  nstime: $(f.nstime)")
  println(io, "  tags: $(f.tags)")
  println(io, "  Type: $(typeof(fctt))")
  println(io, "    Fields: $(fieldnames(typeof(fctt)))")
  show(IOContext(io, :limit=>true, :compact=>true), fctt)
end

function Base.show(io::IO, ::MIME"text/plain", dfg::AbstractDFG)
    summary(io, dfg)
    println(io, "\n  UserId: ", dfg.userId)
    println(io, "  RobotId: ", dfg.robotId)
    println(io, "  SessionId: ", dfg.sessionId)
    println(io, "  Description: ", dfg.description)
    println(io, "  Nr variables: ", length(ls(dfg)))
    println(io, "  Nr factors: ",length(lsf(dfg)))
    println(io, "  User Data: ", keys(dfg.userData))
    println(io, "  Robot Data: ", keys(dfg.robotData))
    println(io, "  Session Data: ", keys(dfg.sessionData))
end


#default for Atom/Juno
Base.show(io::IO, ::MIME"application/prs.juno.inline", x::Union{AbstractDFG, DFGVariable, DFGFactor}) = x


##==============================================================================
## Printing Variables and Factors
##==============================================================================

printVariable(vert::DFGVariable; kwargs...) = printVariable(stdout::IO, vert; kwargs...)

function printVariable(io::IO, vert::DFGVariable;
                       short::Bool=false,
                       compact::Bool=true,
                       limit::Bool=true,
                       skipfields::Vector{Symbol}=Symbol[],
                       solveKeys::Vector{Symbol}=Symbol[])

    ioc = IOContext(io, :limit=>limit, :compact=>compact)

    if short
        printstyled(ioc, summary(vert),"\n", bold=true)
        vnd = getSolverData(vert)
        println(ioc, "label: $(vert.label)")
        println(ioc, "tags: $(getTags(vert))")
        println(ioc, "size marginal samples: $(size(vnd.val))")
        println(ioc, "kde bandwidths: $((vnd.bw)[:,1])")
        if 0 < length(getPPEDict(vert))
            println(ioc, "PPE.suggested: $(round.(getPPE(vert).suggested,digits=4))")
        else
            println(ioc, "No PPEs")
        end
        # println(ioc, "kde max: $(round.(getKDEMax(getKDE(vnd)),digits=4))")
        # println(ioc, "kde max: $(round.(getKDEMax(getKDE(vnd)),digits=4))")
    else

        printstyled(ioc, summary(vert),"\n", bold=true, color=:blue)

        :solver in skipfields && push!(skipfields, :solverDataDict)
        :ppe in skipfields && push!(skipfields, :ppeDict)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f,":\n", color=:blue)
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
end

printFactor(vert::DFGFactor; kwargs...) = printFactor(stdout::IO, vert; kwargs...)
function printFactor(io::IO, vert::DFGFactor;
                     short::Bool=false,
                     compact::Bool=true,
                     limit::Bool=true,
                     skipfields::Vector{Symbol}=Symbol[])

    ioc = IOContext(io, :limit=>limit, :compact=>compact)

    if short
        printstyled(ioc, summary(vert),"\n", bold=true)
        println(ioc, "label: ", vert.label)
        println(ioc, "timestamp: ", vert.timestamp)
        println(ioc, "tags: ", vert.tags)
        println(ioc, "solvable: ", vert.solvable)
        println(ioc, "VariableOrder: ", vert._variableOrderSymbols)
    else

        printstyled(ioc, summary(vert),"\n", bold=true, color=:blue)

        :solver in skipfields && push!(skipfields, :solverData)

        t = typeof(vert)
        fields = setdiff(fieldnames(t), skipfields)
        nf = nfields(vert)

        for f in fields
            printstyled(ioc, f,":\n", color=:blue)
            show(ioc, getproperty(vert, f))
            println(ioc)
        end
    end
end


"""
    $SIGNATURES

Display and return to console the user factor identified by tag name.
"""
printFactor(dfg::AbstractDFG, sym::Symbol) = print(getFactor(dfg, sym))

"""
   $SIGNATURES

Display the content of `VariableNodeData` to console for a given factor graph and variable tag`::Symbol`.

Dev Notes
- TODO split as two show macros between AMP and DFG
"""
printVariable(dfg::AbstractDFG, sym::Symbol) = print(getVariable(dfg, sym))

printNode(dfg::AbstractDFG, sym::Symbol) = isVariable(dfg,sym) ? printVariable(dfg, sym) : printFactor(dfg, sym)
