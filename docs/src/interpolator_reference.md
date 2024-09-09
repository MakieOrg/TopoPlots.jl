# Interpolator reference

This file contains reference figures showing the output of each interpolator available in TopoPlots, as well as timings for them. 

It is a more comprehensive version of the plot in [Interpolation](@ref).

### Example data

```@example 1

using TopoPlots, CairoMakie, ScatteredInterpolation, NaturalNeighbours

data, positions = TopoPlots.example_data()

f = Figure(size=(1000, 1500))

interpolators = [
    SplineInterpolator() NullInterpolator() DelaunayMesh();
    CloughTocher() ScatteredInterpolationMethod(ThinPlate()) ScatteredInterpolationMethod(Shepard(3));
    ScatteredInterpolationMethod(Multiquadratic()) ScatteredInterpolationMethod(InverseMultiquadratic()) ScatteredInterpolationMethod(Gaussian());
    NaturalNeighboursMethod(Hiyoshi(2)) NaturalNeighboursMethod(Sibson()) NaturalNeighboursMethod(Laplace());
    NaturalNeighboursMethod(Farin()) NaturalNeighboursMethod(Sibson(1)) NaturalNeighboursMethod(Nearest());
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
   if interpolation isa Union{NaturalNeighboursMethod, ScatteredInterpolationMethod}
       ax.title = "$(typeof(interpolation))() - $(round(t, digits=2))s"
       ax.subtitle = string(typeof(interpolation.method))
   end
end
f
```

### Randomly sampled function

```@example 1
using TopoPlots, CairoMakie, ScatteredInterpolation, NaturalNeighbours
using TopoPlots.Makie.Random: randsubseq

data = Makie.peaks(20)
sampling_points = randsubseq(CartesianIndices(data), 0.25)
data_slice = data[sampling_points]
positions = Point2f.(Tuple.(sampling_points))

interpolators = [
    SplineInterpolator(; smoothing = 7) NullInterpolator() DelaunayMesh();
    CloughTocher() ScatteredInterpolationMethod(ThinPlate()) ScatteredInterpolationMethod(Shepard(3));
    ScatteredInterpolationMethod(Multiquadratic()) ScatteredInterpolationMethod(InverseMultiquadratic()) ScatteredInterpolationMethod(Gaussian());
    NaturalNeighboursMethod(Hiyoshi(2)) NaturalNeighboursMethod(Sibson()) NaturalNeighboursMethod(Laplace());
    NaturalNeighboursMethod(Farin()) NaturalNeighboursMethod(Sibson(1)) NaturalNeighboursMethod(Nearest());
    ]

f = Figure(; size = (1000, 1500))

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
   if interpolation isa Union{NaturalNeighboursMethod, ScatteredInterpolationMethod}
       ax.title = "$(typeof(interpolation))() - $(round(t, digits=2))s"
       ax.subtitle = string(typeof(interpolation.method))
   end
end
f
```
