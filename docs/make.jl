using TopoPlots
using Documenter

DocMeta.setdocmeta!(TopoPlots, :DocTestSetup, :(using TopoPlots); recursive=true)

makedocs(;
    modules=[TopoPlots],
    authors="Benedikt Ehinger, Simon Danisch, Beacon Biosignals",
    sitename="TopoPlots.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MakieOrg.github.io/TopoPlots.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "General TopoPlots" => "general.md",
        "EEG" => "eeg.md",
        "Function reference" => "functions.md"
    ],
)

deploydocs(;
    repo="github.com/MakieOrg/TopoPlots.jl",
    devbranch="master", push_preview=true
)
