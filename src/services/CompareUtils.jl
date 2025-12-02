## TODO update this file for DFG v1
##==============================================================================
## (==)
##==============================================================================
import Base.==
## @generated compare
# Reference https://github.com/JuliaLang/julia/issues/4648

#=
For now abstract `StateType`s are considered equal if they are the same type, dims, and manifolds (abels are deprecated)
If your implentation has aditional properties such as `DynPose2` with `ut::Int64` (microsecond time) or support different manifolds
implement compare if needed.
=#
# ==(a::StateType,b::StateType) = typeof(a) == typeof(b) && a.dims == b.dims && a.manifolds == b.manifolds

==(a::FactorCache, b::FactorCache) = typeof(a) == typeof(b)

==(a::AbstractObservation, b::AbstractObservation) = typeof(a) == typeof(b)

# Generate compares automatically for all in this union
const GeneratedCompareUnion = Union{
    State,
    Blobentry,
    Bloblet,
    VariableSummary,
    VariableSkeleton,
    FactorSummary,
    FactorSkeleton,
    Recipehyper,
    Recipestate,
}

@generated function ==(x::T, y::T) where {T <: GeneratedCompareUnion}
    return mapreduce(n -> :(x.$n == y.$n), (a, b) -> :($a && $b), fieldnames(x))
end

function ==(x::FactorDFG, y::FactorDFG)
    ignored = [:solvercache, :solvable]
    tp = mapreduce(
        n -> getproperty(x, n) == getproperty(y, n),
        (a, b) -> a && b,
        setdiff(propertynames(x), ignored),
    )
    return tp && getSolvable(x) == getSolvable(y)
end

function ==(x::VariableDFG, y::VariableDFG)
    ignored = [:solvable]
    tp = mapreduce(
        n -> getproperty(x, n) == getproperty(y, n),
        (a, b) -> a && b,
        setdiff(propertynames(x), ignored),
    )
    return tp && getSolvable(x) == getSolvable(y)
end

##==============================================================================
## Compare
##==============================================================================

function compareField(Allc, Bllc, syms)
    (!isdefined(Allc, syms) && !isdefined(Bllc, syms)) && return true
    !isdefined(Allc, syms) && return false
    !isdefined(Bllc, syms) && return false
    a = getproperty(Allc, syms)
    b = getproperty(Bllc, syms)
    @debug "Comparing field directly a vs b" syms a b
    if a isa Base.RefValue
        return a[] == b[]
    else
        return a == b
    end
end

"""
    $(SIGNATURES)

Compare the all fields of T that are not in `skip` for objects `Al` and `Bl` and returns `::Bool`.

TODO > add to func_ref.md
"""
function compareFields(
    Al::T1,
    Bl::T2;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T1, T2}
    #
    T1 == T2 ? nothing : @warn("different types in compareFields", T1, T2)
    for field in fieldnames(T1)
        (field in skip) && continue
        tp = compareField(Al, Bl, field)
        show && !tp && @debug("  $tp : $field")
        show &&
            !tp &&
            (@debug "  $field" a = getproperty(Al, field) b = getproperty(Bl, field))
        !tp && return false
    end
    return true
end

function compareFields(
    Al::T,
    Bl::T;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T <: Union{Number, AbstractString}}
    #
    return Al == Bl
end

function compareAll(
    Al::T,
    Bl::T;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T <: Union{AbstractString, Symbol}}
    #
    return Al == Bl
end

function compareAll(
    Al::T,
    Bl::T;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T <: Union{Array{<:Number}, Number}}
    #
    (length(Al) != length(Bl)) && return false
    return norm(Al - Bl) < 1e-6
end

function compareAll(
    Al::T,
    Bl::T;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T <: Array}
    #
    (length(Al) != length(Bl)) && return false
    for i = 1:length(Al)
        !compareAll(Al[i], Bl[i]; show = false) && return false
    end
    return true
end

"""
    $(SIGNATURES)

Recursively compare the all fields of T that are not in `skip` for objects `Al` and `Bl`.

TODO > add to func_ref.md
"""
function compareAll(
    Al::Tuple,
    Bl::Tuple;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
)
    #
    length(Al) != length(Bl) && return false
    for i = 1:length(Al)
        !compareAll(Al[i], Bl[i]; show = show, skip = skip) && return false
    end
    return true
end

function compareAll(
    Al::T,
    Bl::T;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T <: Dict}
    #
    (length(Al) != length(Bl)) && return false
    for (id, val) in Al
        (Symbol(id) in skip) && continue
        !compareAll(val, Bl[id]; show = show, skip = skip) && return false
    end
    return true
end

function compareAll(
    Al::T1,
    Bl::T2;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
) where {T1, T2}
    @debug "Comparing types $T1, $T2"
    if T1 != T2
        @warn "Types are different" T1 T2
    end
    # @debug "  Al = $Al"
    # @debug "  Bl = $Bl"
    !compareFields(Al, Bl; show = show, skip = skip) && return false
    for field in fieldnames(T1)
        field in skip && continue
        @debug("  Checking field: $field")
        (!isdefined(Al, field) && !isdefined(Al, field)) && return true
        !isdefined(Al, field) && return false
        !isdefined(Bl, field) && return false
        Ad = eval(:($Al.$field))
        Bd = eval(:($Bl.$field))
        !compareAll(Ad, Bd; show = show, skip = skip) && return false
    end
    return true
end

#Compare State
function compare(a::State, b::State)
    a.val != b.val && @debug("val is not equal") === nothing && return false
    a.bw != b.bw && @debug("bw is not equal") === nothing && return false
    # a.BayesNetOutVertIDs != b.BayesNetOutVertIDs &&
    #     @debug("BayesNetOutVertIDs is not equal") === nothing &&
    #     return false
    # a.eliminated != b.eliminated &&
    #     @debug("eliminated is not equal") === nothing &&
    #     return false
    # a.BayesNetVertID != b.BayesNetVertID &&
    #     @debug("BayesNetVertID is not equal") === nothing &&
    #     return false
    a.separator != b.separator &&
        @debug("separator is not equal") === nothing &&
        return false
    a.initialized != b.initialized &&
        @debug("initialized is not equal") === nothing &&
        return false
    !isapprox(a.observability, b.observability; atol = 1e-13) &&
        @debug("infoPerCoord is not equal") === nothing &&
        return false
    a.marginalized != b.marginalized &&
        @debug("ismargin is not equal") === nothing &&
        return false
    # a.dontmargin != b.dontmargin &&
    # @debug("dontmargin is not equal") === nothing &&
    # return false
    getStateKind(a) != getStateKind(b) &&
        @debug("variableType is not equal") === nothing &&
        return false
    return true
end

"""
    $SIGNATURES

Compare that all fields are the same in a `::FactorGraph` variable.
"""
function compareVariable(
    A::VariableDFG,
    B::VariableDFG;
    skip::Vector{Symbol} = Symbol[],
    show::Bool = true,
    skipsamples::Bool = true,
)
    #
    skiplist = union([:states, :atzone, :inzone, :blobentries, :bloblets], skip)
    TP = compareAll(A, B; skip = skiplist, show = show)
    varskiplist = skipsamples ? [:val; :bw] : Symbol[]
    skiplist = union([:variableType;], varskiplist)
    union!(skiplist, skip)
    # TP = TP && compareAll(A.states, B.states; skip = skiplist, show = show)

    Ad = getState(A, :default) #FIXME why onlly comparing default?
    Bd = getState(B, :default)

    # TP = TP && compareAll(A.attributes, B.attributes, skip=[:variableType;], show=show)
    varskiplist = union(varskiplist, [:variableType])
    union!(varskiplist, skip)
    TP = TP && compareAll(Ad, Bd; skip = varskiplist, show = show)
    TP = TP && typeof(getStateKind(Ad)) == typeof(getStateKind(Bd))
    TP = TP && compareAll(getStateKind(Ad), getStateKind(Bd); show = show, skip = skip)
    return TP::Bool
end

"""
    $SIGNATURES

Compare that all fields are the same in a `::FactorGraph` factor.

DevNotes
- TODO `getSolverData(A).fnc.varValsAll / varidx` are only defined downstream, so should should this function not be in IIF?
"""
function compareFactor(
    A::FactorCompute,
    B::FactorCompute;
    show::Bool = true,
    skip::Vector{Symbol} = Symbol[],
    skipsamples::Bool = true,
    skipcompute::Bool = true,
)
    #
    skip_ = union(
        [:attributes, :solverData, :observation, :solvercache, :variableorder, :_gradients],
        skip,
    )
    TP = compareAll(A, B; skip = skip_, show = show)
    @debug "compareFactor 1/5" TP
    TP &= compareAll(A.state, B.state; skip, show)
    TP &= compareAll(A.hyper, B.hyper; skip, show)
    @debug "compareFactor 2/5" TP
    if !TP || :fnc in skip
        return TP
    end
    TP =
        TP & compareAll(
            getObservation(A),
            getObservation(B);
            skip = union(
                [
                    :cpt
                    :measurement
                    :params
                    :varValsAll
                    :varidx
                    :threadmodel
                    :_gradients
                ],
                skip,
            ),
            show = show,
        )
    @debug "compareFactor 3/5" TP

    #FIXME is measurement stil in use
    if !(:measurement in skip)
        TP =
            TP & (
                skipsamples || compareAll(
                    getCache(A).measurement,
                    getCache(B).measurement;
                    show = show,
                    skip = skip,
                )
            )
    end
    @debug "compareFactor 4/5" TP
    #FIXME is varValsAll stil in use and should it be checked, skipping for now
    if !(:varValsAll in skip) && hasfield(typeof(getCache(A)), :varValsAll)
        TP =
            TP & (
                skipcompute || compareAll(
                    getCache(A).varValsAll,
                    getCache(B).varValsAll;
                    show = show,
                    skip = skip,
                )
            )
    end
    @debug "compareFactor 5/5" TP
    #FIXME is varidx stil in use and should it be checked
    if !(:varidx in skip) &&
       hasfield(typeof(getCache(A)), :varidx) &&
       getCache(A).varidx isa Base.RefValue
        TP =
            TP & (
                skipcompute || compareAll(
                    getCache(A).varidx[],
                    getCache(B).varidx[];
                    show = show,
                    skip = skip,
                )
            )
    end

    return TP
end
# Ad = getSolverData(A)
# Bd = getSolverData(B)
# TP =  compareAll(A, B, skip=[:attributes;:data], show=show)
# TP &= compareAll(A.attributes, B.attributes, skip=[:data;], show=show)
# TP &= compareAll(getSolverData(A).fnc.cpt, getSolverData(B).fnc.cpt, show=show)

"""
    $SIGNATURES

Compare all variables in both `::FactorGraph`s A and B.

Notes
- A and B should all the same variables and factors.

Related:

`compareFactorGraphs`, `compareSimilarVariables`, `compareVariable`, `ls`
"""
function compareAllVariables(
    fgA::AbstractDFG,
    fgB::AbstractDFG;
    skip::Vector{Symbol} = Symbol[],
    show::Bool = true,
    skipsamples::Bool = true,
)
    # get all the variables in A or B
    xlA = listVariables(fgA)
    xlB = listVariables(fgB)
    vars = union(xlA, xlB)

    # compare all variables exist in both A and B
    TP = length(xlA) == length(xlB)
    for xla in xlA
        TP &= xla in xlB
    end
    # slightly redundant, but repeating opposite direction anyway
    for xlb in xlB
        TP &= xlb in xlA
    end

    # compare each variable is the same in both A and B
    for var in vars
        TP =
            TP && compareVariable(
                getVariable(fgA, var),
                getVariable(fgB, var);
                skipsamples = skipsamples,
                skip = skip,
            )
    end

    # return comparison result
    return TP::Bool
end

"""
    $SIGNATURES

Compare similar labels between `::FactorGraph`s A and B.

Notes
- At least one variable label should exist in both A and B.

Related:

`compareFactorGraphs`, `compareAllVariables`, `compareSimilarFactors`, `compareVariable`, `ls`.
"""
function compareSimilarVariables(
    fgA::AbstractDFG,
    fgB::AbstractDFG;
    skip::Vector{Symbol} = Symbol[],
    show::Bool = true,
    skipsamples::Bool = true,
)
    #
    xlA = listVariables(fgA)
    xlB = listVariables(fgB)

    # find common variables
    xlAB = intersect(xlA, xlB)
    TP = length(xlAB) > 0

    # compare the common set
    for var in xlAB
        @info var
        TP &= compareVariable(
            getVariable(fgA, var),
            getVariable(fgB, var);
            skipsamples = skipsamples,
            skip = skip,
        )
    end

    # return comparison result
    return TP::Bool
end

"""
    $SIGNATURES

Compare similar factors between `::FactorGraph`s A and B.

Related:

`compareFactorGraphs`, `compareSimilarVariables`, `compareAllVariables`, `ls`.
"""
function compareSimilarFactors(
    fgA::AbstractDFG,
    fgB::AbstractDFG;
    skipsamples::Bool = true,
    skipcompute::Bool = true,
    skip::AbstractVector{Symbol} = Symbol[],
    show::Bool = true,
)
    #
    xlA = listFactors(fgA)
    xlB = listFactors(fgB)

    # find common variables
    xlAB = intersect(xlA, xlB)
    TP = length(xlAB) > 0

    # compare the common set
    for var in xlAB
        TP =
            TP && compareFactor(
                getFactor(fgA, var),
                getFactor(fgB, var);
                skipsamples = skipsamples,
                skipcompute = skipcompute,
                skip = skip,
                show = show,
            )
    end

    # return comparison result
    return TP
end

"""
    $SIGNATURES

Compare and return if two factor graph objects are the same, by comparing similar variables and factors.

Notes:
- Default items to skip with `skipsamples`, `skipcompute`.
- User defined fields to skip can be specified with `skip::Vector{Symbol}`.
- To enable debug messages for viewing which fields are not the same:
  - https://stackoverflow.com/questions/53548681/how-to-enable-debugging-messages-in-juno-julia-editor

Related:

`compareSimilarVariables`, `compareSimilarFactors`, `compareAllVariables`, `ls`.
"""
function compareFactorGraphs(
    fgA::AbstractDFG,
    fgB::AbstractDFG;
    skipsamples::Bool = true,
    skipcompute::Bool = true,
    skip::Vector{Symbol} = Symbol[],
    show::Bool = true,
)
    #
    skiplist = Symbol[
        :g,
        :bn,
        :IDs,
        :fIDs,
        :id,
        :nodeIDs,
        :factorIDs,
        :fifo,
        :solverParams,
        :factorOperationalMemoryType,
        :agent,
        :graph,
    ]
    skiplist = union(skiplist, skip)
    @warn "compareFactorGraphs will skip comparisons on: $skiplist"

    TP = compareAll(fgA, fgB; skip = skiplist, show = show)
    TP =
        TP && compareSimilarVariables(
            fgA,
            fgB;
            skipsamples = skipsamples,
            show = show,
            skip = skiplist,
        )
    TP =
        TP && compareSimilarFactors(
            fgA,
            fgB;
            skipsamples = skipsamples,
            skipcompute = skipcompute,
            show = show,
            skip = skiplist,
        )
    TP = TP && compareAll(fgA.solverParams, fgB.solverParams; skip = skiplist)

    return TP
end
