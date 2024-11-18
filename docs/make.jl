using TopoPlots
using Documenter

using TopoPlots: CHANNEL_TO_POSITION_10_05, CHANNEL_TO_POSITION_10_20

DocMeta.setdocmeta!(TopoPlots, :DocTestSetup, :(using TopoPlots); recursive=true)

makedocs(;
         modules=[TopoPlots],
         authors="Benedikt Ehinger, Simon Danisch, Beacon Biosignals",
         sitename="TopoPlots.jl",
         checkdocs=:exports,
         format=Documenter.HTML(;
                                prettyurls=get(ENV, "CI", "false") == "true",
                                canonical="https://MakieOrg.github.io/TopoPlots.jl",
                                assets=String[],),
         pages=["Home" => "index.md",
                "General TopoPlots" => "general.md",
                "EEG" => "eeg.md",
                "Function reference" => "functions.md",
                "Interpolator reference images" => "interpolator_reference.md"],)

deploydocs(;
           repo="github.com/MakieOrg/TopoPlots.jl",
           devbranch="master", push_preview=true)
