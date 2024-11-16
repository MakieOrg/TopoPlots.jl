using Test
using Aqua
using PythonCall
using TopoPlots
using LinearAlgebra, Statistics, CairoMakie, FileIO
try
    matplotlib = PythonCall.pyimport("matplotlib")

catch e
    # I tried adding Conda for PyPlot, which then installs matplotlib automatically.
    # It looks like this messed with mne, so that then needed manual installation...
    # Now, Conda started making problems (in a fresh CI env?!) https://github.com/MakieOrg/TopoPlots.jl/pull/20#issuecomment-1224822002
    # So, lets go back to install matplotlib manually, and let mne install automatically!
    #run(PyCall.python_cmd(`-m pip install matplotlib`))#
    error("to be addressed")
end

using PyMNE
using PythonPlot
PythonPlot.pygui(false)

include("percy.jl")

@testset "Aqua" begin
    Aqua.test_all(TopoPlots; ambiguities=false)
end

data, positions = TopoPlots.example_data()

function mne_topoplot(fig, data, positions)
    circle = TopoPlots.enclosing_geometry(Circle, positions)
    # Seems like the only way to plot positions with matching head is to norm the positions..
    # Anything else leads to anarchy!
    positions_normed = map(positions) do pos
        return (pos .- circle.center) ./ (circle.r)
    end
    x, y = first.(positions_normed), last.(positions_normed)
    posmat = hcat(x, y)
    f = PythonPlot.figure()
    PyMNE.viz.plot_topomap(data, Py(posmat).to_numpy(); sphere=1.1, extrapolate="box",
                           cmap="RdBu_r", sensors=false, contours=6)
    PythonPlot.scatter(x, y; c=data, cmap="RdBu_r")
    PythonPlot.savefig("pymne_plot.png"; bbox_inches="tight", pad_inches=0, dpi=200)
    img = load("pymne_plot.png")
    rm("pymne_plot.png")
    s = Axis(fig; aspect=DataAspect())
    hidedecorations!(s)
    p = image!(s, rotr90(img))
    return s, p
end

function compare_to_mne(data, positions; kw...)
    f, ax, pl = TopoPlots.eeg_topoplot(data;
                                       interpolation=CloughTocher(; fill_value=NaN,
                                                                  tol=0.001,
                                                                  maxiter=1000,
                                                                  rescale=false),
                                       positions=positions, axis=(aspect=DataAspect(),),
                                       contours=(levels=6,),
                                       label_scatter=(markersize=10, strokewidth=0), kw...)
    hidedecorations!(ax)
    mne_topoplot(f[1, 2], data, positions)
    return f
end

@testset "interpolations" begin
    f = Makie.Figure(; resolution=(1000, 1000))
    interpolators = [DelaunayMesh(), CloughTocher(), SplineInterpolator()]

    s = Slider(f[:, 1]; range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        return data[:, idx, 1]
    end
    for (i, interpolation) in enumerate(interpolators)
        TopoPlots.topoplot(f[2, 1][1, i], data_obs, positions;
                           contours=true,
                           interpolation=interpolation, labels=string.(1:length(positions)),
                           colorrange=(-1, 1),
                           axis=(type=Axis, title="$interpolation", aspect=DataAspect()))
    end
    @test_figure("all-interpolations", f)
end

@testset "ClaughTochter" begin
    f = Makie.Figure(; resolution=(1000, 1000))
    @test_deprecated interpolation = ClaughTochter()

    f, ax, pl = TopoPlots.eeg_topoplot(1:length(TopoPlots.CHANNELS_10_20);
                                       labels=TopoPlots.CHANNELS_10_20, interpolation)
    @test_figure("ClaughTochter", f)
end

@testset "null interpolator" begin # empty eeg topoplot
    f, ax, pl = TopoPlots.eeg_topoplot(1:length(TopoPlots.CHANNELS_10_20);
                                       labels=TopoPlots.CHANNELS_10_20,
                                       interpolation=TopoPlots.NullInterpolator(),)
    @test_figure("nullInterpolator", f)
end

@testset "Delaunay with Slider" begin
    f = Makie.Figure(; size=(1000, 1000))
    s = Makie.Slider(f[:, 1]; range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        return data[:, idx, 1]
    end
    TopoPlots.topoplot(f[2, 1],
                       data_obs, positions;
                       interpolation=DelaunayMesh(),
                       labels=string.(1:length(positions)),
                       colorrange=(-1, 1),
                       axis=(title="delaunay mesh", aspect=DataAspect()))
    display(f)
    @test_figure("delaunay-with-slider", f)
end

@testset "keyword customization" begin
    f, ax, pl = TopoPlots.topoplot(data[:, 340, 1], positions;
                                   axis=(; aspect=DataAspect()),
                                   colorrange=(-1, 1),
                                   bounding_geometry=Rect,
                                   labels=string.(1:length(positions)),
                                   label_text=(; color=:white),
                                   label_scatter=(; strokewidth=2),
                                   contours=(linestyle=:dot, linewidth=2))
    @test_figure("more-parameters", f)
end

@testset "compare to MNE" begin
    data, positions = TopoPlots.example_data()
    f = compare_to_mne(data[:, 340, 1], positions)
    @test_figure("eeg-topoplot", f)

     labels = TopoPlots.CHANNELS_10_20
     pos = TopoPlots.labels2positions(TopoPlots.CHANNELS_10_20)
     f = compare_to_mne(data[1:19, 340, 1], pos)
     @test_figure("eeg-topoplot2", f)

    f = compare_to_mne(data[:, 340, 1], positions)
    @test_figure("eeg-topoplot3", f)

     positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
     posmat = hcat(first.(positions), last.(positions))
     data = zeros(length(positions))
     data[1] = 1.0
     f = compare_to_mne(data, positions)
     @test_figure("eeg-topoplot4", f)

    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    posmat = hcat(first.(positions), last.(positions))
    data = zeros(length(positions))
    data[1] = 1.0
    f = compare_to_mne(data, positions;
                       extrapolation=TopoPlots.GeomExtrapolation(; geometry=Circle))
    @test_figure("eeg-topoplot5", f)
end

@testset "extrapolation" begin
    data, positions = TopoPlots.example_data()
    extra = TopoPlots.GeomExtrapolation()
    pos_extra, data_extra, rect, rect_extended = extra(positions[1:19], data[1:19, 340, 1])

    f, ax, p = Makie.scatter(pos_extra; color=data_extra, axis=(aspect=DataAspect(),),
                             markersize=10)
    scatter!(ax, positions[1:19]; color=data[1:19, 340, 1], markersize=5,
             strokecolor=:white, strokewidth=0.5)
    lines!(ax, rect)
    lines!(ax, rect_extended; color=:red)
    @test_figure("test-extrapolate-data", f)

    data, positions = TopoPlots.example_data()
    extra = TopoPlots.GeomExtrapolation(; geometry=Circle)
    pos_extra, data_extra, rect, rect_extended = extra(positions[1:19], data[1:19, 340, 1])

    f, ax, p = Makie.scatter(pos_extra; color=data_extra, axis=(aspect=DataAspect(),),
                             markersize=10)
    scatter!(ax, positions[1:19]; color=data[1:19, 340, 1], markersize=5,
             strokecolor=:white, strokewidth=0.5)
    lines!(ax, rect)
    lines!(ax, rect_extended; color=:red)
    @test_figure("test-extrapolate-data-circle", f)
end

@testset "custom plotfnc" begin
    data, positions = TopoPlots.example_data()
    f, ax, pl = topoplot(1:10, positions[1:10]; (plotfnc!)=contourf!,
                         plotfnc_kwargs_names=[:colormap])
    @test_figure("test-contour-plotfnc!", f)
    f, ax, pl = topoplot(1:10, positions[1:10];
                         (plotfnc!)=(args...; kwargs...) -> heatmap!(args...; alpha=0.3,
                                                                     kwargs...))
    @test_figure("test-heatmap-with-alphs-plotfnc!", f)
end

@testset "channel labels" begin
    f = TopoPlots.eeg_topoplot(1:10; labels=TopoPlots.CHANNELS_10_20[1:10], label_text=true)
    @test_figure("test-eeg-channel-labels", f)
end

@testset "10/05 channel positions" begin
    pos = TopoPlots.labels2positions(TopoPlots.CHANNELS_10_20)
    pos10_05 = TopoPlots.labels2positions(TopoPlots.CHANNELS_10_05)
    @test pos[TopoPlots.CHANNELS_10_20 .== "t3"] ==
          pos10_05[TopoPlots.CHANNELS_10_05 .== "t7"]
    @test pos[TopoPlots.CHANNELS_10_20 .== "t4"] ==
          pos10_05[TopoPlots.CHANNELS_10_05 .== "t8"]
    @test pos[TopoPlots.CHANNELS_10_20 .== "t5"] ==
          pos10_05[TopoPlots.CHANNELS_10_05 .== "p7"]
    @test pos[TopoPlots.CHANNELS_10_20 .== "t6"] ==
          pos10_05[TopoPlots.CHANNELS_10_05 .== "p8"]
end
