import Base: show

struct DistributedFactorGraph
    # A cache - TBD
    # something::T
    # An API for communication
    api::DFGAPI
    # A series of mirrors that are asynchronously updated.
    mirrors::Vector{DFGAPI}
    DistributedFactorGraph() = new(GraphsJlAPI.getAPI(), Vector{DFGAPI}())
    DistributedFactorGraph(api::DFGAPI) = new(api, Vector{DFGAPI}())
    DistributedFactorGraph(api::DFGAPI, mirrors::Vector{DFGAPI}) = new(api, mirrors)
end

function show(io::IO, d::DistributedFactorGraph)
    println(io, "DFG:")
    println(io, " - Principal API: $(d.api)")
    if length(d.mirrors) > 0
        println(io, " - Mirrors ($(length(d.mirrors))): ")
        map(x -> print(io, "   - $x"), d.mirrors)
    end
end
