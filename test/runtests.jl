using Test
using LinearAlgebra, Statistics, TopoPlots, CairoMakie, FileIO
using DataFrames
using PyCall
try
    PyCall.pyimport("matplotlib")
catch e
    # I tried adding Conda for PyPlot, which then installs matplotlib automatically.
    # It looks like this messed with mne, so that then needed manual installation...
    # Now, Conda started making problems (in a fresh CI env?!) https://github.com/MakieOrg/TopoPlots.jl/pull/20#issuecomment-1224822002
    # So, lets go back to install matplotlib manually, and let mne install automatically!
    run(PyCall.python_cmd(`-m pip install matplotlib`))
end
const PyMNE = try
    # XXX The hidden Conda.jl installation and the way dependency resolution works
    # means that PyMNE sometimes needs to be rebuilt to use the correct Python.
    using PyMNE
    PyMNE
catch
    @info "PyMNE failed to load; trying to the manual way."
    run(PyCall.python_cmd(`-m pip install mne`))
    pyimport("mne")
end
using PyPlot
PyPlot.pygui(false)


include("percy.jl")

data, positions = TopoPlots.example_data()

function mne_topoplot(fig, data, positions)
    circle = TopoPlots.enclosing_geometry(Circle, positions)
    # Seems like the only way to plot positions with matching head is to norm the positions..
    # Anything else leads to anarchy!
    positions_normed = map(positions) do pos
        (pos .- circle.center) ./ (circle.r)
    end
    x, y = first.(positions_normed), last.(positions_normed)
    posmat = hcat(first.(positions_normed), last.(positions_normed))
    f = PyPlot.figure()
    PyMNE.viz.plot_topomap(data, posmat, sphere=1.1, extrapolate="box", cmap="RdBu_r", sensors=false, contours=6)
    PyPlot.scatter(x, y, c=data, cmap="RdBu_r")
    PyPlot.savefig("pymne_plot.png", bbox_inches="tight", pad_inches = 0, dpi = 200)
    img = load("pymne_plot.png")
    rm("pymne_plot.png")
    s = Axis(fig; aspect=DataAspect())
    hidedecorations!(s)
    p = image!(s, rotr90(img))
    return s, p
end

function compare_to_mne(data, positions; kw...)
    f, ax, pl = TopoPlots.eeg_topoplot(data, nothing;
        interpolation=ClaughTochter(
            fill_value = NaN,
            tol = 0.001,
            maxiter = 1000,
            rescale = false),
        positions=positions, axis=(aspect=DataAspect(),), contours=(levels=6,),
        label_scatter=(markersize=10, strokewidth=0,), kw...)
    hidedecorations!(ax)
    mne_topoplot(f[1,2], data, positions)
    return f
end

begin
    f = Makie.Figure(resolution=(1000, 1000))
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
            axis=(type=Axis, title="$interpolation", aspect=DataAspect(),))
    end
    @test_figure("all-interpolations", f)
end


begin # empty eeg topoplot
    f, ax, pl = TopoPlots.eeg_topoplot(1:length(TopoPlots.CHANNELS_10_20),TopoPlots.CHANNELS_10_20; interpolation=TopoPlots.NullInterpolator(),)
    @test_figure("nullInterpolator", f)
end


begin
    f = Makie.Figure(resolution=(1000, 1000))
    s = Makie.Slider(f[:, 1], range=1:size(data, 2), startvalue=351)
    data_obs = map(s.value) do idx
        data[:, idx, 1]
    end
    TopoPlots.topoplot(
        f[2, 1],
        data_obs, positions,
        interpolation=DelaunayMesh(),
        labels = string.(1:length(positions)),
        colorrange=(-1, 1),
        axis=(title="delaunay mesh", aspect=DataAspect(),))
    display(f)
    @test_figure("delaunay-with-slider", f)
end

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
    f = compare_to_mne(data[:, 340, 1], positions)
    @test_figure("eeg-topoplot", f)
end

begin
    labels = TopoPlots.CHANNELS_10_20
    pos = TopoPlots.labels2positions(TopoPlots.CHANNELS_10_20)
    f = compare_to_mne(data[1:19, 340, 1], pos)
    @test_figure("eeg-topoplot2", f)
end

begin
    f = compare_to_mne(data[:, 340, 1], positions)
    @test_figure("eeg-topoplot3", f)
end


begin # df_timebin
        
    df = DataFrame(:erp=>repeat([1],20),:time=>(0:19) ./10,:label=>repeat([1],20))
    x = TopoPlots.df_timebin(df,1.5)
    @test  string.(x.time[1]) == "[0.0, 1.5)"

    x = TopoPlots.df_timebin(df,.5)
    @test  string.(x.time[1]) == "[0.0, 0.5)"
    @test  string.(x.time[4]) == "[1.5, 1.9]"

    x = TopoPlots.df_timebin(df,.1)
    @test nrow(x) == 20-1

    df = DataFrame(:erp=>repeat([1],20*3),:time=>repeat((0:19) ./10,3),:label=>repeat([1,2,3],20))
    x = TopoPlots.df_timebin(df,.1,grouping = [:label])
    @test nrow(x) == (20-1)* 3
end


begin #eeg_topoplot_series Matrix
    f = Figure(resolution=(1000, 1000))
    TopoPlots.eeg_topoplot_series!(f[1,1],data[:,:,1],40, topoplotCfg=(positions=positions,))
    @test_figure("eeg_topoplot_series Matrix",f)
end

begin #eeg_topoplot_series DataFrame
    df = DataFrame(data[:,:,1]',string.(1:size(positions,1)))
    df[!,:time] .= range(start=-0.3,step=1/500,length=size(data,2))
    df = stack(df,Not([:time]),variable_name=:label,value_name="erp")
    
    f = Figure(resolution=(1000, 1000))
    TopoPlots.eeg_topoplot_series!(f,df,0.1, topoplotCfg=(positions=positions,))
    @test_figure("eeg_topoplot_series DataFrame",f)
end
begin # eeg_topoplot_series row/col
   df_collect = []
    for k = 1:2
        df = DataFrame(data[:,:,k]',string.(1:size(positions,1)))
        df[!,:time] .= range(start=-0.3,step=1/500,length=size(data,2))
        df = stack(df,Not([:time]),variable_name=:label,value_name="erp")
        df.category .= k
        push!(df_collect,df)
    end
    df = vcat(df_collect...)

    f = Figure(resolution=(1000, 1000))
    TopoPlots.eeg_topoplot_series!(f,df,0.1;topoplotCfg=(positions=positions,),col=:time,row=:category)
    @test_figure("eeg_topoplot_series row_col",f)

    

begin
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    posmat = hcat(first.(positions), last.(positions))
    data = zeros(length(positions))
    data[1] = 1.0
    f = compare_to_mne(data, positions)
    @test_figure("eeg-topoplot4", f)
end

begin
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    posmat = hcat(first.(positions), last.(positions))
    data = zeros(length(positions))
    data[1] = 1.0
    f = compare_to_mne(data, positions; extrapolation=TopoPlots.GeomExtrapolation(geometry=Circle))
    @test_figure("eeg-topoplot5", f)
end

begin
    data, positions = TopoPlots.example_data()
    extra = TopoPlots.GeomExtrapolation()
    pos_extra, data_extra, rect, rect_extended = extra(positions[1:19], data[1:19, 340, 1])

    f, ax, p = Makie.scatter(pos_extra, color=data_extra, axis=(aspect=DataAspect(),), markersize=10)
    scatter!(ax, positions[1:19]; color=data[1:19, 340, 1], markersize=5, strokecolor=:white, strokewidth=0.5)
    lines!(ax, rect)
    lines!(ax, rect_extended, color=:red)
    @test_figure("test-extrapolate-data", f)
end

begin
    data, positions = TopoPlots.example_data()
    extra = TopoPlots.GeomExtrapolation(geometry=Circle)
    pos_extra, data_extra, rect, rect_extended = extra(positions[1:19], data[1:19, 340, 1])

    f, ax, p = Makie.scatter(pos_extra, color=data_extra, axis=(aspect=DataAspect(),), markersize=10)
    scatter!(ax, positions[1:19]; color=data[1:19, 340, 1], markersize=5, strokecolor=:white, strokewidth=0.5)
    lines!(ax, rect)
    lines!(ax, rect_extended, color=:red)
    @test_figure("test-extrapolate-data-circle", f)

end
