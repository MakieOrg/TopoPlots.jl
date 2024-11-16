# Recipe for General TopoPlots


At the core of TopoPlots.jl is the `topoplot` recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.

```@docs
TopoPlots.topoplot
```

## Interpolation

TopoPlots provides access to interpolators from several different Julia packages through its [`TopoPlots.Interpolator`](@ref) interface.

They can be accessed via plotting, or directly by calling the instantiated interpolator object as is shown below, namely with the arguments `(::Interpolator)(xrange::LinRange, yrange::LinRange, positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})`.  This is similar to using things like Matlab's `regrid` function.  You can find more details in the [Interpolation](@ref) section.

The recipe supports [different interpolation methods](@ref "Interpolator Comparison"), namely:

```@docs
TopoPlots.DelaunayMesh
TopoPlots.CloughTocher
TopoPlots.SplineInterpolator
TopoPlots.ScatteredInterpolationMethod
TopoPlots.NaturalNeighboursMethod
TopoPlots.NullInterpolator
```

You can define your own interpolation by subtyping:

```@docs
TopoPlots.Interpolator
```

and making your interpolator `SomeInterpolator` callable with the signature
```julia
(::SomeInterpolator)(xrange::LinRange, yrange::LinRange, positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number}; mask=nothing)
```

See also [Interpolator Comparison](@ref).

## Extrapolation

There are currently just two extrapolations: None (`NullExtrapolation()`) and a geometry based one:

```@docs
TopoPlots.GeomExtrapolation
```

The extrapolations in action:

```@example general
using CairoMakie, TopoPlots

data, positions = TopoPlots.example_data()
titles = ["No Extrapolation", "Rect", "Circle"]
data_slice = data[:, 340, 1]
f = Figure(resolution=(900, 300))
for (i, extra) in enumerate([NullExtrapolation(), GeomExtrapolation(enlarge=3.0), GeomExtrapolation(enlarge=3.0, geometry=Circle)])
    pos_extra, data_extra, rect_extended, rect = extra(positions, data_slice)
    geom = extra isa NullExtrapolation ? Rect : extra.geometry
    # Note, that enlarge doesn't match (the default), the additional points won't be seen and masked by `bounding_geometry` and `enlarge`.
    enlarge = extra isa NullExtrapolation ? 1.0 : extra.enlarge
    ax, p = topoplot(f[1, i], data_slice, positions; extrapolation=extra, bounding_geometry=geom, enlarge=enlarge, axis=(aspect=DataAspect(), title=titles[i]))
    scatter!(ax, pos_extra, color=data_extra, markersize=10, strokewidth=0.5, strokecolor=:white, colormap = p.colormap, colorrange = p.colorrange)
    lines!(ax, rect_extended, color=:black, linewidth=4)
    lines!(ax, rect, color=:red, linewidth=1)
end
resize_to_layout!(f)
f
```


## Interactive exploration

`DelaunayMesh` is best suited for interactive data exploration, which can be done quite easily with Makie's native UI and observable framework:

```@example general
f = Figure(resolution=(1000, 1250))
s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
data_obs = map(s.value) do idx
    data[:, idx, 1]
end
TopoPlots.topoplot(
    f[2, 1],
    data_obs, positions,
    interpolation=DelaunayMesh(),
    labels = string.(1:length(positions)),
    colorrange=(-1, 1),
    colormap=:viridis,
    axis=(title="delaunay mesh",aspect=DataAspect(),))
f
```

## Different geometry

The bounding geometry pads the input data with more points in the form of the geometry.
So e.g. for maps, one can use `Rect` as the bounding geometry:

```@example general
TopoPlots.topoplot(
    rand(10), rand(Point2f, 10),
    axis=(; aspect=DataAspect()),
    colorrange=(-1, 1),
    bounding_geometry = Rect,
    label_scatter=(; strokewidth=2),
    contours=(linewidth=2, color=:white))
```


## Different plotfunctions

It is possible to exchange the plotting function, from `heatmap!` to `contourf!` or `surface!`. Due to different keyword arguments, one needs to filter which keywords are passed to the plotting function manually.

```@example general
f = Figure()

TopoPlots.topoplot(f[1,1],
    rand(10), rand(Point2f, 10),
    axis=(; aspect=DataAspect()),
    plotfnc! = contourf!, plotfnc_kwargs_names=[:colormap])

TopoPlots.topoplot(f[1,2],
    rand(10), rand(Point2f, 10),
    axis=(; aspect=DataAspect()),
    plotfnc! = surface!) # surface can take all default kwargs similar to heatmap!

f
```
