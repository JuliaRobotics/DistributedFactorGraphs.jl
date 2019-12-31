using Documenter
using DistributedFactorGraphs

makedocs(
    modules = [DistributedFactorGraphs],
    format = Documenter.HTML(),
    sitename = "DistributedFactorGraphs.jl",
    pages = Any[
        "Home" => "index.md",
        "Data Structure" => "DataStructure.md",
        "Getting Started" => [
            "Introduction" => "getting_started.md",
            "Building Graphs" => "BuildingGraphs.md",
            "Drawing Graphs" => "DrawingGraphs.md",
            "Common API Interface" => "ref_api.md"
        ],
        "DistributedFactorGraph API's" => [
            "Graphs.jl" => "apis/graphs.md",
            "LightGraphs.jl" => "apis/graphs.md",
            "CloudGraphs.jl" => "apis/graphs.md",
        ],
        "Reference" => "func_ref.md"
    ]
    # html_prettyurls = !("local" in ARGS),
    )

deploydocs(
    repo   = "github.com/JuliaRobotics/DistributedFactorGraphs.jl.git",
    target = "build",
    deps   = Deps.pip("mkdocs", "python-markdown-math")
)
