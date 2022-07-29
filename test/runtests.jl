using Test
using LinearAlgebra, Statistics, TopoPlots, CairoMakie

include("percy.jl")

data, positions = TopoPlots.example_data()

begin
    f = Figure(resolution=(1000, 1000))
    interpolators = [ClaughTochter(), SplineInterpolator()]

    s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        data[:, idx, 1]
    end
    for (i, interpolation) in enumerate(interpolators)
        TopoPlots.topoplot(
            f[2, 1][1, i], data_obs, positions;
            contours=true,
            interpolation=interpolation, labels = string.(1:length(positions)), colorrange=(-1, 1),
            axis=(type=Axis, title="$interpolation", aspect=DataAspect(),))
    end
    f
    @test_figure("all-interpolations", f)
end

begin # empty eeg topoplot
    f, ax, pl = TopoPlots.eeg_topoplot(1:length(TopoPlots.CHANNELS_10_20),TopoPlots.CHANNELS_10_20; interpolation=TopoPlots.NullInterpolator(),)
    @test_figure("nullInterpolator", f)
end

@testset "peaks" begin
    # 4 coordinates with one peak
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1)]
    i = 1
    peak_xy = positions[i]
    data = zeros(length(positions))
    data[i] = 1
    fig = topoplot(data, positions)
    # tighten the limits so that the limits of the axis and the data will match
    tightlimits!(fig.axis)

    # retrieve the interpolated data
    m = fig.plot.plots[].color[]
    # get the limits of the axes and data
    rect = fig.axis.targetlimits[]
    minx, miny = minimum(rect)
    maxx, maxy = maximum(rect)
    # recreate the coordinates of the data
    x = range(minx, maxx, length=size(m, 1))
    y = range(miny, maxy, length=size(m, 2))
    xys = Point2f.(x, y')

    # find the highest point
    _, i = findmax(x -> isnan(x) ? -Inf : x, m)
    xy = xys[i]
    @test isapprox(xy, peak_xy; atol=0.02)
end

# begin
#     f = Figure(resolution=(1000, 1000))
#     s = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
#     data_obs = map(s.value) do idx
#         data[:, idx, 1]
#     end
#     TopoPlots.topoplot(
#         f[2, 1],
#         data_obs, positions,
#         interpolation=DelaunayMesh(),
#         labels = string.(1:length(positions)),
#         colorrange=(-1, 1),
#         colormap=[:red, :blue],
#         axis=(title="delaunay mesh", aspect=DataAspect(),))
#     display(f)
#     @test_figure("delaunay-with-slider", f)
# end

begin
    f, ax, pl = TopoPlots.topoplot(
        data[:, 340, 1], positions,
        axis=(; aspect=DataAspect()),
        colorrange=(-1, 1),
        bounding_geometry = Rect,
        labels = string.(1:length(positions)),
        label_text=(; color=:white),
        label_scatter=(; strokewidth=2),
        contours=(linestyle=:dot, linewidth=2))
    @test_figure("more-parameters", f)
end


begin
    labels = string.(1:length(positions))
    f, ax, pl = TopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),), head=(color=:green, linewidth=3,))
    @test_figure("eeg-topoplot", f)
end

begin
    labels = TopoPlots.CHANNELS_10_20
    f, ax, pl = TopoPlots.eeg_topoplot(data[1:19, 340, 1], labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
    @test_figure("eeg-topoplot2", f)
end

begin
    f, ax, pl = eeg_topoplot(data[:, 340, 1]; positions=positions)
    @test_figure("eeg-topoplot3", f)
end

