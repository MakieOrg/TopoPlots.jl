### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 2fafb0da-f3a9-11ec-0ddf-6725344070fe
begin
    using Pkg
    Pkg.activate("../../devEnv") # docs
    #Pkg.add("PyMNE")
    #Pkg.add(path="../../../TopoPlotsjl/")
    Pkg.develop(; path="../../../TopoPlotsjl/")
    #Pkg.add("DataFrames")
    #Pkg.add("AlgebraOfGraphics")
    #Pkg.add("StatsBase")
    #Pkg.add("CategoricalArrays")

    #Pkg.add("JLD2")

    #Pkg.add("CairoMakie")
end

# ╔═╡ c4a25915-c7f5-453a-a4f0-4b40ebedea4c
using Revise

# ╔═╡ 59b87673-02d2-4deb-90be-74d923d170eb
using TopoPlots

# ╔═╡ 452a245c-773a-4303-a970-f2592c3e879f
begin
    #using TopoPlots
    #using ../../../Topoplotsjl
    using CairoMakie
    using DataFrames
end

# ╔═╡ 77dc1ba9-9484-485b-a49d-9aa231ef4983
using Statistics

# ╔═╡ 311f10ff-deb8-4f82-8b12-d5b643656828
using PyMNE

# ╔═╡ 9fa5c598-3578-4989-9585-29fd32ae1056
using Distributions

# ╔═╡ 6cda29dc-7086-4079-83c6-3650204a82ff
pathof(TopoPlots)

# ╔═╡ e0cc560f-d3e8-415b-b22d-6bca23ef093c
revise(TopoPlots)

# ╔═╡ f4b81740-d907-42ae-a0df-f46fb2f2cb15
begin
    data = Array{Float32}(undef, 64, 400, 3)
    #read!(TopoPlots.assetpath("example-data.bin"), data)
    read!(splitdir(pathof(TopoPlots))[1] * "/../assets/example-data.bin", data)

    positions = Vector{Point2f}(undef, 64)
    read!(splitdir(pathof(TopoPlots))[1] * "/../assets/layout64.bin", positions)
    #read!(TopoPlots.assetpath("layout64.bin"), positions)

end;

# ╔═╡ 42f7755b-80f4-4185-8d21-42e11730e0fc
begin
    using Random
    pos = positions[1:10]
    eeg_topoplot(rand(MersenneTwister(1), length(pos)), string.(1:length(pos));
                 positions=pos, pad_value=0.0)
end

# ╔═╡ aad784ee-6bb7-4f3c-8444-be050456ddea
eeg_topoplot(data[:, 340, 1], string.(1:length(positions)); positions=positions)

# ╔═╡ 237e4f4a-cdf2-4bac-8096-de8050251745
eeg_topoplot(data[:, 340, 1], string.(1:length(positions)); positions=positions,
             pad_value=0.1)

# ╔═╡ f522329b-3653-4059-9955-8cd05570e923
topoplot(rand(MersenneTwister(1), length(pos)), pos)

# ╔═╡ a9d2a2e2-6c8c-4cfc-9fed-b5e082cb44af
let
    mon = PyMNE.channels.make_standard_montage("standard_1020")

    posMat = (Matrix(hcat(pos...)) .- 0.5) .* 0.5
    #pos = PyMNE.channels.make_eeg_layout(mon).pos
    PyMNE.viz.plot_topomap(rand(MersenneTwister(1), length(pos)), posMat'; cmap="RdBu_r",
                           extrapolate="box", border=-1)
end

# ╔═╡ c358633f-8d18-4c5e-80f7-ab972e8860be
Pkg.status("TopoPlots")

# ╔═╡ c0a2ad2e-ccce-4e80-b52c-75f1428ed182
e1eg_topoplot(data[:, 340, 1], string.(1:length(positions)); positions=positions,
              interpolation=TopoPlots.NormalMixtureInterpolator())

# ╔═╡ d7620a42-d54c-4244-a820-d15aecdae626
@time TopoPlots.eeg_topoplot_series(data[:, :, 1], 40;
                                    topoplotCfg=(positions=positions, label_scatter=false))

# ╔═╡ ec59c704-ae33-4a62-82ce-63acc6b17793
f, ax, pl = TopoPlots.eeg_topoplot(1:length(TopoPlots.CHANNELS_10_20),
                                   TopoPlots.CHANNELS_10_20;
                                   interpolation=TopoPlots.NullInterpolator(),)

# ╔═╡ f3d1f3cc-f7c9-4ef4-ba4f-3d32f2509cad
let
    # 4 coordinates with one peak
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1)]
    i = 1
    peak_xy = positions[i]
    data = zeros(length(positions))
    data[i] = 1.1
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
    x = range(minx, maxx; length=size(m, 1))
    y = range(miny, maxy; length=size(m, 2))
    xys = Point2f.(x, y')

    # find the highest point
    _, i = findmax(x -> isnan(x) ? -Inf : x, m)
    xy = xys[i]
    @show peak_xy
    @show xy
    #@test isapprox(xy, peak_xy; atol=0.02)
    @show isapprox(xy, peak_xy; atol=0.02)
    fig
end

# ╔═╡ 872ac6a4-ddaa-4dfb-a40d-9d5ea55bdb3d
let
    f = Figure()
    axis = Axis(f[1, 1]; aspect=1)
    xlims!(; low=-2, high=2)
    ylims!(; low=-2, high=2)

    data = [0, 0, 0]
    pos1 = [Point2f(-1, -1), Point2f(-1.0, 0.0), Point2f(0, -1)]
    pos2 = [Point2f(1, 1), Point2f(1.0, 0.0), Point2f(0, 1)]

    pos1 = pos1 .- mean(pos1)
    pos2 = pos2 .- mean(pos2)
    eeg_topoplot!(axis, data; positions=pos1)
    eeg_topoplot!(axis, data; positions=pos2)
    f
end

# ╔═╡ Cell order:
# ╠═2fafb0da-f3a9-11ec-0ddf-6725344070fe
# ╠═6cda29dc-7086-4079-83c6-3650204a82ff
# ╠═c4a25915-c7f5-453a-a4f0-4b40ebedea4c
# ╠═e0cc560f-d3e8-415b-b22d-6bca23ef093c
# ╠═59b87673-02d2-4deb-90be-74d923d170eb
# ╠═452a245c-773a-4303-a970-f2592c3e879f
# ╠═f4b81740-d907-42ae-a0df-f46fb2f2cb15
# ╠═77dc1ba9-9484-485b-a49d-9aa231ef4983
# ╠═aad784ee-6bb7-4f3c-8444-be050456ddea
# ╠═237e4f4a-cdf2-4bac-8096-de8050251745
# ╠═42f7755b-80f4-4185-8d21-42e11730e0fc
# ╠═f522329b-3653-4059-9955-8cd05570e923
# ╠═311f10ff-deb8-4f82-8b12-d5b643656828
# ╠═a9d2a2e2-6c8c-4cfc-9fed-b5e082cb44af
# ╠═c358633f-8d18-4c5e-80f7-ab972e8860be
# ╠═9fa5c598-3578-4989-9585-29fd32ae1056
# ╠═c0a2ad2e-ccce-4e80-b52c-75f1428ed182
# ╠═d7620a42-d54c-4244-a820-d15aecdae626
# ╠═ec59c704-ae33-4a62-82ce-63acc6b17793
# ╠═f3d1f3cc-f7c9-4ef4-ba4f-3d32f2509cad
# ╠═872ac6a4-ddaa-4dfb-a40d-9d5ea55bdb3d
