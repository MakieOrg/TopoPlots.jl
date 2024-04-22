# Recipe for General TopoPlots


At the core of TopoPlots.jl is the `topoplot` recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.

```@docs
TopoPlots.topoplot
```

## Interpolation

TopoPlots provides access to interpolators from several different Julia packages through its [`Interpolator`](@ref) interface.

They can be accessed via plotting, or directly by calling the instantiated interpolator object as is shown below, namely with the arguments `(::Interpolator)(xrange::LinRange, yrange::LinRange, positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})`.  This is similar to using things like Matlab's `regrid` function.  You can find more details in the [Interpolation](@ref) section.

The recipe supports different interpolation methods, namely:

```@docs
TopoPlots.DelaunayMesh
TopoPlots.CloughTocher
TopoPlots.SplineInterpolator
TopoPlots.ScatteredInterpolationMethod
TopoPlots.NaturalNeighbourMethod
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

The different interpolation schemes look quite different:

```@example 1
using TopoPlots, CairoMakie, ScatteredInterpolation, NaturalNeighbours

data, positions = TopoPlots.example_data()

f = Figure(resolution=(1000, 1250))

interpolators = [
    DelaunayMesh() CloughTocher();
    SplineInterpolator() NullInterpolator();
    ScatteredInterpolationMethod(ThinPlate()) ScatteredInterpolationMethod(Shepard(3));
    NaturalNeighboursMethod(Sibson(1)) NaturalNeighboursMethod(Triangle());
    ]

data_slice = data[:, 360, 1]

for idx in CartesianIndices(interpolators)
    interpolation = interpolators[idx]

    # precompile to get accurate measurements
    TopoPlots.topoplot(
        data_slice, positions;
        contours=true, interpolation=interpolation,
        labels = string.(1:length(positions)), colorrange=(-1, 1),
        label_scatter=(markersize=10,),
        axis=(type=Axis, title="...", aspect=DataAspect(),))

    # measure time, to give an idea of what speed to expect from the different interpolators
    t = @elapsed ax, pl = TopoPlots.topoplot(
        f[Tuple(idx)...], data_slice, positions;
        contours=true,
        interpolation=interpolation,
        labels = string.(1:length(positions)), colorrange=(-1, 1),
        label_scatter=(markersize=10,),
        axis=(type=Axis, title="$(typeof(interpolation))()",aspect=DataAspect(),))

   ax.title = ("$(typeof(interpolation))() - $(round(t, digits=2))s")
end
f
```

## Extrapolation

There are currently just two extrapolations: None (`NullExtrapolation()`) and a geometry based one:

```@docs
TopoPlots.GeomExtrapolation
```

The extrapolations in action:

```@example 1
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

```@example 1
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

```@example 1
TopoPlots.topoplot(
    rand(10), rand(Point2f, 10),
    axis=(; aspect=DataAspect()),
    colorrange=(-1, 1),
    bounding_geometry = Rect,
    label_scatter=(; strokewidth=2),
    contours=(linewidth=2, color=:white))
```
