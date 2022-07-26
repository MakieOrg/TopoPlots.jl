# Recipe for General TopoPlots


At the core of TopoPlots.jl is the `topoplot` recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.

```@docs
TopoPlots.topoplot
```


## Interpolators

The recipe supports different interpolation methods, namely:

```@docs
TopoPlots.ClaughTochter
TopoPlots.SplineInterpolator
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
interpolators = [ClaughTochter(), SplineInterpolator()]
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
