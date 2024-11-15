```@meta
CurrentModule = TopoPlots
```

# TopoPlots

Documentation for [TopoPlots](https://github.com/MakieOrg/TopoPlots.jl).

A package for creating topoplots from data that were measured on arbitrarily positioned sensors:

```@example intro
using TopoPlots, CairoMakie
f = Figure(;resolution=(800,280))
topoplot(f[1,1],rand(20), rand(Point2f, 20))
topoplot(f[1,2],rand(20), rand(Point2f, 20); contours=(color=:white, linewidth=2),
         label_scatter=true, bounding_geometry=Rect(0,0,1,1), colormap=:viridis)
eeg_topoplot(f[1,3],rand(20),1:20;positions=rand(Point2f, 20), colormap=:Oranges)
f
```

Find more documentation for `topoplot` in [Recipe for General TopoPlots](@ref).

It also contains some more convenience methods for EEG data, which is explained in [EEG Topoplots](@ref).

You can also use TopoPlots' interpolators as a simple interface to regrid irregular data.  See [Interpolation](@ref) for more details.
