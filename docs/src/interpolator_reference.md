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
