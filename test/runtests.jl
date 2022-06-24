using Test
using LinearAlgebra, Statistics, TopoPlots, CairoMakie, JLD2

example_data = JLD2.load(joinpath(@__DIR__, "example.jld2"))
pos = example_data["pos2"]
data = example_data["data"]
positions = Point2f.(pos[:,1], pos[:,2])

include("percy.jl")

begin
    f = Figure(resolution=(1000, 1000))
    interpolators = [DelaunayMesh(), ClaughTochter(), SplineInterpolator()]

    s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        data[:, idx, 1]
    end
    for (i, interpolation) in enumerate(interpolators)
        TopoPlots.topoplot(
            f[2, 1][1, i], data_obs, positions;
            contours=true,
            interpolation=interpolation, labels = string.(1:length(positions)), colorrange=(-1, 1),
            axis=(type=Axis, title="$interpolation",aspect=DataAspect(),))
    end
    @test_figure("all-interpolations", f)
end

begin
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
    @test_figure("delaunay-with-slider", f)
end

begin
    f, ax, pl = TopoPlots.topoplot(
        data[:, 340, 1], positions,
        axis=(; aspect=DataAspect()),
        colorrange=(-1, 1),
        padding_geometry = Rect,
        labels = string.(1:length(positions)),
        label_text=(; color=:white),
        label_scatter=(; strokewidth=2),
        contours=(linestyle=:dot, linewidth=2))
    @test_figure("more-parameters", f)
end


begin
    labels = string.(1:length(positions))
    f, ax, pl = TopoPlots.eegtopoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
    @test_figure("eeg-topoplot", f)
end

begin
    labels = TopoPlots.CHANNELS_10_20
    f, ax, pl = TopoPlots.eegtopoplot(data[1:19, 340, 1], labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
    @test_figure("eeg-topoplot2", f)
end
