```@meta
CurrentModule = TopoPlots
```

# TopoPlots

Documentation for [TopoPlots](https://github.com/MakieOrg/TopoPlots.jl).

A package for creating topoplots from data that were measured on arbitrarily positioned sensors:

```@example 1
using TopoPlots, CairoMakie
topoplot(rand(10), rand(Point2f, 10); contours=(color=:white, linewidth=2), label_scatter=true)
```

Find more documentation for `topoplot` in [Recipe for General TopoPlots](@ref).

It also contains some more convenience methods for EEG data, which is explained in [EEG Topoplots](@ref).
