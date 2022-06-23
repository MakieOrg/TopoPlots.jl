using Test
using LinearAlgebra, Statistics, TopoPlots, CairoMakie, JLD2

example_data = JLD2.load(joinpath(@__DIR__, "example.jld2"))
pos = example_data["pos2"]
data = example_data["data"]
positions = Point2f.(pos[:,1], pos[:,2])

function test1()
    f = Figure(resolution=(1000, 1000))
    interpolators = [DelaunayMesh(), ClaughTochter(), SplineInterpolator()]

    s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        data[:, idx, 1]
    end
    for (i, interpolation) in enumerate(interpolators)
        TopoPlots.topoplot(
            f[2, 1][1, i], positions, data_obs;
            interpolation=interpolation, labels = string.(1:length(positions)), colorrange=(-1, 1),
            axis=(title="$interpolation",aspect=DataAspect(),))
    end
    f
end
test1()


function test2()
    f = Figure(resolution=(1000, 1000))
    s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        data[:, idx, 1]
    end
    TopoPlots.topoplot(
        f[2, 1],
        positions,
        data_obs,
        interpolation=DelaunayMesh(),
        labels = string.(1:length(positions)),
        colorrange=(-1, 1),
        colormap=:viridis,
        axis=(title="delaunay mesh",aspect=DataAspect(),), )
    f
end
using CairoMakie

test1() |> display
test2() |> display

using GLMakie
GLMakie.activate!()
TopoPlots.topoplot(
    positions, data[:, 340, 1],
    axis=(; aspect=DataAspect()),
    colorrange=(-1, 1),
    padding_geometry = Rect,
    labels = string.(1:length(positions)),
    label_text=(; color=:white),
    label_scatter=(; strokewidth=2),
    contours=(; levels=levels, linewidth=2)) |> display


labels = string.(1:length(positions))
TopoPlots.eegtopoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
