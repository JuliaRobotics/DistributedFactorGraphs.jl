using Documenter
using GraphMakie
using DistributedFactorGraphs

DFG.@usingDFG true

makedocs(;
    modules = [DistributedFactorGraphs],
    format = Documenter.HTML(),
    sitename = "DistributedFactorGraphs.jl",
    pages = Any[
        "Home" => "index.md",
        "Getting Started" => [
            "DFG Data Structures" => "DataStructure.md",
            "Building Graphs" => "BuildingGraphs.md",
            "Using Graph Elements" => "GraphData.md",
            "Drawing Graphs" => "DrawingGraphs.md",
            "Quick API Reference" => "ref_api.md",
        ],
        "Reference" => ["func_ref.md", "services_ref.md", "blob_ref.md"],
    ],
    checkdocs = :public,
    # warnonly=[:doctest],
    # html_prettyurls = !("local" in ARGS),
)

deploydocs(;
    repo = "github.com/JuliaRobotics/DistributedFactorGraphs.jl.git",
    target = "build",
)
