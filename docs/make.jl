using Documenter
using GraphPlot
push!(ENV, "DFG_USE_CGDFG" => "true")
using DistributedFactorGraphs

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
        "Function Reference" => "func_ref.md",
    ],
    # html_prettyurls = !("local" in ARGS),
)

deploydocs(;
    repo = "github.com/JuliaRobotics/DistributedFactorGraphs.jl.git",
    target = "build",
    # deps   = Deps.pip("mkdocs", "python-markdown-math")
)
