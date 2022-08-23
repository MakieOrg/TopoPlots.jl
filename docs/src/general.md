# Recipe for General TopoPlots


At the core of TopoPlots.jl is the `topoplot` recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.

```@docs
TopoPlots.topoplot
```

## Interpolation

The recipe supports different interpolation methods, namely:

```@docs
TopoPlots.DelaunayMesh
TopoPlots.ClaughTochter
TopoPlots.SplineInterpolator
TopoPlots.NullInterpolator
```
One can define your own interpolation by subtyping:

```@docs
TopoPlots.Interpolator
```

The different interpolation schemes look quite different:

```@example 1
using TopoPlots, CairoMakie

data, positions = TopoPlots.example_data()

f = Figure(resolution=(1000, 1000))

interpolators = [
    DelaunayMesh(), ClaughTochter(),
    SplineInterpolator(), NullInterpolator()]

data_slice = data[:, 360, 1]

for (i, interpolation) in enumerate(interpolators)
    j = i == 3 ? (:) : i
    TopoPlots.topoplot(
        f[((i - 1) ÷ 2) + 1, j], data_slice, positions;
        contours=true,
        interpolation=interpolation,
        labels = string.(1:length(positions)), colorrange=(-1, 1),
        axis=(type=Axis, title="$(typeof(interpolation))()",aspect=DataAspect(),))
end
f[1, ]
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
f = Figure()
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
f
```


## Interactive exploration

`DelaunayMesh` is best suited for interactive data exploration, which can be done quite easily with Makie's native UI and observable framework:

```@example 1
f = Figure(resolution=(1000, 1000))
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
