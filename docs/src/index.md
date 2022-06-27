```@meta
CurrentModule = TopoPlots
```

# TopoPlots

Documentation for [TopoPlots](https://github.com/MakieOrg/TopoPlots.jl).


```@example 1
using LinearAlgebra, Statistics, TopoPlots, CairoMakie

data = Array{Float32}(undef, 64, 400, 3)
read!(TopoPlots.assetpath("example-data.bin"), data)

positions = Vector{Point2f}(undef, 64)
read!(TopoPlots.assetpath("layout64.bin"), positions)

f = Figure(resolution=(1000, 1000))
interpolators = [DelaunayMesh(), ClaughTochter(), SplineInterpolator()]
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
    colormap=[:red, :blue],
    axis=(title="delaunay mesh",aspect=DataAspect(),))
f
```

```@example 1
TopoPlots.topoplot(
    data[:, 340, 1], positions,
    axis=(; aspect=DataAspect()),
    colorrange=(-1, 1),
    padding_geometry = Rect,
    labels = string.(1:length(positions)),
    label_text=(; color=:white),
    label_scatter=(; strokewidth=2),
    contours=(linestyle=:dot, linewidth=2))
```


```@example 1
labels = string.(1:length(positions))
TopoPlots.eegtopoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
```

```@example 1
labels = TopoPlots.CHANNELS_10_20
TopoPlots.eegtopoplot(data[1:19, 340, 1], labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
```


```@index
```

```@autodocs
Modules = [TopoPlots]
```
