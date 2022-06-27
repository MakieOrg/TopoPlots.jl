using TopoPlots
using Documenter

DocMeta.setdocmeta!(TopoPlots, :DocTestSetup, :(using TopoPlots); recursive=true)

makedocs(;
    modules=[TopoPlots],
    authors="Benedikt Ehinger, Simon Danisch, Beacon Biosignals",
    repo="https://github.com/MakieOrg/TopoPlots.jl/blob/{commit}{path}#{line}",
    sitename="TopoPlots.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MakieOrg.github.io/TopoPlots.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    strict=true
)

deploydocs(;
    repo="github.com/MakieOrg/TopoPlots.jl",
    devbranch="master", push_preview=true
)
